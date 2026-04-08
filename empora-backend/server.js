// empora-backend/server.js

const express      = require('express');
const mongoose     = require('mongoose');
const dotenv       = require('dotenv');
const cors         = require('cors');
const cookieParser = require('cookie-parser');
const path         = require('path');

dotenv.config();

const app = express();

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors({ origin: process.env.CLIENT_URL || '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ─── Auth middleware imports ──────────────────────────────────────────────────
const { verifyToken }   = require('./middleware/authMiddleware');
const { approvalGate }  = require('./middleware/approvalGate');

// ─── Module route factory ─────────────────────────────────────────────────────
const { createModuleRouter } = require('./routes/moduleRoutes');

// ─── Routes ───────────────────────────────────────────────────────────────────

// Auth routes — NO approval gate (login/register must be public)
app.use('/api/auth',  require('./routes/authRoutes'));

// Admin routes — NO approval gate (admin has its own guard: verifyToken + adminOnly)
app.use('/api/admin', require('./routes/adminRoutes'));

// ── Payment — verifyToken only, NO approvalGate ───────────────────────────────
// Reason: any logged-in user (even pending-approval) must be able to pay.
// The approvalGate would block them before they can upgrade, which is wrong.
// Payment routes internally use verifyToken via paymentRoutes.js already.
app.use('/api/payment', require('./routes/paymentRoutes'));

// ── All routes below require: valid token + admin-approved account ─────────────
// The approvalGate middleware blocks anyone with isApproved: false or isActive: false.

app.use('/api/fund',
  verifyToken, approvalGate, require('./routes/fundRaisingRoutes'));

app.use('/api/ai',
  verifyToken, approvalGate, require('./routes/aiRoutes'));

app.use('/api/chat',
  verifyToken, approvalGate, require('./routes/chatRoutes'));

app.use('/api/notifications',
  verifyToken, approvalGate, require('./routes/notificationRoutes'));

// Each module gets its OWN collection — all protected by approvalGate
app.use('/api/stratic',
  verifyToken, approvalGate, createModuleRouter(require('./models/Stratic')));

app.use('/api/taxation',
  verifyToken, approvalGate, createModuleRouter(require('./models/Taxation')));

app.use('/api/landLegal',
  verifyToken, approvalGate, createModuleRouter(require('./models/LandLegal')));

app.use('/api/licence',
  verifyToken, approvalGate, createModuleRouter(require('./models/Licence')));

app.use('/api/loans',
  verifyToken, approvalGate, createModuleRouter(require('./models/Loans')));

app.use('/api/riskManagement',
  verifyToken, approvalGate, createModuleRouter(require('./models/RiskManagement')));

app.use('/api/projectManagement',
  verifyToken, approvalGate, createModuleRouter(require('./models/ProjectManagement')));

app.use('/api/cyberSecurity',
  verifyToken, approvalGate, createModuleRouter(require('./models/CyberSecurity')));

app.use('/api/restructure',
  verifyToken, approvalGate, createModuleRouter(require('./models/Restructure')));

// ─── Health check (public) ────────────────────────────────────────────────────
app.get('/api/health', (req, res) =>
  res.json({ success: true, message: 'Empora API is running.' })
);

// ─── 404 handler ──────────────────────────────────────────────────────────────
app.use((req, res) =>
  res.status(404).json({ success: false, message: 'Route not found.' })
);

// ─── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error.',
  });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () =>
  console.log(`🚀 Empora server running on port ${PORT}`)
);

// ─── Database Connect ─────────────────────────────────────────────────────────
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected');

    const { checkMembershipExpiry } = require('./controllers/notificationController');
    checkMembershipExpiry();
    setInterval(checkMembershipExpiry, 24 * 60 * 60 * 1000);
    console.log('⏰ Membership expiry checker started');
    console.log('📦 Collections: fundraisings, stratics, taxations, landlegals, licences, loans, riskmanagements, projectmanagements, cybersecurities, restructures');
  })
  .catch((err) => {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });