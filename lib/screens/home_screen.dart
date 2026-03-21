// lib/screens/home_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// IMPROVEMENTS v2:
//   1. Home header COMPACT — greeting + health ring + motivational quote
//   2. Business health score animated ring in header
//   3. Motivational quote card
//   4. Alerts tab → repurposed as "My Uploads" tab
//   5. Profile hero FULLY CENTERED — avatar, name, email, badge
//   6. Profile hero improved — gradient avatar, better spacing & badge style
//   7. Modules tab search bar fixed (white bg on teal header)
//   8. Custom _EmporaLogo widget used throughout
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/screens/notifications_screen.dart';
import 'package:empora/models/module_model.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/screens/module_screen.dart';
import 'package:empora/screens/login_screen.dart';
import 'package:empora/screens/membership_screen.dart';
import 'package:empora/screens/fund/fund_screen.dart';
import 'package:empora/screens/stratic/stratic_screen.dart';
import 'package:empora/screens/taxation/taxation_screen.dart';
import 'package:empora/screens/land_legal/land_legal_screen.dart';
import 'package:empora/screens/licence/licence_screen.dart';
import 'package:empora/screens/risk/risk_screen.dart';
import 'package:empora/screens/project/project_screen.dart';
import 'package:empora/screens/cyber/cyber_screen.dart';
import 'package:empora/screens/restructure/restructure_screen.dart';
import 'package:empora/screens/loans/loans_screen.dart';
import 'package:empora/screens/payment_screen.dart';
import 'package:empora/screens/onboarding_screen.dart';
import 'package:empora/screens/admin/admin_dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int    _selectedIndex = 0;
  String _searchQuery   = '';
  final  _searchCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().fetchProfile();
    });
  }

  List<AppModule> get _filteredModules {
    if (_searchQuery.isEmpty) return ModuleData.modules;
    return ModuleData.modules
        .where((m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.watch<AuthProvider>().isAdmin
          ? const Color(0xFF0F0F18)
          : AppTheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) => IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeDashboardTab(onViewAllModules: () => setState(() => _selectedIndex = 1)),
            _ModulesTab(
              filteredModules: _filteredModules,
              searchController: _searchCtrl,
              searchQuery: _searchQuery,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
            ),
            const _MyUploadsTab(),
            const _ProfileTab(),
            if (auth.isAdmin) const AdminDashboardScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded,            label: 'Home',    isSelected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
                _NavItem(icon: Icons.apps_rounded,            label: 'Modules', isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                _NavItem(icon: Icons.upload_file_rounded,     label: 'Uploads', isSelected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
                _NavItem(icon: Icons.person_rounded,          label: 'Profile', isSelected: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
                if (auth.isAdmin)
                  _NavItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    isSelected: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                    color: const Color(0xFFE94560),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPORA LOGO WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _EmporaLogo extends StatelessWidget {
  final double size;
  const _EmporaLogo({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Center(
        child: Text('E',
          style: GoogleFonts.montserrat(
            fontSize: size * 0.58, fontWeight: FontWeight.w800,
            color: const Color(0xFF1A3A7C), height: 1,
          )),
      ),
    );
  }
}




class _HomeDashboardTab extends StatefulWidget {
  final VoidCallback onViewAllModules;
  const _HomeDashboardTab({required this.onViewAllModules});
  @override
  State<_HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<_HomeDashboardTab> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount();
    if (mounted) setState(() => _unreadCount = count);
  }
  static const _quotes = [
    'Success is not final, failure is not fatal.',
    'The secret of getting ahead is getting started.',
    'Dream big. Start small. Act now.',
    'Your business is your story — make it great.',
    'Every expert was once a beginner.',
    'Focus on progress, not perfection.',
  ];

  String get _todayQuote => _quotes[DateTime.now().day % _quotes.length];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final top4 = ModuleData.modules.take(4).toList();

    return CustomScrollView(
      slivers: [

        // ── COMPACT HEADER ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: auth.isAdmin
                  ? [const Color(0xFF0A0A0F), const Color(0xFF1A1A2E), const Color(0xFF0D0D1A)]
                  : [const Color(0xFF0D1B4B), const Color(0xFF1A3A7C), const Color(0xFF1565C0)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT: logo + greeting + name + badge
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Logo + title + action buttons in one row
                        Row(children: [
                          _EmporaLogo(size: 32),
                          const SizedBox(width: 8),
                          Text('EMPORA', style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3)),
                          const Spacer(),

                          // 🔔 Bell with badge
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                              _loadUnreadCount();
                            },
                            child: Stack(clipBehavior: Clip.none, children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9)),
                                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  right: -2, top: -2,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(width: 6),
                          // Logout button
                          GestureDetector(
                            onTap: () {
                              context.read<AuthProvider>().logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9)),
                              child: const Icon(Icons.logout_outlined, color: Colors.white, size: 16),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Text(_greeting(), style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(auth.user?.name ?? 'Welcome!',
                          style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (auth.isAdmin || auth.isMember) ? AppTheme.accentGold : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(auth.isMember ? Icons.workspace_premium : Icons.person_outline,
                              color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(auth.isAdmin ? 'ADMIN' : auth.isMember ? 'MEMBER' : 'FREE',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                    ),


                  ],
                ),
              ),
            ),
          ),
        ),

        // ── STATS ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              _StatCard(icon: Icons.apps_rounded, label: 'Modules', value: '${ModuleData.modules.length}', color: AppTheme.primary),
              const SizedBox(width: 10),
              _StatCard(icon: Icons.upload_file_rounded, label: 'Uploads', value: '0', color: const Color(0xFF00897B)),
              const SizedBox(width: 10),
              _StatCard(
                icon:  auth.isMember ? Icons.workspace_premium : Icons.lock_outline,
                label: auth.isMember ? 'Member' : 'Upgrade',
                value: auth.isMember ? '✓' : '→',
                color: auth.isMember ? AppTheme.accentGold : const Color(0xFFE65100),
                onTap: auth.isMember ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
              ),
            ]),
          ),
        ),

        // ── QUOTE CARD ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: auth.isAdmin ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: auth.isAdmin ? Colors.white12 : AppTheme.primary.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.format_quote_rounded, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_todayQuote,
                    style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic, height: 1.45, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),

        // ── PROFILE COMPLETE BANNER (hidden for admin) ───────────────────
        if (!auth.isAdmin && auth.user?.founderProfileComplete != true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Complete Your Profile',
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Help AI give you personalized advice',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('Complete',
                        style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // ── UPGRADE BANNER ────────────────────────────────────────────────
        if (!auth.isMember && !auth.isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Unlock All Features',
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Upgrade to membership — access all 10 modules',
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                    ])),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('Upgrade',
                        style: GoogleFonts.inter(color: const Color(0xFFF5A623), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // ── QUICK ACCESS HEADER ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 4, height: 20,
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text('Quick Access', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
              GestureDetector(
                onTap: widget.onViewAllModules,
                child: Text('View All →', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),

        // ── MODULE GRID (top 4) ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final module   = top4[index];
                final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
                return _ModuleCard(module: module, displayIndex: index + 1, isLocked: isLocked);
              },
              childCount: top4.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color; final VoidCallback? onTap;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 7),
            Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — ALL MODULES (teal header, WHITE search bar — fixed)
// ─────────────────────────────────────────────────────────────────────────────
class _ModulesTab extends StatelessWidget {
  final List<AppModule> filteredModules;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _ModulesTab({required this.filteredModules, required this.searchController, required this.searchQuery, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D1B4B), Color(0xFF1A3A7C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.apps_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Text('All Modules', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('${filteredModules.length} total', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),
            // WHITE search bar so text is clearly visible on teal
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search modules...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: filteredModules.isEmpty
              ? Center(child: Text('No modules found', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0),
                  itemCount: filteredModules.length,
                  itemBuilder: (context, index) {
                    final module   = filteredModules[index];
                    final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
                    return _ModuleCard(module: module, displayIndex: index + 1, isLocked: isLocked);
                  },
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — MY UPLOADS (repurposed Alerts tab)
// ─────────────────────────────────────────────────────────────────────────────
class _MyUploadsTab extends StatefulWidget {
  const _MyUploadsTab();
  @override
  State<_MyUploadsTab> createState() => _MyUploadsTabState();
}

class _MyUploadsTabState extends State<_MyUploadsTab> {
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getMySubmissions();
      setState(() { _submissions = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':  return Colors.green;
      case 'rejected':  return Colors.red;
      case 'completed': return Colors.blue;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D1B4B), Color(0xFF1A3A7C)])),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Text('My Uploads', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('${_submissions.length} files', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: _load, child: const Icon(Icons.refresh, color: Colors.white, size: 20)),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _submissions.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _submissions.length,
                        itemBuilder: (_, i) {
                          final item       = _submissions[i];
                          final status     = item['status']     as String? ?? 'pending';
                          final title      = item['title']      as String? ?? 'Untitled';
                          final moduleType = (item['moduleType'] as String? ?? '').replaceAll('_', ' ').toUpperCase();
                          final color      = _statusColor(status);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border(left: BorderSide(color: color, width: 4)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text(moduleType, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(status[0].toUpperCase() + status.substring(1),
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFF00897B).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF00897B))),
          const SizedBox(height: 20),
          Text('No uploads yet', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Files you submit through the modules\nwill appear here so you can track their status.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          Text('Go to Module → Submit → Track here',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF00897B), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PROFILE (FULLY CENTERED + improved hero)
// ─────────────────────────────────────────────────────────────────────────────

const kNavy    = Color(0xFF0F2A5E);
const kGold    = Color(0xFFF5A623);
const kRed     = Color(0xFFE63B2E);
const kGreen   = Color(0xFF27AE60);
const kBg      = Color(0xFFF0F2F7);
const kBorder  = Color(0xFFE5E7EB);
const kSub     = Color(0xFF6B7280);
const kInputBg = Color(0xFFF8F9FC);

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String _name = '', _email = '', _bizName = '', _industry = '', _stage = '', _revenue = '', _location = '', _phone = '';
  bool   _initialized = false;

  void _initFromAuth(AuthProvider auth) {
    if (_initialized) return;
    _initialized = true;
    _name  = auth.user?.name  ?? '';
    _email = auth.user?.email ?? '';
    _loadFounderFields();
  }

  Future<void> _loadFounderFields() async {
    try {
      final res = await ApiService.getFounderProfile();
      final raw = res['data'] ?? res['founderProfile'] ?? res;
      final fp  = raw is Map<String, dynamic> ? raw : null;
      if (fp != null && mounted) {
        setState(() {
          _bizName  = fp['businessName']  as String? ?? '';
          _industry = fp['industry']      as String? ?? '';
          _stage    = fp['businessStage'] as String? ?? '';
          _revenue  = fp['annualRevenue'] as String? ?? '';
          final city = fp['city']  as String? ?? '';
          final st   = fp['state'] as String? ?? '';
          _location = [city, st].where((s) => s.isNotEmpty).join(', ');
          _phone    = fp['phone'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  double get _pct {
    int n = 0;
    if (_bizName.isNotEmpty)  n++;
    if (_industry.isNotEmpty) n++;
    if (_stage.isNotEmpty)    n++;
    if (_revenue.isNotEmpty)  n++;
    if (_location.isNotEmpty) n++;
    if (_phone.isNotEmpty)    n++;
    return n / 6;
  }

  Future<void> _save() async {
    try {
      final parts    = _location.split(',');
      final city     = parts.isNotEmpty ? parts[0].trim() : '';
      final stateVal = parts.length > 1  ? parts[1].trim() : '';
      await ApiService.saveFounderProfile({
        'businessName': _bizName, 'industry': _industry, 'businessStage': _stage,
        'annualRevenue': _revenue, 'city': city, 'state': stateVal, 'phone': _phone,
      });
      await context.read<AuthProvider>().fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓  Saved successfully'), backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
    } catch (_) {}
  }

  Future<void> _edit({
    required String title, required String current, List<String>? options,
    String? hint, TextInputType keyboard = TextInputType.text, required ValueChanged<String> onSave,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(title: title, current: current, options: options, hint: hint, keyboard: keyboard),
    );
    if (result != null && result.isNotEmpty) { onSave(result); _save(); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _initFromAuth(auth);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHero(auth),
            if (!auth.isAdmin) _buildCompletionCard(),
            _buildSectionHeader('Account'),
            _buildCardGroup([
              _FieldRow(icon: Icons.person_outline, iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF4F6EF7),
                label: 'Full Name', value: _name,
                onEdit: () => _edit(title: 'Full Name', current: _name, hint: 'Enter your full name', onSave: (v) => setState(() => _name = v))),
              _FieldRow(icon: Icons.email_outlined, iconBg: const Color(0xFFFEF3E2), iconColor: kGold,
                label: 'Email', value: _email,
                onEdit: () => _edit(title: 'Email Address', current: _email, hint: 'Enter email', keyboard: TextInputType.emailAddress, onSave: (v) => setState(() => _email = v))),
              _FieldRow(icon: Icons.badge_outlined, iconBg: const Color(0xFFFEF3E2), iconColor: kGold,
                label: 'Account Type', value: auth.isAdmin ? 'Administrator' : auth.isMember ? 'Member' : 'Free',
                valueColor: (auth.isAdmin || auth.isMember) ? kGold : kSub, showEdit: false),
            ]),
            if (!auth.isAdmin) _buildSectionHeader('Complete Your Profile', subtitle: '● required to unlock AI advice', subtitleColor: kRed),
            if (!auth.isAdmin) _buildCardGroup([
              _FieldRow(icon: Icons.home_work_outlined, iconBg: const Color(0xFFEEFAF3), iconColor: kGreen,
                label: 'Business Name', value: _bizName, required: true,
                onEdit: () => _edit(title: 'Business Name', current: _bizName, hint: 'e.g. Acme Corp', onSave: (v) => setState(() => _bizName = v))),
              _FieldRow(icon: Icons.language_outlined, iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF4F6EF7),
                label: 'Industry', value: _industry, required: true,
                onEdit: () => _edit(title: 'Industry', current: _industry,
                  options: const ['Technology','Finance','Real Estate','Healthcare','Retail','Manufacturing','Education','Logistics','Other'],
                  onSave: (v) => setState(() => _industry = v))),
              _FieldRow(icon: Icons.trending_up_outlined, iconBg: const Color(0xFFFFF3F3), iconColor: kRed,
                label: 'Business Stage', value: _stage, required: true,
                onEdit: () => _edit(title: 'Business Stage', current: _stage,
                  options: const ['Idea / Pre-revenue','Early Stage (0–1 yr)','Growth (1–3 yrs)','Scaling (3–7 yrs)','Established (7+ yrs)'],
                  onSave: (v) => setState(() => _stage = v))),
              _FieldRow(icon: Icons.currency_rupee_outlined, iconBg: const Color(0xFFFEF3E2), iconColor: kGold,
                label: 'Annual Revenue', value: _revenue, required: true,
                onEdit: () => _edit(title: 'Annual Revenue', current: _revenue,
                  options: const ['Pre-revenue','Under ₹10L','₹10L – ₹50L','₹50L – ₹1Cr','₹1Cr – ₹5Cr','Above ₹5Cr'],
                  onSave: (v) => setState(() => _revenue = v))),
              _FieldRow(icon: Icons.location_on_outlined, iconBg: const Color(0xFFEEFAF3), iconColor: kGreen,
                label: 'Location', value: _location,
                onEdit: () => _edit(title: 'Location', current: _location, hint: 'City, State', onSave: (v) => setState(() => _location = v))),
              _FieldRow(icon: Icons.phone_outlined, iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF4F6EF7),
                label: 'Phone Number', value: _phone,
                onEdit: () => _edit(title: 'Phone Number', current: _phone, hint: '+91 98765 43210',
                  keyboard: TextInputType.phone, onSave: (v) => setState(() => _phone = v))),
            ]),
            if (auth.isAdmin) ...[
              _buildSectionHeader('Admin'),
              _buildCardGroup([
                _FieldRow(icon: Icons.admin_panel_settings_outlined, iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF4F6EF7),
                  label: 'Admin Panel', value: 'Manage users & submissions', showEdit: false, showArrow: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))),
              ]),
            ],
            if (!auth.isMember && !auth.isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen())),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFFF6B35)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Upgrade to Membership', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Unlock all AI advisor modules', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      ])),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15), elevation: 4,
                    shadowColor: kRed.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  // ── HERO — 100% CENTERED ─────────────────────────────────────────────────
  Widget _buildHero(AuthProvider auth) {
    final initial    = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
    final roleLabel  = auth.isAdmin ? 'ADMIN ACCOUNT' : auth.isMember ? 'MEMBER' : 'FREE ACCOUNT';
    final badgeColor = (auth.isAdmin || auth.isMember) ? kGold : Colors.white.withValues(alpha: 0.18);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A1E46), Color(0xFF0F2A5E), Color(0xFF1A3A7C)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -40, right: -40, child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
        Positioned(bottom: -20, left: -30, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 30),
          child: Column(
            // ✅ CENTER EVERYTHING
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar — centered
              Center(
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0A1E46).withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
                        BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2)),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
                    ),
                    child: Center(
                      child: Text(initial,
                        style: GoogleFonts.montserrat(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F2A5E), height: 1)),
                    ),
                  ),
                  // Edit button
                  Positioned(right: 0, bottom: 0,
                    child: GestureDetector(
                      onTap: () => _edit(title: 'Full Name', current: _name, hint: 'Enter your full name',
                        onSave: (v) => setState(() => _name = v)),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: kGold, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 13),
                      ),
                    )),
                ]),
              ),
              const SizedBox(height: 16),

              // Name — CENTERED
              Text(_name.isEmpty ? 'Your Name' : _name,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),

              // Email — CENTERED
              if (_email.isNotEmpty)
                Text(_email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
              const SizedBox(height: 14),

              // Badge — CENTERED
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(24),
                    border: (auth.isAdmin || auth.isMember) ? null : Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    boxShadow: (auth.isAdmin || auth.isMember)
                        ? [BoxShadow(color: kGold.withValues(alpha: 0.4), blurRadius: 14)]
                        : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon((auth.isAdmin || auth.isMember) ? Icons.workspace_premium : Icons.person_outline,
                      color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(roleLabel,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCompletionCard() {
    final pct = _pct;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        SizedBox(width: 50, height: 50,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: pct, strokeWidth: 4, backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(kGold)),
            Text('${(pct * 100).round()}%',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kGold)),
          ])),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Complete Your Profile',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36))),
          const SizedBox(height: 2),
          Text('Help AI give you personalised advice', style: GoogleFonts.inter(fontSize: 11, color: kSub)),
          const SizedBox(height: 7),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: kBorder, color: kGold)),
        ])),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, Color? subtitleColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(children: [
        Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: kSub, letterSpacing: 0.8)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: subtitleColor ?? kSub)),
        ],
      ]),
    );
  }

  Widget _buildCardGroup(List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(children: [e.value, if (!isLast) Divider(height: 1, indent: 56, color: kBorder)]);
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String label, value; final Color? valueColor;
  final bool required, showEdit, showArrow;
  final VoidCallback? onEdit, onTap;

  const _FieldRow({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.label, required this.value,
    this.valueColor, this.required = false, this.showEdit = true,
    this.showArrow = false, this.onEdit, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? (showEdit ? onEdit : null),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: kSub, fontWeight: FontWeight.w500)),
              if (required) Text(' ●', style: GoogleFonts.inter(fontSize: 9, color: kRed)),
            ]),
            const SizedBox(height: 2),
            Text(value.isEmpty ? 'Not set' : value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
                color: value.isEmpty ? kSub.withValues(alpha: 0.5) : (valueColor ?? const Color(0xFF1A1F36)))),
          ])),
          if (showEdit && onEdit != null)
            Container(width: 30, height: 30,
              decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
              child: Icon(Icons.edit_outlined, size: 14, color: kSub)),
          if (showArrow) Icon(Icons.chevron_right, color: kSub, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final String title, current; final List<String>? options; final String? hint; final TextInputType keyboard;
  const _EditSheet({required this.title, required this.current, this.options, this.hint, this.keyboard = TextInputType.text});
  @override State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.current); }
  @override void dispose()   { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isOptions = widget.options != null;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Edit ${widget.title}', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: kNavy)),
            const SizedBox(height: 16),
            if (isOptions)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options!.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                  itemBuilder: (_, i) {
                    final opt      = widget.options![i];
                    final selected = opt == widget.current;
                    return ListTile(
                      title: Text(opt, style: GoogleFonts.inter(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? kNavy : const Color(0xFF374151))),
                      trailing: selected ? const Icon(Icons.check_circle, color: kGold) : null,
                      onTap: () => Navigator.pop(context, opt),
                    );
                  },
                ),
              )
            else ...[
              Container(
                decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                child: TextField(
                  controller: _ctrl, keyboardType: widget.keyboard, autofocus: true,
                  style: GoogleFonts.inter(fontSize: 15, color: kNavy),
                  decoration: InputDecoration(hintText: widget.hint, hintStyle: GoogleFonts.inter(color: kSub),
                    border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _ctrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNavy, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                )),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final AppModule module; final int displayIndex; final bool isLocked;
  const _ModuleCard({required this.module, required this.displayIndex, required this.isLocked});
  @override State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, lowerBound: 0.94, upperBound: 1.0, value: 1.0, duration: const Duration(milliseconds: 120)); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _screen(AppModule m) {
    switch (m.id) {
      case 1: return const FundScreen();      case 2: return const StraticScreen();
      case 3: return const TaxationScreen();  case 4: return const LandLegalScreen();
      case 5: return const LicenceScreen();   case 6: return const LoansScreen();
      case 7: return const RiskScreen();      case 8: return const ProjectScreen();
      case 9: return const CyberScreen();     case 10: return const RestructureScreen();
      default: return ModuleScreen(module: m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m      = widget.module;
    final numStr = widget.displayIndex.toString().padLeft(2, '0');
    return ScaleTransition(
      scale: _ctrl,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) { _ctrl.forward(); Navigator.push(context, MaterialPageRoute(builder: (_) => widget.isLocked ? const MembershipScreen() : _screen(m))); },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Stack(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                      borderRadius: BorderRadius.circular(14)),
                    child: Center(child: FaIcon(m.icon, color: widget.isLocked ? Colors.grey.shade400 : m.color, size: 20))),
                  if (widget.isLocked)
                    Positioned(right: 0, bottom: 0,
                      child: Container(padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                        child: const Icon(Icons.lock, color: Colors.white, size: 8))),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(numStr,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                      color: widget.isLocked ? Colors.grey.shade400 : m.color)),
                ),
              ]),
              const Spacer(),
              Text(m.title,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700,
                  color: widget.isLocked ? AppTheme.textSecondary : AppTheme.textPrimary, height: 1.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(m.subtitle,
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: widget.isLocked ? AppTheme.accentGold : m.color,
                    borderRadius: BorderRadius.circular(8)),
                  child: Icon(widget.isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
                    color: Colors.white, size: 12)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? Colors.white : (color ?? AppTheme.textSecondary), size: 22),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}