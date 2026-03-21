// lib/screens/pending_approval_screen.dart
// Shown to new users who have registered but not yet been approved by admin

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/theme/app_theme.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;
  Timer? _checkTimer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the waiting icon
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-check every 30 seconds if admin has approved
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkApproval());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApproval() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await context.read<AuthProvider>().fetchProfile();
      // If now approved, AuthProvider will update isApproved → RootRouter redirects
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'there';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── Animated waiting icon ──────────────────────────────────
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppTheme.accentGold,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Title ──────────────────────────────────────────────────
              Text(
                'Hi $name! 👋',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Your account is pending\nadmin approval',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
              ),

              const SizedBox(height: 20),

              // ── Info card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(children: [
                  _Step(
                    number: '1',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    title: 'Account Created',
                    subtitle: 'Your registration is complete',
                    done: true,
                  ),
                  const SizedBox(height: 14),
                  _Step(
                    number: '2',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppTheme.accentGold,
                    title: 'Admin Review',
                    subtitle: 'Our team is reviewing your account',
                    done: false,
                    active: true,
                  ),
                  const SizedBox(height: 14),
                  _Step(
                    number: '3',
                    icon: Icons.rocket_launch_rounded,
                    color: AppTheme.accent,
                    title: 'Access Granted',
                    subtitle: 'Start using all EMPORA modules',
                    done: false,
                  ),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Info text ──────────────────────────────────────────────
              Text(
                'You will be notified once your account is approved. This usually takes less than 24 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 13, height: 1.6),
              ),

              const Spacer(),

              // ── Check now button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _checkApproval,
                  icon: _checking
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _checking ? 'Checking...' : 'Check Approval Status',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Logout link ────────────────────────────────────────────
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step widget ──────────────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number, title, subtitle;
  final IconData icon;
  final Color color;
  final bool done, active;

  const _Step({
    required this.number, required this.icon, required this.color,
    required this.title, required this.subtitle,
    this.done = false, this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: done
              ? color.withValues(alpha: 0.15)
              : active
                  ? color.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: done || active ? color.withValues(alpha: 0.5) : Colors.white12,
            width: active ? 2 : 1,
          ),
        ),
        child: Icon(
          done ? Icons.check_rounded : icon,
          color: done || active ? color : Colors.white24,
          size: 20,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                color: done || active ? Colors.white : Colors.white38,
                fontSize: 13, fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: GoogleFonts.inter(
                color: done || active ? Colors.white54 : Colors.white24,
                fontSize: 11)),
      ])),
      if (active)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text('Pending',
              style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
        ),
    ]);
  }
}