// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppTheme.adminBg,
        appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('E',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF0A0A0F),
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Admin Panel',
                style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text('EMPORA',
                style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 2)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined,         size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline,              size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.inbox_outlined,              size: 18), text: 'Submissions'),
            Tab(icon: Icon(Icons.sell_outlined,               size: 18), text: 'Pricing'),
            Tab(icon: Icon(Icons.bar_chart_rounded,           size: 18), text: 'Revenue'),
            Tab(icon: Icon(Icons.pending_actions_rounded,     size: 18), text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _UsersTab(),
          _SubmissionsTab(),
          _PricingTab(),
          _RevenueTab(),
          _PendingUsersTab(),
        ],
      ),
    ),
  );
  }
}

// ─── OVERVIEW TAB ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _loading = true;
  Map<String, dynamic> _stats   = {};
  Map<String, dynamic> _pricing = {};
  List _growthData = [];
  List _recentUsers = [];
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch dashboard + pricing in parallel
      final results = await Future.wait([
        ApiService.adminGet('/dashboard'),
        ApiService.adminGet('/pricing').catchError((_) => <String, dynamic>{}),
        ApiService.adminGet('/stats').catchError((_) => <String, dynamic>{}),
      ]);

      final dashRes    = results[0];
      final pricingRes = results[1];
      final statsRes   = results[2];

      final raw = (dashRes['data'] is Map<String, dynamic>)
          ? dashRes['data'] as Map<String, dynamic>
          : dashRes;

      // Merge pricing
      if (pricingRes['pricing'] != null) {
        raw['pricing'] = pricingRes['pricing'];
      }

      // Merge growth + recent users from /stats if available
      final statsData = statsRes['stats'] as Map<String, dynamic>? ?? {};
      if (statsData.isNotEmpty) {
        _growthData  = statsData['growthData']  as List? ?? [];
        _recentUsers = statsData['recentUsers'] as List? ?? [];

        // Merge richer user breakdown
        final statsUsers = statsData['users'] as Map<String, dynamic>? ?? {};
        final statsRevenue = statsData['revenue'] as Map<String, dynamic>? ?? {};
        final statsMembership = statsData['membership'] as Map<String, dynamic>? ?? {};

        if (statsUsers.isNotEmpty) raw['statsUsers'] = statsUsers;
        if (statsRevenue.isNotEmpty) raw['statsRevenue'] = statsRevenue;
        if (statsMembership.isNotEmpty) raw['statsMembership'] = statsMembership;
      }

      setState(() { _stats = raw; _pricing = raw['pricing'] as Map<String, dynamic>? ?? {}; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmt(num v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _timeAgo(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(onRetry: _load, message: _error!);

    // ── Parse all stats ────────────────────────────────────────────────────
    final s            = _stats['data'] ?? _stats['stats'] ?? _stats;
    final usersMap     = (s['users']       as Map<String, dynamic>?) ?? {};
    final subsMap      = (s['submissions'] as Map<String, dynamic>?) ?? {};
    final statsUsers   = (_stats['statsUsers']      as Map<String, dynamic>?) ?? {};
    final statsRevenue = (_stats['statsRevenue']    as Map<String, dynamic>?) ?? {};
    final statsMem     = (_stats['statsMembership'] as Map<String, dynamic>?) ?? {};

    // User counts
    final totalUsers   = (usersMap['total']      ?? s['totalUsers']      ?? statsUsers['total']   ?? 0) as num;
    final memberUsers  = (usersMap['membership'] ?? s['memberUsers']     ?? statsMem['totalActive']?? 0) as num;
    final freeUsers    = (usersMap['free']       ?? s['freeUsers']       ?? statsUsers['free']    ?? (totalUsers - memberUsers)) as num;
    final newToday     = (statsUsers['newToday']     ?? 0) as num;
    final newThisWeek  = (statsUsers['newThisWeek']  ?? 0) as num;
    final newThisMonth = (statsUsers['newThisMonth'] ?? 0) as num;
    final expiringSoon = (statsUsers['expiringSoon'] ?? 0) as num;

    // Monthly / yearly member split
    final monthlyMem = (usersMap['monthlyMembers'] ?? statsMem['monthly'] ?? 0) as num;
    final yearlyMem  = (usersMap['yearlyMembers']  ?? statsMem['yearly']  ?? 0) as num;

    // Submission stats
    final totalSubs = (subsMap['total']   ?? s['totalSubmissions'] ?? 0) as num;
    final pending   = (subsMap['pending'] ?? s['pendingApprovals'] ?? 0) as num;
    final approved  = (subsMap['approved']?? s['approvedCount']    ?? 0) as num;
    final rejected  = (subsMap['rejected']?? s['rejectedCount']    ?? 0) as num;

    // Pricing
    final monthlyPrice = (_pricing['monthly'] ?? s['pricing']?['monthly'] ?? 999) as num;
    final yearlyPrice  = (_pricing['yearly']  ?? s['pricing']?['yearly']  ?? 7999) as num;

    // Revenue
    final revenueFromStats  = (statsRevenue['total']        ?? 0) as num;
    final thisMonthRevenue  = (statsRevenue['thisMonth']    ?? 0) as num;
    final activeMonthlyRev  = (statsRevenue['activeMonthly']?? 0) as num;
    final activeYearlyRev   = (statsRevenue['activeYearly'] ?? 0) as num;
    // Fallback estimate if /stats not available
    final estRevenue = revenueFromStats > 0
        ? revenueFromStats
        : (monthlyMem > 0 || yearlyMem > 0
            ? (monthlyMem * monthlyPrice + yearlyMem * yearlyPrice)
            : (memberUsers * monthlyPrice));
    final estMonthlyRev = activeMonthlyRev > 0 ? activeMonthlyRev : monthlyMem * monthlyPrice;
    final estYearlyRev  = activeYearlyRev  > 0 ? activeYearlyRev  : yearlyMem  * yearlyPrice;
    final estThisMonth  = thisMonthRevenue > 0 ? thisMonthRevenue : 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── HEADER BANNER ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0A0F), Color(0xFF0F3460)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text('Platform Overview', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (newToday > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('+$newToday today',
                        style: GoogleFonts.inter(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$totalUsers',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                  Text('Total Users', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 14),
                      const SizedBox(width: 5),
                      Text('$memberUsers Members',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_outline, color: Colors.white54, size: 14),
                      const SizedBox(width: 5),
                      Text('$freeUsers Free',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── USER STATS ──────────────────────────────────────────────────
          _sectionLabel('Users'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(label: 'Members',   value: '$memberUsers', icon: Icons.workspace_premium, color: AppTheme.accentGold)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Free Users', value: '$freeUsers', icon: Icons.person_outline,     color: AppTheme.accent)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(label: 'New This Week',  value: '$newThisWeek',  icon: Icons.trending_up_rounded,    color: AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'New This Month', value: '$newThisMonth', icon: Icons.bar_chart_rounded,       color: const Color(0xFF2196F3))),
          ]),

          // ── EXPIRY ALERT ─────────────────────────────────────────────────
          if (expiringSoon > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: 8),
                Text('$expiringSoon membership${expiringSoon > 1 ? 's' : ''} expiring within 7 days',
                    style: GoogleFonts.inter(color: AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // ── MEMBERSHIP PLAN SPLIT ─────────────────────────────────────────
          _sectionLabel('Membership Breakdown'),
          const SizedBox(height: 10),
          _MembershipSplitCard(monthly: monthlyMem.toInt(), yearly: yearlyMem.toInt(), free: freeUsers.toInt()),

          const SizedBox(height: 20),

          // ── REVENUE ──────────────────────────────────────────────────────
          _sectionLabel('Revenue'),
          const SizedBox(height: 10),

          // Big revenue card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2B0D), Color(0xFF0A3A1A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.currency_rupee, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 6),
                Text('Total Estimated Revenue', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              Text(_fmt(estRevenue),
                  style: GoogleFonts.montserrat(color: const Color(0xFF4CAF50), fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              // 3-column breakdown
              Row(children: [
                Expanded(child: _RevStat(label: 'This Month', value: _fmt(estThisMonth), color: AppTheme.success)),
                Container(width: 1, height: 36, color: Colors.white12),
                Expanded(child: _RevStat(label: 'Monthly Plans', value: _fmt(estMonthlyRev), color: const Color(0xFF2196F3))),
                Container(width: 1, height: 36, color: Colors.white12),
                Expanded(child: _RevStat(label: 'Yearly Plans', value: _fmt(estYearlyRev), color: AppTheme.accentGold)),
              ]),
            ]),
          ),

          const SizedBox(height: 10),

          // Plan prices
          Row(children: [
            Expanded(child: _StatCard(label: 'Monthly Price', value: '₹$monthlyPrice', icon: Icons.repeat_rounded,      color: const Color(0xFF4CAF50))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Yearly Price',  value: '₹$yearlyPrice',  icon: Icons.star_rate_rounded,   color: AppTheme.accentGold)),
          ]),

          // ── 7-DAY GROWTH CHART ────────────────────────────────────────────
          if (_growthData.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('New Users — Last 7 Days'),
            const SizedBox(height: 10),
            _GrowthChart(data: _growthData),
          ],

          const SizedBox(height: 20),

          // ── SUBMISSIONS ───────────────────────────────────────────────────
          _sectionLabel('Submissions'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total',    value: '$totalSubs', icon: Icons.inbox_outlined,        color: const Color(0xFF1A3A7C))),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Pending',  value: '$pending',   icon: Icons.pending_outlined,      color: AppTheme.warning)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(label: 'Approved', value: '$approved',  icon: Icons.check_circle_outline,  color: AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Rejected', value: '$rejected',  icon: Icons.cancel_outlined,       color: AppTheme.error)),
          ]),

          if (pending > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.notifications_active, color: AppTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '$pending submission${pending > 1 ? 's' : ''} awaiting review',
                  style: GoogleFonts.inter(color: AppTheme.warning, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
          ],

          // ── RECENT SIGNUPS ────────────────────────────────────────────────
          if (_recentUsers.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('Recent Signups'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: List.generate(_recentUsers.length, (i) {
                  final u = _recentUsers[i] as Map<String, dynamic>;
                  final isMember = u['isMember'] as bool? ?? false;
                  final plan = u['membershipPlan'] as String? ?? '';
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: isMember
                                ? AppTheme.accentGold.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            ((u['name'] as String?) ?? '?').isNotEmpty
                                ? (u['name'] as String)[0].toUpperCase() : '?',
                            style: GoogleFonts.montserrat(
                              color: isMember ? AppTheme.accentGold : Colors.white54,
                              fontWeight: FontWeight.w800, fontSize: 15),
                          )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u['name'] as String? ?? '—',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(u['email'] as String? ?? '',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isMember
                                  ? AppTheme.accentGold.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isMember ? plan.toUpperCase() : 'FREE',
                              style: GoogleFonts.inter(
                                color: isMember ? AppTheme.accentGold : Colors.white38,
                                fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(_timeAgo(u['createdAt'] as String?),
                              style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                        ]),
                      ]),
                    ),
                    if (i < _recentUsers.length - 1)
                      const Divider(color: Colors.white12, height: 1),
                  ]);
                }),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.montserrat(
          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70,
          letterSpacing: 0.5));
}

// ── Revenue sub-stat ───────────────────────────────────────────────────────────
class _RevStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RevStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
  ]);
}

// ── Membership split bar ───────────────────────────────────────────────────────
class _MembershipSplitCard extends StatelessWidget {
  final int monthly, yearly, free;
  const _MembershipSplitCard({required this.monthly, required this.yearly, required this.free});

  @override
  Widget build(BuildContext context) {
    final total = monthly + yearly + free;
    if (total == 0) return Container(
      height: 56, alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
      child: Text('No users yet', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
    );
    final mPct = (monthly / total * 100).round();
    final yPct = (yearly  / total * 100).round();
    final fPct = (free    / total * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(height: 13, child: Row(children: [
            if (mPct > 0) Expanded(flex: mPct, child: Container(color: const Color(0xFF2196F3))),
            if (yPct > 0) Expanded(flex: yPct, child: Container(color: AppTheme.accentGold)),
            if (fPct > 0) Expanded(flex: fPct, child: Container(color: const Color(0xFF2A2A4E))),
          ])),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _BarLeg(color: const Color(0xFF2196F3), label: 'Monthly', count: monthly, pct: mPct),
          _BarLeg(color: AppTheme.accentGold,     label: 'Yearly',  count: yearly,  pct: yPct),
          _BarLeg(color: const Color(0xFF3A3A5E), label: 'Free',    count: free,    pct: fPct),
        ]),
      ]),
    );
  }
}

