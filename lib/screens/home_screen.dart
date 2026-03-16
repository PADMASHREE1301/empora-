// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/models/module_model.dart';
import 'package:empora/services/auth_provider.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<AppModule> get _filteredModules {
    if (_searchQuery.isEmpty) return ModuleData.modules;
    return ModuleData.modules
        .where((m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            filteredModules: _filteredModules,
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onSearchClear: () { _searchController.clear(); setState(() => _searchQuery = ''); },
          ),
          _ModulesTab(
            filteredModules: _filteredModules,
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
          ),
          const _AlertsTab(),
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
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,          label: 'Home',    isSelected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
              _NavItem(icon: Icons.apps_rounded,          label: 'Modules', isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
              _NavItem(icon: Icons.notifications_rounded, label: 'Alerts',  isSelected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
              _NavItem(icon: Icons.person_rounded,        label: 'Profile', isSelected: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final List<AppModule> filteredModules;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  const _HomeTab({
    required this.filteredModules,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  String _getGreeting() {
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
                Positioned(top: -20, right: -20,
                  child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
                Positioned(bottom: 20, right: 60,
                  child: Container(width: 60, height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withOpacity(0.15)))),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        // Logo
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                            child: Center(child: Text('E', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary))),
                          ),
                          const SizedBox(width: 10),
                          Text('EMPORA', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3)),
                        ]),
                        // Actions
                        Row(children: [
                          // Admin button ✅
                          if (auth.isAdmin)
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminPlaceholder())),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(20)),
                                child: Row(children: [
                                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Admin', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ),
                          // Logout
                          GestureDetector(
                            onTap: () {
                              auth.logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                            },
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 16),
                      Text(_getGreeting(), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      const SizedBox(height: 4),
                      // Name + Membership Badge ✅
                      Row(children: [
                        Expanded(
                          child: Text(auth.user?.name ?? 'Welcome!',
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: auth.isAdmin ? AppTheme.accentGold
                                : auth.isMember ? AppTheme.accentGold
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(auth.isMember ? Icons.workspace_premium : Icons.person_outline, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              auth.isAdmin ? 'ADMIN' : auth.isMember ? 'MEMBER' : 'FREE',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search modules...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary), onPressed: onSearchClear)
                        : null,
                    border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              _StatChip(label: '${ModuleData.modules.length} Modules', icon: Icons.apps),
              const SizedBox(width: 10),
              _StatChip(label: 'Active', icon: Icons.circle, iconColor: AppTheme.success),
              const Spacer(),
              Text('${filteredModules.length} showing', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),


        // ── Complete Profile Banner ───────────────────────────────────────────
        if (auth.user?.founderProfileComplete != true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppTheme.primary, blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Complete Your Profile', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Help AI give you personalized advice', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('Complete', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // ── Upgrade Banner (free users only) ─────────────────────────────────
        if (!auth.isMember && !auth.isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Color(0xFFF5A623).withOpacity(0.35),
                        blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Unlock All Features',
                            style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Upgrade to membership — access all 10 modules',
                            style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9), fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('Upgrade',
                          style: GoogleFonts.inter(
                              color: Color(0xFFF5A623), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('Business Modules', style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ]),
          ),
        ),

        // Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final module = filteredModules[index];
                final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
                return _ModuleCard(module: module, displayIndex: index + 1, isLocked: isLocked);
              },
              childCount: filteredModules.length,
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

// ─── MODULES TAB ──────────────────────────────────────────────────────────────
class _ModulesTab extends StatelessWidget {
  final List<AppModule> filteredModules;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

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
            Text('All Modules', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 20),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
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
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0,
            ),
            itemCount: filteredModules.length,
            itemBuilder: (context, index) {
              final module = filteredModules[index];
              final isLocked = !auth.isMember && !auth.isAdmin && module.id > 2;
              return _ModuleCard(module: module, displayIndex: index + 1, isLocked: isLocked);
            },
          ),
        ),
      ]),
    );
  }
}

// ─── ALERTS TAB ───────────────────────────────────────────────────────────────
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
          child: Text('Alerts', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none_rounded, size: 72, color: AppTheme.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No alerts yet', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Important updates will appear here', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text(
                    (auth.user?.name ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.montserrat(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(auth.user?.name ?? '', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(auth.user?.email ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: auth.isAdmin ? AppTheme.accentGold : auth.isMember ? AppTheme.accentGold : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(auth.isMember ? Icons.workspace_premium : Icons.person_outline, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    auth.isAdmin ? 'ADMIN ACCOUNT' : auth.isMember ? 'MEMBER' : 'FREE ACCOUNT',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Upgrade banner for free users ✅
          if (!auth.isMember && !auth.isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              _ProfileTile(icon: Icons.person_outline,   label: 'Full Name',    value: auth.user?.name ?? '-'),
              _ProfileTile(icon: Icons.email_outlined,   label: 'Email',        value: auth.user?.email ?? '-'),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Account Type',
                value: auth.isAdmin ? 'Administrator' : auth.isMember ? 'Member' : 'Free',
                valueColor: auth.isMember || auth.isAdmin ? AppTheme.accentGold : AppTheme.textSecondary,
              ),
              // Admin panel access tile ✅
              if (auth.isAdmin)
                _ProfileTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Panel',
                  value: 'Manage users & submissions',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminPlaceholder())),
                  showArrow: true,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Module Card ──────────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final AppModule module;
  final int displayIndex;
  final bool isLocked;
  const _ModuleCard({required this.module, required this.displayIndex, this.isLocked = false});
  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.95, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Widget _buildScreen(AppModule m) {
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
    final m = widget.module;
    final numStr = widget.displayIndex.toString().padLeft(2, '0');

    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          if (widget.isLocked) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => _buildScreen(m)));
          }
        },
        onTapCancel: () => _controller.forward(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: m.color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Icon with lock badge ✅
                Stack(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: FaIcon(m.icon, color: widget.isLocked ? Colors.grey.shade400 : m.color, size: 20)),
                  ),
                  if (widget.isLocked)
                    Positioned(right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                        child: const Icon(Icons.lock, color: Colors.white, size: 8),
                      )),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isLocked ? Colors.grey.shade100 : m.lightColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(numStr, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: widget.isLocked ? Colors.grey.shade400 : m.color)),
                ),
              ]),
              const Spacer(),
              Text(m.title,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: widget.isLocked ? AppTheme.textSecondary : AppTheme.textPrimary, height: 1.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(m.subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: widget.isLocked ? AppTheme.accentGold : m.color, borderRadius: BorderRadius.circular(8)),
                  child: Icon(widget.isLocked ? Icons.lock_outline : Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Tile ─────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showArrow;
  const _ProfileTile({required this.icon, required this.label, required this.value, this.valueColor, this.onTap, this.showArrow = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
          ])),
          if (showArrow) Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
        ]),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  const _StatChip({required this.label, required this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: iconColor ?? AppTheme.primaryLight),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? AppTheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 22),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}

class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A6B), elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin Panel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.admin_panel_settings_rounded, size: 64, color: Color(0xFFF5A623)),
          SizedBox(height: 16),
          Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          SizedBox(height: 8),
          Text('Full admin dashboard coming soon', style: TextStyle(color: Color(0xFF6B7C93), fontSize: 14)),
        ]),
      ),
    );
  }
}