// empora-backend/config/db.js
// Kept for reference — connection is handled in server.js directly.
// You can import this instead if you prefer a separate config.

const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
  } catch (err) {
    console.error(`❌ DB Error: ${err.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;