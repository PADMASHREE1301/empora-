// empora-backend/middleware/approvalGate.js
//
// PURPOSE:
//   Blocks any logged-in user who has NOT been approved by an admin
//   from accessing protected API routes.
//
// USAGE in server.js:
//   app.use('/api/someRoute', verifyToken, approvalGate, require('./routes/someRoute'));
//
// Admin users (role === 'admin') always bypass this check.

const User = require('../models/User');

const approvalGate = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Not authenticated.' });
    }

    const user = await User.findById(userId).select('role isAdmin isApproved isActive');

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found.' });
    }

    // Admins always pass through
    if (user.role === 'admin' || user.isAdmin === true) return next();

    // Block deactivated accounts
    if (user.isActive === false) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated. Please contact support.',
        code: 'ACCOUNT_DEACTIVATED',
      });
    }

    // Block users not yet approved by admin
    if (!user.isApproved) {
      return res.status(403).json({
        success: false,
        message: 'Your account is pending admin approval. You will be notified once approved.',
        code: 'PENDING_APPROVAL',
      });
    }

    next();
  } catch (err) {
    console.error('approvalGate error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

module.exports = { approvalGate };