// lib/screens/licence/licence_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class LicenceScreen extends StatefulWidget {
  const LicenceScreen({super.key});
  @override State<LicenceScreen> createState() => _LicenceScreenState();
}

class _LicenceScreenState extends State<LicenceScreen> {
  static const _accent = Color(0xFFFF6B9D);

  String? _industry; String? _size;
  List<Map<String, String>>? _results;

  final _industries = ['Food & Beverage', 'Retail / Trading', 'IT / Software',
    'Healthcare', 'Manufacturing', 'Education', 'Construction', 'Export / Import'];
  final _sizes = ['Sole Proprietor', 'Partnership / LLP', 'Private Limited', 'OPC'];

  final _db = <String, List<Map<String, String>>>{
    'Food & Beverage': [
      {'n': 'FSSAI Licence',         't': 'Central / State', 'd': '30-60 days'},
      {'n': 'Shop & Establishment',  't': 'State Govt',      'd': '7-15 days'},
      {'n': 'Trade Licence',         't': 'Municipal Corp',  'd': '7-21 days'},
      {'n': 'GST Registration',      't': 'Central Govt',    'd': '3-7 days'},
      {'n': 'Fire Safety NOC',       't': 'Fire Dept',       'd': '15-30 days'},
    ],
    'IT / Software': [
      {'n': 'Shop & Establishment',  't': 'State Govt',   'd': '7-15 days'},
      {'n': 'GST Registration',      't': 'Central Govt', 'd': '3-7 days'},
      {'n': 'MSME / Udyam',          't': 'Central Govt', 'd': '1-2 days'},
      {'n': 'Professional Tax',      't': 'State Govt',   'd': '7-14 days'},
    ],
    'Healthcare': [
      {'n': 'Clinical Establishment', 't': 'State Govt',     'd': '30-60 days'},
      {'n': 'Pharmacy Licence',       't': 'State Drugs Ctrl','d': '45-90 days'},
      {'n': 'GST Registration',       't': 'Central Govt',   'd': '3-7 days'},
      {'n': 'MSME / Udyam',           't': 'Central Govt',   'd': '1-2 days'},
    ],
    'Export / Import': [
      {'n': 'IEC (Import Export Code)', 't': 'DGFT',          'd': '2-3 days'},
      {'n': 'GST Registration',         't': 'Central Govt',  'd': '3-7 days'},
      {'n': 'RCMC Certificate',         't': 'Export Council','d': '15-30 days'},
      {'n': 'AD Code Registration',     't': 'Bank/Customs',  'd': '3-5 days'},
    ],
    'Manufacturing': [
      {'n': 'Factory Licence',       't': 'State Labour',  'd': '30-60 days'},
      {'n': 'Pollution NOC',         't': 'SPCB',          'd': '60-90 days'},
      {'n': 'GST Registration',      't': 'Central Govt',  'd': '3-7 days'},
      {'n': 'MSME / Udyam',          't': 'Central Govt',  'd': '1-2 days'},
      {'n': 'Fire Safety NOC',       't': 'Fire Dept',     'd': '15-30 days'},
    ],
  };

  void _find() {
    final key = _db.containsKey(_industry) ? _industry! : 'IT / Software';
    setState(() => _results = _db[key]);
  }

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'licence', title: 'Compliance Advisor',
      subtitle: 'Licences, Registrations & Compliance',
      icon: Icons.verified_rounded, accentColor: Color(0xFFFF6B9D),
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
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Compliance Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Licences, Registrations & Compliance', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          ModuleCard(
            icon: Icons.search_outlined, color: _accent,
            title: 'Licence Finder',
            subtitle: 'Find all licences your business needs',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _industry, hint: Text('Select industry', style: GoogleFonts.inter(fontSize: 13)),
                  isDense: true,
                  decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent, width: 2))),
                  items: _industries.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() { _industry = v; _results = null; }),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _size, hint: Text('Business structure', style: GoogleFonts.inter(fontSize: 13)),
                  isDense: true,
                  decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent, width: 2))),
                  items: _sizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() { _size = v; _results = null; }),
                )),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _industry != null && _size != null ? _find : null,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Find', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              ]),
              if (_results != null) ...[
                const SizedBox(height: 14),
                Text('${_results!.length} licences required for $_industry:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
                const SizedBox(height: 8),
                ..._results!.map((l) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withValues(alpha: 0.2))),
                  child: Row(children: [
                    Icon(Icons.verified_outlined, color: _accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l['n']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${l['t']} • ${l['d']}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                    ])),
                  ])),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Compliance Advisor', sub: 'Licences · GST · Company Registration · Renewal', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}