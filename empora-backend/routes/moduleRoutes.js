// empora-backend/routes/moduleRoutes.js
// Factory that returns an Express router for any module model.
//
// CRITICAL ROUTE ORDER RULE:
// Specific routes (/:id/data, /:id/upload, /:id/ai-report)
// MUST be registered BEFORE the wildcard /:id route.
// If /:id is registered first, Express matches it for every
// request and the specific sub-routes are never reached → 404.

const express = require('express');
const { verifyToken } = require('../middleware/authMiddleware');
const upload  = require('../middleware/uploadMiddleware');
const { createModuleController } = require('../controllers/moduleController');

function createModuleRouter(Model) {
  const router = express.Router();
  const ctrl   = createModuleController(Model);

  // ── Public PDF download (supports ?token= query param for browser links) ──
  router.get('/:id/report/pdf', (req, res, next) => {
    if (!req.headers.authorization && req.query.token) {
      const jwt = require('jsonwebtoken');
      try {
        req.user = jwt.verify(req.query.token, process.env.JWT_SECRET);
      } catch (_) {
        return res.status(401).json({ success: false, message: 'Invalid token.' });
      }
    }
    next();
  }, ctrl.downloadReportPdf);

  // ── All routes below require a valid JWT ───────────────────────────────────
  router.use(verifyToken);

  // Collection-level routes (no :id)
  router.post('/create', ctrl.createRecord);
  router.get('/my',      ctrl.getMyRecords);

  // ── IMPORTANT: specific sub-routes BEFORE the bare /:id wildcard ──────────
  // If /:id is placed first, Express will match it for /:id/data,
  // /:id/upload, /:id/ai-report etc., and those handlers are never called.

  router.get('/:id/data',          ctrl.getModuleData);
  router.put('/:id/upload',        upload.single('moduleFile'), ctrl.uploadSlotFile);
  router.post('/:id/ai-report',    ctrl.saveAiReport);
  router.get('/:id/report/pdf',    ctrl.downloadReportPdf);

  // Wildcard /:id must come LAST
  router.get('/:id',    ctrl.getRecordById);
  router.delete('/:id', ctrl.deleteRecord);

  return router;
}

module.exports = { createModuleRouter };