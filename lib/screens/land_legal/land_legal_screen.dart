// lib/screens/land_legal/land_legal_screen.dart

import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class LandLegalScreen extends StatelessWidget {
  const LandLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'landLegal',
      title:    'Property Advisor',
      subtitle: 'Land, Legal & Property Guidance',
      icon:     Icons.home_work_rounded,
      accentColor: Color(0xFF6C8EFF),
      welcomeMessage:
          'I\'m your personal property and legal advisor. I can help you evaluate whether '
          'it\'s the right time to buy, rent, or sell property — based on your actual financial situation.\n\n'
          'Tell me what you\'re planning and I\'ll analyze your situation.',
      suggestedQuestions: [
        '🏢 Should I buy office space now?',
        '📋 How to verify a property\'s title',
        '📝 Review my lease agreement',
        '💼 RERA compliance check',
      ],
    );
  }
}