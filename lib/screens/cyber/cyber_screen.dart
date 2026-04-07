// lib/screens/cyber/cyber_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class CyberScreen extends StatefulWidget {
  const CyberScreen({super.key});
  @override State<CyberScreen> createState() => _CyberScreenState();
}

class _CyberScreenState extends State<CyberScreen> {
  static const _accent = Color(0xFF2C3E50);

  final Map<String, List<Map<String, dynamic>>> _audit = {
    'Passwords & Access': [
      {'t': 'Strong passwords (12+ chars) on all accounts', 'v': false},
      {'t': '2FA enabled on Google, email, bank accounts',  'v': false},
      {'t': 'No shared passwords across team members',      'v': false},
    ],
    'Data Protection': [
      {'t': 'Regular data backups (minimum weekly)',         'v': false},
      {'t': 'Customer data stored securely / encrypted',    'v': false},
      {'t': 'Privacy policy published on website',          'v': false},
    ],
    'Device Security': [
      {'t': 'Antivirus installed on all work devices',      'v': false},
      {'t': 'OS and apps updated regularly',                'v': false},
      {'t': 'VPN used when working on public Wi-Fi',        'v': false},
    ],
    'Network & Access': [
      {'t': 'Wi-Fi password changed in last 90 days',       'v': false},
      {'t': 'Separate guest network for visitors',          'v': false},
      {'t': 'Ex-employees\' access revoked immediately',    'v': false},
    ],
  };

  int get _total   => _audit.values.fold(0, (s, l) => s + l.length);
  int get _checked => _audit.values.fold(0, (s, l) => s + l.where((c) => c['v'] as bool).length);
  double get _pct  => _total > 0 ? _checked / _total : 0;
  
  String get _scoreLabel => _pct >= 0.8 ? 'Strong 🔒' : _pct >= 0.5 ? 'Moderate ⚠️' : 'Weak 🚨';

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'cyberSecurity', title: 'Security Advisor',
      subtitle: 'Cybersecurity & Data Protection',
      icon: Icons.security_rounded, accentColor: Color(0xFF2C3E50),
      welcomeMessage:
          'I\'m your cybersecurity advisor. I\'ll help you protect your business data, '
          'set up security policies, and stay compliant with India\'s data protection laws.\n\n'
          'Let\'s start with a quick security health check — I\'ll ask you a few questions.',
      suggestedQuestions: [
        '🔒 Check my security posture',
        '📱 Secure my team\'s devices',
        '🛡️ DPDP Act compliance',
        '🚨 We had a data breach!',
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
          Text('Security Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Cybersecurity & Data Protection', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Security Score Banner ─────────────────────────────────────────
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.9), _accent],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(child: Text('${(_pct * 100).round()}%',
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Security Score', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(_scoreLabel, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _pct, color: Colors.white,
                    backgroundColor: Colors.white24, minHeight: 6)),
                const SizedBox(height: 2),
                Text('$_checked of $_total checks passed',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ])),
            ])),

          const SizedBox(height: 16),

          // ── Audit Checklist ───────────────────────────────────────────────
          ..._audit.entries.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModuleCard(
              icon: _catIcon(cat.key), color: _accent,
              title: cat.key, subtitle: '${cat.value.where((c) => c['v'] as bool).length}/${cat.value.length} completed',
              child: Column(children: cat.value.asMap().entries.map((e) =>
                CheckboxListTile(
                  value: e.value['v'] as bool, activeColor: _accent,
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: Text(e.value['t'], style: GoogleFonts.inter(fontSize: 13,
                    decoration: e.value['v'] as bool ? TextDecoration.lineThrough : null,
                    color: e.value['v'] as bool ? Colors.grey : Colors.black87)),
                  onChanged: (v) => setState(() => cat.value[e.key]['v'] = v!),
                )).toList()),
            ))),

          const SizedBox(height: 8),
          ModuleChatButton(label: 'Ask Security Advisor', sub: 'DPDP Act · Data breach · Device security · Policies', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  IconData _catIcon(String k) {
    if (k.contains('Password')) return Icons.lock_outline;
    if (k.contains('Data'))     return Icons.storage_outlined;
    if (k.contains('Device'))   return Icons.devices_outlined;
    return Icons.wifi_outlined;
  }
}