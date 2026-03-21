import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/models/module_model.dart';
import 'package:empora/screens/chat/chat_advisor_screen.dart';

class ModuleScreen extends StatelessWidget {
  final AppModule module;
  const ModuleScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // App bar with module color
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: module.color,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      module.color.withOpacity(0.9),
                      module.color,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: FaIcon(module.icon, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              module.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              module.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats
                  Row(
                    children: [
                      _QuickStat(label: 'Active', value: '12', color: AppTheme.success),
                      const SizedBox(width: 12),
                      _QuickStat(label: 'Pending', value: '4', color: AppTheme.accentGold),
                      const SizedBox(width: 12),
                      _QuickStat(label: 'Total', value: '38', color: module.color),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  _SectionHeader('Overview'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(
                      'The ${module.title} module provides comprehensive tools and analytics to help you manage and streamline your business operations. Use the features below to get started.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SectionHeader('Quick Actions'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.add_circle_outline,
                    title: 'Create New',
                    subtitle: 'Add a new ${module.title.toLowerCase()} record',
                    color: module.color,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.list_alt_outlined,
                    title: 'View All Records',
                    subtitle: 'Browse all ${module.title.toLowerCase()} data',
                    color: module.color,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Analytics',
                    subtitle: 'View reports and insights',
                    color: module.color,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Configure ${module.title.toLowerCase()} preferences',
                    color: module.color,
                  ),

                  const SizedBox(height: 32),

                  // ── AI Chat CTA ─────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      final config = _advisorConfigFor(module);
                      if (config != null) {
                        Navigator.push(context,
                          MaterialPageRoute(
                            builder: (_) => ChatAdvisorScreen(config: config)));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [module.color, module.color.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(
                          color: module.color.withValues(alpha: 0.35),
                          blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.chat_outlined, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ask AI Advisor',
                              style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w700)),
                            Text('Get instant AI-powered advice for ${module.title}',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12)),
                          ],
                        )),
                        const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 16),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ],
      ),
    );
  }
}
// ─── Map module ID to AdvisorConfig ──────────────────────────────────────────
AdvisorConfig? _advisorConfigFor(AppModule module) {
  switch (module.id) {
    case 3:  return AdvisorConfigs.taxation;
    case 4:  return AdvisorConfigs.landLegal;
    case 5:  return AdvisorConfigs.licence;
    case 6:  return AdvisorConfigs.loans;
    case 7:  return AdvisorConfigs.risk;
    case 8:  return AdvisorConfigs.project;
    case 9:  return AdvisorConfigs.cyber;
    case 10: return AdvisorConfigs.restructure;
    default: return null;
  }
}