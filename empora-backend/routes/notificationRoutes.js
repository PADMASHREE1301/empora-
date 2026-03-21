// empora-backend/routes/notificationRoutes.js

const express    = require('express');
const router     = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAll,
} = require('../controllers/notificationController');

router.get('/',              verifyToken, getNotifications);
router.get('/unread-count',  verifyToken, getUnreadCount);
router.put('/read-all',      verifyToken, markAllAsRead);
router.put('/:id/read',      verifyToken, markAsRead);
router.delete('/clear-all',  verifyToken, clearAll);
router.delete('/:id',        verifyToken, deleteNotification);

module.exports = router;