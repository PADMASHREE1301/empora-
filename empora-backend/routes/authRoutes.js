// empora-backend/routes/authRoutes.js

const express        = require('express');
const router         = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// Public
router.post('/register',        authController.register);
router.post('/login',           authController.login);
router.post('/logout',          authController.logout);

// Protected
router.get('/me',               verifyToken, authController.getMe);
router.put('/update-profile',   verifyToken, upload.single('profilePicture'), authController.updateProfile);
router.put('/change-password',  verifyToken, authController.changePassword);
router.delete('/delete-account',verifyToken, authController.deleteAccount);
router.post('/upgrade-membership', verifyToken, authController.upgradeMembership);

// ── Founder profile ──────────────────────────────────────────────────────────
router.put('/founder-profile',  verifyToken, authController.saveFounderProfile);
router.get('/founder-profile',  verifyToken, authController.getFounderProfile);

module.exports = router;