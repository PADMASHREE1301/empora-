// empora-backend/controllers/paymentController.js

const Razorpay  = require('razorpay');
const crypto    = require('crypto');
const User      = require('../models/User');
const Settings  = require('../models/Settings');

const razorpay = new Razorpay({
  key_id:     process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// ── Default fallback prices in paise (₹ × 100) ───────────────────────────────
const DEFAULT_PLANS = {
  monthly: { amount: 99900,  label: 'Monthly', description: 'EMPORA Monthly Membership' },
  yearly:  { amount: 799900, label: 'Yearly',  description: 'EMPORA Yearly Membership'  },
};

// ── Fetch live pricing from DB, fallback to defaults ─────────────────────────
async function getPlans() {
  try {
    const doc = await Settings.findOne({ key: 'membership_pricing' });
    if (doc && doc.value) {
      return {
        monthly: { ...DEFAULT_PLANS.monthly, amount: Math.round(doc.value.monthly * 100) },
        yearly:  { ...DEFAULT_PLANS.yearly,  amount: Math.round(doc.value.yearly  * 100) },
      };
    }
  } catch (_) {}
  return DEFAULT_PLANS;
}

// ─── GET /api/payment/pricing (public — no auth required) ────────────────────
exports.getPricing = async (req, res) => {
  try {
    const doc     = await Settings.findOne({ key: 'membership_pricing' });
    const pricing = doc?.value ?? { monthly: 999, yearly: 7999 };
    return res.status(200).json({ success: true, pricing });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ─── POST /api/payment/create-order ──────────────────────────────────────────
exports.createOrder = async (req, res) => {
  try {
    console.log('=== createOrder called ===');
    console.log('User:', req.user ? req.user.id : 'NO USER - auth failed');
    console.log('Body:', req.body);

    const { plan } = req.body;
    const plans    = await getPlans();

    if (!plans[plan]) {
      return res.status(400).json({ success: false, message: 'Invalid plan. Choose monthly or yearly.' });
    }

    const planDetails = plans[plan];

    const order = await razorpay.orders.create({
      amount:   planDetails.amount,
      currency: 'INR',
      receipt:  `ep_${req.user.id.toString().slice(-8)}_${Date.now().toString().slice(-8)}`,
      notes: {
        userId:    req.user.id,
        plan,
        userEmail: req.user.email,
        userName:  req.user.name,
      },
    });

    return res.status(200).json({
      success:  true,
      order_id: order.id,
      amount:   order.amount,
      currency: order.currency,
      key_id:   process.env.RAZORPAY_KEY_ID,
      plan,
      user: {
        name:  req.user.name,
        email: req.user.email,
      },
    });
  } catch (err) {
    console.error('createOrder error:', err);
    const msg = err?.error?.description || err?.message || 'Failed to create payment order.';
    return res.status(500).json({ success: false, message: msg, debug: err?.error || err?.message });
  }
};

// ─── POST /api/payment/verify ─────────────────────────────────────────────────
exports.verifyPayment = async (req, res) => {
  try {
    const razorpay_order_id   = req.body.razorpay_order_id   || req.body.order_id;
    const razorpay_payment_id = req.body.razorpay_payment_id || req.body.payment_id;
    const razorpay_signature  = req.body.razorpay_signature  || req.body.signature;
    const { plan } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !plan) {
      return res.status(400).json({ success: false, message: 'Missing payment details.' });
    }

    // Verify Razorpay signature
    const body     = razorpay_order_id + '|' + razorpay_payment_id;
    const expected = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    if (expected !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Payment verification failed. Invalid signature.' });
    }

    // Upgrade membership
    const now     = new Date();
    const endDate = plan === 'yearly'
      ? new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000)
      : new Date(now.getTime() +  30 * 24 * 60 * 60 * 1000);

    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        role:               'membership',
        membershipStatus:   'active',
        membershipPlan:      plan,
        membershipStartDate: now,
        membershipEndDate:   endDate,
      },
      { new: true }
    );

    return res.status(200).json({
      success: true,
      message: `🎉 Membership activated! Welcome to EMPORA ${plan} plan.`,
      user: {
        id:                user._id,
        name:              user.name,
        email:             user.email,
        role:              user.role,
        membershipStatus:  user.membershipStatus,
        membershipPlan:    user.membershipPlan,
        membershipEndDate: user.membershipEndDate,
      },
    });
  } catch (err) {
    console.error('verifyPayment error:', err);
    return res.status(500).json({ success: false, message: 'Payment verification failed.' });
  }
};

// ─── POST /api/payment/webhook ────────────────────────────────────────────────
exports.webhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const secret    = process.env.RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_KEY_SECRET;

    const expected = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (expected !== signature) {
      return res.status(400).json({ success: false, message: 'Invalid webhook signature.' });
    }

    if (req.body.event === 'payment.captured') {
      const payment = req.body.payload.payment.entity;
      const notes   = payment.notes || {};
      const userId  = notes.userId;
      const plan    = notes.plan || 'monthly';

      if (userId) {
        const now     = new Date();
        const endDate = plan === 'yearly'
          ? new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000)
          : new Date(now.getTime() +  30 * 24 * 60 * 60 * 1000);

        await User.findByIdAndUpdate(userId, {
          role:               'membership',
          membershipStatus:   'active',
          membershipPlan:      plan,
          membershipStartDate: now,
          membershipEndDate:   endDate,
          razorpayPaymentId:   payment.id,
        });

        console.log(`✅ Webhook: Membership activated for user ${userId} (${plan})`);
      }
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('webhook error:', err);
    return res.status(500).json({ success: false });
  }
};

// ─── GET /api/payment/status ──────────────────────────────────────────────────
exports.getStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select(
      'name email role membershipStatus membershipPlan membershipStartDate membershipEndDate'
    );

    const isActive = user.membershipStatus === 'active' && user.membershipEndDate > new Date();

    return res.status(200).json({
      success: true,
      membership: {
        isActive,
        plan:      user.membershipPlan,
        status:    user.membershipStatus,
        startDate: user.membershipStartDate,
        endDate:   user.membershipEndDate,
        daysLeft:  isActive
          ? Math.ceil((user.membershipEndDate - new Date()) / (1000 * 60 * 60 * 24))
          : 0,
      },
    });
  } catch (err) {
    console.error('getStatus error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};