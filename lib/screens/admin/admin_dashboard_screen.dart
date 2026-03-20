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
    _tabController = TabController(length: 4, vsync: this);
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
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
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline,     size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.inbox_outlined,     size: 18), text: 'Submissions'),
            Tab(icon: Icon(Icons.sell_outlined,         size: 18), text: 'Pricing'),
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
        ],
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
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res     = await ApiService.adminGet('/dashboard');
      final payload = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;
      // Also fetch pricing to show revenue
      try {
        final pricingRes = await ApiService.adminGet('/pricing');
        payload['pricing'] = pricingRes['pricing'];
      } catch (_) {}
      setState(() { _stats = payload; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(onRetry: _load, message: _error!);

    // Handle all possible response shapes from /api/admin/dashboard
    final raw         = _stats['data'] ?? _stats['stats'] ?? _stats;
    final s           = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final usersMap    = (s['users']       as Map<String, dynamic>?) ?? {};
    final subsMap     = (s['submissions'] as Map<String, dynamic>?) ?? {};
    final totalUsers  = (usersMap['total']      ?? s['totalUsers']      ?? _stats['totalUsers']      ?? 0) as num;
    final memberUsers = (usersMap['membership'] ?? s['memberUsers']     ?? _stats['memberUsers']     ?? 0) as num;
    final freeUsers   = (usersMap['free']       ?? s['freeUsers']       ?? (totalUsers - memberUsers)) as num;
    final totalSubs   = (subsMap['total']       ?? s['totalSubmissions'] ?? _stats['totalSubmissions'] ?? 0) as num;
    final pending     = (subsMap['pending']     ?? s['pendingApprovals'] ?? _stats['pendingApprovals'] ?? 0) as num;
    final approved    = (subsMap['approved']    ?? s['approvedCount']    ?? 0) as num;
    final rejected    = (subsMap['rejected']    ?? s['rejectedCount']    ?? 0) as num;
    // Revenue calculation
    final pricing     = _stats['pricing'] as Map<String, dynamic>? ?? {};
    final monthlyPrice= (pricing['monthly'] ?? s['pricing']?['monthly'] ?? 999) as num;
    final yearlyPrice = (pricing['yearly']  ?? s['pricing']?['yearly']  ?? 7999) as num;
    final monthlyMem  = (usersMap['monthlyMembers'] ?? 0) as num;
    final yearlyMem   = (usersMap['yearlyMembers']  ?? 0) as num;
    // Estimate: if breakdown not available, use memberUsers * monthly price
    final estRevenue  = monthlyMem > 0 || yearlyMem > 0
        ? (monthlyMem * monthlyPrice + yearlyMem * yearlyPrice)
        : (memberUsers * monthlyPrice);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [const Color(0xFF0A0A0F), Color(0xFF0F3460)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text('Platform Overview',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$totalUsers',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  Text('Total Users',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 16),
                    const SizedBox(width: 6),
                    Text('$memberUsers Members',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),
          Text('User Stats',
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),

          // User stat cards
          Row(children: [
            Expanded(child: _StatCard(
                label: 'Members', value: '$memberUsers',
                icon: Icons.workspace_premium, color: AppTheme.accentGold)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
                label: 'Free Users', value: '$freeUsers',
                icon: Icons.person_outline, color: AppTheme.accent)),
          ]),

          const SizedBox(height: 20),

          // ── REVENUE SECTION ──────────────────────────────────────────────
          Text('Revenue',
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A0A), Color(0xFF0A3A1A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.currency_rupee, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 6),
                Text('Total Estimated Revenue',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Text('₹${estRevenue.toStringAsFixed(0)}',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF4CAF50), fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Monthly Members', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('$memberUsers × ₹$monthlyPrice',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ])),
                Container(width: 1, height: 36, color: Colors.white12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Total Members', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('$memberUsers active',
                      style: GoogleFonts.inter(color: const Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ]),
          ),

          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(
                label: 'Monthly Plan', value: '₹$monthlyPrice',
                icon: Icons.calendar_month_outlined, color: const Color(0xFF4CAF50))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
                label: 'Yearly Plan', value: '₹$yearlyPrice',
                icon: Icons.calendar_today_outlined, color: AppTheme.accentGold)),
          ]),

          const SizedBox(height: 20),
          Text('Submissions',
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),

          // Submission stat cards
          Row(children: [
            Expanded(child: _StatCard(
                label: 'Total', value: '$totalSubs',
                icon: Icons.inbox_outlined, color: const Color(0xFF1A3A7C))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
                label: 'Pending', value: '$pending',
                icon: Icons.pending_outlined, color: AppTheme.warning)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(
                label: 'Approved', value: '$approved',
                icon: Icons.check_circle_outline, color: AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
                label: 'Rejected', value: '$rejected',
                icon: Icons.cancel_outlined, color: AppTheme.error)),
          ]),

          if (pending > 0) ...[
            const SizedBox(height: 20),
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
                  style: GoogleFonts.inter(
                      color: AppTheme.warning, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 30),
        ]),
      ),
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
        color: Colors.white,
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
        color: Colors.white,
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
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
            _StatusBadge(status: status),
          ]),
          const SizedBox(height: 6),
          if (moduleType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A7C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(moduleType,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF0A0A0F), fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(user['name'] as String? ?? 'Unknown',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
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
            const Icon(Icons.email_outlined, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(user['email'] as String? ?? '',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary)),
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
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
        color: AppTheme.surface,
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
        color: const Color(0xFF1A1A2E),
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