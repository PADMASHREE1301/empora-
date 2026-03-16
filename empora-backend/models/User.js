// empora-backend/models/User.js

const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: [80, 'Name cannot exceed 80 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email address'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: 6,
      select: false,
    },
    // ── CHANGED: was ['founder','investor','admin'], now ['free','membership','admin'] ──
    role: {
      type: String,
      enum: ['free', 'membership', 'admin'],
      default: 'free',
    },
    // ── NEW: membership fields ────────────────────────────────────────────────
    membershipStatus: {
      type: String,
      enum: ['inactive', 'active', 'expired'],
      default: 'inactive',
    },
    membershipPlan: {
      type: String,
      enum: ['monthly', 'yearly', null],
      default: null,
    },
    membershipStartDate: { type: Date, default: null },
    membershipEndDate:   { type: Date, default: null },
    // ─────────────────────────────────────────────────────────────────────────
    profilePicture: { type: String, default: null },
    lastLogin:      { type: Date,   default: null  },
    isActive:       { type: Boolean, default: true },
  },
  {
    timestamps: true,
  }
);

// ── NEW helper method ─────────────────────────────────────────────────────────
UserSchema.methods.hasMembership = function () {
  return (
    this.role === 'membership' &&
    this.membershipStatus === 'active' &&
    this.membershipEndDate != null &&
    this.membershipEndDate > new Date()
  );
};

module.exports = mongoose.model('User', UserSchema);