class _BarLeg extends StatelessWidget {
  final Color color; final String label; final int count, pct;
  const _BarLeg({required this.color, required this.label, required this.count, required this.pct});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$count', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      Text('$label ($pct%)', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
    ]),
  ]);
}

// ── 7-day growth chart (pure Flutter, no extra package) ───────────────────────
class _GrowthChart extends StatelessWidget {
  final List data;
  const _GrowthChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => (d as Map)['count'] as int? ?? 0).fold(0, (a, b) => a > b ? a : b);
    final peak   = maxVal == 0 ? 1 : maxVal;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((d) {
              final m     = d as Map<String, dynamic>;
              final count = m['count'] as int? ?? 0;
              final pct   = count / peak;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (count > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('$count', style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    child: Container(
                      height: (pct * 72).clamp(4.0, 72.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Color(0xFF1A3A7C), Color(0xFF2196F3)],
                        ),
                      ),
                    ),
                  ),
                ]),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((d) => Expanded(child: Text(
            (d as Map)['label'] as String? ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 9),
          ))).toList(),
        ),
      ]),
    );
  }
}

// ─── USERS TAB ────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  bool   _loading    = true;
  List   _users      = [];
  int    _total      = 0;
  String _roleFilter = '';
  String _search     = '';
  final  _searchCtrl = TextEditingController();
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      String q = '/users?limit=50';
      if (_roleFilter.isNotEmpty) q += '&role=$_roleFilter';
      if (_search.isNotEmpty)     q += '&search=$_search';
      final res = await ApiService.adminGet(q);
      setState(() {
        _users   = res['users'] as List? ?? [];
        _total   = res['total'] as int?  ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await ApiService.adminPatch('/users/$userId', data);
      _load();
      if (mounted) _snack('User updated.', AppTheme.success);
    } catch (e) {
      if (mounted) _snack('Failed: $e', AppTheme.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showRoleDialog(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Role',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(u['email'] ?? '',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          for (final role in ['free', 'membership', 'admin'])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                role == 'admin' ? Icons.admin_panel_settings
                    : role == 'membership' ? Icons.workspace_premium
                    : Icons.person_outline,
                color: role == 'admin' ? AppTheme.error
                    : role == 'membership' ? AppTheme.success
                    : AppTheme.textSecondary,
              ),
              title: Text(role.toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              trailing: u['role'] == role
                  ? const Icon(Icons.check_circle, color: AppTheme.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                final id = (u['_id'] ?? u['id'] ?? '').toString();
                _updateUser(id, {
                  'role': role,
                  'membershipStatus': role == 'membership' ? 'active' : 'inactive',
                });
              },
            ),
        ]),
        actions: [TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search + filter bar
      Container(
        color: const Color(0xFF0A0A0F),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) { _search = v; _load(); },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search name or email...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['All', 'free', 'membership', 'admin'].map((f) {
              final active = f == 'All' ? _roleFilter.isEmpty : f == _roleFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _roleFilter = f == 'All' ? '' : f); _load(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? Colors.white : Colors.white38),
                    ),
                    child: Text(f[0].toUpperCase() + f.substring(1),
                        style: GoogleFonts.inter(
                            color: active ? const Color(0xFF0A0A0F) : Colors.white70,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList()),
          ),
        ]),
      ),

      // Total count
      Container(
        color: const Color(0xFF0A0A0F),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('$_total users',
              style: GoogleFonts.inter(
                  color: Colors.white60, fontSize: 12)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: AppTheme.textSecondary),
            onPressed: _load,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),

      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(onRetry: _load, message: _error!)
              : _users.isEmpty
                  ? Center(child: Text('No users found.',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final u = _users[i] as Map<String, dynamic>;
                          return _UserCard(
                            user: u,
                            onChangeRole: () => _showRoleDialog(u),
                            onUpdate: _updateUser,
                          );
                        },
                      ),
                    )),
    ]);
  }
}

