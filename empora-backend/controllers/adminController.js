// empora-backend/controllers/adminController.js

const User       = require('../models/User');
const Submission = require('../models/Submission');

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────
exports.getDashboardStats = async (req, res) => {
  try {
    const [
      totalUsers, freeUsers, membershipUsers,
      totalSubs, pendingSubs, approvedSubs, rejectedSubs, completedSubs,
    ] = await Promise.all([
      User.countDocuments({ role: { $ne: 'admin' } }),
      User.countDocuments({ role: 'free' }),
      User.countDocuments({ role: 'membership' }),
      Submission.countDocuments(),
      Submission.countDocuments({ status: 'pending' }),
      Submission.countDocuments({ status: 'approved' }),
      Submission.countDocuments({ status: 'rejected' }),
      Submission.countDocuments({ status: 'completed' }),
    ]);

    const moduleStats = await Submission.aggregate([
      { $group: { _id: '$moduleType', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const newThisWeek  = await User.countDocuments({
      role: { $ne: 'admin' },
      createdAt: { $gte: sevenDaysAgo },
    });

    return res.status(200).json({
      success: true,
      stats: {
        users: {
          total: totalUsers,
          free: freeUsers,
          membership: membershipUsers,
          newThisWeek,
        },
        submissions: {
          total:     totalSubs,
          pending:   pendingSubs,
          approved:  approvedSubs,
          rejected:  rejectedSubs,
          completed: completedSubs,
        },
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
    const { role, search, page = 1, limit = 20 } = req.query;

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
      .skip((page - 1) * limit)
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
  try {
    const { status, moduleType, page = 1, limit = 20 } = req.query;

    const query = {};
    if (status)     query.status = status;
    if (moduleType) query.moduleType = moduleType;

    const total       = await Submission.countDocuments(query);
    const submissions = await Submission.find(query)
      .populate('user', 'name email role membershipStatus')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    return res.status(200).json({ success: true, total, submissions });
  } catch (err) {
    console.error('getAllSubmissions error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/admin/submissions/:id ──────────────────────────────────────────
exports.getSubmissionDetail = async (req, res) => {
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

// ─── PATCH /api/admin/submissions/:id/approve ─────────────────────────────────
exports.approveSubmission = async (req, res) => {
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

// ─── PATCH /api/admin/submissions/:id/reject ──────────────────────────────────
exports.rejectSubmission = async (req, res) => {
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
const Settings = require('../models/Settings');

exports.getPricing = async (req, res) => {
  try {
    const doc = await Settings.findOne({ key: 'membership_pricing' });
    const pricing = doc?.value ?? { monthly: 999, yearly: 7999 };
    return res.status(200).json({ success: true, pricing });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── PUT /api/admin/pricing ───────────────────────────────────────────────────
exports.updatePricing = async (req, res) => {
  try {
    const { monthly, yearly } = req.body;

    if (!monthly || !yearly || isNaN(monthly) || isNaN(yearly)) {
      return res.status(400).json({ success: false, message: 'Provide valid monthly and yearly prices (in ₹).' });
    }

    if (monthly < 1 || yearly < 1) {
      return res.status(400).json({ success: false, message: 'Prices must be greater than 0.' });
    }

    await Settings.findOneAndUpdate(
      { key: 'membership_pricing' },
      { value: { monthly: Number(monthly), yearly: Number(yearly) }, updatedBy: req.user.id, updatedAt: new Date() },
      { upsert: true, new: true }
    );

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