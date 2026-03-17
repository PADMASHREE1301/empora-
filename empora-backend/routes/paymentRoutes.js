// empora-backend/routes/paymentRoutes.js

const express = require('express');
const router  = express.Router();

const { verifyToken } = require('../middleware/authMiddleware');
const {
  getPricing,
  createOrder,
  verifyPayment,
  webhook,
  getStatus,
} = require('../controllers/paymentController');

// Public route — no auth required
router.get('/pricing', getPricing);

// Webhook — NO auth (called by Razorpay directly)
router.post('/webhook', express.raw({ type: 'application/json' }), webhook);

// Protected routes
router.post('/create-order', verifyToken, createOrder);
router.post('/verify',       verifyToken, verifyPayment);
router.get('/status',        verifyToken, getStatus);

module.exports = router;