// ─── SUBMISSIONS TAB ──────────────────────────────────────────────────────────
class _SubmissionsTab extends StatefulWidget {
  const _SubmissionsTab();
  @override
  State<_SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<_SubmissionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool   _loading     = true;
  List   _submissions = [];
  int    _total       = 0;
  String? _error;

  final _tabs = ['All', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final status = _tabs[_tabCtrl.index];
    final q = status == 'All'
        ? '/submissions?limit=50'
        : '/submissions?status=$status&limit=50';
    try {
      final res = await ApiService.adminGet(q);
      setState(() {
        _submissions = res['submissions'] as List? ?? [];
        _total       = res['total']       as int?  ?? 0;
        _loading     = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _action(String id, String action) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          action == 'approve' ? 'Approve Submission' : 'Reject Submission',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            action == 'approve' ? 'Add optional notes:' : 'Reason for rejection:',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: action == 'approve' ? 'Optional notes...' : 'Enter reason...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: action == 'approve' ? AppTheme.success : AppTheme.error),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? AppTheme.success : AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action == 'approve' ? 'Approve' : 'Reject',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (action == 'reject' && ctrl.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rejection reason is required.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    try {
      if (action == 'approve') {
        await ApiService.adminPatch('/submissions/$id/approve', {'adminNotes': ctrl.text});
      } else {
        await ApiService.adminPatch('/submissions/$id/reject', {'rejectionReason': ctrl.text});
      }
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Submission ${action}d successfully.',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: action == 'approve' ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Sub-tabs
      Container(
        color: const Color(0xFF0A0A0F),
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) =>
              Tab(text: t[0].toUpperCase() + t.substring(1))).toList(),
        ),
      ),

      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('$_total submission${_total != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                  color: Colors.white60, fontSize: 12)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: AppTheme.textSecondary),
            onPressed: _load,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),

      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(onRetry: _load, message: _error!)
              : _submissions.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, size: 56,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No submissions found.',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _submissions.length,
                        itemBuilder: (_, i) {
                          final s  = _submissions[i] as Map<String, dynamic>;
                          final id = (s['_id'] ?? '').toString();
                          return _SubmissionCard(
                            data: s,
                            onApprove: () => _action(id, 'approve'),
                            onReject:  () => _action(id, 'reject'),
                          );
                        },
                      ),
                    )),
    ]);
  }
}

// ─── USER CARD ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChangeRole;
  final Function(String, Map<String, dynamic>) onUpdate;
  const _UserCard({required this.user, required this.onChangeRole, required this.onUpdate});

  Color get _roleColor {
    switch (user['role']) {
      case 'admin':      return AppTheme.error;
      case 'membership': return AppTheme.success;
      default:           return AppTheme.textSecondary;
    }
  }

  IconData get _roleIcon {
    switch (user['role']) {
      case 'admin':      return Icons.admin_panel_settings;
      case 'membership': return Icons.workspace_premium;
      default:           return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role   = user['role']             as String? ?? 'free';
    final plan   = user['membershipPlan']   as String?;
    final status = user['membershipStatus'] as String? ?? 'inactive';
    final end    = user['membershipEndDate'] as String?;
    final active = user['isActive']         as bool?   ?? true;
    final id     = (user['_id'] ?? user['id'] ?? '').toString();
    final isActive = status == 'active';

    String daysLeft = '';
    if (end != null && isActive) {
      try {
        final diff = DateTime.parse(end).difference(DateTime.now()).inDays;
        daysLeft = '$diff days left';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar
            Stack(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Center(child: Text(
                  ((user['name'] as String?) ?? 'U').isNotEmpty
                      ? (user['name'] as String)[0].toUpperCase() : 'U',
                  style: GoogleFonts.montserrat(
                      color: _roleColor, fontWeight: FontWeight.w800, fontSize: 18),
                )),
              ),
              if (!active)
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(
                      color: AppTheme.error, shape: BoxShape.circle),
                  child: const Icon(Icons.block, color: Colors.white, size: 9),
                )),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['name'] ?? '-',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(user['email'] ?? '-',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary)),
              if (role == 'membership' && plan != null)
                Text(
                  '${plan[0].toUpperCase()}${plan.substring(1)} Plan'
                      '${daysLeft.isNotEmpty ? ' • $daysLeft' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isActive ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w500),
                ),
            ])),

            // Role badge (tappable)
            GestureDetector(
              onTap: onChangeRole,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_roleIcon, color: _roleColor, size: 12),
                  const SizedBox(width: 4),
                  Text(role.toUpperCase(),
                      style: GoogleFonts.inter(
                          color: _roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 3),
                  Icon(Icons.edit, color: _roleColor, size: 10),
                ]),
              ),
            ),
          ]),
        ),

        // Membership bar
        if (role == 'membership')
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.success.withValues(alpha: 0.06)
                  : AppTheme.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? AppTheme.success.withValues(alpha: 0.2)
                    : AppTheme.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(children: [
              Icon(isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? AppTheme.success : AppTheme.error, size: 14),
              const SizedBox(width: 8),
              Text(isActive ? 'Active Membership' : 'Membership Expired',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.error)),
              const Spacer(),
              // Quick deactivate/activate
              GestureDetector(
                onTap: () => onUpdate(id, {
                  'isActive': !active,
                }),
                child: Text(active ? 'Deactivate' : 'Activate',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: active ? AppTheme.error : AppTheme.success,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─── SUBMISSION CARD ──────────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _SubmissionCard({required this.data, required this.onApprove, required this.onReject});

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':  return AppTheme.success;
      case 'rejected':  return AppTheme.error;
      case 'completed': return AppTheme.accent;
      default:          return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status     = data['status']     as String? ?? 'pending';
    final user       = data['user']       as Map<String, dynamic>? ?? {};
    final moduleType = (data['moduleType'] as String? ?? '')
        .replaceAll('_', ' ').toUpperCase();
    final title      = data['title']      as String? ?? 'Untitled';
    final reason     = data['rejectionReason'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white))),
            _StatusBadge(status: status),
          ]),
          const SizedBox(height: 6),
          if (moduleType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(moduleType,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text(user['name'] as String? ?? 'Unknown',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (user['role'] == 'membership' ? AppTheme.success : AppTheme.accent)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(user['role'] == 'membership' ? 'Member' : 'Free',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: user['role'] == 'membership'
                          ? AppTheme.success : AppTheme.accent,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.email_outlined, size: 14, color: Colors.white38),
            const SizedBox(width: 4),
            Text(user['email'] as String? ?? '',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white38)),
          ]),

          if (status == 'rejected' && reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.error),
                const SizedBox(width: 6),
                Expanded(child: Text(reason,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.error))),
              ]),
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 12),
      Text(value, style: GoogleFonts.montserrat(
          fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.inter(
          fontSize: 12, color: AppTheme.textSecondary)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = status == 'approved' ? AppTheme.success
        : status == 'rejected' ? AppTheme.error
        : status == 'completed' ? AppTheme.accent
        : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1),
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorView({required this.onRetry, this.message = ''});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 52, color: AppTheme.error),
      const SizedBox(height: 12),
      Text('Failed to load',
          style: GoogleFonts.inter(color: Colors.white60, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 16),
        label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A0A0F), foregroundColor: Colors.white),
      ),
    ]),
  );
}

// ─── PRICING TAB ─────────────────────────────────────────────────────────────
class _PricingTab extends StatefulWidget {
  const _PricingTab();
  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  bool    _loading  = true;
  bool    _saving   = false;
  String? _error;
  String? _success;

  final _monthlyCtrl = TextEditingController();
  final _yearlyCtrl  = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _monthlyCtrl.dispose();
    _yearlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getAdminPricing();
      final pricing = res['pricing'] as Map<String, dynamic>;
      _monthlyCtrl.text = pricing['monthly'].toString();
      _yearlyCtrl.text  = pricing['yearly'].toString();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final monthly = int.tryParse(_monthlyCtrl.text.trim());
    final yearly  = int.tryParse(_yearlyCtrl.text.trim());

    if (monthly == null || yearly == null || monthly < 1 || yearly < 1) {
      setState(() => _error = 'Enter valid prices greater than 0.');
      return;
    }

    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiService.updatePricing(monthly: monthly, yearly: yearly);
      setState(() {
        _saving  = false;
        _success = '✅ Pricing updated successfully!';
      });
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [const Color(0xFF0A0A0F), const Color(0xFF1A3A7C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.sell_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text('Membership Pricing',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text('Set prices users pay to unlock all modules.',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
          ]),
        ),

        const SizedBox(height: 24),

        // Monthly price
        Text('Monthly Plan (₹)',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        _PriceField(
          controller: _monthlyCtrl,
          icon: Icons.calendar_month_outlined,
          hint: 'e.g. 999',
          label: 'Monthly price in ₹',
          color: AppTheme.accent,
        ),

        const SizedBox(height: 20),

        // Yearly price
        Text('Yearly Plan (₹)',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: const Color.fromARGB(255, 50, 50, 185))),
        const SizedBox(height: 8),
        _PriceField(
          controller: _yearlyCtrl,
          icon: Icons.calendar_today_outlined,
          hint: 'e.g. 7999',
          label: 'Yearly price in ₹',
          color: AppTheme.accentGold,
        ),

        const SizedBox(height: 12),

        // Preview
        _PricePreview(monthlyCtrl: _monthlyCtrl, yearlyCtrl: _yearlyCtrl),

        const SizedBox(height: 20),

        // Error / success
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!,
                  style: GoogleFonts.inter(color: AppTheme.error, fontSize: 12))),
            ]),
          ),

        if (_success != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 16),
              const SizedBox(width: 8),
              Text(_success!,
                  style: GoogleFonts.inter(color: AppTheme.success, fontSize: 12)),
            ]),
          ),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Pricing',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }
}

