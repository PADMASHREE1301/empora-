// empora-backend/routes/fundRaisingRoutes.js

const express = require('express');
const router  = express.Router();

const {
  createFundRaising,
  getMyFundRaisings,
  getFundRaisingById,
  getExtractedText,
  getModuleData,
  updatePitchDeck,
  updateValuation,
  updateComments,
  uploadModuleFile,
  saveAiReport,
  deleteFundRaising,
  getAllFundRaisings,
  downloadModuleReportPdf,
} = require('../controllers/fundRaisingController');

const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// ── PDF download — before auth so browser can open directly with ?token= ────
router.get('/:id/module/:moduleName/report/pdf', (req, res, next) => {
  if (!req.headers.authorization && req.query.token) {
    const jwt = require('jsonwebtoken');
    try {
      req.user = jwt.verify(req.query.token, process.env.JWT_SECRET);
    } catch (_) {
      return res.status(401).json({ success: false, message: 'Invalid token.' });
    }
  }
  next();
}, downloadModuleReportPdf);

router.use(verifyToken);

router.post('/create', createFundRaising);
router.get('/my',      getMyFundRaisings);
router.get('/all',     getAllFundRaisings);

// ── Must be declared BEFORE /:id ─────────────────────────────────────────────
router.get('/:id/extracted-text',          getExtractedText);
router.get('/:id/module/:moduleName',      getModuleData);

router.get('/:id',    getFundRaisingById);
router.delete('/:id', deleteFundRaising);

// ── Fundraising section updates ───────────────────────────────────────────────
router.put('/:id/pitch-deck', upload.single('pitchFile'),     updatePitchDeck);
router.put('/:id/valuation',  upload.single('valuationFile'), updateValuation);
router.put('/:id/comments',   upload.single('commentsFile'),  updateComments);

// ── Generic module file upload (Risk, Project, Cyber, Restructure, etc.) ─────
// Body: { module: 'riskManagement', slotKey: 'strategicRisks' }
router.put('/:id/module-upload', upload.single('commentsFile'), uploadModuleFile);

// ── AI report save (works for all modules) ────────────────────────────────────
// Body: { module: 'riskManagement', verdict: '...', scores: {...}, ... }
router.post('/:id/ai-report', saveAiReport);

module.exports = router;