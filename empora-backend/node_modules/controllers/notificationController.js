// empora-backend/controllers/notificationController.js

const Notification = require('../models/Notification');
const User         = require('../models/User');

// ─── GET all notifications for logged-in user ────────────────────────────────
const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);

    const unreadCount = await Notification.countDocuments({
      userId: req.user.id,
      isRead: false,
    });

    res.json({ success: true, notifications, unreadCount });
  } catch (err) {
    console.error('getNotifications error:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// ─── GET unread count only ────────────────────────────────────────────────────
const getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Notification.countDocuments({
      userId: req.user.id,
      isRead: false,
    });
    res.json({ success: true, unreadCount });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to get unread count' });
  }
};

// ─── MARK single notification as read ────────────────────────────────────────
const markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, notification });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to mark as read' });
  }
};

// ─── MARK ALL notifications as read ──────────────────────────────────────────
const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user.id, isRead: false },
      { isRead: true }
    );
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to mark all as read' });
  }
};

// ─── DELETE single notification ───────────────────────────────────────────────
const deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
};

// ─── CLEAR ALL notifications for user ────────────────────────────────────────
const clearAll = async (req, res) => {
  try {
    await Notification.deleteMany({ userId: req.user.id });
    res.json({ success: true, message: 'All notifications cleared' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to clear notifications' });
  }
};

// ─── CREATE notification (internal helper — not a route) ──────────────────────
const createNotification = async ({ userId, title, message, type = 'system', icon = 'notifications', color = '#1A3A6B' }) => {
  try {
    const notification = await Notification.create({ userId, title, message, type, icon, color });
    return notification;
  } catch (err) {
    console.error('createNotification error:', err);
    return null;
  }
};

// ─── MEMBERSHIP EXPIRY CHECKER (called from server.js daily) ─────────────────
const checkMembershipExpiry = async () => {
  try {
    const now     = new Date();
    const in3Days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    // Find members whose membership expires within the next 3 days (expiry warning)
    const soonExpiring = await User.find({
      isMember:        true,
      membershipExpiry: { $gte: now, $lte: in3Days },
    });

    for (const user of soonExpiring) {
      // Avoid duplicate warning notifications
      const alreadyNotified = await Notification.findOne({
        userId:    user._id,
        type:      'membership_expiry',
        createdAt: { $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000) }, // within last 24h
      });

      if (!alreadyNotified) {
        const daysLeft = Math.ceil((user.membershipExpiry - now) / (1000 * 60 * 60 * 24));
        await createNotification({
          userId:  user._id,
          title:   '⚠️ Membership Expiring Soon',
          message: `Your EMPORA membership expires in ${daysLeft} day${daysLeft === 1 ? '' : 's'}. Renew now to keep access.`,
          type:    'membership_expiry',
          icon:    'warning',
          color:   '#F5A623',
        });
      }
    }

    // Find members whose membership has just expired (expired today)
    const justExpired = await User.find({
      isMember:        true,
      membershipExpiry: { $lt: now },
    });

    for (const user of justExpired) {
      // Downgrade user membership
      await User.findByIdAndUpdate(user._id, { isMember: false, role: 'free' });

      // Avoid duplicate expired notifications
      const alreadyNotified = await Notification.findOne({
        userId:    user._id,
        type:      'membership_expired',
        createdAt: { $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000) },
      });

      if (!alreadyNotified) {
        await createNotification({
          userId:  user._id,
          title:   '❌ Membership Expired',
          message: 'Your EMPORA membership has expired. Renew to regain access to all 10 advisory modules.',
          type:    'membership_expired',
          icon:    'error',
          color:   '#E74C3C',
        });
      }
    }

    console.log(`✅ Membership expiry check done: ${soonExpiring.length} expiring, ${justExpired.length} expired`);
  } catch (err) {
    console.error('checkMembershipExpiry error:', err);
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAll,
  createNotification,
  checkMembershipExpiry,
};