// empora-backend/controllers/authController.js

const User         = require('../models/User');
const bcrypt       = require('bcryptjs');
const jwt          = require('jsonwebtoken');
const Notification = require('../models/Notification');

// ─── Helpers ──────────────────────────────────────────────────────────────────

const generateToken = (userId) =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
};

// ─── @route   POST /api/auth/register ─────────────────────────────────────────
exports.register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email and password are required.',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters.',
      });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists.',
      });
    }

    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    // ── CHANGED: default role is now 'free' instead of 'founder' ──────────────
    const allowedRoles = ['free', 'membership'];
    const assignedRole = allowedRoles.includes(role) ? role : 'free';

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: hashedPassword,
      role: assignedRole,
    });

    // Send welcome notification
    await Notification.create({
      userId:  user._id,
      title:   '🎉 Welcome to EMPORA!',
      message: 'Your account is ready. Complete your business profile to get personalized AI advice from all 10 advisors.',
      type:    'welcome',
      icon:    'celebration',
      color:   '#1A3A6B',
    });

    const token = generateToken(user._id);
    res.cookie('token', token, cookieOptions);

    return res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      token,
      user: {
        id:               user._id,
        name:             user.name,
        email:            user.email,
        role:             user.role,
        membershipStatus: user.membershipStatus,
        isMember:         user.hasMembership(),
        isAdmin:          user.role === 'admin',
        createdAt:        user.createdAt,
      },
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

// ─── @route   POST /api/auth/login ────────────────────────────────────────────
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    user.lastLogin = new Date();
    await user.save({ validateBeforeSave: false });

    const token = generateToken(user._id);
    res.cookie('token', token, cookieOptions);

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        id:                 user._id,
        name:               user.name,
        email:              user.email,
        role:               user.role,
        membershipStatus:   user.membershipStatus,
        membershipEndDate:  user.membershipEndDate,
        // ── NEW: convenience flags for Flutter ────────────────────────────────
        isMember:           user.hasMembership(),
        isAdmin:            user.role === 'admin',
        lastLogin:          user.lastLogin,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Server error. Please try again.' });
  }
};

// ─── @route   POST /api/auth/logout ───────────────────────────────────────────
exports.logout = async (req, res) => {
  res.clearCookie('token');
  return res.status(200).json({ success: true, message: 'Logged out successfully.' });
};

// ─── @route   GET /api/auth/me ────────────────────────────────────────────────
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    return res.status(200).json({
      success: true,
      user: {
        id:                 user._id,
        name:               user.name,
        email:              user.email,
        role:               user.role,
        membershipStatus:   user.membershipStatus,
        membershipPlan:     user.membershipPlan,
        membershipEndDate:  user.membershipEndDate,
        isMember:           user.hasMembership(),
        isAdmin:            user.role === 'admin',
        profilePicture:     user.profilePicture,
        createdAt:          user.createdAt,
        founderProfile:     user.founderProfile,
      },
    });
  } catch (err) {
    console.error('GetMe error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   PUT /api/auth/update-profile ────────────────────────────────────
exports.updateProfile = async (req, res) => {
  try {
    const { name, email } = req.body;
    const updates = {};

    if (name) updates.name = name.trim();
    if (email) {
      const taken = await User.findOne({
        email: email.toLowerCase(),
        _id: { $ne: req.user.id },
      });
      if (taken) {
        return res.status(409).json({ success: false, message: 'Email already in use by another account.' });
      }
      updates.email = email.toLowerCase().trim();
    }

    if (req.file) {
      updates.profilePicture = `/uploads/${req.file.filename}`;
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updates },
      { new: true, runValidators: true }
    ).select('-password');

    return res.status(200).json({ success: true, message: 'Profile updated successfully.', user });
  } catch (err) {
    console.error('UpdateProfile error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   PUT /api/auth/change-password ───────────────────────────────────
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Current and new passwords are required.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'New password must be at least 6 characters.' });
    }

    const user = await User.findById(req.user.id).select('+password');
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }

    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    return res.status(200).json({ success: true, message: 'Password changed successfully.' });
  } catch (err) {
    console.error('ChangePassword error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   DELETE /api/auth/delete-account ─────────────────────────────────
exports.deleteAccount = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user.id);
    res.clearCookie('token');
    return res.status(200).json({ success: true, message: 'Account deleted successfully.' });
  } catch (err) {
    console.error('DeleteAccount error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   POST /api/auth/upgrade-membership ── NEW ───────────────────────
// @desc    Upgrade current user to membership plan
// @access  Private
exports.upgradeMembership = async (req, res) => {
  try {
    const { plan } = req.body; // 'monthly' | 'yearly'

    if (!['monthly', 'yearly'].includes(plan)) {
      return res.status(400).json({ success: false, message: "Plan must be 'monthly' or 'yearly'." });
    }

    const durationMs  = plan === 'monthly'
      ? 30  * 24 * 60 * 60 * 1000
      : 365 * 24 * 60 * 60 * 1000;

    const now     = new Date();
    const endDate = new Date(now.getTime() + durationMs);

    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        role:                'membership',
        membershipStatus:    'active',
        membershipPlan:       plan,
        membershipStartDate:  now,
        membershipEndDate:    endDate,
      },
      { new: true }
    );

    // Send membership notification
    await Notification.create({
      userId:  req.user.id,
      title:   '🏆 Membership Activated!',
      message: `Your ${plan} membership is now active. All 10 AI advisor modules are unlocked. Enjoy!`,
      type:    'payment',
      icon:    'workspace_premium',
      color:   '#C9A030',
    });

    return res.status(200).json({
      success: true,
      message: `Successfully upgraded to ${plan} membership.`,
      user: {
        id:                user._id,
        name:              user.name,
        email:             user.email,
        role:              user.role,
        membershipStatus:  user.membershipStatus,
        membershipPlan:    user.membershipPlan,
        membershipEndDate: user.membershipEndDate,
        isMember:          user.hasMembership(),
        isAdmin:           user.role === 'admin',
      },
    });
  } catch (err) {
    console.error('UpgradeMembership error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   PUT /api/auth/founder-profile ───────────────────────────────────
exports.saveFounderProfile = async (req, res) => {
  try {
    const {
      phone, city, state,
      businessName, businessType, industry, businessStage,
      yearFounded, teamSize, annualRevenue, fundingStage,
      primaryGoal, challenges,
    } = req.body;

    const update = {
      'founderProfile.phone':         phone         || null,
      'founderProfile.city':          city          || null,
      'founderProfile.state':         state         || null,
      'founderProfile.businessName':  businessName  || null,
      'founderProfile.businessType':  businessType  || null,
      'founderProfile.industry':      industry      || null,
      'founderProfile.businessStage': businessStage || null,
      'founderProfile.yearFounded':   yearFounded   || null,
      'founderProfile.teamSize':      teamSize      || null,
      'founderProfile.annualRevenue': annualRevenue || null,
      'founderProfile.fundingStage':  fundingStage  || null,
      'founderProfile.primaryGoal':   primaryGoal   || null,
      'founderProfile.challenges':    challenges    || [],
      'founderProfile.isComplete':    true,
    };

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: update },
      { new: true }
    ).select('-password');

    return res.status(200).json({
      success: true,
      message: 'Founder profile saved.',
      founderProfile: user.founderProfile,
    });
  } catch (err) {
    console.error('saveFounderProfile error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── @route   GET /api/auth/founder-profile ───────────────────────────────────
exports.getFounderProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('founderProfile');
    return res.status(200).json({ success: true, founderProfile: user.founderProfile });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};