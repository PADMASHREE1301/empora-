// lib/screens/risk/risk_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});
  @override State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  static const _accent = Color(0xFFE74C3C);

  final List<Map<String, dynamic>> _risks = [
    {'name': 'Financial Risk',     'icon': Icons.account_balance_wallet_outlined, 'v': 1.0, 'tip': 'Check cash runway, burn rate and debt ratio'},
    {'name': 'Market Risk',        'icon': Icons.trending_down_rounded,           'v': 1.0, 'tip': 'Monitor competitor moves and demand shifts'},
    {'name': 'Operational Risk',   'icon': Icons.settings_outlined,               'v': 1.0, 'tip': 'Document key processes, avoid single points of failure'},
    {'name': 'Legal / Compliance', 'icon': Icons.gavel_outlined,                  'v': 1.0, 'tip': 'Stay updated on regulations, file returns on time'},
    {'name': 'Cyber Security',     'icon': Icons.security_outlined,               'v': 1.0, 'tip': 'Protect data, enable 2FA, have a breach response plan'},
    {'name': 'Team / HR Risk',     'icon': Icons.people_outline,                  'v': 1.0, 'tip': 'Avoid key-person dependency, document all roles'},
  ];

  Color _col(double v)   => v >= 4 ? Colors.red : v >= 3 ? Colors.orange : Colors.green;
  String _lbl(double v)  => v >= 4 ? 'HIGH'     : v >= 3 ? 'MEDIUM'     : 'LOW';
  int get _highCount     => _risks.where((r) => (r['v'] as double) >= 4).length;

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'riskManagement', title: 'Risk Advisor',
      subtitle: 'Business Risk & Continuity Planning',
      icon: Icons.shield_rounded, accentColor: Color(0xFFE74C3C),
      welcomeMessage:
          'I\'m your business risk consultant. I\'ll help you identify hidden risks, '
          'prioritize them, and build a solid mitigation strategy.\n\n'
          'Let\'s start with a quick risk health check of your business.',
      suggestedQuestions: [
        '🔍 Assess my business risks now',
        '📋 Build a continuity plan',
        '🛡️ What insurance do I need?',
        '💰 Analyze my cash flow risk',
      ],
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Risk Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Business Risk & Continuity Planning', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // Summary banner
          if (_highCount > 0) Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('$_highCount high-risk area${_highCount > 1 ? 's' : ''} need immediate attention',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade800))),
            ])),

          ModuleCard(
            icon: Icons.radar_outlined, color: _accent,
            title: 'Risk Radar Assessment',
            subtitle: 'Rate each area to see your risk exposure',
            child: Column(children: [
              ..._risks.asMap().entries.map((e) {
                final risk = e.value;
                final v    = risk['v'] as double;
                return Padding(padding: const EdgeInsets.only(bottom: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(risk['icon'] as IconData, size: 16, color: _col(v)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(risk['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _col(v).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(_lbl(v), style: GoogleFonts.inter(color: _col(v), fontSize: 10, fontWeight: FontWeight.w800))),
                    ]),
                    SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
                      child: Slider(value: v, min: 1, max: 5, divisions: 4, activeColor: _col(v),
                        inactiveColor: Colors.grey.shade200,
                        onChanged: (nv) => setState(() => _risks[e.key]['v'] = nv))),
                    if (v >= 3) Padding(padding: const EdgeInsets.only(left: 4),
                      child: Text('💡 ${risk['tip']}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]))),
                  ]));
              }),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _RiskLegend('🟢 Low',    '1-2', Colors.green),
                _RiskLegend('🟠 Medium', '3',   Colors.orange),
                _RiskLegend('🔴 High',   '4-5', Colors.red),
              ]),
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Risk Advisor', sub: 'Risk Mitigation · Insurance · Continuity Plan', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  final String label, range; final Color color;
  const _RiskLegend(this.label, this.range, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    Text('Score: $range', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
  ]);
}