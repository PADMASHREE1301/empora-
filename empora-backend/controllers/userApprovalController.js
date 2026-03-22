// empora-backend/controllers/userApprovalController.js

const User                   = require('../models/User');
const { createNotification } = require('./notificationController');

// ─── GET /api/admin/pending-users ─────────────────────────────────────────────
const getPendingUsers = async (req, res) => {
  try {
    const users = await User.find({
      isApproved: false,
      isAdmin:    { $ne: true },    // exclude isAdmin flag
      role:       { $ne: 'admin' }, // exclude legacy admin role string
    })
      .sort({ createdAt: -1 })
      .select('name email phone company createdAt role');

    res.json({ success: true, users, total: users.length });
  } catch (err) {
    console.error('getPendingUsers error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch pending users' });
  }
};

// ─── POST /api/admin/approve-user/:userId ─────────────────────────────────────
const approveUser = async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { isApproved: true },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    await createNotification({
      userId:  user._id,
      title:   '🎉 Account Approved!',
      message: 'Your EMPORA account has been approved by the admin. Welcome aboard! You can now access all modules.',
      type:    'welcome',
      icon:    'celebration',
      color:   '#27AE60',
    });

    res.json({ success: true, message: `${user.name} approved successfully`, user });
  } catch (err) {
    console.error('approveUser error:', err);
    res.status(500).json({ success: false, message: 'Failed to approve user' });
  }
};

// ─── POST /api/admin/reject-user/:userId ──────────────────────────────────────
const rejectUser = async (req, res) => {
  try {
    const { reason } = req.body;
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    try {
      await createNotification({
        userId:  user._id,
        title:   '❌ Account Not Approved',
        message: reason?.trim()
          ? `Your account was not approved. Reason: ${reason}`
          : 'Your account registration was not approved. Please contact support.',
        type:    'system',
        icon:    'error',
        color:   '#E74C3C',
      });
    } catch (_) {}

    await User.findByIdAndDelete(req.params.userId);
    res.json({ success: true, message: 'User rejected and removed' });
  } catch (err) {
    console.error('rejectUser error:', err);
    res.status(500).json({ success: false, message: 'Failed to reject user' });
  }
};

module.exports = { getPendingUsers, approveUser, rejectUser };