// empora-backend/routes/adminRoutes.js

const express    = require('express');
const router     = express.Router();
const admin      = require('../controllers/adminController');
const { verifyToken, adminOnly } = require('../middleware/authMiddleware');
const { getPendingUsers, approveUser, rejectUser } = require('../controllers/userApprovalController');

const guard = [verifyToken, adminOnly];

router.get('/dashboard',                  ...guard, admin.getDashboardStats);
router.get('/users',                      ...guard, admin.getAllUsers);
router.patch('/users/:id',                ...guard, admin.updateUser);
router.get('/submissions',                ...guard, admin.getAllSubmissions);
router.patch('/submissions/:id/approve',  ...guard, admin.approveSubmission);
router.patch('/submissions/:id/reject',   ...guard, admin.rejectSubmission);

// ── Pricing ───────────────────────────────────────────────────────────────────
router.get('/pricing',                    ...guard, admin.getPricing);
router.put('/pricing',                    ...guard, admin.updatePricing);

// ── User Approval ─────────────────────────────────────────────────────────────
router.get('/pending-users',              ...guard, getPendingUsers);
router.post('/approve-user/:userId',      ...guard, approveUser);
router.post('/reject-user/:userId',       ...guard, rejectUser);

module.exports = router;