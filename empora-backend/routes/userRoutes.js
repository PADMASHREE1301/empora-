const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// GET /api/user/profile
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.status(200).json({ success: true, ...user.toObject() });
  } catch (err) {
    res.status(500).json({ message: 'Could not fetch profile' });
  }
});

// PUT /api/user/profile
router.put(
  '/profile',
  protect,
  [
    body('name').optional().notEmpty().withMessage('Name cannot be empty'),
    body('email').optional().isEmail().withMessage('Invalid email'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: errors.array()[0].msg });
    }
    const { name, phone, company, avatar } = req.body;
    try {
      const user = await User.findByIdAndUpdate(
        req.user._id,
        { name, phone, company, avatar },
        { new: true, runValidators: true }
      );
      res.status(200).json({ success: true, user });
    } catch (err) {
      res.status(500).json({ message: 'Profile update failed' });
    }
  }
);

// PUT /api/user/change-password
router.put('/change-password', protect, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  try {
    const user = await User.findById(req.user._id).select('+password');
    if (!(await user.matchPassword(currentPassword))) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ message: 'New password must be at least 6 characters' });
    }
    user.password = newPassword;
    await user.save();
    res.status(200).json({ success: true, message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Password change failed' });
  }
});

module.exports = router;