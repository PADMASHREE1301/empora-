// lib/screens/taxation/taxation_screen.dart

import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class TaxationScreen extends StatelessWidget {
  const TaxationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'taxation',
      title:    'Tax Advisor',
      subtitle: 'Personal CA & Tax Planning',
      icon:     Icons.receipt_long_rounded,
      accentColor: Color(0xFF00C896),
      welcomeMessage:
          'I\'m your personal CA and tax advisor. I can help you with income tax planning, '
          'GST compliance, TDS, startup exemptions, and tax-saving strategies.\n\n'
          'Tell me about your business and I\'ll guide you through your tax obligations step by step.',
      suggestedQuestions: [
        '📊 How much tax will I pay this year?',
        '🏢 GST registration for my startup',
        '💰 Tax-saving options for my business',
        '📅 What are my upcoming tax deadlines?',
      ],
    );
  }
}