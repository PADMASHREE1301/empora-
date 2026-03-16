// empora-backend/createAdmin.js
// Run once: node createAdmin.js

const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');
const dotenv   = require('dotenv');

dotenv.config();

const UserSchema = new mongoose.Schema({
  name:             String,
  email:            String,
  password:         String,
  role:             String,
  membershipStatus: String,
  isActive:         Boolean,
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);

async function createAdmin() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ MongoDB connected');

  // Check if admin already exists
  const existing = await User.findOne({ email: 'admin@empora.com' });
  if (existing) {
    console.log('⚠️  Admin already exists. Skipping.');
    process.exit(0);
  }

  const salt     = await bcrypt.genSalt(12);
  const password = await bcrypt.hash('Admin@1234', salt);

  await User.create({
    name:             'Empora Admin',
    email:            'admin@empora.com',
    password,
    role:             'admin',
    membershipStatus: 'inactive',
    isActive:         true,
  });

  console.log('🎉 Admin created successfully!');
  console.log('📧 Email:    admin@empora.com');
  console.log('🔑 Password: Admin@1234');
  console.log('👉 Change the password after first login!');
  process.exit(0);
}

createAdmin().catch((err) => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});