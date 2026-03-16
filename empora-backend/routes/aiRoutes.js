// empora-backend/routes/aiRoutes.js
// Proxies the Groq AI analysis request.
// The Flutter app can call this endpoint instead of Groq directly
// to keep the API key server-side (recommended for production).

const express = require('express');
const router = express.Router();
const { analyzeStartup } = require('../controllers/aiController');
const { verifyToken } = require('../middleware/authMiddleware');

// POST /api/ai/analyze
// Body: { pitchDeck: {...}, valuation: {...}, comments: {...} }
router.post('/analyze', verifyToken, analyzeStartup);

module.exports = router;