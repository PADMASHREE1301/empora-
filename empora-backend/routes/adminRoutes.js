// empora-backend/routes/adminRoutes.js

const express    = require('express');
const router     = express.Router();
const { verifyToken, adminOnly } = require('../middleware/authMiddleware');
const ctrl       = require('../controllers/adminController');

// All admin routes require: valid token + admin role
router.use(verifyToken, adminOnly);

// ─── Dashboard & Stats ────────────────────────────────────────────────────────
router.get('/dashboard',  ctrl.getDashboardStats);

// ─── Users ───────────────────────────────────────────────────────────────────
router.get('/users',           ctrl.getAllUsers);
router.patch('/users/:userId', ctrl.updateUser);

// ─── Pending user approval flow ───────────────────────────────────────────────
router.get('/pending-users',             ctrl.getPendingUsers);
router.post('/approve-user/:userId',     ctrl.approveUser);
router.post('/reject-user/:userId',      ctrl.rejectUser);

// ─── Submissions ──────────────────────────────────────────────────────────────
router.get('/submissions',                                ctrl.getAllSubmissions);
router.get('/submissions/:submissionId',                  ctrl.getSubmissionDetail);
router.patch('/submissions/:submissionId/approve',        ctrl.approveSubmission);
router.patch('/submissions/:submissionId/reject',         ctrl.rejectSubmission);

// ─── Pricing ─────────────────────────────────────────────────────────────────
router.get('/pricing',  ctrl.getPricing);
router.put('/pricing',  ctrl.updatePricing);

module.exports = router;