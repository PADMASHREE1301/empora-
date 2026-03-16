// lib/screens/cyber/cyber_screen.dart
import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class CyberScreen extends StatelessWidget {
  const CyberScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'cyberSecurity',
      title:    'Security Advisor',
      subtitle: 'Cybersecurity & Data Protection',
      icon:     Icons.security_rounded,
      accentColor: Color(0xFF7B61FF),
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
    );
  }
}