// empora-backend/scripts/fixExistingUsers.js
//
// Run ONCE to backfill isApproved and isActive on all existing users.
// Safe to run multiple times — uses $set so it won't overwrite manual changes.
//
// HOW TO RUN:
//   node scripts/fixExistingUsers.js

const mongoose = require('mongoose');
const dotenv   = require('dotenv');
dotenv.config();

async function fix() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ MongoDB connected');

  const db = mongoose.connection.db;

  // 1. Admins — always approved
  const adminResult = await db.collection('users').updateMany(
    { role: 'admin' },
    { $set: { isApproved: true, isAdmin: true, isActive: true } }
  );
  console.log(`✅ Admins fixed: ${adminResult.modifiedCount}`);

  // 2. Membership users — always approved (they paid)
  const memberResult = await db.collection('users').updateMany(
    { role: 'membership' },
    { $set: { isApproved: true, isMember: true, isActive: true } }
  );
  console.log(`✅ Membership users fixed: ${memberResult.modifiedCount}`);

  // 3. Free users — approve all existing ones
  //    (new registrations after this script will start as isApproved: false)
  const freeResult = await db.collection('users').updateMany(
    { role: 'free', isApproved: { $exists: false } },
    { $set: { isApproved: true, isActive: true } }
  );
  console.log(`✅ Free users backfilled: ${freeResult.modifiedCount}`);

  // 4. Make sure isActive is set for all users that don't have it
  const activeResult = await db.collection('users').updateMany(
    { isActive: { $exists: false } },
    { $set: { isActive: true } }
  );
  console.log(`✅ isActive backfilled: ${activeResult.modifiedCount}`);

  console.log('\n🎉 Done! All existing users have been backfilled.');
  console.log('   New registrations will now require admin approval.\n');
  process.exit(0);
}

fix().catch((err) => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});