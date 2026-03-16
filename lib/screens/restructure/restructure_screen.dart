// lib/screens/restructure/restructure_screen.dart
import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class RestructureScreen extends StatelessWidget {
  const RestructureScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'restructure',
      title:    'Restructure Advisor',
      subtitle: 'Business Transformation & Turnaround',
      icon:     Icons.autorenew_rounded,
      accentColor: Color(0xFFFFD700),
      welcomeMessage:
          'I\'m your business restructuring advisor. Whether you\'re pivoting, '
          'optimizing costs, or planning a turnaround — I\'ll guide you through it.\n\n'
          'Tell me what\'s driving the need to restructure and we\'ll build a plan together.',
      suggestedQuestions: [
        '🔄 How to pivot my business model',
        '💰 Cut costs without hurting growth',
        '👥 Right-size my team',
        '🚪 Exit strategy options',
      ],
    );
  }
}