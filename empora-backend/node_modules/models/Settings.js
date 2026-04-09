// empora-backend/models/Settings.js

const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema(
  {
    key:       { type: String, required: true, unique: true },
    value:     { type: mongoose.Schema.Types.Mixed },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.models.Settings || mongoose.model('Settings', settingsSchema);