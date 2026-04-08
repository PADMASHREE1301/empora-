// lib/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'
    if (dart.library.html) 'package:empora/services/razorpay_stub.dart';

class PaymentScreen extends StatefulWidget {
  final String initialPlan;
  const PaymentScreen({super.key, this.initialPlan = 'monthly'});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String _plan;
  int  _monthlyPrice   = 999;    // fallback only
  int  _yearlyPrice    = 7999;   // fallback only
  bool _pricingLoaded  = false;
  bool _pricingError   = false;  // ← NEW: track fetch failures visibly
  bool _loading        = false;
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan;
    _loadPricing();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR,   _onError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _onSuccess(PaymentSuccessResponse r) =>
      _verify(r.paymentId ?? '', r.orderId ?? '', r.signature ?? '');

  void _onError(PaymentFailureResponse r) {
    setState(() => _loading = false);
    _err(r.message ?? 'Payment cancelled.');
  }

  void _onWallet(ExternalWalletResponse r) {}

  // ── FIX: Surfaces errors instead of silently falling back ─────────────────
  Future<void> _loadPricing() async {
    setState(() { _pricingError = false; });
    try {
      final res     = await ApiService.getPublicPricing();
      final pricing = res['pricing'] as Map<String, dynamic>?;
      if (pricing == null) throw Exception('Pricing data missing in response');
      if (mounted) {
        setState(() {
          _monthlyPrice  = (pricing['monthly'] as num).toInt();
          _yearlyPrice   = (pricing['yearly']  as num).toInt();
          _pricingLoaded = true;
          _pricingError  = false;
        });
      }
    } catch (e) {
      debugPrint('[PaymentScreen] Pricing fetch failed: $e');
      if (mounted) {
        setState(() {
          _pricingLoaded = false;
          _pricingError  = true;   // ← show retry UI, don't silently use stale values
        });
      }
    }
  }

  // ── Savings badge text (computed dynamically) ──────────────────────────────
  String? get _yearlyBadge {
    if (_monthlyPrice <= 0) return null;
    final saving = ((_monthlyPrice * 12 - _yearlyPrice) / (_monthlyPrice * 12) * 100).round();
    return saving > 0 ? 'Save $saving%' : null;
  }

  // ── Pay ───────────────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (!_pricingLoaded) {
      _err('Pricing not loaded yet. Please wait or retry.');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth   = context.read<AuthProvider>();
      final result = await ApiService.createPaymentOrder(plan: _plan);

      if (result['success'] != true) {
        _err(result['message'] ?? 'Failed to create order.');
        setState(() => _loading = false);
        return;
      }

      final keyId   = '${result['key_id']}';
      final orderId = '${result['order_id']}';
      final amount  = result['amount'] as int;
      final name    = auth.user?.name  ?? '';
      final email   = auth.user?.email ?? '';

