// empora-backend/routes/reportRoutes.js

const express = require('express');
const router  = express.Router();

const {
  createSubmission,
  getMySubmissions,
  getReport,
  downloadReport,
} = require('../controllers/reportController');

const { verifyToken, membershipOnly } = require('../middleware/authMiddleware');

// All routes require login
router.use(verifyToken);

router.post('/',                             createSubmission);   // All users
router.get('/my',                            getMySubmissions);   // All users
router.get('/:submissionId',                 getReport);          // Role-filtered inside
router.get('/:submissionId/download',        membershipOnly, downloadReport); // Members only

module.exports = router;