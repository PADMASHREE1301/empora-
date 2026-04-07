// lib/screens/restructure/restructure_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/screens/chat/module_chat_screen.dart';
import 'package:empora/theme/app_theme.dart';
import '../shared_module_widgets.dart';

class RestructureScreen extends StatefulWidget {
  const RestructureScreen({super.key});
  @override State<RestructureScreen> createState() => _RestructureScreenState();
}

class _RestructureScreenState extends State<RestructureScreen> {

  final _revCtrl  = TextEditingController();
  final _expCtrl  = TextEditingController();
  final _debtCtrl = TextEditingController();
  final _custCtrl = TextEditingController();
  Map<String, dynamic>? _result;

  @override void dispose() { _revCtrl.dispose(); _expCtrl.dispose(); _debtCtrl.dispose(); _custCtrl.dispose(); super.dispose(); }

  void _assess() {
    final rev  = double.tryParse(_revCtrl.text.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final exp  = double.tryParse(_expCtrl.text.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final debt = double.tryParse(_debtCtrl.text.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    final cust = double.tryParse(_custCtrl.text) ?? 0;
    if (rev <= 0) return;

    final margin    = ((rev - exp) / rev * 100);
    final debtRatio = debt / rev;
    final status    = margin < 0 ? 'Critical 🚨' : margin < 15 ? 'Needs Attention ⚠️' : 'Healthy 💪';
    final statusCol = margin < 0 ? Colors.red : margin < 15 ? Colors.orange : Colors.green;

    final tips = margin < 0
      ? ['Immediately cut all non-essential expenses', 'Review and revise your pricing strategy', 'Explore debt restructuring options urgently']
      : debtRatio > 1.0
      ? ['Debt load is high — prioritise repayment', 'Avoid new loans until debt-to-revenue < 0.5', 'Negotiate better repayment terms with lenders']
      : margin < 15
      ? ['Improve gross margins by reducing COGS', 'Identify and eliminate revenue leakages', 'Focus on customer retention over acquisition']
      : ['Business is healthy — invest in growth', 'Consider expanding to adjacent markets', 'Explore new revenue streams to diversify'];

    setState(() => _result = {
      'margin': margin, 'debtRatio': debtRatio,
      'customers': cust, 'status': status, 'statusCol': statusCol, 'tips': tips,
    });
  }


  void _openChat() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ModuleChatScreen(
      module: 'restructure', title: 'Restructure Advisor',
      subtitle: 'Business Transformation & Turnaround',
      icon: Icons.autorenew_rounded, accentColor: Color(0xFFF5A623),
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
    )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Restructure Advisor', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Business Transformation & Turnaround', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openChat)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          ModuleCard(
            icon: Icons.monitor_heart_outlined, color: const Color(0xFFF5A623),
            title: 'Business Health Check',
            subtitle: 'Diagnose your financial health in 60 seconds',
            child: Column(children: [
              _FieldRow(ctrl: _revCtrl,  label: 'Monthly Revenue',  prefix: '₹'),
              const SizedBox(height: 10),
              _FieldRow(ctrl: _expCtrl,  label: 'Monthly Expenses', prefix: '₹'),
              const SizedBox(height: 10),
              _FieldRow(ctrl: _debtCtrl, label: 'Total Debt Outstanding', prefix: '₹'),
              const SizedBox(height: 10),
              _FieldRow(ctrl: _custCtrl, label: 'Active Customers', suffix: 'customers'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity,
                child: ElevatedButton(onPressed: _assess,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Run Health Check', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)))),

              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_result!['statusCol'] as Color).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (_result!['statusCol'] as Color).withValues(alpha: 0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_result!['status'], style: GoogleFonts.montserrat(
                      fontSize: 20, fontWeight: FontWeight.w900, color: _result!['statusCol'] as Color)),
                    const SizedBox(height: 12),
                    _MetricRow('Profit Margin', '${(_result!['margin'] as double).toStringAsFixed(1)}%',
                      (_result!['margin'] as double) >= 15 ? Colors.green : Colors.red),
                    _MetricRow('Debt-to-Revenue', '${(_result!['debtRatio'] as double).toStringAsFixed(2)}x',
                      (_result!['debtRatio'] as double) < 0.5 ? Colors.green : Colors.orange),
                    _MetricRow('Active Customers', '${(_result!['customers'] as double).toInt()}', Colors.blue),
                    const Divider(height: 20),
                    Text('Recommendations', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...(_result!['tips'] as List<String>).map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('• ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _result!['statusCol'] as Color)),
                        Expanded(child: Text(tip, style: GoogleFonts.inter(fontSize: 13, height: 1.4))),
                      ]))),
                  ])),
              ],
            ]),
          ),

          const SizedBox(height: 20),
          ModuleChatButton(label: 'Ask Restructure Advisor', sub: 'Pivot · Cost Cutting · Debt · Exit Strategy', color: const Color(0xFFF5A623), onTap: _openChat),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final TextEditingController ctrl; final String label; final String? prefix, suffix;
  const _FieldRow({required this.ctrl, required this.label, this.prefix, this.suffix});
  @override
  Widget build(BuildContext context) => TextField(controller: ctrl, keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))));
}

class _MetricRow extends StatelessWidget {
  final String label, value; final Color color;
  const _MetricRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]))),
      Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ]));
}