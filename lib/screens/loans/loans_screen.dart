// lib/screens/loans/loans_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});
  @override State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  static const _accent = Color(0xFFFFB347);

  final _amtCtrl    = TextEditingController();
  final _rateCtrl   = TextEditingController();
  final _tenureCtrl = TextEditingController();
  double? _emi, _totalAmt, _totalInterest;

  @override void dispose() { _amtCtrl.dispose(); _rateCtrl.dispose(); _tenureCtrl.dispose(); super.dispose(); }

  void _calc() {
    final p = double.tryParse(_amtCtrl.text.replaceAll(',', '').replaceAll('₹', ''));
    final r = double.tryParse(_rateCtrl.text);
    final n = double.tryParse(_tenureCtrl.text);
    if (p == null || r == null || n == null || p <= 0 || r <= 0 || n <= 0) return;
    final monthly = r / 12 / 100;
    final factor  = monthly * _pow(1 + monthly, n) / (_pow(1 + monthly, n) - 1);
    setState(() {
      _emi           = p * factor;
      _totalAmt      = _emi! * n;
      _totalInterest = _totalAmt! - p;
    });
  }

  double _pow(double base, double exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'loans', title: 'Loan Advisor',
      subtitle: 'Business Finance & Debt Management',
      icon: Icons.account_balance_rounded, accentColor: Color(0xFFFFB347),
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
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Loan Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Business Finance & Debt Management', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          ModuleCard(
            icon: Icons.calculate_outlined, color: _accent,
            title: 'EMI Calculator',
            subtitle: 'Know your monthly repayment before borrowing',
            child: Column(children: [
              _Field(ctrl: _amtCtrl,    label: 'Loan Amount',          prefix: '₹'),
              const SizedBox(height: 10),
              _Field(ctrl: _rateCtrl,   label: 'Annual Interest Rate', suffix: '% p.a.'),
              const SizedBox(height: 10),
              _Field(ctrl: _tenureCtrl, label: 'Tenure',               suffix: 'months'),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: ElevatedButton(onPressed: _calc,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Calculate EMI', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)))),
              if (_emi != null) ...[
                const SizedBox(height: 16),
                Row(children: [
                  ModuleResultTile('Monthly EMI',     _fmt(_emi!),          _accent),
                  const SizedBox(width: 8),
                  ModuleResultTile('Total Interest',  _fmt(_totalInterest!), Colors.red),
                  const SizedBox(width: 8),
                  ModuleResultTile('Total Payable',   _fmt(_totalAmt!),     Colors.deepPurple),
                ]),
              ],
            ]),
          ),

          const SizedBox(height: 16),

          ModuleCard(
            icon: Icons.account_balance_outlined, color: Colors.blue,
            title: 'Govt Loan Schemes',
            subtitle: 'Popular schemes for startups & SMEs',
            child: Column(children: [
              _SchemeRow('MUDRA Shishu',   'Up to ₹50K',   '10-12%',  'Micro businesses'),
              _SchemeRow('MUDRA Kishore',  'Up to ₹5L',    '11-13%',  'Small businesses'),
              _SchemeRow('MUDRA Tarun',    'Up to ₹10L',   '11-14%',  'Growing SMEs'),
              _SchemeRow('SIDBI MSME',     'Up to ₹25L',   '9-12%',   'Registered MSMEs'),
              _SchemeRow('CGTMSE',         'Up to ₹2Cr',   'Market',  'No collateral needed'),
              _SchemeRow('Startup India',  'Up to ₹10Cr',  'Varied',  'DPIIT recognized'),
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Loan Advisor', sub: 'MUDRA · SIDBI · Bank Loans · Debt Management', color: _accent, onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl; final String label; final String? prefix, suffix;
  const _Field({required this.ctrl, required this.label, this.prefix, this.suffix});
  @override
  Widget build(BuildContext context) => TextField(controller: ctrl, keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))));
}

class _SchemeRow extends StatelessWidget {
  final String name, amount, rate, note;
  const _SchemeRow(this.name, this.amount, this.rate, this.note);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(note, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
      ])),
      Expanded(flex: 2, child: Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green.shade700))),
      Expanded(flex: 2, child: Text(rate, style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700))),
    ]));
}