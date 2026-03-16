// empora-backend/routes/moduleRoutes.js
// Factory that returns an Express router for any module model.

const express  = require('express');
const { verifyToken } = require('../middleware/authMiddleware');
const upload   = require('../middleware/uploadMiddleware');
const { createModuleController } = require('../controllers/moduleController');

function createModuleRouter(Model) {
  const router = express.Router();
  const ctrl   = createModuleController(Model);

  // PDF download — supports ?token= query param (browser direct link)
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

  router.use(verifyToken);

  router.post('/create',           ctrl.createRecord);
  router.get('/my',                ctrl.getMyRecords);
  router.get('/:id',               ctrl.getRecordById);
  router.delete('/:id',            ctrl.deleteRecord);
  router.put('/:id/upload',        upload.single('moduleFile'), ctrl.uploadSlotFile);
  router.get('/:id/data',          ctrl.getModuleData);
  router.post('/:id/ai-report',    ctrl.saveAiReport);

  return router;
}

module.exports = { createModuleRouter };