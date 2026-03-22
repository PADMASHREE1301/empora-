// lib/screens/land_legal/land_legal_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class LandLegalScreen extends StatefulWidget {
  const LandLegalScreen({super.key});
  @override State<LandLegalScreen> createState() => _LandLegalScreenState();
}

class _LandLegalScreenState extends State<LandLegalScreen> {
  static const _accent = Color(0xFF8E44AD);

  String _type = 'Office Lease';
  late List<bool> _checked;

  final Map<String, List<String>> _db = {
    'Office Lease': [
      'Lock-in period clearly stated',
      'Rent escalation clause capped (10-15%)',
      'Security deposit terms defined',
      'Maintenance responsibility split',
      'Exit / termination notice period',
      'Sub-letting restrictions mentioned',
      'Fit-out period & rent-free period',
      'Force majeure clause included',
    ],
    'Vendor Agreement': [
      'Scope of work clearly defined',
      'Payment milestones specified',
      'IP ownership clause included',
      'Confidentiality / NDA clause',
      'Liability cap & indemnity terms',
      'Termination & notice period',
      'Dispute resolution mechanism',
      'Penalty for delay clause',
    ],
    'Employment Contract': [
      'Designation & reporting structure',
      'CTC breakdown & all benefits',
      'Notice period (both sides)',
      'Non-compete & non-solicitation',
      'IP assignment to company',
      'Probation period terms',
      'Leave policy referenced',
      'Moonlighting restriction',
    ],
    'Co-founder Agreement': [
      'Equity split & vesting schedule',
      'Cliff period (minimum 1 year)',
      'Decision-making authority',
      'IP assigned to company',
      'Exit & buyback provision',
      'Roles & responsibilities',
      'Salary & compensation',
      'Dispute resolution process',
    ],
  };

  @override void initState() { super.initState(); _reset(); }
  void _reset() => _checked = List.filled(_db[_type]!.length, false);
  int get _done  => _checked.where((c) => c).length;
  int get _total => _db[_type]!.length;

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'landLegal', title: 'Property Advisor',
      subtitle: 'Land, Legal & Property Guidance',
      icon: Icons.home_work_rounded, accentColor: Color(0xFF8E44AD),
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
    )));

  @override
  Widget build(BuildContext context) {
    final clauses = _db[_type]!;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Color(0xFF8E44AD), foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Property Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Land, Legal & Property Guidance', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          ModuleCard(
            icon: Icons.checklist_rounded, color: _accent,
            title: 'Contract Clause Checker',
            subtitle: 'Verify must-have clauses before signing',
            child: Column(children: [
              // Progress
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _total > 0 ? _done / _total : 0,
                    color: _accent, backgroundColor: Colors.grey.shade200, minHeight: 7))),
                const SizedBox(width: 10),
                Text('$_done/$_total', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: _accent, fontSize: 14)),
              ]),
              const SizedBox(height: 12),
              // Type selector
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: 'Contract type', isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent, width: 2))),
                items: _db.keys.map((k) => DropdownMenuItem(value: k, child: Text(k, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() { _type = v!; _reset(); }),
              ),
              const SizedBox(height: 12),
              ...clauses.asMap().entries.map((e) => CheckboxListTile(
                value: _checked[e.key], activeColor: _accent,
                dense: true, contentPadding: EdgeInsets.zero,
                title: Text(e.value, style: GoogleFonts.inter(fontSize: 13,
                  decoration: _checked[e.key] ? TextDecoration.lineThrough : null,
                  color: _checked[e.key] ? Colors.grey : Colors.black87)),
                onChanged: (v) => setState(() => _checked[e.key] = v!),
              )),
              if (_done == _total && _total > 0) ...[
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('All clauses verified! Safe to proceed.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600))),
                  ])),
              ],
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Property Advisor', sub: 'Contracts · RERA · Title Verification · Leases', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  } 
}