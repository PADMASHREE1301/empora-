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
    role: {
      type: String,
      enum: ['free', 'membership', 'admin'],
      default: 'free',
    },
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
    profilePicture: { type: String, default: null },
    lastLogin:      { type: Date,   default: null  },
    isActive:       { type: Boolean, default: true  },
    isAdmin:        { type: Boolean, default: false },  // ← true for admin accounts
    isMember:       { type: Boolean, default: false },  // ← true when membership active
    isApproved:     { type: Boolean, default: false },  // ← admin must approve new users
    membershipExpiry: { type: Date, default: null },    // ← used by expiry checker

    // ── Top-level contact (used by approval screen) ───────────────────────────
    phone:   { type: String, default: '' },
    company: { type: String, default: '' },

    // ── Founder Profile ───────────────────────────────────────────────────────
    founderProfileComplete: { type: Boolean, default: false }, // ← used by auth_provider
    founderProfile: {
      phone:         { type: String, default: null },
      city:          { type: String, default: null },
      state:         { type: String, default: null },
      businessName:  { type: String, default: null },
      businessType:  { type: String, default: null },
      industry:      { type: String, default: null },
      businessStage: { type: String, default: null },
      teamSize:      { type: String, default: null },
      annualRevenue: { type: String, default: null },
      fundingStage:  { type: String, default: null },
      yearFounded:   { type: Number, default: null },
      primaryGoal:   { type: String, default: null },
      challenges:    { type: [String], default: [] },
      isComplete:    { type: Boolean, default: false },
    },
  },
  {
    timestamps: true,
  }
);

UserSchema.methods.hasMembership = function () {
  return (
    this.isMember === true &&
    this.membershipStatus === 'active' &&
    (this.membershipExpiry == null || this.membershipExpiry > new Date())
  );
};

module.exports = mongoose.model('User', UserSchema);