      if (kIsWeb) {
        setState(() => _loading = false);
        _webDialog(keyId, orderId, amount, name, email);
      } else {
        _razorpay?.open({
          'key':         keyId,
          'order_id':    orderId,
          'amount':      amount,
          'currency':    'INR',
          'name':        'EMPORA',
          'description': _plan == 'monthly' ? 'Monthly Membership' : 'Yearly Membership',
          'prefill':     {'name': name, 'email': email, 'contact': ''},
          'theme':       {'color': '#1A3A6B'},
          'external':    {'wallets': ['paytm', 'phonepe', 'googlepay']},
        });
      }
    } on ApiException catch (e) {
      setState(() => _loading = false);
      if (e.statusCode == 500) {
        _showOrderError(
          'Payment service is temporarily unavailable.\n\n'
          'This is usually a server configuration issue. '
          'Please try again in a few minutes or contact support.',
        );
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        _showOrderError(
          'Session expired. Please log out and log back in, then try again.',
        );
      } else {
        _showOrderError(e.message);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showOrderError(
        'Could not reach the payment server. '
        'Please check your internet connection and try again.',
      );
    }
  }

  // ── Order error dialog with Retry button ──────────────────────────────────
  void _showOrderError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Text('Payment Failed',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 16)),
        ]),
        content: Text(message,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _pay(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Verify ────────────────────────────────────────────────────────────────
  Future<void> _verify(String pid, String oid, String sig) async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.verifyPayment(
        orderId: oid, paymentId: pid, signature: sig, plan: _plan,
      );
      if (!mounted) return;

      if (r['success'] == true) {
        final auth = context.read<AuthProvider>();

        // Apply the updated user from the verify response immediately so the UI
        // reflects membership right away without waiting for a /me round-trip.
        if (r['user'] != null) {
          auth.updateUserFromPaymentResponse(r['user'] as Map<String, dynamic>);
        }

        // Also do a full re-fetch in the background to guarantee sync with DB.
        auth.fetchProfile();

        _success();
      } else {
        _err(r['message'] ?? 'Verification failed.');
      }
    } catch (e) {
      _err('Contact support. Payment ID: $pid');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Web dialog ────────────────────────────────────────────────────────────
  void _webDialog(String keyId, String orderId, int amount,
      String name, String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete Payment',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.payment_rounded, size: 52, color: AppTheme.primary),
          const SizedBox(height: 16),
          _infoBox(orderId, amount),
          const SizedBox(height: 12),
          Text(
            'Use the mobile app for the best payment experience.\n'
            'Web checkout opens Razorpay in a new window.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _err('Please use the mobile app for payments, or contact support.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Got it',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String orderId, int amount) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(children: [
      _infoRow('Order ID', orderId),
      _infoRow('Amount',   '₹${amount ~/ 100}'),
      _infoRow('Plan',     _plan),
    ]),
  );

  Widget _infoRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$k: ', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      Expanded(child: Text(v, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary))),
    ]),
  );

  void _success() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 52),
          ),
          const SizedBox(height: 20),
          Text('Payment Successful! 🎉',
              style: GoogleFonts.montserrat(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Your EMPORA ${_plan == 'monthly' ? 'Monthly' : 'Yearly'} '
            'membership is now active!\nAll AI modules are unlocked.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Start Using EMPORA',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Upgrade Membership',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(child: Column(children: [
        // Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium,
                  color: AppTheme.accentGold, size: 52),
            ),
            const SizedBox(height: 16),
            Text('Unlock All AI Advisors',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Get access to all 10 AI business advisor modules',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8), fontSize: 13)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Pricing error / loading state ────────────────────────────────
            if (_pricingError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Could not load pricing. Tap to retry.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.error)),
                  ),
                  TextButton(
                    onPressed: _loadPricing,
                    child: Text('Retry',
                        style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Plans
            Text('Choose Your Plan', style: GoogleFonts.montserrat(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),

            if (!_pricingLoaded && !_pricingError)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else
              Row(children: [
                Expanded(child: _PlanCard(
                  label: 'Monthly', price: '₹$_monthlyPrice', period: '/month',
                  description: 'Billed monthly',
                  isSelected: _plan == 'monthly',
                  onTap: () => setState(() => _plan = 'monthly'),
                )),
                const SizedBox(width: 14),
                Expanded(child: _PlanCard(
                  label: 'Yearly', price: '₹$_yearlyPrice', period: '/year',
                  description: 'Billed yearly',
                  badge: _yearlyBadge,     // ← dynamic, not hardcoded
                  isSelected: _plan == 'yearly',
                  onTap: () => setState(() => _plan = 'yearly'),
                )),
              ]),

            const SizedBox(height: 28),

            // Features
            Text('What\'s Included', style: GoogleFonts.montserrat(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            _featureList(),
            const SizedBox(height: 28),

            // Button
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: (_loading || !_pricingLoaded) ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_open_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text('Pay ₹${_plan == 'monthly' ? _monthlyPrice : _yearlyPrice} & Unlock',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
              ),
            ),
            const SizedBox(height: 12),

            // Badges
            Center(child: Column(children: [
              Text('Secured by Razorpay',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _badge('UPI'), _badge('Card'), _badge('NetBanking'), _badge('Wallet'),
              ]),
              const SizedBox(height: 8),
              Text('Cancel anytime · No hidden fees',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            const SizedBox(height: 32),
          ]),
        ),
      ])),
    );
  }

  Widget _featureList() {
    final items = [
      'All 10 AI business advisor modules',
      'Memory-based personalized AI chat',
      'Taxation & Legal advisor',
      'Loans & Finance advisor',
      'Risk, Project & Cyber advisors',
      'Restructure & Compliance advisors',
      'Priority AI processing',
      'Download PDF reports',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider)),
      child: Column(children: items.map((f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          Text(f, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
        ]),
      )).toList()),
    );
  }

  Widget _badge(String label) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
  );
}

// ── Plan Card ──────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String label, price, period, description;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanCard({required this.label, required this.price, required this.period,
      required this.description, this.badge, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.12),
              blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(badge!, style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
          ],
          Text(label, style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: GoogleFonts.montserrat(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            Padding(padding: const EdgeInsets.only(bottom: 2),
                child: Text(period, style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 11))),
          ]),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.inter(
              color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 14),
              const SizedBox(width: 4),
              Text('Selected', style: GoogleFonts.inter(
                  color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}