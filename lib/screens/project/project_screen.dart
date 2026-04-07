// lib/screens/project/project_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});
  @override State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  static const _accent = Color(0xFF16A085);

  final _taskCtrl  = TextEditingController();
  final _ownerCtrl = TextEditingController();
  String _priority = 'Medium';
  final List<Map<String, dynamic>> _tasks = [];

  @override void dispose() { _taskCtrl.dispose(); _ownerCtrl.dispose(); super.dispose(); }

  Color _pColor(String p) => p == 'High' ? Colors.red : p == 'Medium' ? Colors.orange : Colors.green;
  int get _done  => _tasks.where((t) => t['done'] as bool).length;

  void _add() {
    if (_taskCtrl.text.trim().isEmpty) return;
    setState(() {
      _tasks.add({
        'task':     _taskCtrl.text.trim(),
        'owner':    _ownerCtrl.text.trim().isEmpty ? 'Me' : _ownerCtrl.text.trim(),
        'priority': _priority,
        'done':     false,
      });
      _taskCtrl.clear(); _ownerCtrl.clear();
    });
  }

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'projectManagement', title: 'Project Advisor',
      subtitle: 'Planning, Milestones & Delivery',
      icon: Icons.task_alt_rounded, accentColor: Color(0xFF16A085),
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
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Project Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Planning, Milestones & Delivery', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          ModuleCard(
            icon: Icons.task_alt_outlined, color: _accent,
            title: 'Project Task Tracker',
            subtitle: 'Track tasks, owners and priorities',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Progress bar
              if (_tasks.isNotEmpty) ...[
                Row(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: _done / _tasks.length,
                      color: _accent, backgroundColor: Colors.grey.shade200, minHeight: 8))),
                  const SizedBox(width: 10),
                  Text('$_done/${_tasks.length} done',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _accent, fontSize: 13)),
                ]),
                const SizedBox(height: 14),
              ],

              // Add task form
              TextField(controller: _taskCtrl,
                decoration: InputDecoration(labelText: 'Task name', isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent, width: 2)))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _ownerCtrl,
                  decoration: InputDecoration(labelText: 'Owner', isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButton<String>(value: _priority, underline: const SizedBox(),
                    items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p,
                      child: Text(p, style: TextStyle(color: _pColor(p), fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _priority = v!))),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add Task', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),

              // Task list
              if (_tasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                ..._tasks.asMap().entries.map((e) {
                  final t = e.value;
                  return ListTile(contentPadding: EdgeInsets.zero, dense: true,
                    leading: Checkbox(value: t['done'] as bool, activeColor: _accent,
                      onChanged: (v) => setState(() => _tasks[e.key]['done'] = v!)),
                    title: Text(t['task'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                      decoration: t['done'] as bool ? TextDecoration.lineThrough : null,
                      color: t['done'] as bool ? Colors.grey : Colors.black87)),
                    subtitle: Text(t['owner'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                    trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _pColor(t['priority']).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(t['priority'],
                        style: GoogleFonts.inter(fontSize: 10, color: _pColor(t['priority']), fontWeight: FontWeight.w700))));
                }),
              ],
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Project Advisor', sub: 'Roadmaps · OKRs · Team Management · Delivery', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}