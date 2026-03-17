// lib/screens/home_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// WHAT CHANGED vs the old file:
//   • _ProfileTab is now a StatefulWidget with full editable profile fields
//   • "Complete Your Profile" section is shown INSIDE the Profile tab
//   • Tapping any field opens a bottom-sheet editor (text or dropdown)
//   • Changes auto-save via ApiService.saveFounderProfile()
//   • Live completion ring + progress bar at top of profile
//   • Everything else (Home, Modules, Alerts tabs, nav bar) is UNCHANGED
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:empora/theme/app_theme.dart';
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // ── Tab 0 : Home ──────────────────────────────────────────────────
          _HomeTab(
            filteredModules: _filteredModules,
            searchController: _searchCtrl,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onSearchClear: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          ),
          // ── Tab 1 : All Modules ───────────────────────────────────────────
          _ModulesTab(
            filteredModules: _filteredModules,
            searchController: _searchCtrl,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
          ),
          // ── Tab 2 : Alerts ────────────────────────────────────────────────
          const _AlertsTab(),
          // ── Tab 3 : Profile (NEW) ─────────────────────────────────────────
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.apps_rounded,
                label: 'Modules',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — HOME
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final List<AppModule>        filteredModules;
  final TextEditingController  searchController;
  final String                 searchQuery;
  final ValueChanged<String>   onSearchChanged;
  final VoidCallback           onSearchClear;

  const _HomeTab({
    required this.filteredModules,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CustomScrollView(
      slivers: [
        // ── App bar with gradient header ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 210,
          floating: false,
          pinned: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  top: -20, right: -20,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, right: 60,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // EMPORA logo
                            Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    'E',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'EMPORA',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                            ]),
                            // Action buttons
                            Row(children: [
                              if (auth.isAdmin)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Admin',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  auth.logout();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (r) => false,
                                  );
                                },
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                                ),
                              ),
                            ]),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Greeting
                        Text(
                          _greeting(),
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Name + badge
                        Row(children: [
                          Expanded(
                            child: Text(
                              auth.user?.name ?? 'Welcome!',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: auth.isAdmin || auth.isMember
                                  ? AppTheme.accentGold
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                auth.isMember ? Icons.workspace_premium : Icons.person_outline,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                auth.isAdmin ? 'ADMIN' : auth.isMember ? 'MEMBER' : 'FREE',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          // Search bar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search modules...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                            onPressed: onSearchClear,
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Stats row ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              _StatChip(label: '${ModuleData.modules.length} Modules', icon: Icons.apps),
              const SizedBox(width: 10),
              _StatChip(label: 'Active', icon: Icons.circle, iconColor: AppTheme.success),
              const Spacer(),
              Text(
                '${filteredModules.length} showing',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Complete Profile Banner (only if profile not done) ─────────────
        if (auth.user?.founderProfileComplete != true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'Complete Your Profile',
                          style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Help AI give you personalized advice',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Complete',
                        style: GoogleFonts.inter(
                          color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // ── Upgrade Banner (free users only) ──────────────────────────────
        if (!auth.isMember && !auth.isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'Unlock All Features',
                          style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Upgrade to membership — access all 10 modules',
                          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Upgrade',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF5A623), fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // ── Section header ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Business Modules',
                style: GoogleFonts.montserrat(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                ),
              ),
            ]),
          ),
        ),

        // ── Module grid ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final module   = filteredModules[index];
                final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
                return _ModuleCard(
                  module: module,
                  displayIndex: index + 1,
                  isLocked: isLocked,
                );
              },
              childCount: filteredModules.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — ALL MODULES
// ─────────────────────────────────────────────────────────────────────────────
class _ModulesTab extends StatelessWidget {
  final List<AppModule>       filteredModules;
  final TextEditingController searchController;
  final String                searchQuery;
  final ValueChanged<String>  onSearchChanged;

  const _ModulesTab({
    required this.filteredModules,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: Column(children: [
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'All Modules',
              style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemCount: filteredModules.length,
            itemBuilder: (context, index) {
              final module   = filteredModules[index];
              final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
              return _ModuleCard(
                module: module,
                displayIndex: index + 1,
                isLocked: isLocked,
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — ALERTS
// ─────────────────────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: AppTheme.primary,
          child: Text(
            'Alerts',
            style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 72,
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No alerts yet',
                style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Important updates will appear here',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PROFILE  ← THIS IS THE NEW ONE
// ─────────────────────────────────────────────────────────────────────────────

// Colour shortcuts used only inside this profile tab
const _kNavy    = Color(0xFF0F2A5E);
const _kNavyDk  = Color(0xFF0A1E46);
const _kGold    = Color(0xFFF5A623);
const _kRed     = Color(0xFFE63B2E);
const _kGreen   = Color(0xFF27AE60);
const _kBg      = Color(0xFFF0F2F7);
const _kBorder  = Color(0xFFE5E7EB);
const _kSub     = Color(0xFF6B7280);
const _kInputBg = Color(0xFFF8F9FC);

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  // ── Editable field values ─────────────────────────────────────────────────
  String _name     = '';
  String _email    = '';
  String _bizName  = '';
  String _industry = '';
  String _stage    = '';
  String _revenue  = '';
  String _location = '';
  String _phone    = '';

  bool _initialized = false;

  // Seeds name/email from UserModel (always available on the model directly).
  // Then calls ApiService.getFounderProfile() → GET /api/auth/founder-profile
  // to load the nested business fields that are not stored on UserModel.
  void _initFromAuth(AuthProvider auth) {
    if (_initialized) return;
    _initialized = true;
    _name  = auth.user?.name  ?? '';
    _email = auth.user?.email ?? '';
    _loadFounderFields();
  }

  Future<void> _loadFounderFields() async {
    try {
      // ApiService.getFounderProfile() → GET /api/auth/founder-profile
      // Returns: { founderProfile: { businessName, industry, businessStage,
      //   annualRevenue, city, state, phone, ... } }
      final res = await ApiService.getFounderProfile();

      // The endpoint may wrap data under 'data', 'founderProfile', or return it flat
      final raw = res['data'] ?? res['founderProfile'] ?? res;
      final fp  = raw is Map<String, dynamic> ? raw : null;

      if (fp != null && mounted) {
        setState(() {
          _bizName  = fp['businessName']  as String? ?? '';
          _industry = fp['industry']      as String? ?? '';
          _stage    = fp['businessStage'] as String? ?? '';
          _revenue  = fp['annualRevenue'] as String? ?? '';
          final city     = fp['city']  as String? ?? '';
          final stateStr = fp['state'] as String? ?? '';
          _location = [city, stateStr].where((s) => s.isNotEmpty).join(', ');
          _phone    = fp['phone'] as String? ?? '';
        });
      }
    } catch (_) {
      // silently ignore — fields stay empty, user can fill them in manually
    }
  }

  // ── Completion % ──────────────────────────────────────────────────────────
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

  // ── Save to backend ───────────────────────────────────────────────────────
  Future<void> _save() async {
    try {
      final parts    = _location.split(',');
      final city     = parts.isNotEmpty ? parts[0].trim() : '';
      final stateVal = parts.length > 1  ? parts[1].trim() : '';
      await ApiService.saveFounderProfile({
        'businessName':  _bizName,
        'industry':      _industry,
        'businessStage': _stage,
        'annualRevenue': _revenue,
        'city':          city,
        'state':         stateVal,
        'phone':         _phone,
      });
      await context.read<AuthProvider>().fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓  Saved successfully'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  // ── Open bottom-sheet editor ──────────────────────────────────────────────
  // Pass  options: null  →  free-text TextField
  // Pass  options: [...]  →  scrollable list picker
  Future<void> _edit({
    required String        title,
    required String        current,
    List<String>?          options,
    String?                hint,
    TextInputType          keyboard = TextInputType.text,
    required ValueChanged<String> onSave,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        title:   title,
        current: current,
        options: options,
        hint:    hint,
        keyboard: keyboard,
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
      _save(); // auto-persist after every edit
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _initFromAuth(auth);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero banner ─────────────────────────────────────────
              _buildHero(auth),

              // ── 2. Completion ring card ────────────────────────────────
              _buildCompletionCard(),

              // ── 3. Account section (name, email, type) ─────────────────
              _buildSectionHeader('Account'),
              _buildCardGroup([
                _FieldRow(
                  icon: Icons.person_outline,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F6EF7),
                  label: 'Full Name',
                  value: _name,
                  onEdit: () => _edit(
                    title: 'Full Name',
                    current: _name,
                    hint: 'Enter your full name',
                    onSave: (v) => setState(() => _name = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.email_outlined,
                  iconBg: const Color(0xFFFEF3E2),
                  iconColor: _kGold,
                  label: 'Email',
                  value: _email,
                  onEdit: () => _edit(
                    title: 'Email Address',
                    current: _email,
                    hint: 'Enter email address',
                    keyboard: TextInputType.emailAddress,
                    onSave: (v) => setState(() => _email = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.badge_outlined,
                  iconBg: const Color(0xFFFEF3E2),
                  iconColor: _kGold,
                  label: 'Account Type',
                  value: auth.isAdmin ? 'Administrator' : auth.isMember ? 'Member' : 'Free',
                  valueColor: (auth.isAdmin || auth.isMember) ? _kGold : _kSub,
                  showEdit: false,  // account type is not manually editable
                ),
              ]),

              // ── 4. Complete Your Profile section ───────────────────────
              _buildSectionHeader(
                'Complete Your Profile',
                subtitle: '● required to unlock AI advice',
                subtitleColor: _kRed,
              ),
              _buildCardGroup([
                _FieldRow(
                  icon: Icons.home_work_outlined,
                  iconBg: const Color(0xFFEEFAF3),
                  iconColor: _kGreen,
                  label: 'Business Name',
                  value: _bizName,
                  required: true,
                  onEdit: () => _edit(
                    title: 'Business Name',
                    current: _bizName,
                    hint: 'e.g. Acme Corp',
                    onSave: (v) => setState(() => _bizName = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.language_outlined,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F6EF7),
                  label: 'Industry',
                  value: _industry,
                  required: true,
                  onEdit: () => _edit(
                    title: 'Industry',
                    current: _industry,
                    options: const [
                      'Technology', 'Finance', 'Real Estate',
                      'Healthcare', 'Retail', 'Manufacturing',
                      'Education', 'Logistics', 'Other',
                    ],
                    onSave: (v) => setState(() => _industry = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.trending_up_outlined,
                  iconBg: const Color(0xFFFFF3F3),
                  iconColor: _kRed,
                  label: 'Business Stage',
                  value: _stage,
                  required: true,
                  onEdit: () => _edit(
                    title: 'Business Stage',
                    current: _stage,
                    options: const [
                      'Idea / Pre-revenue',
                      'Early Stage (0–1 yr)',
                      'Growth (1–3 yrs)',
                      'Scaling (3–7 yrs)',
                      'Established (7+ yrs)',
                    ],
                    onSave: (v) => setState(() => _stage = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.currency_rupee_outlined,
                  iconBg: const Color(0xFFFEF3E2),
                  iconColor: _kGold,
                  label: 'Annual Revenue',
                  value: _revenue,
                  required: true,
                  onEdit: () => _edit(
                    title: 'Annual Revenue',
                    current: _revenue,
                    options: const [
                      'Pre-revenue',
                      'Under ₹10L',
                      '₹10L – ₹50L',
                      '₹50L – ₹1Cr',
                      '₹1Cr – ₹5Cr',
                      'Above ₹5Cr',
                    ],
                    onSave: (v) => setState(() => _revenue = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.location_on_outlined,
                  iconBg: const Color(0xFFEEFAF3),
                  iconColor: _kGreen,
                  label: 'Location',
                  value: _location,
                  onEdit: () => _edit(
                    title: 'Location',
                    current: _location,
                    hint: 'City, State',
                    onSave: (v) => setState(() => _location = v),
                  ),
                ),
                _FieldRow(
                  icon: Icons.phone_outlined,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F6EF7),
                  label: 'Phone Number',
                  value: _phone,
                  onEdit: () => _edit(
                    title: 'Phone Number',
                    current: _phone,
                    hint: '+91 98765 43210',
                    keyboard: TextInputType.phone,
                    onSave: (v) => setState(() => _phone = v),
                  ),
                ),
              ]),

              // ── 5. Admin section (only for admins) ─────────────────────
              if (auth.isAdmin) ...[
                _buildSectionHeader('Admin'),
                _buildCardGroup([
                  _FieldRow(
                    icon: Icons.admin_panel_settings_outlined,
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF4F6EF7),
                    label: 'Admin Panel',
                    value: 'Manage users & submissions',
                    showEdit: false,
                    showArrow: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                  ),
                ]),
              ],

              // ── 6. Upgrade banner (free users only) ────────────────────
              if (!auth.isMember && !auth.isAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MembershipScreen()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kGold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              'Upgrade to Membership',
                              style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Unlock all AI advisor modules',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ]),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ]),
                    ),
                  ),
                ),

              // ── 7. Logout button ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 4,
                      shadowColor: _kRed.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero widget ────────────────────────────────────────────────────────────
  Widget _buildHero(AuthProvider auth) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavyDk, _kNavy],
        ),
      ),
      child: Stack(children: [
        // Decorative circle top-right
        Positioned(
          top: -50, right: -50,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        // Decorative circle bottom-left
        Positioned(
          bottom: -30, left: -30,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(children: [
            // Avatar with edit button
            Stack(children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _kNavyDk.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.montserrat(
                      fontSize: 36, fontWeight: FontWeight.w800, color: _kNavy,
                    ),
                  ),
                ),
              ),
              // Gold pencil edit button
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => _edit(
                    title: 'Full Name',
                    current: _name,
                    hint: 'Enter your full name',
                    onSave: (v) => setState(() => _name = v),
                  ),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _kGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 13),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // Name
            Text(
              _name.isEmpty ? 'Your Name' : _name,
              style: GoogleFonts.montserrat(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              _email,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            // Admin / Member / Free badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: (auth.isAdmin || auth.isMember)
                    ? _kGold
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  (auth.isAdmin || auth.isMember)
                      ? Icons.workspace_premium
                      : Icons.person_outline,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  auth.isAdmin ? 'ADMIN ACCOUNT' : auth.isMember ? 'MEMBER' : 'FREE ACCOUNT',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Completion ring card ───────────────────────────────────────────────────
  Widget _buildCompletionCard() {
    final pct      = _pct;
    final pctLabel = '${(pct * 100).round()}%';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        // Circular progress
        SizedBox(
          width: 50, height: 50,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: pct,
              strokeWidth: 4,
              backgroundColor: _kBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
            ),
            Text(
              pctLabel,
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700, color: _kGold,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Complete Your Profile',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Help AI give you personalised advice',
              style: GoogleFonts.inter(fontSize: 11, color: _kSub),
            ),
            const SizedBox(height: 7),
            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: _kBorder,
                color: _kGold,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    String title, {
    String?  subtitle,
    Color?   subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: _kSub, letterSpacing: 0.08,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10, color: subtitleColor ?? _kSub,
            ),
          ),
        ],
      ]),
    );
  }

  // ── Card group wrapper ─────────────────────────────────────────────────────
  Widget _buildCardGroup(List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16, color: _kBorder),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD ROW — single row inside a card group
// ─────────────────────────────────────────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  final IconData     icon;
  final Color        iconBg;
  final Color        iconColor;
  final String       label;
  final String       value;
  final Color?       valueColor;
  final bool         required;   // show red dot
  final bool         showEdit;   // show pencil button
  final bool         showArrow;  // show chevron (for nav rows)
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const _FieldRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.required  = false,
    this.showEdit  = true,
    this.showArrow = false,
    this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;

    return GestureDetector(
      onTap: onTap ?? (showEdit ? onEdit : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Coloured icon box
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),

          // Label + value
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11, color: _kSub, fontWeight: FontWeight.w500,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                      color: _kRed, shape: BoxShape.circle,
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(
                empty ? 'Tap to add' : value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                  color: empty
                      ? const Color(0xFFB0B8C8)
                      : (valueColor ?? const Color(0xFF1A1F36)),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),

          // Pencil edit button
          if (showEdit && onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kInputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: const Icon(Icons.edit_outlined, size: 15, color: _kSub),
              ),
            ),

          // Chevron for navigation rows (e.g. Admin Panel)
          if (showArrow)
            const Icon(Icons.chevron_right, color: _kSub, size: 22),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final String       title;
  final String       current;
  final List<String>? options;   // null = free-text, non-null = picker list
  final String?      hint;
  final TextInputType keyboard;

  const _EditSheet({
    required this.title,
    required this.current,
    this.options,
    this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TextEditingController _ctrl;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl     = TextEditingController(text: widget.current);
    _selected = widget.options?.contains(widget.current) == true
        ? widget.current
        : null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final val = widget.options != null
        ? (_selected ?? '')
        : _ctrl.text.trim();
    if (val.isNotEmpty) Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    final isDropdown = widget.options != null;

    return Padding(
      // push sheet up when keyboard opens
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _kBorder, borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(
                  child: Text(
                    'Edit ${widget.title}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1F36),
                    ),
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _kInputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Icon(Icons.close, size: 18, color: _kSub),
                  ),
                ),
              ]),
            ),

            const Divider(height: 24, indent: 20, endIndent: 20, color: _kBorder),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field label
                  Text(
                    widget.title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _kSub, letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Dropdown list (for options) ───────────────────────
                  if (isDropdown)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.options!.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _kBorder),
                          itemBuilder: (_, i) {
                            final opt = widget.options![i];
                            final sel = _selected == opt;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = opt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13,
                                ),
                                color: sel
                                    ? _kNavy.withValues(alpha: 0.06)
                                    : Colors.transparent,
                                child: Row(children: [
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: sel
                                            ? _kNavy
                                            : const Color(0xFF1A1F36),
                                      ),
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(Icons.check_circle,
                                        color: _kNavy, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    )

                  // ── Free-text input ───────────────────────────────────
                  else
                    TextField(
                      controller: _ctrl,
                      keyboardType: widget.keyboard,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 15, color: const Color(0xFF1A1F36),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint ?? 'Enter value...',
                        hintStyle: GoogleFonts.inter(color: _kSub),
                        filled: true,
                        fillColor: _kInputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kNavy, width: 1.5),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final AppModule module;
  final int       displayIndex;
  final bool      isLocked;
  const _ModuleCard({
    required this.module,
    required this.displayIndex,
    this.isLocked = false,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _screen(AppModule m) {
    switch (m.id) {
      case 1:  return const FundScreen();
      case 2:  return const StraticScreen();
      case 3:  return const TaxationScreen();
      case 4:  return const LandLegalScreen();
      case 5:  return const LicenceScreen();
      case 6:  return const LoansScreen();
      case 7:  return const RiskScreen();
      case 8:  return const ProjectScreen();
      case 9:  return const CyberScreen();
      case 10: return const RestructureScreen();
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
        onTapUp: (_) {
          _ctrl.forward();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => widget.isLocked
                  ? const MembershipScreen()
                  : _screen(m),
            ),
          );
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: m.color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Icon with optional lock badge
                Stack(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: FaIcon(
                        m.icon,
                        color: widget.isLocked ? Colors.grey.shade400 : m.color,
                        size: 20,
                      ),
                    ),
                  ),
                  if (widget.isLocked)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock, color: Colors.white, size: 8),
                      ),
                    ),
                ]),
                // Number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    numStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isLocked ? Colors.grey.shade400 : m.color,
                    ),
                  ),
                ),
              ]),
              const Spacer(),
              // Title
              Text(
                m.title,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.isLocked ? AppTheme.textSecondary : AppTheme.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                m.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10, color: AppTheme.textSecondary, height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Arrow button
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: widget.isLocked ? AppTheme.accentGold : m.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CHIP  (used in Home tab stats row)
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color?   iconColor;
  const _StatChip({required this.label, required this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: iconColor ?? AppTheme.primaryLight),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEM  (bottom navigation bar pill)
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            size: 22,
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}