class _PriceField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint, label;
  final Color color;
  const _PriceField({required this.controller, required this.icon,
      required this.hint, required this.label, required this.color});
  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 54, height: 56,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13), bottomLeft: Radius.circular(13)),
          ),
          child: Center(child: Icon(widget.icon, color: widget.color, size: 22)),
        ),
        const SizedBox(width: 4),
        Text('₹', style: GoogleFonts.montserrat(
            fontSize: 20, fontWeight: FontWeight.w700, color: widget.color)),
        const SizedBox(width: 4),
        Expanded(child: TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.montserrat(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.montserrat(
                color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        )),
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _PricePreview extends StatefulWidget {
  final TextEditingController monthlyCtrl, yearlyCtrl;
  const _PricePreview({required this.monthlyCtrl, required this.yearlyCtrl});
  @override
  State<_PricePreview> createState() => _PricePreviewState();
}

class _PricePreviewState extends State<_PricePreview> {
  @override
  void initState() {
    super.initState();
    widget.monthlyCtrl.addListener(() => setState(() {}));
    widget.yearlyCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final monthly = int.tryParse(widget.monthlyCtrl.text) ?? 0;
    final yearly  = int.tryParse(widget.yearlyCtrl.text)  ?? 0;
    final saving  = monthly > 0 ? ((monthly * 12 - yearly) / (monthly * 12) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('User Preview', style: GoogleFonts.inter(
            color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _PreviewCard(
            label: 'Monthly', price: monthly,
            sub: 'per month', color: AppTheme.accent,
          )),
          const SizedBox(width: 12),
          Expanded(child: _PreviewCard(
            label: 'Yearly', price: yearly,
            sub: saving > 0 ? 'Save $saving%' : 'per year',
            color: AppTheme.accentGold,
            badge: saving > 0 ? 'BEST VALUE' : null,
          )),
        ]),
      ]),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String label, sub;
  final int price;
  final Color color;
  final String? badge;
  const _PreviewCard({required this.label, required this.price,
      required this.sub, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 248, 248, 249),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(badge!,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        Text(label, style: GoogleFonts.inter(
            color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text('₹$price', style: GoogleFonts.montserrat(
            color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(sub, style: GoogleFonts.inter(
            color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
// ─── REVENUE ANALYTICS TAB ────────────────────────────────────────────────────
class _RevenueTab extends StatefulWidget {
  const _RevenueTab();
  @override
  State<_RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<_RevenueTab> {
  bool   _loading = true;
  String? _error;

  // Pricing
  int _monthlyPrice = 999;
  int _yearlyPrice  = 7999;

  // Member counts
  int _monthlyMembers  = 0;
  int _yearlyMembers   = 0;
  int _totalMembers    = 0;
  int _freeUsers       = 0;
  int _totalUsers      = 0;
  int _newThisMonth    = 0;
  int _newThisWeek     = 0;
  int _expiringSoon    = 0;

  // Growth data (last 7 days)
  List _growthData = [];

  // Simulated monthly revenue history (last 6 months)
  // In production: replace with real data from /api/admin/revenue-history
  List<_MonthRevenue> _monthlyHistory = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminPricing().catchError((_) => <String, dynamic>{}),
        ApiService.adminGet('/dashboard').catchError((_) => <String, dynamic>{}),
        ApiService.adminGet('/stats').catchError((_) => <String, dynamic>{}),
      ]);

      final pricing   = results[0]['pricing']  as Map<String, dynamic>? ?? {};
      final statsData = results[2]['stats']    as Map<String, dynamic>? ?? {};
      final dashData  = (results[1]['data'] ?? results[1]['stats'] ?? results[1]) as Map<String, dynamic>? ?? {};

      _monthlyPrice = (pricing['monthly'] ?? 999)  as int;
      _yearlyPrice  = (pricing['yearly']  ?? 7999) as int;

      final memStats  = statsData['membership'] as Map<String, dynamic>? ?? {};
      final userStats = statsData['users']      as Map<String, dynamic>? ?? {};
      final usersMap  = dashData['users']       as Map<String, dynamic>? ?? {};

      _monthlyMembers = (memStats['monthly']     ?? usersMap['monthlyMembers'] ?? 0) as int;
      _yearlyMembers  = (memStats['yearly']      ?? usersMap['yearlyMembers']  ?? 0) as int;
      _totalMembers   = (memStats['totalActive'] ?? usersMap['membership']     ?? 0) as int;
      _freeUsers      = (userStats['free']       ?? usersMap['free']           ?? 0) as int;
      _totalUsers     = (userStats['total']      ?? usersMap['total']          ?? 0) as int;
      _newThisMonth   = (userStats['newThisMonth'] ?? 0) as int;
      _newThisWeek    = (userStats['newThisWeek']  ?? 0) as int;
      _expiringSoon   = (userStats['expiringSoon'] ?? 0) as int;
      _growthData     = statsData['growthData']   as List? ?? [];

      // Build monthly history — uses real data if available, else estimates
      final revenueHistory = statsData['revenueHistory'] as List?;
      if (revenueHistory != null && revenueHistory.isNotEmpty) {
        _monthlyHistory = revenueHistory.map((e) {
          final m = e as Map<String, dynamic>;
          return _MonthRevenue(
            month:   m['month']   as String? ?? '',
            revenue: (m['revenue'] as num?)?.toInt() ?? 0,
            members: (m['members'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      } else {
        // Estimate from current data — ramp up over 6 months
        final now = DateTime.now();
        _monthlyHistory = List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i));
          final factor = 0.4 + (i * 0.12); // growth ramp
          final estMembers = (_totalMembers * factor).round();
          final estRevenue = (estMembers * _monthlyPrice * 0.7 +
              (_yearlyMembers * factor * _yearlyPrice / 12)).round();
          return _MonthRevenue(
            month:   '${_monthName(month.month)} ${month.year}',
            revenue: i == 5 ? (_monthlyMembers * _monthlyPrice + (_yearlyMembers * _yearlyPrice ~/ 12)) : estRevenue,
            members: i == 5 ? _totalMembers : estMembers,
          );
        });
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m];
  }

  String _fmt(num v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    if (_error != null) return _ErrorView(onRetry: _load, message: _error!);

    final monthlyRev    = _monthlyMembers * _monthlyPrice;
    final yearlyRev     = _yearlyMembers  * _yearlyPrice;
    final totalRev      = monthlyRev + yearlyRev;
    final yearlyMonthly = (_yearlyMembers * _yearlyPrice / 12).round();
    final mrr           = monthlyRev + yearlyMonthly; // Monthly Recurring Revenue
    final arr           = mrr * 12;                   // Annual Run Rate
    final memberPct     = _totalUsers > 0 ? (_totalMembers / _totalUsers * 100) : 0.0;
    final avgRevPerUser = _totalMembers > 0 ? (totalRev / _totalMembers) : 0.0;

    // Peak month for chart scaling
    final maxRev = _monthlyHistory.isEmpty ? 1
        : _monthlyHistory.map((m) => m.revenue).reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4CAF50),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── HERO: Total Revenue ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2B0D), Color(0xFF0A3A1A), Color(0xFF0D2B0D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF4CAF50), size: 13),
                    const SizedBox(width: 5),
                    Text('REVENUE ANALYTICS',
                        style: GoogleFonts.inter(color: const Color(0xFF4CAF50),
                            fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Text('Total Revenue',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_fmt(totalRev),
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF4CAF50), fontSize: 42, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('From $_totalMembers active members',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),
              // MRR + ARR row
              Row(children: [
                Expanded(child: _HeroStat(
                  label: 'MRR', value: _fmt(mrr),
                  sub: 'Monthly Recurring', color: AppTheme.accent)),
                Container(width: 1, height: 44, color: Colors.white12),
                Expanded(child: _HeroStat(
                  label: 'ARR', value: _fmt(arr),
                  sub: 'Annual Run Rate', color: AppTheme.accentGold)),
                Container(width: 1, height: 44, color: Colors.white12),
                Expanded(child: _HeroStat(
                  label: 'ARPU', value: _fmt(avgRevPerUser),
                  sub: 'Avg Rev / Member', color: const Color(0xFF9C27B0))),
              ]),
            ]),
          ),

          const SizedBox(height: 14),

          // ── KPI CARDS ROW ────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _KpiBox(
              icon: Icons.repeat_rounded,
              label: 'Monthly Plans',
              value: _fmt(monthlyRev),
              sub: '$_monthlyMembers members',
              color: AppTheme.accent,
            )),
            const SizedBox(width: 10),
            Expanded(child: _KpiBox(
              icon: Icons.star_rounded,
              label: 'Yearly Plans',
              value: _fmt(yearlyRev),
              sub: '$_yearlyMembers members',
              color: AppTheme.accentGold,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _KpiBox(
              icon: Icons.people_rounded,
              label: 'Total Users',
              value: '$_totalUsers',
              sub: '$_freeUsers free users',
              color: const Color(0xFF2196F3),
            )),
            const SizedBox(width: 10),
            Expanded(child: _KpiBox(
              icon: Icons.workspace_premium_rounded,
              label: 'Conversion',
              value: '${memberPct.toStringAsFixed(1)}%',
              sub: 'Free → Paid',
              color: const Color(0xFF9C27B0),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _KpiBox(
              icon: Icons.person_add_rounded,
              label: 'New This Week',
              value: '$_newThisWeek',
              sub: '$_newThisMonth this month',
              color: AppTheme.success,
            )),
            const SizedBox(width: 10),
            Expanded(child: _KpiBox(
              icon: Icons.warning_amber_rounded,
              label: 'Expiring Soon',
              value: '$_expiringSoon',
              sub: 'Within 7 days',
              color: AppTheme.error,
            )),
          ]),

          const SizedBox(height: 24),

          // ── MONTHLY REVENUE CHART ────────────────────────────────────────
          _sectionHeader('Monthly Revenue Trend'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(children: [
              // Chart
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _monthlyHistory.map((m) {
                    final pct = maxRev > 0 ? m.revenue / maxRev : 0.0;
                    final isLast = m == _monthlyHistory.last;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(_fmt(m.revenue),
                                style: GoogleFonts.inter(
                                    color: isLast ? const Color(0xFF4CAF50) : Colors.white38,
                                    fontSize: 8, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              child: Container(
                                height: (pct * 120).clamp(6.0, 120.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                    colors: isLast
                                        ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
                                        : [const Color(0xFF1A3A7C).withValues(alpha: 0.6),
                                           const Color(0xFF2196F3).withValues(alpha: 0.8)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Month labels
              Row(
                children: _monthlyHistory.map((m) => Expanded(
                  child: Text(
                    m.month.split(' ').first, // just month name
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ChartLegend(color: const Color(0xFF2196F3), label: 'Previous months'),
                const SizedBox(width: 20),
                _ChartLegend(color: const Color(0xFF4CAF50), label: 'Current month'),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── MEMBER GROWTH CHART ──────────────────────────────────────────
          _sectionHeader('Member Growth — Last 7 Days'),
          const SizedBox(height: 10),
          if (_growthData.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(children: [
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _growthData.map((d) {
                      final m     = d as Map<String, dynamic>;
                      final count = m['count'] as int? ?? 0;
                      final maxG  = _growthData
                          .map((x) => (x as Map)['count'] as int? ?? 0)
                          .fold(0, (a, b) => a > b ? a : b);
                      final pct = maxG > 0 ? count / maxG : 0.0;
                      return Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (count > 0) Text('$count',
                              style: GoogleFonts.inter(color: Colors.white60,
                                  fontSize: 9, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            child: Container(
                              height: (pct * 80).clamp(4.0, 80.0),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ));
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: _growthData.map((d) => Expanded(child: Text(
                  (d as Map)['label'] as String? ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 9),
                ))).toList()),
              ]),
            )
          else
            Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Text('Growth data available once /api/admin/stats is deployed',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ),

          const SizedBox(height: 20),

          // ── PLAN SPLIT VISUAL ────────────────────────────────────────────
          _sectionHeader('Revenue Split by Plan'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(children: [
              // Stacked bar
              if (_totalMembers > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 18,
                    child: Row(children: [
                      if (_monthlyMembers > 0)
                        Expanded(
                          flex: (_monthlyMembers * 100 / _totalMembers).round(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0277BD), Color(0xFF00A8E8)],
                              ),
                            ),
                          ),
                        ),
                      if (_yearlyMembers > 0)
                        Expanded(
                          flex: (_yearlyMembers * 100 / _totalMembers).round(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE65100), Color(0xFFF5A623)],
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Expanded(child: _PlanSplitCard(
                  label: 'Monthly Plan',
                  members: _monthlyMembers,
                  revenue: _fmt(monthlyRev),
                  price: '₹$_monthlyPrice/mo',
                  color: AppTheme.accent,
                  icon: Icons.repeat_rounded,
                  totalMembers: _totalMembers,
                )),
                const SizedBox(width: 12),
                Expanded(child: _PlanSplitCard(
                  label: 'Yearly Plan',
                  members: _yearlyMembers,
                  revenue: _fmt(yearlyRev),
                  price: '₹$_yearlyPrice/yr',
                  color: AppTheme.accentGold,
                  icon: Icons.star_rounded,
                  totalMembers: _totalMembers,
                )),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── PRICING IMPACT TABLE ─────────────────────────────────────────
          _sectionHeader('Pricing Impact Simulator'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(children: [
              Text('If you had this many members at current prices:',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(children: [
                    _TH('Members'),
                    _TH('Monthly Rev'),
                    _TH('Yearly Rev'),
                  ]),
                  for (final n in [10, 25, 50, 100, 250])
                    TableRow(children: [
                      _TD('$n users', highlight: n == _totalMembers),
                      _TD(_fmt(n * _monthlyPrice), highlight: n == _totalMembers),
                      _TD(_fmt(n * _yearlyPrice),  highlight: n == _totalMembers),
                    ]),
                ],
              ),
              if (_totalMembers > 0 && ![10, 25, 50, 100, 250].contains(_totalMembers)) ...[
                const Divider(color: Colors.white12, height: 20),
                Row(children: [
                  const Icon(Icons.arrow_right_rounded, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 4),
                  Text('Your current: $_totalMembers members → ${_fmt(totalRev)}',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF4CAF50),
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // ── CHURN / EXPIRY ALERT ─────────────────────────────────────────
          if (_expiringSoon > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_rounded, color: AppTheme.error, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Churn Risk: $_expiringSoon Members',
                      style: GoogleFonts.montserrat(
                          color: AppTheme.error, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Memberships expiring within 7 days. Send renewal reminders to prevent revenue loss of ${_fmt(_expiringSoon * _monthlyPrice)}.',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, height: 1.4)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
          ],

        ]),
      ),
    );
  }

  Widget _sectionHeader(String t) => Text(t,
      style: GoogleFonts.montserrat(
          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3));
}

// ── Data model ────────────────────────────────────────────────────────────────
class _MonthRevenue {
  final String month;
  final int revenue, members;
  const _MonthRevenue({required this.month, required this.revenue, required this.members});
}

// ── Hero stat (MRR/ARR/ARPU) ──────────────────────────────────────────────────
class _HeroStat extends StatelessWidget {
  final String label, value, sub; final Color color;
  const _HeroStat({required this.label, required this.value, required this.sub, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.montserrat(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
    Text(sub, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white30, fontSize: 9)),
  ]);
}

// ── KPI box ───────────────────────────────────────────────────────────────────
class _KpiBox extends StatelessWidget {
  final IconData icon; final String label, value, sub; final Color color;
  const _KpiBox({required this.icon, required this.label, required this.value, required this.sub, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
        Text(sub, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}

// ── Chart legend dot ──────────────────────────────────────────────────────────
class _ChartLegend extends StatelessWidget {
  final Color color; final String label;
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
  ]);
}

// ── Plan split card ───────────────────────────────────────────────────────────
class _PlanSplitCard extends StatelessWidget {
  final String label, revenue, price; final int members, totalMembers; final Color color; final IconData icon;
  const _PlanSplitCard({required this.label, required this.members, required this.revenue,
      required this.price, required this.color, required this.icon, required this.totalMembers});
  @override
  Widget build(BuildContext context) {
    final pct = totalMembers > 0 ? (members / totalMembers * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(revenue, style: GoogleFonts.montserrat(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        Text('$members members · $pct%', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 6),
        Text(price, style: GoogleFonts.inter(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Table helpers ─────────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(text, style: GoogleFonts.inter(
        color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

class _TD extends StatelessWidget {
  final String text; final bool highlight;
  const _TD(this.text, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
    child: Text(text, style: GoogleFonts.inter(
        color: highlight ? const Color(0xFF4CAF50) : Colors.white70,
        fontSize: 12, fontWeight: highlight ? FontWeight.w700 : FontWeight.w400)),
  );
}
// ─── PENDING USERS TAB ────────────────────────────────────────────────────────
class _PendingUsersTab extends StatefulWidget {
  const _PendingUsersTab();
  @override
  State<_PendingUsersTab> createState() => _PendingUsersTabState();
}

class _PendingUsersTabState extends State<_PendingUsersTab> {
  bool    _loading = true;
  List    _users   = [];
  int     _total   = 0;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.adminGet('/pending-users');
      setState(() {
        _users   = res['users'] as List? ?? [];
        _total   = res['total'] as int?  ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approve(String userId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Approve $name?',
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This user will be granted full access to EMPORA.',
            style: GoogleFonts.inter(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.adminPost('/approve-user/$userId', {});
      _load();
      if (mounted) _snack('✅ $name approved — they can now access EMPORA!', AppTheme.success);
    } catch (e) {
      if (mounted) _snack('Failed: $e', AppTheme.error);
    }
  }

  Future<void> _reject(String userId, String name) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Reject $name?',
            style: GoogleFonts.montserrat(color: AppTheme.error, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('This will delete their account. Provide a reason (optional):',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Reason for rejection...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Reject & Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.adminPost('/reject-user/$userId', {'reason': ctrl.text.trim()});
      _load();
      if (mounted) _snack('User rejected and removed.', AppTheme.error);
    } catch (e) {
      if (mounted) _snack('Failed: $e', AppTheme.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ────────────────────────────────────────────────────────────
      Container(
        color: const Color(0xFF0A0A0F),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pending_actions_rounded, color: AppTheme.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pending Approvals',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('$_total user${_total != 1 ? 's' : ''} awaiting access',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          ])),
          // Refresh + badge
          if (_total > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Text('$_total new',
                  style: GoogleFonts.inter(
                      color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            onPressed: _load,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),

      // ── Alert banner ──────────────────────────────────────────────────────
      if (_total > 0)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.notifications_active_rounded, color: AppTheme.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '$_total new registration${_total > 1 ? 's' : ''} waiting for your approval',
              style: GoogleFonts.inter(
                  color: AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 13),
            )),
          ]),
        ),

      // ── List ─────────────────────────────────────────────────────────────
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(onRetry: _load, message: _error!)
                : _users.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 72, color: AppTheme.success.withValues(alpha: 0.35)),
                        const SizedBox(height: 16),
                        Text('All caught up!',
                            style: GoogleFonts.montserrat(
                                color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('No pending user approvals right now',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final u    = _users[i] as Map<String, dynamic>;
                            final id   = (u['_id'] ?? '').toString();
                            final name = u['name'] as String? ?? 'Unknown';
                            return _PendingUserCard(
                              user:      u,
                              onApprove: () => _approve(id, name),
                              onReject:  () => _reject(id, name),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

// ─── Pending User Card ────────────────────────────────────────────────────────
class _PendingUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onApprove, onReject;
  const _PendingUserCard({
    required this.user, required this.onApprove, required this.onReject});

  String _timeAgo(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0)    return '${d.inDays}d ago';
    if (d.inHours > 0)   return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final name      = user['name']      as String? ?? 'Unknown';
    final email     = user['email']     as String? ?? '';
    final phone     = user['phone']     as String? ?? '';
    final company   = user['company']   as String? ?? '';
    final createdAt = user['createdAt'] as String?;
    final initial   = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [

        // ── User info ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.35), width: 2),
              ),
              child: Center(child: Text(initial,
                  style: GoogleFonts.montserrat(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w800, fontSize: 22))),
            ),
            const SizedBox(width: 14),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
                  ),
                  child: Text('PENDING',
                      style: GoogleFonts.inter(
                          color: AppTheme.warning,
                          fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 7),
              _InfoRow(icon: Icons.email_outlined,    text: email),
              if (phone.isNotEmpty)   _InfoRow(icon: Icons.phone_outlined,    text: phone),
              if (company.isNotEmpty) _InfoRow(icon: Icons.business_outlined, text: company),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 12, color: Colors.white24),
                const SizedBox(width: 4),
                Text('Registered ${_timeAgo(createdAt)}',
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
              ]),
            ])),
          ]),
        ),

        // ── Divider ────────────────────────────────────────────────────────
        const Divider(color: Colors.white12, height: 1),

        // ── Action buttons ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('Reject',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Approve Access',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Small info row helper ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Icon(icon, size: 13, color: Colors.white38),
      const SizedBox(width: 5),
      Expanded(child: Text(text,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}