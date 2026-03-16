// lib/screens/loans/loans_screen.dart

import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'loans',
      title:    'Loan Advisor',
      subtitle: 'Business Finance & Debt Management',
      icon:     Icons.account_balance_rounded,
      accentColor: Color(0xFFFFB347),
      welcomeMessage:
          'I\'m your personal banking and finance advisor. I\'ll help you understand your '
          'existing loan portfolio, analyze if you can take on more debt, and find the best '
          'loan products for your business needs.\n\n'
          'Start by telling me about your current loans and business financials.',
      suggestedQuestions: [
        '💳 Can I take another loan right now?',
        '🏦 Best business loan options in India',
        '📊 My current loan EMI analysis',
        '🏛️ Government schemes for startups',
      ],
    );
  }
}