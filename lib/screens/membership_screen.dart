// lib/screens/membership_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/screens/payment_screen.dart';
import 'package:empora/services/api_service.dart';           // ← ADDED

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String _plan = 'monthly';

  // ── Pricing (loaded from API, falls back to defaults only if fetch fails) ──
  int  _monthlyPrice  = 999;   // fallback
  int  _yearlyPrice   = 7999;  // fallback
  bool _pricingLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();            // ← ADDED
  }

  // ── Fetch admin-controlled pricing ─────────────────────────────────────────
  Future<void> _loadPricing() async {
    try {
      final res     = await ApiService.getPublicPricing();
      final pricing = res['pricing'] as Map<String, dynamic>?;
      if (pricing != null && mounted) {
        setState(() {
          _monthlyPrice  = (pricing['monthly'] as num).toInt();
          _yearlyPrice   = (pricing['yearly']  as num).toInt();
          _pricingLoaded = true;
        });
      }
    } catch (e) {
      // Keep hardcoded fallbacks; log for debugging in dev builds.
      debugPrint('[MembershipScreen] Failed to load pricing: $e');
    }
  }

  // ── Savings badge text (computed, not hardcoded) ───────────────────────────
  String? get _yearlyBadge {
    if (_monthlyPrice <= 0) return null;
    final saving = ((_monthlyPrice * 12 - _yearlyPrice) / (_monthlyPrice * 12) * 100).round();
    return saving > 0 ? 'Save $saving%' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Membership',
            style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Banner ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 52),
                ),
                const SizedBox(height: 16),
                Text('Unlock Full Access',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Get access to all 10 AI business advisors\nand premium features.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.6),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── What you get ──────────────────────────────────────────
                  Text('What you get',
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildFeatureTable(),
                  const SizedBox(height: 28),

                  // ── AI Modules List ───────────────────────────────────────
                  Text('AI Advisor Modules Included',
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  _buildModulesList(),
                  const SizedBox(height: 28),

                  // ── Plan Selection ────────────────────────────────────────
                  Text('Choose your plan',
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),

                  // ── Show shimmer while pricing loads ──────────────────────
                  if (!_pricingLoaded)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Row(children: [
                      Expanded(
                        child: _PlanCard(
                          title: 'Monthly',
                          price: '₹$_monthlyPrice',
                          period: '/month',
                          description: 'Billed monthly',
                          isSelected: _plan == 'monthly',
                          onTap: () => setState(() => _plan = 'monthly'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PlanCard(
                          title: 'Yearly',
                          price: '₹$_yearlyPrice',
                          period: '/year',
                          description: 'Billed yearly',
                          badge: _yearlyBadge,            // ← dynamic, not hardcoded
                          isSelected: _plan == 'yearly',
                          onTap: () => setState(() => _plan = 'yearly'),
                        ),
                      ),
                    ]),

                  const SizedBox(height: 28),

                  // ── Upgrade Button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _pricingLoaded
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PaymentScreen(initialPlan: _plan)),
                              )
                          : null, // disabled until price is confirmed
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock ${_plan == 'monthly' ? 'Monthly Plan' : 'Yearly Plan'}',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text('Cancel anytime · No hidden fees',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature comparison table ──────────────────────────────────────────────
  Widget _buildFeatureTable() {
    final features = [
      {'label': 'Upload documents',          'free': true,  'member': true},
      {'label': 'View report summary',        'free': true,  'member': true},
      {'label': 'Fund & Strategy modules',    'free': true,  'member': true},
      {'label': 'View full AI report',        'free': false, 'member': true},
      {'label': 'Download PDF report',        'free': false, 'member': true},
      {'label': 'All 10 AI advisor modules',  'free': false, 'member': true},
      {'label': 'Memory-based AI chat',       'free': false, 'member': true},
      {'label': 'Priority AI processing',     'free': false, 'member': true},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(child: Text('Feature',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
            SizedBox(width: 56, child: Center(child: Text('Free',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 12)))),
            SizedBox(width: 72, child: Center(child: Text('Member',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 12)))),
          ]),
        ),
        const Divider(height: 1, color: AppTheme.divider),
        ...features.asMap().entries.map((e) {
          final f = e.value;
          final isLast = e.key == features.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(children: [
                Expanded(child: Text(f['label'] as String,
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary))),
                SizedBox(width: 56, child: Center(child: Icon(
                    f['free'] as bool ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: f['free'] as bool ? AppTheme.success : AppTheme.divider,
                    size: 20))),
                SizedBox(width: 72, child: Center(child: Icon(
                    f['member'] as bool ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: f['member'] as bool ? AppTheme.primary : AppTheme.divider,
                    size: 20))),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: AppTheme.divider),
          ]);
        }).toList(),
      ]),
    );
  }

  // ── AI Modules list ────────────────────────────────────────────────────────
  Widget _buildModulesList() {
    final modules = [
      {'icon': Icons.calculate_outlined,      'title': 'Taxation Advisor',      'desc': 'CA & tax planning expert'},
      {'icon': Icons.gavel_outlined,          'title': 'Land Legal Advisor',     'desc': 'Property & legal guidance'},
      {'icon': Icons.account_balance_outlined,'title': 'Loans Advisor',          'desc': 'Banking & finance expert'},
      {'icon': Icons.verified_outlined,       'title': 'Licence Advisor',        'desc': 'Compliance & licensing'},
      {'icon': Icons.shield_outlined,         'title': 'Risk Management',        'desc': 'Risk assessment expert'},
      {'icon': Icons.task_alt_outlined,       'title': 'Project Management',     'desc': 'Project planning advisor'},
      {'icon': Icons.security_outlined,       'title': 'Cybersecurity Advisor',  'desc': 'Security & data protection'},
      {'icon': Icons.corporate_fare_outlined, 'title': 'Restructure Advisor',    'desc': 'Business restructuring'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: modules.asMap().entries.map((e) {
          final m = e.value;
          final isLast = e.key == modules.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m['icon'] as IconData, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['title'] as String,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text(m['desc'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('MEMBER',
                      style: GoogleFonts.inter(
                          color: AppTheme.accentGold, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: AppTheme.divider),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─── Plan Card ─────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title, price, period, description;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

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
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.accentGold, borderRadius: BorderRadius.circular(20)),
              child: Text(badge!,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
          ],
          Text(title,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price,
                style: GoogleFonts.montserrat(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(period,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(description,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 14),
              const SizedBox(width: 4),
              Text('Selected',
                  style: GoogleFonts.inter(
                      color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}