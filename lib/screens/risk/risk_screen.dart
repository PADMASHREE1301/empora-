// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/risk/risk_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// import 'package:flutter/material.dart';
// import 'package:empora/screens/chat/module_chat_screen.dart';
// class RiskScreen extends StatelessWidget {
//   const RiskScreen({super.key});
//   @override
//   Widget build(BuildContext context) => const ModuleChatScreen(
//     module: 'riskManagement', title: 'Risk Advisor',
//     subtitle: 'Business Risk & Continuity',
//     icon: Icons.shield_rounded, accentColor: Color(0xFFFF4757),
//     welcomeMessage: 'I\'m your risk management consultant...',
//     suggestedQuestions: ['🔍 Assess my business risks', '📋 Business continuity plan'],
//   );
// }

// Each screen below should be its own file. Copy the relevant section.
// ─────────────────────────────────────────────────────────────────────────────

// FILE: lib/screens/risk/risk_screen.dart
import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class RiskScreen extends StatelessWidget {
  const RiskScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'riskManagement',
      title:    'Risk Advisor',
      subtitle: 'Business Risk & Continuity Planning',
      icon:     Icons.shield_rounded,
      accentColor: Color(0xFFFF4757),
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
    );
  }
}