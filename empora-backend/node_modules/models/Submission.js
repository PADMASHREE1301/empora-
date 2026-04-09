// empora-backend/models/Submission.js

const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    title: {
      type: String,
      default: 'Untitled Submission',
      trim: true,
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
      default: 'fund_raising',
    },

    status: {
      type: String,
      enum: ['pending', 'processing', 'approved', 'rejected', 'completed'],
      default: 'pending',
    },

    // NEW (from your update)
    content: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    // EXISTING (file uploads)
    uploadedFiles: [
      {
        fileName: { type: String },
        fileUrl: { type: String },
        fileSize: { type: Number },
        uploadedAt: { type: Date, default: Date.now },
      },
    ],

    adminNotes: { type: String, default: '' },
    rejectionReason: { type: String, default: '' },

    // EXISTING (report system)
    report: {
      summary: { type: String, default: '' },
      fullContent: { type: String, default: '' },
      reportUrl: { type: String, default: null },
      generatedAt: { type: Date },
    },

    isReportGenerated: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Prevent model overwrite issue
module.exports =
  mongoose.models.Submission ||
  mongoose.model('Submission', submissionSchema);