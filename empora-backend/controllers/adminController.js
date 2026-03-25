// empora-backend/controllers/adminController.js

const User = require('../models/User');

// Safe require — Submission model may not exist yet
let Submission;
try { Submission = require('../models/Submission'); } catch (_) { Submission = null; }

// Safe require — Settings model may not exist yet
let Settings;
try { Settings = require('../models/Settings'); } catch (_) { Settings = null; }

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────
exports.getDashboardStats = async (req, res) => {
  try {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const [totalUsers, freeUsers, membershipUsers, newThisWeek] = await Promise.all([
      User.countDocuments({ role: { $ne: 'admin' } }),
      User.countDocuments({ role: 'free' }),
      User.countDocuments({ role: 'membership' }),
      User.countDocuments({ role: { $ne: 'admin' }, createdAt: { $gte: sevenDaysAgo } }),
    ]);

    // Submission stats — only if model exists
    let subStats = { total: 0, pending: 0, approved: 0, rejected: 0, completed: 0 };
    let moduleStats = [];
    if (Submission) {
      const [total, pending, approved, rejected, completed] = await Promise.all([
        Submission.countDocuments(),
        Submission.countDocuments({ status: 'pending' }),
        Submission.countDocuments({ status: 'approved' }),
        Submission.countDocuments({ status: 'rejected' }),
        Submission.countDocuments({ status: 'completed' }),
      ]);
      subStats = { total, pending, approved, rejected, completed };
      moduleStats = await Submission.aggregate([
        { $group: { _id: '$moduleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]);
    }

    return res.status(200).json({
      success: true,
      stats: {
        users: { total: totalUsers, free: freeUsers, membership: membershipUsers, newThisWeek },
        submissions: subStats,
        moduleStats,
      },
    });
  } catch (err) {
    console.error('getDashboardStats error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/admin/users ─────────────────────────────────────────────────────
exports.getAllUsers = async (req, res) => {
  try {
    const { role, search, page = 1, limit = 50 } = req.query;

    const query = { role: { $ne: 'admin' } };
    if (role)   query.role = role;
    if (search) {
      query.$or = [
        { name:  { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }

    const total = await User.countDocuments(query);
    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    return res.status(200).json({ success: true, total, users });
  } catch (err) {
    console.error('getAllUsers error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── PATCH /api/admin/users/:userId ──────────────────────────────────────────
exports.updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { role, membershipStatus, isActive } = req.body;

    const user = await User.findById(userId);
    if (!user || user.role === 'admin') {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    if (role !== undefined)             user.role = role;
    if (membershipStatus !== undefined) user.membershipStatus = membershipStatus;
    if (isActive !== undefined)         user.isActive = isActive;

    if (role === 'membership' && membershipStatus === 'active') {
      user.membershipStartDate = new Date();
      user.membershipEndDate   = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      user.membershipExpiry    = user.membershipEndDate;
      user.isMember            = true;
    }

    if (role === 'free') {
      user.isMember         = false;
      user.membershipStatus = 'inactive';
    }

    await user.save({ validateBeforeSave: false });
    return res.status(200).json({ success: true, message: 'User updated.', user });
  } catch (err) {
    console.error('updateUser error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/admin/submissions ───────────────────────────────────────────────
exports.getAllSubmissions = async (req, res) => {
  if (!Submission) return res.json({ success: true, total: 0, submissions: [] });
  try {
    const { status, moduleType, page = 1, limit = 50 } = req.query;
    const query = {};
    if (status)     query.status = status;
    if (moduleType) query.moduleType = moduleType;

    const total       = await Submission.countDocuments(query);
    const submissions = await Submission.find(query)
      .populate('user', 'name email role membershipStatus')
      .sort({ createdAt: -1 })
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    return res.status(200).json({ success: true, total, submissions });
  } catch (err) {
    console.error('getAllSubmissions error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/admin/submissions/:submissionId ─────────────────────────────────
exports.getSubmissionDetail = async (req, res) => {
  if (!Submission) return res.status(404).json({ success: false, message: 'Not found.' });
  try {
    const submission = await Submission.findById(req.params.submissionId)
      .populate('user', 'name email role membershipStatus');
    if (!submission) {
      return res.status(404).json({ success: false, message: 'Submission not found.' });
    }
    return res.status(200).json({ success: true, submission });
  } catch (err) {
    console.error('getSubmissionDetail error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── PATCH /api/admin/submissions/:submissionId/approve ───────────────────────
exports.approveSubmission = async (req, res) => {
  if (!Submission) return res.status(404).json({ success: false, message: 'Not found.' });
  try {
    const { adminNotes } = req.body;
    const submission = await Submission.findByIdAndUpdate(
      req.params.submissionId,
      { status: 'approved', adminNotes: adminNotes || '' },
      { new: true }
    ).populate('user', 'name email');

    if (!submission) {
      return res.status(404).json({ success: false, message: 'Submission not found.' });
    }
    return res.status(200).json({ success: true, message: 'Submission approved.', submission });
  } catch (err) {
    console.error('approveSubmission error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── PATCH /api/admin/submissions/:submissionId/reject ────────────────────────
exports.rejectSubmission = async (req, res) => {
  if (!Submission) return res.status(404).json({ success: false, message: 'Not found.' });
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason) {
      return res.status(400).json({ success: false, message: 'Rejection reason is required.' });
    }
    const submission = await Submission.findByIdAndUpdate(
      req.params.submissionId,
      { status: 'rejected', rejectionReason },
      { new: true }
    ).populate('user', 'name email');

    if (!submission) {
      return res.status(404).json({ success: false, message: 'Submission not found.' });
    }
    return res.status(200).json({ success: true, message: 'Submission rejected.', submission });
  } catch (err) {
    console.error('rejectSubmission error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/admin/pricing ───────────────────────────────────────────────────
exports.getPricing = async (req, res) => {
  try {
    // If Settings model exists, use it — otherwise return defaults
    if (Settings) {
      const doc     = await Settings.findOne({ key: 'membership_pricing' });
      const pricing = doc?.value ?? { monthly: 999, yearly: 7999 };
      return res.status(200).json({ success: true, pricing });
    }
    return res.status(200).json({ success: true, pricing: { monthly: 999, yearly: 7999 } });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── PUT /api/admin/pricing ───────────────────────────────────────────────────
exports.updatePricing = async (req, res) => {
  try {
    const { monthly, yearly } = req.body;

    if (!monthly || !yearly || isNaN(monthly) || isNaN(yearly)) {
      return res.status(400).json({
        success: false, message: 'Provide valid monthly and yearly prices (in ₹).',
      });
    }
    if (Number(monthly) < 1 || Number(yearly) < 1) {
      return res.status(400).json({
        success: false, message: 'Prices must be greater than 0.',
      });
    }

    if (Settings) {
      await Settings.findOneAndUpdate(
        { key: 'membership_pricing' },
        {
          value:     { monthly: Number(monthly), yearly: Number(yearly) },
          updatedBy: req.user?.id,
          updatedAt: new Date(),
        },
        { upsert: true, new: true }
      );
    }

    return res.status(200).json({
      success: true,
      message: 'Pricing updated successfully.',
      pricing: { monthly: Number(monthly), yearly: Number(yearly) },
    });
  } catch (err) {
    console.error('updatePricing error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};