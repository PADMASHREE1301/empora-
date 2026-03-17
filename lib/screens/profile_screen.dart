// lib/screens/profile_screen.dart
//
// Drop-in replacement for the _ProfileTab() widget in home_screen.dart.
// Usage in home_screen.dart → replace  const _ProfileTab()  with  const ProfileScreen()
// and add:  import 'package:empora/screens/profile_screen.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/screens/login_screen.dart';
import 'package:empora/screens/admin/admin_dashboard_screen.dart';

// ─── Colour / style constants ─────────────────────────────────────────────────
const _kNavy     = Color(0xFF0F2A5E);
const _kNavyDark = Color(0xFF0A1E46);
const _kGold     = Color(0xFFF5A623);
const _kRed      = Color(0xFFE63B2E);
const _kGreen    = Color(0xFF27AE60);
const _kBg       = Color(0xFFF0F2F7);
const _kCard     = Colors.white;
const _kBorder   = Color(0xFFE5E7EB);
const _kSub      = Color(0xFF6B7280);
const _kInputBg  = Color(0xFFF8F9FC);

// ─── Main screen ──────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Editable profile field values (loaded from auth on first build)
  String _name     = '';
  String _email    = '';
  String _bizName  = '';
  String _industry = '';
  String _stage    = '';
  String _revenue  = '';
  String _location = '';
  String _phone    = '';

  bool _initialized = false;

  void _initFromAuth(AuthProvider auth) {
    if (_initialized) return;
    _initialized = true;
    // name & email exist directly on UserModel ✅
    _name  = auth.user?.name  ?? '';
    _email = auth.user?.email ?? '';
    // founderProfile sub-fields are NOT on UserModel —
    // load them async from GET /api/auth/founder-profile
    _loadFounderFields();
  }

  Future<void> _loadFounderFields() async {
    try {
      final res = await ApiService.getFounderProfile();
      // response may wrap data under 'data', 'founderProfile', or return flat
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
      // silently ignore — fields stay empty, user can fill them manually
    }
  }

  // ── Completion % ─────────────────────────────────────────────────────────
  double get _completionPct {
    int filled = 0;
    if (_bizName.isNotEmpty)  filled++;
    if (_industry.isNotEmpty) filled++;
    if (_stage.isNotEmpty)    filled++;
    if (_revenue.isNotEmpty)  filled++;
    if (_location.isNotEmpty) filled++;
    if (_phone.isNotEmpty)    filled++;
    return filled / 6;
  }

  // ── Open bottom-sheet editor ──────────────────────────────────────────────
  Future<void> _edit({
    required String title,
    required String current,
    List<String>? options,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    required ValueChanged<String> onSave,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        title: title,
        current: current,
        options: options,
        hint: hint,
        keyboard: keyboard,
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
      // persist changes
      _persist();
    }
  }

  Future<void> _persist() async {
    // Capture providers BEFORE any await to avoid BuildContext-across-async-gap lint
    final authProvider = context.read<AuthProvider>();
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
        'isComplete':    true,
      });
      await authProvider.fetchProfile();
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

  // ── Build ─────────────────────────────────────────────────────────────────
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
              _buildHero(auth),
              _buildCompletionCard(),
              _buildSection('Account', _buildAccountGroup(auth)),
              _buildSection(
                'Complete Your Profile',
                _buildProfileGroup(),
                subtitle: '● required to unlock AI advice',
                subtitleColor: _kRed,
              ),
              if (auth.isAdmin)
                _buildSection('Admin', _buildAdminGroup(context, auth)),
              _buildLogoutButton(context, auth),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero(AuthProvider auth) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavyDark, _kNavy],
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
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
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _kNavyDark.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.montserrat(
                            fontSize: 36, fontWeight: FontWeight.w800,
                            color: _kNavy,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: () => _edit(
                          title: 'Edit Full Name',
                          current: _name,
                          hint: 'Enter your full name',
                          onSave: (v) => setState(() => _name = v),
                        ),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: _kGold,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _name,
                  style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _AdminBadge(auth: auth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Completion ring card ──────────────────────────────────────────────────
  Widget _buildCompletionCard() {
    final pct = _completionPct;
    final pctLabel = '${(pct * 100).round()}%';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: _kBorder,
                    color: _kGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection(
    String title,
    Widget content, {
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  // ── Account group (name, email, type) ─────────────────────────────────────
  Widget _buildAccountGroup(AuthProvider auth) {
    return Column(
      children: [
        _FieldRow(
          icon: Icons.person_outline,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F6EF7),
          label: 'Full Name',
          value: _name,
          onEdit: () => _edit(
            title: 'Edit Full Name',
            current: _name,
            hint: 'Enter full name',
            onSave: (v) => setState(() => _name = v),
          ),
        ),
        const _Divider(),
        _FieldRow(
          icon: Icons.email_outlined,
          iconBg: const Color(0xFFFEF3E2),
          iconColor: _kGold,
          label: 'Email',
          value: _email,
          onEdit: () => _edit(
            title: 'Edit Email',
            current: _email,
            hint: 'Enter email address',
            keyboard: TextInputType.emailAddress,
            onSave: (v) => setState(() => _email = v),
          ),
        ),
        const _Divider(),
        _FieldRow(
          icon: Icons.badge_outlined,
          iconBg: const Color(0xFFFEF3E2),
          iconColor: _kGold,
          label: 'Account Type',
          value: auth.isAdmin ? 'Administrator' : auth.isMember ? 'Member' : 'Free',
          valueColor: (auth.isAdmin || auth.isMember) ? _kGold : _kSub,
          showEdit: false,
        ),
      ],
    );
  }

  // ── "Complete your profile" fields ────────────────────────────────────────
  Widget _buildProfileGroup() {
    return Column(
      children: [
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
        const _Divider(),
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
              'Technology', 'Finance', 'Real Estate', 'Healthcare',
              'Retail', 'Manufacturing', 'Education', 'Logistics', 'Other',
            ],
            onSave: (v) => setState(() => _industry = v),
          ),
        ),
        const _Divider(),
        _FieldRow(
          icon: Icons.group_outlined,
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
        const _Divider(),
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
        const _Divider(),
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
        const _Divider(),
        _FieldRow(
          icon: Icons.phone_outlined,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F6EF7),
          label: 'Phone Number',
          value: _phone,
          keyboard: TextInputType.phone,
          onEdit: () => _edit(
            title: 'Phone Number',
            current: _phone,
            hint: '+91 98765 43210',
            keyboard: TextInputType.phone,
            onSave: (v) => setState(() => _phone = v),
          ),
        ),
      ],
    );
  }

  // ── Admin group ───────────────────────────────────────────────────────────
  Widget _buildAdminGroup(BuildContext context, AuthProvider auth) {
    return _FieldRow(
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
    );
  }

  // ── Logout button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            auth.logout();
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ─── Field Row ─────────────────────────────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool required;
  final bool showEdit;
  final bool showArrow;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final TextInputType keyboard;

  const _FieldRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.required = false,
    this.showEdit = true,
    this.showArrow = false,
    this.onEdit,
    this.onTap,
    this.keyboard = TextInputType.text,
  });

  bool get _isEmpty => value.isEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? (showEdit ? onEdit : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 2),
                  Text(
                    _isEmpty ? 'Tap to add' : value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _isEmpty ? FontWeight.w400 : FontWeight.w600,
                      color: _isEmpty
                          ? const Color(0xFFB0B8C8)
                          : (valueColor ?? const Color(0xFF1A1F36)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Edit / arrow button
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
            if (showArrow)
              const Icon(Icons.chevron_right, color: _kSub, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: _kBorder);
}

// ─── Admin badge ──────────────────────────────────────────────────────────────
class _AdminBadge extends StatelessWidget {
  final AuthProvider auth;
  const _AdminBadge({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isAdmin  = auth.isAdmin;
    final isMember = auth.isMember;
    final label = isAdmin ? 'ADMIN ACCOUNT' : isMember ? 'MEMBER' : 'FREE ACCOUNT';
    final icon  = (isAdmin || isMember) ? Icons.workspace_premium : Icons.person_outline;
    final color = (isAdmin || isMember) ? _kGold : Colors.white.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Bottom Sheet ────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final String title;
  final String current;
  final List<String>? options;
  final String? hint;
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
    _selected = widget.options?.contains(widget.current) == true ? widget.current : null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final val = widget.options != null ? (_selected ?? '') : _ctrl.text.trim();
    if (val.isNotEmpty) Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    final isSelect = widget.options != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _kBorder, borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1F36),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _kSub, letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown options
                  if (isSelect)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
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
                                horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? _kNavy.withValues(alpha: 0.06)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                    )
                  else
                    TextField(
                      controller: _ctrl,
                      keyboardType: widget.keyboard,
                      autofocus: true,
                      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1F36)),
                      decoration: InputDecoration(
                        hintText: widget.hint ?? 'Enter value...',
                        hintStyle: GoogleFonts.inter(color: _kSub),
                        filled: true,
                        fillColor: _kInputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kNavy, width: 1.5),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
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