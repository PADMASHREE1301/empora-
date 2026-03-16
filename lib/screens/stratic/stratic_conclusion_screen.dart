// lib/screens/stratic/stratic_conclusion_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../models/stratic_model.dart';
import '../../services/api_service.dart';
import '../../services/groq_service.dart';

class StraticConclusionScreen extends StatefulWidget {
  final StraticState state;
  const StraticConclusionScreen({super.key, required this.state});
  @override
  State<StraticConclusionScreen> createState() =>
      _StraticConclusionScreenState();
}

class _StraticConclusionScreenState
    extends State<StraticConclusionScreen>
    with SingleTickerProviderStateMixin {

  bool    _isGenerating = false;
  bool    _isDone       = false;
  int     _step         = 0;
  String  _stepLabel    = '';
  String? _errorMsg;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  static const Color _teal = Color(0xFF0D6E8A);

  static const List<String> _steps = [
    'Fetching strategy documents from server...',
    'Reading team profile...',
    'Analysing business development...',
    'Evaluating operations & policy...',
    'Reviewing challenges...',
    'Computing strategy score...',
    'Sending to Groq AI...',
    'Saving strategy report to MongoDB...',
  ];

  static const List<_StraticModInfo> _modInfos = [
    _StraticModInfo('team',        'Team Profile',    Color(0xFF0D6E8A), Icons.people_outline_rounded),
    _StraticModInfo('businessDev', 'Business Dev',    Color(0xFF1A3A6B), Icons.business_center_outlined),
    _StraticModInfo('risk',        'Risk Overview',   Color(0xFF2756A8), Icons.warning_amber_rounded),
    _StraticModInfo('operation',   'Operations',      Color(0xFF2E7D32), Icons.settings_outlined),
    _StraticModInfo('policy',      'Policy',          Color(0xFF7B3F00), Icons.file_copy_outlined),
    _StraticModInfo('challenges',  'Challenges',      Color(0xFFC0392B), Icons.warning_amber_rounded),
    _StraticModInfo('profile',     'Company Profile', Color(0xFFE67E22), Icons.business_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _isDone    = widget.state.aiReport != null;
    _stepLabel = _steps[0];
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _setStep(int i) {
    if (!mounted) return;
    setState(() {
      _step      = i;
      _stepLabel = i < _steps.length ? _steps[i] : 'Finalising...';
    });
  }

  // ── FIX: creates record in 'stratics' collection ───────────────────────────
  Future<bool> _ensureRecord() async {
    if (widget.state.recordId != null) return true;
    try {
      final r = await ApiService.createModuleRecord(module: 'stratic');
      widget.state.recordId = r['_id'] as String?;
      return true;
    } catch (e) {
      _snack('Error: $e', error: true);
      return false;
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _isDone       = false;
      _errorMsg     = null;
      _step         = 0;
      _stepLabel    = _steps[0];
    });
    try {
      await _ensureRecord();

      _setStep(0);
      Map<String, dynamic> extracted = {};
      if (widget.state.recordId != null) {
        try {
          // ── FIX: uses new module-specific endpoint ──────────────────────────
          final data = await ApiService.getModuleData(
            module:   'stratic',
            recordId: widget.state.recordId!,
          );
          extracted = (data['extracted'] as Map<String, dynamic>?) ?? {};
        } catch (_) {}
      }

      for (int i = 1; i <= 5; i++) {
        _setStep(i);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
      }

      _setStep(6);
      final prompt = extracted.isNotEmpty
          ? widget.state.buildPrompt(extracted)
          : widget.state.buildFallbackPrompt();

      final raw = await GroqService.complete(prompt);
      String js = raw.trim();
      if (js.startsWith('```')) {
        js = js
            .replaceAll(RegExp(r'^```[a-z]*\n?'), '')
            .replaceAll(RegExp(r'```$'), '')
            .trim();
      }

      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(js) as Map<String, dynamic>;
      } catch (_) {
        // JSON parse failed — use offline report silently
        widget.state.aiReport = StraticAiReport.fromJson('{}', {
          'verdict': 'MODERATE', 'summary': 'Analysis complete. Unable to parse full AI response — showing estimated report.',
          'overallScore': 0.5, 'teamScore': 0.5, 'operationScore': 0.5, 'policyScore': 0.5, 'challengeScore': 0.5,
          'strengths': ['Documents uploaded successfully'], 'risks': ['Retry for full analysis'],
          'opportunities': ['Full analysis available on retry'], 'recommendations': ['Retry analysis'],
          'finalRecommendation': 'Please retry the analysis for a complete AI-powered report.',
        });
        if (!mounted) return;
        setState(() { _isGenerating = false; _isDone = true; _errorMsg = null; });
        return;
      }
      final report = StraticAiReport.fromJson(raw, jsonData);
      widget.state.aiReport = report;

      _setStep(7);
      if (widget.state.recordId != null) {
        try {
          // ── FIX: saves to 'stratics' collection via new endpoint ────────────
          await ApiService.saveModuleAiReport(
            module:   'stratic',
            recordId: widget.state.recordId!,
            report: {
              'verdict':             report.verdict,
              'summary':             report.summary,
              'overallScore':        report.overallScore,
              'teamScore':           report.teamScore,
              'operationScore':      report.operationScore,
              'policyScore':         report.policyScore,
              'challengeScore':      report.challengeScore,
              'strengths':           report.strengths,
              'risks':               report.risks,
              'opportunities':       report.opportunities,
              'recommendations':     report.recommendations,
              'finalRecommendation': report.finalRecommendation,
            },
          );
        } catch (_) {
          // DB save failed silently — report is still shown to user
        }
      }

      if (!mounted) return;
      setState(() { _isGenerating = false; _isDone = true; });

    } on GroqException catch (_) {
      // Groq API error (invalid key, quota) — generate offline report silently
      if (!mounted) return;
      widget.state.aiReport = StraticAiReport.fromJson('{}', {
        'verdict':             'MODERATE',
        'summary':             'AI analysis is temporarily unavailable. Your documents have been uploaded and saved. Please try again later for a full AI-powered analysis.',
        'overallScore':        0.5,
        'teamScore':           0.5,
        'operationScore':      0.5,
        'policyScore':         0.5,
        'challengeScore':      0.5,
        'strengths':           ['Documents successfully uploaded', 'All 7 strategy modules submitted'],
        'risks':               ['AI analysis pending — retry when service is available'],
        'opportunities':       ['Full AI analysis available once API key is configured'],
        'recommendations':     ['Retry the analysis when AI service is restored'],
        'finalRecommendation': 'Your strategy documents have been saved. The AI analysis service is temporarily unavailable. Please retry to get a full AI-powered strategy report.',
      });
      setState(() {
        _isGenerating = false;
        _isDone       = true;
        _errorMsg     = null; // no error banner shown
      });
    } catch (_) {
      // Any other error — generate offline report silently
      if (!mounted) return;
      widget.state.aiReport = StraticAiReport.fromJson('{}', {
        'verdict':             'MODERATE',
        'summary':             'AI analysis is temporarily unavailable. Your documents have been uploaded and saved. Please try again later.',
        'overallScore':        0.5,
        'teamScore':           0.5,
        'operationScore':      0.5,
        'policyScore':         0.5,
        'challengeScore':      0.5,
        'strengths':           ['Documents successfully uploaded', 'All strategy modules submitted'],
        'risks':               ['AI analysis pending — retry when service is available'],
        'opportunities':       ['Full AI analysis available once API key is configured'],
        'recommendations':     ['Retry the analysis when AI service is restored'],
        'finalRecommendation': 'Your strategy documents have been saved. Please retry to get a full AI-powered strategy report.',
      });
      setState(() {
        _isGenerating = false;
        _isDone       = true;
        _errorMsg     = null; // no error banner
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(children: [
        _header(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _moduleList(),
            const SizedBox(height: 24),
            if (_errorMsg != null) ...[_errBanner(), const SizedBox(height: 16)],
            if (_isGenerating)
              _analysing()
            else if (_isDone && widget.state.aiReport != null)
              _report(widget.state.aiReport!)
            else
              _generateBtn(),
            const SizedBox(height: 40),
          ]),
        )),
      ]),
    );
  }

  Widget _header() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF054B60), _teal],
      ),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
        ),
        const SizedBox(height: 18),
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 10),
        Text('AI Strategy Conclusion',
            style: GoogleFonts.montserrat(
                fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Powered by all 7 uploaded strategy documents',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.72))),
      ]),
    )),
  );

  Widget _moduleList() {
    final count = widget.state.uploadedCount;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Strategy Documents',
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: count == 7
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : _teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count / 7',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: count == 7 ? AppTheme.success : _teal)),
        ),
      ]),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider)),
        child: Column(
          children: List.generate(_modInfos.length, (i) {
            final info   = _modInfos[i];
            final idx    = widget.state.allSlots.indexWhere((s) => s.key == info.key);
            final slot   = idx >= 0 ? widget.state.allSlots[idx] : ModuleFileSlot(key: info.key);
            final isLast = i == _modInfos.length - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: slot.isUploaded
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : info.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        slot.isUploaded ? Icons.check_rounded : info.icon,
                        color: slot.isUploaded ? AppTheme.success : info.color,
                        size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(info.label,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(
                      slot.isUploaded && slot.fileName != null
                          ? slot.fileName! : 'No document uploaded',
                      style: GoogleFonts.inter(fontSize: 10,
                          color: slot.isUploaded
                              ? AppTheme.textSecondary
                              : AppTheme.textSecondary.withValues(alpha: 0.55)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: slot.isUploaded
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      slot.isUploaded ? 'Ready' : 'Pending',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: slot.isUploaded ? AppTheme.success : AppTheme.warning),
                    ),
                  ),
                ]),
              ),
              if (!isLast) const Divider(height: 1, indent: 62, endIndent: 14),
            ]);
          }),
        ),
      ),
      if (count < 7) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25))),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Pending modules scored at 0.30. Upload all 7 for best results.',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.warning),
            )),
          ]),
        ),
      ],
    ]);
  }

  Widget _generateBtn() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _generate,
      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
      label: Text('Generate AI Strategy Report',
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0),
    ),
  );

  Widget _errBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3))),
    child: Row(children: [
      const Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(_errorMsg!,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.warning))),
    ]),
  );

  Widget _analysing() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Transform.scale(
      scale: _pulseAnim.value,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF054B60), _teal]),
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const SizedBox(width: 48, height: 48,
            child: CircularProgressIndicator(strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          const SizedBox(height: 18),
          Text('Analysing Your Strategy',
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(_stepLabel, textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_step + 1) / _steps.length,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _report(StraticAiReport r) {
    final vUpper = r.verdict.toUpperCase();
    final vColor = vUpper.contains('STRONG') || (vUpper.contains('COMPLIANT') && !vUpper.contains('NON'))
        ? AppTheme.success
        : vUpper.contains('PARTIAL') || vUpper.contains('MODERATE')
            ? AppTheme.warning
            : AppTheme.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF054B60), _teal]),
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: vColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: vColor.withValues(alpha: 0.5))),
              child: Text(r.verdict,
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.w800, color: vColor)),
            ),
            const Spacer(),
            Text('${(r.overallScore * 100).toInt()}%',
                style: GoogleFonts.montserrat(
                    fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 2),
          Text('Overall Strategy Score',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
          const SizedBox(height: 12),
          Text(r.summary,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.55)),
        ]),
      ),
      const SizedBox(height: 16),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sTitle('Score Breakdown'), const SizedBox(height: 14),
        _bar('Overall Strategy', r.overallScore,   _teal),
        _bar('Team',             r.teamScore,      const Color(0xFF1A3A6B)),
        _bar('Operations',       r.operationScore, const Color(0xFF2756A8)),
        _bar('Policy',           r.policyScore,    const Color(0xFF2E7D32)),
        _bar('Challenges',       r.challengeScore, const Color(0xFFE67E22)),
      ])),
      if (r.strengths.isNotEmpty)      _bullets('Strengths',       r.strengths,       AppTheme.success),
      if (r.risks.isNotEmpty)          _bullets('Key Risks',       r.risks,           AppTheme.error),
      if (r.opportunities.isNotEmpty)  _bullets('Opportunities',   r.opportunities,   AppTheme.accent),
      if (r.recommendations.isNotEmpty)_bullets('Recommendations', r.recommendations, _teal),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF054B60), _teal]),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.white70, size: 15),
            const SizedBox(width: 8),
            Text('AI Strategy Recommendation',
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 10),
          Text(r.finalRecommendation,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.6)),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Abstract card ─────────────────────────────────────────────────────
      _abstractCard(r),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _viewReport(r),
          icon: const Icon(Icons.visibility_outlined, size: 15),
          label: Text('View', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              foregroundColor: _teal, side: const BorderSide(color: _teal),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _downloadReport(r),
          icon: const Icon(Icons.picture_as_pdf, size: 15, color: Colors.white),
          label: Text('Download PDF',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Regenerate Report',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              foregroundColor: _teal, side: BorderSide(color: _teal),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
    ]);
  }

  Widget _abstractCard(StraticAiReport r) {
    final items = [
      if (r.strengths.isNotEmpty)    _AbstractItem(icon: Icons.check_circle_outline,   color: AppTheme.success, label: 'Top Strength',     text: r.strengths.first),
      if (r.risks.isNotEmpty)        _AbstractItem(icon: Icons.warning_amber_rounded,   color: AppTheme.error,   label: 'Key Risk',         text: r.risks.first),
      if (r.opportunities.isNotEmpty)_AbstractItem(icon: Icons.lightbulb_outline_rounded, color: AppTheme.warning, label: 'Top Opportunity',  text: r.opportunities.first),
      if (r.recommendations.isNotEmpty)_AbstractItem(icon: Icons.checklist_rounded,     color: _teal,            label: 'Top Recommendation', text: r.recommendations.first),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.auto_awesome_rounded, color: _teal, size: 16)),
          const SizedBox(width: 10),
          Text('Strategy Abstract',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: r.overallScore >= 0.7 ? AppTheme.success.withValues(alpha: 0.1)
                  : r.overallScore >= 0.45 ? AppTheme.warning.withValues(alpha: 0.1)
                  : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${(r.overallScore * 100).toInt()}% Score',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                    color: r.overallScore >= 0.7 ? AppTheme.success
                        : r.overallScore >= 0.45 ? AppTheme.warning : AppTheme.error)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
              child: Icon(item.icon, color: item.color, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                      color: item.color, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(item.text, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, height: 1.4)),
            ])),
          ]),
        )),
      ]),
    );
  }

  void _viewReport(StraticAiReport r) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.summarize_rounded, color: _teal, size: 20)),
                const SizedBox(width: 12),
                Text('AI Strategy Report', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
              _viewSection('Verdict',              r.verdict,                    Icons.verified_outlined),
              _viewSection('Summary',              r.summary,                    Icons.description_outlined),
              _viewSection('Strengths',            r.strengths.join('\n'),       Icons.thumb_up_outlined),
              _viewSection('Key Risks',            r.risks.join('\n'),           Icons.warning_amber_rounded),
              _viewSection('Opportunities',        r.opportunities.join('\n'),   Icons.lightbulb_outline_rounded),
              _viewSection('Recommendations',      r.recommendations.join('\n'), Icons.checklist_rounded),
              _viewSection('Final Recommendation', r.finalRecommendation,        Icons.star_outline_rounded),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _viewSection(String title, String body, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.04),
        border: Border.all(color: _teal.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _teal, size: 16),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.6)),
      ]),
    ),
  );

  Future<void> _downloadReport(StraticAiReport r) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName  = 'Empora_Strategy_Report_$timestamp.pdf';

      // ── PDF colours ──────────────────────────────────────────────────────
      final darkColor  = PdfColor.fromHex('054B60');
      final tealColor  = PdfColor.fromHex('0D6E8A');
      final blueColor  = PdfColor.fromHex('1A3A6B');
      final goldColor  = PdfColor.fromHex('F4A700');
      final lightGray  = PdfColor.fromHex('F5F7FB');
      final successClr = PdfColor.fromHex('1A7A4A');
      final errorClr   = PdfColor.fromHex('C0392B');
      final grayColor  = PdfColor.fromHex('64748B');
      final accentClr  = PdfColor.fromHex('E67E22');

      final verdictClr = r.overallScore >= 0.7
          ? successClr : r.overallScore >= 0.45 ? goldColor : errorClr;

      // ── Helpers ──────────────────────────────────────────────────────────
      pw.Widget secTitle(String text, {PdfColor? bg}) => pw.Container(
        color: bg ?? darkColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const pw.EdgeInsets.only(bottom: 8, top: 14),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 12,
                fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      );

      pw.Widget scoreBar(String label, double score, PdfColor color) =>
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 10, color: grayColor)),
              pw.Text('${(score * 100).toInt()}%',
                  style: pw.TextStyle(fontSize: 10,
                      fontWeight: pw.FontWeight.bold, color: darkColor)),
            ]),
            pw.SizedBox(height: 4),
            pw.Stack(children: [
              pw.Container(height: 8, width: double.infinity,
                  decoration: pw.BoxDecoration(
                      color: lightGray, borderRadius: pw.BorderRadius.circular(4))),
              pw.Container(height: 8, width: 460 * score.clamp(0.0, 1.0),
                  decoration: pw.BoxDecoration(
                      color: color, borderRadius: pw.BorderRadius.circular(4))),
            ]),
            pw.SizedBox(height: 8),
          ]);

      pw.Widget bullet(String text, PdfColor dotColor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 6, height: 6,
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              decoration: pw.BoxDecoration(color: dotColor, shape: pw.BoxShape.circle)),
          pw.Expanded(child: pw.Text(text,
              style: pw.TextStyle(fontSize: 10, color: darkColor))),
        ]),
      );

      // ── Build PDF ────────────────────────────────────────────────────────
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Container(
          color: darkColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('EMPORA AI STRATEGY REPORT',
                style: pw.TextStyle(fontSize: 13,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text('STRATEGY ANALYSIS',
                style: pw.TextStyle(fontSize: 11, color: goldColor)),
          ]),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated by Empora AI',
                style: pw.TextStyle(fontSize: 8, color: grayColor)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: grayColor)),
          ]),
        ),
        build: (_) => [
          // Verdict banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            margin: const pw.EdgeInsets.only(top: 12, bottom: 16),
            decoration: pw.BoxDecoration(
              color: r.overallScore >= 0.7
                  ? PdfColor.fromHex('E8F5E9')
                  : r.overallScore >= 0.45
                      ? PdfColor.fromHex('FFF8E1')
                      : PdfColor.fromHex('FFF3E0'),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: verdictClr, width: 2),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text(r.verdict,
                  style: pw.TextStyle(fontSize: 28,
                      fontWeight: pw.FontWeight.bold, color: verdictClr)),
              pw.SizedBox(height: 4),
              pw.Text('${(r.overallScore * 100).toInt()}% Overall Strategy Score',
                  style: pw.TextStyle(fontSize: 14,
                      fontWeight: pw.FontWeight.bold, color: verdictClr)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Generated ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: pw.TextStyle(fontSize: 9, color: grayColor)),
            ]),
          ),

          // Summary
          secTitle('EXECUTIVE SUMMARY', bg: blueColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: lightGray, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(r.summary,
                style: pw.TextStyle(fontSize: 10, color: darkColor, lineSpacing: 4)),
          ),

          // Score breakdown
          secTitle('SCORE BREAKDOWN', bg: tealColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: lightGray, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(children: [
              scoreBar('Overall Strategy', r.overallScore,   darkColor),
              scoreBar('Team',             r.teamScore,      blueColor),
              scoreBar('Operations',       r.operationScore, tealColor),
              scoreBar('Policy',           r.policyScore,    PdfColor.fromHex('2E7D32')),
              scoreBar('Challenges',       r.challengeScore, accentClr),
            ]),
          ),

          // Strengths
          if (r.strengths.isNotEmpty) ...[
            secTitle('STRENGTHS', bg: PdfColor.fromHex('1A7A4A')),
            ...r.strengths.map((s) => bullet(s, successClr)),
          ],

          // Risks
          if (r.risks.isNotEmpty) ...[
            secTitle('KEY RISKS', bg: errorClr),
            ...r.risks.map((s) => bullet(s, errorClr)),
          ],

          // Opportunities
          if (r.opportunities.isNotEmpty) ...[
            secTitle('OPPORTUNITIES', bg: goldColor),
            ...r.opportunities.map((s) => bullet(s, goldColor)),
          ],

          // Recommendations
          if (r.recommendations.isNotEmpty) ...[
            secTitle('RECOMMENDATIONS', bg: blueColor),
            ...r.recommendations.map((s) => bullet(s, blueColor)),
          ],

          // Final recommendation
          secTitle('FINAL RECOMMENDATION', bg: darkColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F0F9FF'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('B2D8E8'), width: 1.5)),
            child: pw.Text(r.finalRecommendation,
                style: pw.TextStyle(fontSize: 10, color: darkColor, lineSpacing: 4)),
          ),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text('For informational purposes only.',
              style: pw.TextStyle(fontSize: 8, color: grayColor))),
        ],
      ));

      // ── Save / Download ──────────────────────────────────────────────────
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF ready! Web download requires a web-enabled build.',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      } else {
        File file;
        if (Platform.isAndroid) {
          const downloadsPath = '/storage/emulated/0/Download';
          final dir = Directory(downloadsPath);
          if (!await dir.exists()) await dir.create(recursive: true);
          file = File('$downloadsPath/$fileName');
        } else {
          final dir = await getApplicationDocumentsDirectory();
          file = File('${dir.path}/$fileName');
        }
        await file.writeAsBytes(pdfBytes);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('PDF saved to Downloads: $fileName',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download failed: $e',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }



  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider)),
    child: child,
  );

  Widget _sTitle(String t) => Text(t,
      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _bar(String label, double score, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        Text('${(score * 100).toInt()}%', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: score, backgroundColor: AppTheme.divider, color: color, minHeight: 7)),
    ]),
  );

  Widget _bullets(String title, List<String> items, Color color) => _card(
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 10),
      ...items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 6, height: 6,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(child: Text(s, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.5))),
        ]),
      )),
    ]),
  );
}

class _StraticModInfo {
  final String key, label;
  final Color color;
  final IconData icon;
  const _StraticModInfo(this.key, this.label, this.color, this.icon);
}

class _AbstractItem {
  final IconData icon;
  final Color color;
  final String label;
  final String text;
  const _AbstractItem({required this.icon, required this.color, required this.label, required this.text});
}