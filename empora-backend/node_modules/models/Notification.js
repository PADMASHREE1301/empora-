// empora-backend/models/Notification.js

const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title:   { type: String, required: true },
    message: { type: String, required: true },
    type: {
      type: String,
      enum: ['welcome', 'membership_expiry', 'membership_expired',
             'profile_complete', 'ai_tip', 'system', 'payment'],
      default: 'system',
    },
    isRead:   { type: Boolean, default: false },
    icon:     { type: String, default: 'notifications' },
    color:    { type: String, default: '#1A3A6B' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', NotificationSchema);