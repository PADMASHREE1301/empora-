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

// ─── Module route factory ─────────────────────────────────────────────────────
const { createModuleRouter } = require('./routes/moduleRoutes');

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth',               require('./routes/authRoutes'));
app.use('/api/fund',               require('./routes/fundRaisingRoutes'));
app.use('/api/ai',                 require('./routes/aiRoutes'));
app.use('/api/admin',              require('./routes/adminRoutes'));
app.use('/api/payment',            require('./routes/paymentRoutes'));
app.use('/api/chat',               require('./routes/chatRoutes'));
app.use('/api/notifications',      require('./routes/notificationRoutes'));

// Each module gets its OWN collection and route prefix
app.use('/api/stratic',            createModuleRouter(require('./models/Stratic')));
app.use('/api/taxation',           createModuleRouter(require('./models/Taxation')));
app.use('/api/landLegal',          createModuleRouter(require('./models/LandLegal')));
app.use('/api/licence',            createModuleRouter(require('./models/Licence')));
app.use('/api/loans',              createModuleRouter(require('./models/Loans')));
app.use('/api/riskManagement',     createModuleRouter(require('./models/RiskManagement')));
app.use('/api/projectManagement',  createModuleRouter(require('./models/ProjectManagement')));
app.use('/api/cyberSecurity',      createModuleRouter(require('./models/CyberSecurity')));
app.use('/api/restructure',        createModuleRouter(require('./models/Restructure')));

// Health check
app.get('/api/health', (req, res) =>
  res.json({ success: true, message: 'Empora API is running.' })
);

// 404 handler
app.use((req, res) =>
  res.status(404).json({ success: false, message: 'Route not found.' })
);

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error.',
  });
});

// ─── Start Server First ───────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () =>
  console.log(`🚀 Empora server running on port ${PORT}`)
);

// ─── Database Connect ─────────────────────────────────────────────────────────
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected');

    // ─── Daily membership expiry check (runs every 24 hours) ─────────────────
    const { checkMembershipExpiry } = require('./controllers/notificationController');
    checkMembershipExpiry(); // run once on startup
    setInterval(checkMembershipExpiry, 24 * 60 * 60 * 1000); // then every 24h
    console.log('⏰ Membership expiry checker started');
    console.log('📦 Collections: fundraisings, stratics, taxations, landlegals, licences, loans, riskmanagements, projectmanagements, cybersecurities, restructures');
  })
  .catch((err) => {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });