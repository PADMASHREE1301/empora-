// empora-backend/controllers/reportController.js

const Submission = require('../models/Submission');

// ─── POST /api/reports ────────────────────────────────────────────────────────
exports.createSubmission = async (req, res) => {
  try {
    const { moduleType, title } = req.body;

    const uploadedFiles = req.files
      ? req.files.map((f) => ({
          fileName: f.originalname,
          fileUrl:  f.path,
          fileSize: f.size,
        }))
      : [];

    const submission = await Submission.create({
      user: req.user._id,
      moduleType,
      title,
      uploadedFiles,
      status: 'pending',
    });

    return res.status(201).json({ success: true, submission });
  } catch (err) {
    console.error('createSubmission error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/reports/my ──────────────────────────────────────────────────────
exports.getMySubmissions = async (req, res) => {
  try {
    const submissions = await Submission.find({ user: req.user._id })
      .sort({ createdAt: -1 });
    return res.status(200).json({ success: true, submissions });
  } catch (err) {
    console.error('getMySubmissions error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/reports/:submissionId ──────────────────────────────────────────
// Free user  → summary only (page 1)
// Member     → full content + download URL
exports.getReport = async (req, res) => {
  try {
    const submission = await Submission.findOne({
      _id:  req.params.submissionId,
      user: req.user._id,
    });

    if (!submission) {
      return res.status(404).json({ success: false, message: 'Report not found.' });
    }

    if (!submission.isReportGenerated) {
      return res.status(200).json({
        success: true,
        reportReady: false,
        message: 'Report is still being generated.',
      });
    }

    const isMember = req.user.hasMembership() || req.user.role === 'admin';

    if (isMember) {
      return res.status(200).json({
        success: true,
        reportReady: true,
        isMember: true,
        report: {
          summary:     submission.report.summary,
          fullContent: submission.report.fullContent,
          reportUrl:   submission.report.reportUrl,
          generatedAt: submission.report.generatedAt,
        },
        moduleType: submission.moduleType,
        title:      submission.title,
        status:     submission.status,
      });
    } else {
      // Free user — page 1 only
      return res.status(200).json({
        success: true,
        reportReady: true,
        isMember: false,
        report: {
          summary:     submission.report.summary,
          fullContent: null,
          reportUrl:   null,
        },
        moduleType:     submission.moduleType,
        title:          submission.title,
        status:         submission.status,
        upgradeMessage: 'Upgrade to membership to view the full report and download the PDF.',
      });
    }
  } catch (err) {
    console.error('getReport error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── GET /api/reports/:submissionId/download (membership only) ────────────────
exports.downloadReport = async (req, res) => {
  try {
    const submission = await Submission.findOne({
      _id:  req.params.submissionId,
      user: req.user._id,
    });

    if (!submission || !submission.report.reportUrl) {
      return res.status(404).json({ success: false, message: 'Report PDF not available.' });
    }

    return res.status(200).json({ success: true, reportUrl: submission.report.reportUrl });
  } catch (err) {
    console.error('downloadReport error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};