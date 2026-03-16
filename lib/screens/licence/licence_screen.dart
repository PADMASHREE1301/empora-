// lib/screens/licence/licence_screen.dart
import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class LicenceScreen extends StatelessWidget {
  const LicenceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'licence',
      title:    'Compliance Advisor',
      subtitle: 'Licences, Registrations & Compliance',
      icon:     Icons.verified_rounded,
      accentColor: Color(0xFFFF6B9D),
      welcomeMessage:
          'I\'m your compliance advisor. I\'ll help you get the right licences, '
          'stay compliant, and never miss a renewal deadline.\n\n'
          'Tell me about your business type and I\'ll guide you through everything you need.',
      suggestedQuestions: [
        '📋 What licences does my business need?',
        '🏢 How to register a Pvt Ltd company',
        '📅 My compliance calendar',
        '⚡ MSME/Udyam registration',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/risk/risk_screen.dart
// (Create as a separate file in lib/screens/risk/risk_screen.dart)

// import 'package:flutter/material.dart';
// import 'package:empora/screens/chat/module_chat_screen.dart';
// 
// class RiskScreen extends StatelessWidget {
//   const RiskScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const ModuleChatScreen(
//       module:   'riskManagement',
//       title:    'Risk Advisor',
//       subtitle: 'Business Risk & Continuity',
//       icon:     Icons.shield_rounded,
//       accentColor: Color(0xFFFF4757),
//       welcomeMessage:
//           'I\'m your risk management consultant. I\'ll help you identify, '
//           'prioritize, and mitigate the key risks in your business.\n\n'
//           'Let\'s start with a quick risk assessment of your business.',
//       suggestedQuestions: [
//         '🔍 Assess my business risks',
//         '📋 Business continuity plan',
//         '🛡️ What insurance do I need?',
//         '💰 Cash flow risk analysis',
//       ],
//     );
//   }
// }