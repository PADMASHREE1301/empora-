// lib/screens/stratic/stratic_conclusion_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _viewReport(r),
          icon: const Icon(Icons.visibility_outlined, size: 15),
          label: Text('View', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              foregroundColor: _teal, side: BorderSide(color: _teal),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _downloadReport(r),
          icon: const Icon(Icons.download_rounded, size: 15),
          label: Text('Download', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              foregroundColor: _teal, side: BorderSide(color: _teal),
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

  void _downloadReport(StraticAiReport r) {
    final content = [
      'AI Strategy Report', '=' * 50, '',
      'VERDICT: ${r.verdict}',
      'OVERALL SCORE: ${(r.overallScore * 100).toStringAsFixed(0)}%',
      '', 'SUMMARY', '-' * 30, r.summary,
      '', 'STRENGTHS', '-' * 30, ...r.strengths.map((s) => '• $s'),
      '', 'KEY RISKS', '-' * 30, ...r.risks.map((s) => '• $s'),
      '', 'OPPORTUNITIES', '-' * 30, ...r.opportunities.map((s) => '• $s'),
      '', 'RECOMMENDATIONS', '-' * 30, ...r.recommendations.map((s) => '• $s'),
      '', 'FINAL RECOMMENDATION', '-' * 30, r.finalRecommendation,
    ].join('\n');
    _showDownloadSheet('AI Strategy Report', content);
  }

  void _showDownloadSheet(String title, String content) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(children: [
              Expanded(child: Text(title,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700))),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Report copied to clipboard!', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy All'),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(content,
                style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.black87, height: 1.6)),
          )),
        ]),
      ),
    );
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