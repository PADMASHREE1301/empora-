// empora-backend/routes/chatRoutes.js

const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/authMiddleware'); // ✅ FIXED
const {
  sendMessage,
  getHistory,
  clearChat,
} = require('../controllers/chatController');

// All chat routes require authentication
router.use(verifyToken);

// POST   /api/chat/:module/message   — send a message, get AI reply
router.post('/:module/message', sendMessage);

// GET    /api/chat/:module/history   — load past conversation
router.get('/:module/history', getHistory);

// DELETE /api/chat/:module/clear     — clear conversation
router.delete('/:module/clear', clearChat);

module.exports = router;