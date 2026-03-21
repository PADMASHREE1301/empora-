// empora-backend/routes/adminRoutes.js

const express    = require('express');
const router     = express.Router();
const admin      = require('../controllers/adminController');
const { verifyToken, adminOnly } = require('../middleware/authMiddleware');

const guard = [verifyToken, adminOnly];

router.get('/dashboard',          ...guard, admin.getDashboardStats);
router.get('/users',              ...guard, admin.getAllUsers);
router.patch('/users/:id',        ...guard, admin.updateUser);
router.get('/submissions',        ...guard, admin.getAllSubmissions);
router.patch('/submissions/:id/approve', ...guard, admin.approveSubmission);
router.patch('/submissions/:id/reject',  ...guard, admin.rejectSubmission);

// ── Pricing ──────────────────────────────────────────────────────────────────
router.get('/pricing',            ...guard, admin.getPricing);
router.put('/pricing',            ...guard, admin.updatePricing);

module.exports = router;
// empora-backend/routes/adminRoutes.js
// ─────────────────────────────────────────────────────────────────────────────
// PASTE THESE 4 LINES into your existing adminRoutes.js:
//
// 1. Add this require near the top (with your other controller requires):
const { getPendingUsers, approveUser, rejectUser } = require('../controllers/userApprovalController');
//
// 2. Add these 3 routes (anywhere before module.exports = router):
router.get('/pending-users',          verifyToken, isAdmin, getPendingUsers);
router.post('/approve-user/:userId',  verifyToken, isAdmin, approveUser);
router.post('/reject-user/:userId',   verifyToken, isAdmin, rejectUser);