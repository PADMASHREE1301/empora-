// empora-backend/models/Submission.js

const mongoose = require('mongoose');

const SubmissionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    moduleType: {
      type: String,
      enum: [
        'cyber_security',
        'fund_raising',
        'land_legal',
        'licence',
        'loans',
        'project_management',
        'restructure',
        'risk_management',
        'stratic',
        'taxation',
      ],
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    uploadedFiles: [
      {
        fileName: { type: String },
        fileUrl:  { type: String },
        fileSize: { type: Number },
        uploadedAt: { type: Date, default: Date.now },
      },
    ],
    status: {
      type: String,
      enum: ['pending', 'processing', 'approved', 'rejected', 'completed'],
      default: 'pending',
    },
    adminNotes:      { type: String, default: '' },
    rejectionReason: { type: String, default: '' },

    // Generated report
    report: {
      summary:     { type: String, default: '' }, // Page 1 — visible to ALL users
      fullContent: { type: String, default: '' }, // Full report — membership only
      reportUrl:   { type: String, default: null }, // PDF — membership only
      generatedAt: { type: Date },
    },

    isReportGenerated: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Submission', SubmissionSchema);