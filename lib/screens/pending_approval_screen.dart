// lib/screens/pending_approval_screen.dart
//
// Shown to a user who has registered but has NOT yet been approved by admin.
// Also shown when a previously-registered user tries to log in before approval.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/auth_provider.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated hourglass icon ───────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 52,
                  color: AppTheme.accentGold,
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                'Awaiting Approval',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 14),

              // ── Subtitle ──────────────────────────────────────────────────
              Text(
                'Your account has been created successfully.\n\nAn admin will review and approve your request. You\'ll receive a notification as soon as you\'re approved — usually within 24 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 36),

              // ── Status card ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: AppTheme.accentGold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Pending Review',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentGold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Our admin team typically reviews new accounts within 24 hours.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Steps ─────────────────────────────────────────────────────
              _StepRow(
                step: '1',
                text: 'Account registered',
                done: true,
                color: AppTheme.success,
              ),
              const SizedBox(height: 10),
              _StepRow(
                step: '2',
                text: 'Admin reviews your request',
                done: false,
                color: AppTheme.accentGold,
              ),
              const SizedBox(height: 10),
              _StepRow(
                step: '3',
                text: 'You get notified & can log in',
                done: false,
                color: AppTheme.primary,
              ),

              const Spacer(flex: 3),

              // ── Back to login button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Questions? Contact support@empora.com',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step row widget ────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String step;
  final String text;
  final bool done;
  final Color color;

  const _StepRow({
    required this.step,
    required this.text,
    required this.done,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color.withValues(alpha: 0.15) : AppTheme.divider,
            border: Border.all(
              color: done ? color : AppTheme.divider,
              width: 1.5,
            ),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 16, color: color)
              : Center(
                  child: Text(
                    step,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: done ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: done ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}