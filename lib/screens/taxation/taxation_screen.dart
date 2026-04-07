// lib/screens/taxation/taxation_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class TaxationScreen extends StatefulWidget {
  const TaxationScreen({super.key});
  @override State<TaxationScreen> createState() => _TaxationScreenState();
}

class _TaxationScreenState extends State<TaxationScreen> {
  static const _accent = Color(0xFF27AE60);

  final _ctrl = TextEditingController();
  String _rate = '18%';
  double? _gst, _cgst, _sgst, _total;

  final _rates = {'5%': 0.05, '12%': 0.12, '18%': 0.18, '28%': 0.28};

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _calc() {
    final t = double.tryParse(_ctrl.text.replaceAll(',', '').replaceAll('₹', ''));
    if (t == null || t <= 0) return;
    final r = _rates[_rate]!;
    setState(() {
      _gst   = t * r;
      _cgst  = _gst! / 2;
      _sgst  = _gst! / 2;
      _total = t + _gst!;
    });
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'taxation', title: 'Tax Advisor',
      subtitle: 'Personal CA & Tax Planning',
      icon: Icons.receipt_long_rounded, accentColor: Color(0xFF27AE60),
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
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tax Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Personal CA & Tax Planning', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            onPressed: _openChat,
            tooltip: 'Open Chat',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── GST Calculator ───────────────────────────────────────────────
          ModuleCard(
            icon: Icons.calculate_outlined, color: _accent,
            title: 'GST Calculator',
            subtitle: 'Estimate your GST liability instantly',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select GST Rate', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _rates.keys.map((r) =>
                GestureDetector(onTap: () => setState(() { _rate = r; _gst = null; }),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _rate == r ? _accent : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _rate == r ? _accent : Colors.grey.shade300)),
                    child: Text(r, style: GoogleFonts.inter(
                      color: _rate == r ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700, fontSize: 13))))).toList()),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: _ctrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Monthly taxable turnover', prefixText: '₹ ',
                    isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent, width: 2))))),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _calc,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Calculate', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              ]),
              if (_gst != null) ...[
                const SizedBox(height: 16),
                Row(children: [
                  ModuleResultTile('GST Payable', _fmt(_gst!), _accent),
                  const SizedBox(width: 8),
                  ModuleResultTile('CGST', _fmt(_cgst!), Colors.blue),
                  const SizedBox(width: 8),
                  ModuleResultTile('SGST', _fmt(_sgst!), Colors.purple),
                ]),
                const SizedBox(height: 10),
                ModuleResultTile('Total Invoice Value', _fmt(_total!), Colors.green, wide: true),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withValues(alpha: 0.2))),
                  child: Column(children: [
                    ModuleDeadlineRow('GSTR-1 (Monthly)', '11th of next month'),
                    ModuleDeadlineRow('GSTR-3B', '20th of next month'),
                    ModuleDeadlineRow('GSTR-1 (Quarterly)', 'Last day of next month'),
                  ])),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // ── Filing Deadlines quick reference ─────────────────────────────
          ModuleCard(
            icon: Icons.calendar_month_outlined, color: Colors.orange,
            title: 'Annual Tax Calendar',
            subtitle: 'Key deadlines for startups & SMEs',
            child: Column(children: [
              ModuleDeadlineRow('ITR Filing (Audit cases)',  '31 Oct every year'),
              ModuleDeadlineRow('ITR Filing (Non-audit)',    '31 Jul every year'),
              ModuleDeadlineRow('Advance Tax Q1',            '15 Jun'),
              ModuleDeadlineRow('Advance Tax Q2',            '15 Sep'),
              ModuleDeadlineRow('Advance Tax Q3',            '15 Dec'),
              ModuleDeadlineRow('Advance Tax Q4',            '15 Mar'),
              ModuleDeadlineRow('TDS Return (Q4)',           '31 May'),
            ]),
          ),

          const SizedBox(height: 24),
          ModuleChatButton(label: 'Ask Tax Advisor', sub: 'GST · Income Tax · TDS · Startup Exemptions', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}