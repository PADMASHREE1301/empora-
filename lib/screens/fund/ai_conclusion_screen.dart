// lib/screens/fund/ai_conclusion_screen.dart
//
// ─── UPDATED FLOW ─────────────────────────────────────────────────────────────
// Step 0 → GET /api/fund/:id/extracted-text     (backend returns file text)
// Step 1-5 → animate while building prompt
// Step 6 → buildPromptWithExtractedText() → GroqService.complete()
// Step 7 → POST /api/fund/:id/ai-report         (save report to MongoDB)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../theme/app_theme.dart';
import '../../models/fund_raising_model.dart';
import '../../services/groq_service.dart';
import '../../services/api_service.dart';

class AiConclusionScreen extends StatefulWidget {
  final FundRaisingState sharedState;
  const AiConclusionScreen({super.key, required this.sharedState});

  @override
  State<AiConclusionScreen> createState() => _AiConclusionScreenState();
}

class _AiConclusionScreenState extends State<AiConclusionScreen>
    with TickerProviderStateMixin {
  bool    _isAnalyzing    = false;
  bool    _isDone         = false;
  int     _analysisStep   = 0;
  String  _stepLabel      = '';
  String? _errorMsg;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  static const List<String> _steps = [
    'Fetching documents from server...',   // 0
    'Reading pitch deck content...',       // 1
    'Analyzing financial data...',         // 2
    'Evaluating team & background...',     // 3
    'Assessing market opportunity...',     // 4
    'Calculating investment score...',     // 5
    'Generating investor report...',       // 6
    'Saving report to database...',        // 7
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _isDone    = widget.sharedState.aiReport != null;
    _stepLabel = _steps[0];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setStep(int i) {
    if (!mounted) return;
    setState(() {
      _analysisStep = i;
      _stepLabel    = (i < _steps.length) ? _steps[i] : 'Finalizing...';
    });
  }

  // ─── MAIN ANALYSIS RUNNER ─────────────────────────────────────────────────
  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing  = true;
      _isDone       = false;
      _analysisStep = 0;
      _stepLabel    = _steps[0];
      _errorMsg     = null;
    });

    try {
      // ── Step 0: fetch extracted text from MongoDB ──────────────────────────
      _setStep(0);
      Map<String, dynamic> extracted = {};
      final recordId = widget.sharedState.recordId;

      if (recordId != null) {
        try {
          extracted = await ApiService.getExtractedText(recordId: recordId);
        } catch (_) {
          // Could not fetch file text — will use form data only, no banner
        }
      }

      // ── Steps 1-5: animate while we prepare the prompt ────────────────────
      for (int i = 1; i <= 5; i++) {
        _setStep(i);
        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted || !_isAnalyzing) return;
      }

      // Build prompt — use rich extracted-text version if available
      final prompt = extracted.isNotEmpty
          ? widget.sharedState.buildPromptWithExtractedText(extracted)
          : widget.sharedState.buildPrompt();

      // ── Step 6: send to Groq ───────────────────────────────────────────────
      _setStep(6);
      final rawResponse = await GroqService.complete(prompt);

      // ── Robust JSON extraction ──────────────────────────────────────────────
      String jsonStr = rawResponse.trim();

      // Strip ```json fences
      if (jsonStr.contains('```')) {
        jsonStr = jsonStr
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
      }

      // Extract only the first valid JSON object (handles trailing text)
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd   = jsonStr.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      // Repair common Groq JSON issues:
      // 1. Remove trailing commas before } or ]
      jsonStr = jsonStr.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
      // 2. Replace fancy quotes with straight quotes
      jsonStr = jsonStr
          .replaceAll('\u201C', '"').replaceAll('\u201D', '"')
          .replaceAll('\u2018', "'").replaceAll('\u2019', "'");
      // 3. Remove control characters that break JSON
      jsonStr = jsonStr.replaceAll(RegExp(r'[\x00-\x09\x0b\x0c\x0e-\x1f]'), ' ');

      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        // JSON parse failed — show offline report silently, no banner
        widget.sharedState.aiReport = widget.sharedState.generateReport();
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _isDone      = true;
          _errorMsg    = null; // no banner shown
        });
        return;
      }

      final report = AiReportData.fromGroqResponse(rawResponse, jsonData);
      widget.sharedState.aiReport = report;

      // ── Step 7: save report to MongoDB ────────────────────────────────────
      _setStep(7);
      if (recordId != null) {
        try {
          await ApiService.saveFundAiReport(
            recordId: recordId,
            report: {
              'verdict':             report.verdict,
              'summary':             report.summary,
              'overallScore':        report.overallScore,
              'pitchScore':          report.pitchScore,
              'valuationScore':      report.valuationScore,
              'teamScore':           report.teamScore,
              'marketScore':         report.marketScore,
              'strengths':           report.strengths,
              'weaknesses':          report.weaknesses,
              'opportunities':       report.opportunities,
              'recommendations':     report.recommendations,
              'finalRecommendation': report.recommendation,
              'rawText':             report.rawText,
            },
          );
        } catch (_) {
          // DB save failed — report is still shown, no banner needed
        }
      }

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _isDone      = true;
      });
    } on GroqException catch (_) {
      // Groq API error (e.g. invalid key, quota) — show offline report silently
      if (!mounted) return;
      widget.sharedState.aiReport = widget.sharedState.generateReport();
      setState(() {
        _isAnalyzing = false;
        _isDone      = true;
        _errorMsg    = null; // no banner — user just sees the report
      });
    } catch (_) {
      // Any other error — show offline report silently
      if (!mounted) return;
      widget.sharedState.aiReport = widget.sharedState.generateReport();
      setState(() {
        _isAnalyzing = false;
        _isDone      = true;
        _errorMsg    = null; // no banner
      });
    }
  }

  // ─── Download ─────────────────────────────────────────────────────────────
  Future<void> _downloadReport() async {
    final report = widget.sharedState.aiReport;
    if (report == null) return;
    try {
      final pd        = widget.sharedState.pitchDeck;
      final company   = pd.company.isNotEmpty ? pd.company.replaceAll(' ', '_') : 'Startup';
      final timestamp = report.generatedAt.millisecondsSinceEpoch;
      final fileName  = 'Empora_Report_${company}_$timestamp.pdf';

      // ── Build PDF ──────────────────────────────────────────────────────────
      final pdf = pw.Document();

      final darkColor  = PdfColor.fromHex('0D1B3E');
      final blueColor  = PdfColor.fromHex('1A3A6B');
      final tealColor  = PdfColor.fromHex('0D6E8A');
      final goldColor  = PdfColor.fromHex('F4A700');
      final lightGray  = PdfColor.fromHex('F5F7FB');
      final successClr = PdfColor.fromHex('1A7A4A');
      final errorClr   = PdfColor.fromHex('C0392B');
      final grayColor  = PdfColor.fromHex('64748B');

      final verdictClr = report.overallScore >= 0.7
          ? successClr
          : report.overallScore >= 0.45
              ? goldColor
              : errorClr;

      pw.Widget sectionTitle(String text, {PdfColor? bg}) => pw.Container(
            color: bg ?? darkColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const pw.EdgeInsets.only(bottom: 8, top: 14),
            child: pw.Text(text,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          );

      pw.Widget scoreBar(String label, double score, PdfColor color) =>
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(label,
                      style: pw.TextStyle(fontSize: 10, color: grayColor)),
                  pw.Text('${(score * 100).toInt()}%',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor)),
                ]),
            pw.SizedBox(height: 4),
            pw.Stack(children: [
              pw.Container(
                  height: 8,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                      color: lightGray,
                      borderRadius: pw.BorderRadius.circular(4))),
              pw.Container(
                  height: 8,
                  width: 460 * score.clamp(0.0, 1.0), // 460pt = approx full width on A4
                  decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(4))),
            ]),
            pw.SizedBox(height: 8),
          ]);

      pw.Widget bulletItem(String text, PdfColor dotColor) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                      width: 6,
                      height: 6,
                      margin: const pw.EdgeInsets.only(top: 4, right: 8),
                      decoration: pw.BoxDecoration(
                          color: dotColor, shape: pw.BoxShape.circle)),
                  pw.Expanded(
                      child: pw.Text(text,
                          style:
                              pw.TextStyle(fontSize: 10, color: darkColor))),
                ]),
          );

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Container(
          color: darkColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('EMPORA AI INVESTOR REPORT',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text(
                    pd.company.isNotEmpty ? pd.company.toUpperCase() : 'STARTUP',
                    style: pw.TextStyle(fontSize: 11, color: goldColor)),
              ]),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by Empora AI (Groq / Llama3)',
                    style: pw.TextStyle(fontSize: 8, color: grayColor)),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: grayColor)),
              ]),
        ),
        build: (ctx) => [
          // ── Verdict banner ───────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            margin: const pw.EdgeInsets.only(top: 12, bottom: 16),
            decoration: pw.BoxDecoration(
              // Solid light colors — alpha causes solid red block in pdf package
              color: report.overallScore >= 0.7
                  ? PdfColor.fromHex('E8F5E9')   // light green
                  : report.overallScore >= 0.45
                      ? PdfColor.fromHex('FFF8E1') // light amber
                      : PdfColor.fromHex('FFF3E0'), // light orange
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: verdictClr, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
              pw.Text(report.verdict,
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: verdictClr)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${(report.overallScore * 100).toInt()}% Overall Score',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: verdictClr)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Generated ${report.generatedAt.toLocal().toString().substring(0, 16)}',
                  style: pw.TextStyle(fontSize: 9, color: grayColor)),
            ]),
          ),

          // ── Executive Summary ────────────────────────────────────────────
          sectionTitle('EXECUTIVE SUMMARY', bg: blueColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(report.summary,
                style: pw.TextStyle(
                    fontSize: 10, color: darkColor, lineSpacing: 4)),
          ),

          // ── Score Breakdown ──────────────────────────────────────────────
          sectionTitle('SCORE BREAKDOWN', bg: tealColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(children: [
              scoreBar('Overall',    report.overallScore,    darkColor),
              scoreBar('Pitch Deck', report.pitchScore,     blueColor),
              scoreBar('Valuation',  report.valuationScore, tealColor),
              scoreBar('Team',       report.teamScore,      tealColor),
              scoreBar('Market',     report.marketScore,    blueColor),
            ]),
          ),

          // ── Strengths ────────────────────────────────────────────────────
          sectionTitle('STRENGTHS', bg: PdfColor.fromHex('1A7A4A')),
          ...report.strengths.map((s) => bulletItem(s, successClr)),

          // ── Weaknesses ───────────────────────────────────────────────────
          sectionTitle('WEAKNESSES', bg: errorClr),
          ...report.weaknesses.map((w) => bulletItem(w, errorClr)),

          // ── Opportunities ────────────────────────────────────────────────
          sectionTitle('OPPORTUNITIES', bg: goldColor),
          ...report.opportunities.map((o) => bulletItem(o, goldColor)),

          // ── Recommendations ──────────────────────────────────────────────
          sectionTitle('RECOMMENDATIONS', bg: blueColor),
          ...report.recommendations.map((r) => bulletItem(r, blueColor)),

          // ── Final Recommendation ─────────────────────────────────────────
          sectionTitle('FINAL RECOMMENDATION', bg: darkColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F0F4FF'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('BBCCEE'), width: 1.5)),
            child: pw.Text(report.recommendation,
                style: pw.TextStyle(
                    fontSize: 10, color: darkColor, lineSpacing: 4)),
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text('For informational purposes only.',
                style: pw.TextStyle(fontSize: 8, color: grayColor)),
          ),
        ],
      ));

      // ── Save / Download PDF ────────────────────────────────────────────────
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Web: trigger browser download using universal_html / js interop
        _downloadBytesOnWeb(pdfBytes, fileName);
      } else {
        File file;
        if (Platform.isAndroid) {
          const downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir  = Directory(downloadsPath);
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
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
          Expanded(
            child: Text(
              'PDF saved to Downloads: $fileName',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download failed: $e',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  /// Triggers a browser file download on Flutter Web.
  /// dart:js is NOT used to keep this file mobile-safe.
  void _downloadBytesOnWeb(List<int> bytes, String fileName) {
    debugPrint('Web download: $fileName (${bytes.length} bytes)');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'PDF ready! Web download requires a web-enabled build.',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _viewReport() {
    final report = widget.sharedState.aiReport;
    if (report == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(report: report),
    );
  }


  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF4A148C),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildHero()),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isAnalyzing && !_isDone) _buildReadinessCheck(),
                  if (_isAnalyzing)               _buildAnalyzingState(),
                  if (_isDone && widget.sharedState.aiReport != null) ...[
                    if (_errorMsg != null) _buildWarningBanner(_errorMsg!),
                    _buildReport(widget.sharedState.aiReport!),
                  ],

                  const SizedBox(height: 20),

                  // Generate / Re-run button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _runAnalysis,
                      icon: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isAnalyzing ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white),
                      ),
                      label: Text(
                        _isAnalyzing ? 'Analyzing...'
                            : _isDone    ? 'Re-run Analysis'
                            : 'Generate AI Report',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3FA0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  // View / Download row
                  if (_isDone && widget.sharedState.aiReport != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewReport,
                          icon: const Icon(Icons.visibility_outlined,
                              size: 18, color: Color(0xFF6B3FA0)),
                          label: Text('View Report',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: const Color(0xFF6B3FA0))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: Color(0xFF6B3FA0), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadReport,
                          icon: const Icon(Icons.download_rounded,
                              size: 18, color: Colors.white),
                          label: Text('Download',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A148C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final state    = widget.sharedState;
    final hasFiles = state.pitchDeck.fileUrl != null ||
                     state.valuation.fileUrl != null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0533), Color(0xFF4A148C), Color(0xFF6B3FA0)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: -40, right: -40,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04))),
        ),
        Positioned(
          bottom: 20, left: -30,
          child: Container(width: 130, height: 130,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B3FA0).withValues(alpha: 0.3))),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.psychology,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Conclusion',
                            style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(
                          hasFiles
                              ? 'Reads your actual uploaded documents'
                              : 'Powered by Groq · Llama3-8b',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Wrap(spacing: 8, children: [
                  _DataBadge(label: 'Pitch',     done: state.isPitchReady),
                  _DataBadge(label: 'Valuation', done: state.isValuationReady),
                  _DataBadge(label: 'Comments',  done: state.isCommentsReady),
                  _DataBadge(label: 'Files',     done: hasFiles),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Readiness card ──────────────────────────────────────────────────────
  Widget _buildReadinessCheck() {
    final state    = widget.sharedState;
    final hasFiles = state.pitchDeck.fileUrl != null || state.valuation.fileUrl != null;
    final good     = hasFiles || state.isPitchReady;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: good
            ? AppTheme.success.withValues(alpha: 0.08)
            : AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: good
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(good ? Icons.check_circle : Icons.warning_amber_rounded,
              color: good ? AppTheme.success : AppTheme.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFiles
                  ? 'Documents uploaded — AI will read your files!'
                  : state.isPitchReady
                      ? 'Ready to Generate!'
                      : 'Upload files or fill in form fields first',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: good ? AppTheme.success : AppTheme.warning),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _CheckItem(label: 'Pitch Deck file',   done: state.pitchDeck.fileUrl != null),
        const SizedBox(height: 6),
        _CheckItem(label: 'Valuation file',    done: state.valuation.fileUrl != null),
        const SizedBox(height: 6),
        _CheckItem(
          label: 'Pitch form data',
          done: state.isPitchReady,
          optional: hasFiles,   // show as optional (not error) when files uploaded
        ),
        const SizedBox(height: 6),
        _CheckItem(
          label: 'Valuation data',
          done: state.isValuationReady,
          optional: hasFiles,
        ),
        const SizedBox(height: 6),
        _CheckItem(
          label: 'Comments / Profile',
          done: state.isCommentsReady,
          optional: hasFiles,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6B3FA0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF6B3FA0), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasFiles
                    ? 'AI will read the actual content of your uploaded files for a deeper, more accurate analysis.'
                    : 'Upload files for best results. Form-data-only reports are also supported.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── Analyzing animation ──────────────────────────────────────────────────
  Widget _buildAnalyzingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A0533), Color(0xFF4A148C)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) =>
              Transform.scale(scale: _pulseAnim.value, child: child),
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.psychology, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text('Analyzing with Groq AI...',
            style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text(_stepLabel,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_analysisStep + 1) / _steps.length,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            color: AppTheme.accentGold,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 10),
        Text('${_analysisStep + 1} / ${_steps.length} steps',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
      ]),
    );
  }

  // ─── Warning banner ───────────────────────────────────────────────────────
  Widget _buildWarningBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.warning, height: 1.4)),
        ),
      ]),
    );
  }

  // ─── Report ───────────────────────────────────────────────────────────────
  Widget _buildReport(AiReportData r) {
    final verdictColor = _verdictColor(r.verdict);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: verdictColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: verdictColor.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(r.verdict,
              style: GoogleFonts.montserrat(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: verdictColor, letterSpacing: 2)),
          Text('${(r.overallScore * 100).toInt()}% Overall Score',
              style: GoogleFonts.inter(
                  fontSize: 14, color: verdictColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Generated ${_fmt(r.generatedAt)}',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
      const SizedBox(height: 20),

      _SectionTitle('Executive Summary'),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Text(r.summary,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textPrimary, height: 1.6)),
      ),
      const SizedBox(height: 20),

      _SectionTitle('Score Breakdown'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(children: [
          _ScoreBar(label: 'Pitch Deck', score: r.pitchScore,      color: const Color(0xFF1A3A6B)),
          const SizedBox(height: 12),
          _ScoreBar(label: 'Valuation',  score: r.valuationScore,  color: const Color(0xFF2756A8)),
          const SizedBox(height: 12),
          _ScoreBar(label: 'Team',       score: r.teamScore,        color: const Color(0xFF0D6E8A)),
          const SizedBox(height: 12),
          _ScoreBar(label: 'Market',     score: r.marketScore,      color: const Color(0xFF6B3FA0)),
        ]),
      ),
      const SizedBox(height: 20),

      if (r.strengths.isNotEmpty) ...[
        _SectionTitle('Strengths'), const SizedBox(height: 8),
        ...r.strengths.map((s) => _BulletCard(
            icon: Icons.check_circle_outline, color: AppTheme.success, text: s)),
        const SizedBox(height: 12),
      ],
      if (r.weaknesses.isNotEmpty) ...[
        _SectionTitle('Weaknesses'), const SizedBox(height: 8),
        ...r.weaknesses.map((s) => _BulletCard(
            icon: Icons.cancel_outlined, color: AppTheme.error, text: s)),
        const SizedBox(height: 12),
      ],
      if (r.opportunities.isNotEmpty) ...[
        _SectionTitle('Opportunities'), const SizedBox(height: 8),
        ...r.opportunities.map((s) => _BulletCard(
            icon: Icons.trending_up, color: AppTheme.warning, text: s)),
        const SizedBox(height: 12),
      ],
      if (r.recommendations.isNotEmpty) ...[
        _SectionTitle('Recommendations'), const SizedBox(height: 8),
        ...r.recommendations.map((s) => _BulletCard(
            icon: Icons.lightbulb_outline,
            color: const Color(0xFF6B3FA0), text: s)),
        const SizedBox(height: 12),
      ],
      _RecommendationCard(report: r),
      const SizedBox(height: 8),
    ]);
  }

  Color _verdictColor(String v) {
    switch (v.toUpperCase()) {
      case 'STRONG INVEST': return const Color(0xFF00875A);
      case 'INVEST':        return AppTheme.success;
      case 'CONSIDER':      return AppTheme.warning;
      default:              return AppTheme.error;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Full Report Sheet ────────────────────────────────────────────────────────
class _ReportSheet extends StatelessWidget {
  final AiReportData report;
  const _ReportSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 1.0,
      minChildSize: 0.5,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              const Icon(Icons.psychology, color: Color(0xFF6B3FA0), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('AI Investor Report',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B3FA0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF6B3FA0).withValues(alpha: 0.3)),
                      ),
                      child: Text(report.verdict,
                          style: GoogleFonts.montserrat(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: const Color(0xFF6B3FA0), letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section('Executive Summary', report.summary),
                  const SizedBox(height: 16),
                  _scores(report),
                  const SizedBox(height: 16),
                  _list('✓  Strengths',       report.strengths,       AppTheme.success),
                  _list('✗  Weaknesses',      report.weaknesses,      AppTheme.error),
                  _list('→  Opportunities',   report.opportunities,   AppTheme.warning),
                  _list('•  Recommendations', report.recommendations, const Color(0xFF6B3FA0)),
                  const SizedBox(height: 16),
                  _section('Final Recommendation', report.recommendation),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                        'Generated by Empora AI (Groq / Llama3)\nFor informational purposes only.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _section(String title, String body) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textPrimary, height: 1.6)),
      ]);

  Widget _scores(AiReportData r) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Score Breakdown',
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        _ScoreBar(label: 'Overall',    score: r.overallScore,   color: const Color(0xFF6B3FA0)),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Pitch Deck', score: r.pitchScore,     color: const Color(0xFF1A3A6B)),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Valuation',  score: r.valuationScore, color: const Color(0xFF2756A8)),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Team',       score: r.teamScore,      color: const Color(0xFF0D6E8A)),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Market',     score: r.marketScore,    color: const Color(0xFF00875A)),
      ]);

  Widget _list(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: GoogleFonts.montserrat(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 8),
      ...items.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Expanded(
                  child: Text(s,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textPrimary, height: 1.5))),
            ]),
          )),
      const SizedBox(height: 14),
    ]);
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color  color;
  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        Text('${(score * 100).toInt()}%',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: score,
          backgroundColor: AppTheme.divider,
          color: color,
          minHeight: 7,
        ),
      ),
    ]);
  }
}

class _BulletCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  const _BulletCard({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
        ),
      ]),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AiReportData report;
  const _RecommendationCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6B3FA0)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text('AI Final Recommendation',
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        Text(report.recommendation,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.montserrat(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }
}

class _DataBadge extends StatelessWidget {
  final String label;
  final bool   done;
  const _DataBadge({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.success.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: done ? AppTheme.success.withValues(alpha: 0.4) : Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppTheme.success : Colors.white54, size: 12,
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: done ? AppTheme.success : Colors.white60,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool   done;
  /// When true, shows a neutral dash instead of a red cross (used for
  /// optional form fields when files are already uploaded).
  final bool   optional;
  const _CheckItem({required this.label, required this.done, this.optional = false});

  @override
  Widget build(BuildContext context) {
    // Files uploaded covers optional fields -> green tick for everything
    final bool satisfied = done || optional;
    return Row(children: [
      Icon(
        satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
        color: satisfied ? AppTheme.success : AppTheme.textSecondary,
        size: 16,
      ),
      const SizedBox(width: 8),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 13,
              color: satisfied ? AppTheme.success : AppTheme.textSecondary,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400)),
      if (optional && !done) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('via file',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppTheme.success.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ]);
  }
}