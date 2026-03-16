// lib/screens/project/project_screen.dart
import 'package:flutter/material.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ModuleChatScreen(
      module:   'projectManagement',
      title:    'Project Advisor',
      subtitle: 'Planning, Milestones & Delivery',
      icon:     Icons.task_alt_rounded,
      accentColor: Color(0xFF00D2FF),
      welcomeMessage:
          'I\'m your project management advisor. I\'ll help you plan projects, '
          'track milestones, manage resources, and keep deliveries on time.\n\n'
          'Tell me about your current projects and biggest challenges.',
      suggestedQuestions: [
        '📋 Set up my project roadmap',
        '🎯 Define OKRs for my team',
        '⚠️ My project is delayed — help!',
        '👥 How to manage remote team',
      ],
    );
  }
}