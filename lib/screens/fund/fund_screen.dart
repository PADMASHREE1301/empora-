// lib/screens/fund/fund_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/fund_raising_model.dart';
import '../../services/api_service.dart';
import 'ai_conclusion_screen.dart';

class FundScreen extends StatefulWidget {
  const FundScreen({super.key});

  @override
  State<FundScreen> createState() => _FundScreenState();
}

class _FundScreenState extends State<FundScreen> {
  final FundRaisingState _sharedState = FundRaisingState();

  // ── Per-slot file state ─────────────────────────────────────────────────────
  PlatformFile? _pitchFile;
  PlatformFile? _valuationFile;
  PlatformFile? _commentsFile;

  bool _pitchUploaded     = false;
  bool _valuationUploaded = false;
  bool _commentsUploaded  = false;

  bool _pitchUploading     = false;
  bool _valuationUploading = false;
  bool _commentsUploading  = false;

  bool _isGenerating = false;

  // ── File slot config ────────────────────────────────────────────────────────
  static const _slots = [
    _SlotConfig(
      key: 'pitch',
      title: 'Pitch Deck',
      subtitle: 'PDF, PPT, PPTX',
      icon: Icons.play_circle_outline_rounded,
      extensions: ['pdf', 'ppt', 'pptx'],
    ),
    _SlotConfig(
      key: 'valuation',
      title: 'Valuation',
      subtitle: 'PDF, XLSX, CSV',
      icon: Icons.bar_chart_rounded,
      extensions: ['pdf', 'xlsx', 'xls', 'csv'],
    ),
    _SlotConfig(
      key: 'comments',
      title: 'Comments / Profile',
      subtitle: 'PDF, DOCX, TXT',
      icon: Icons.chat_bubble_outline_rounded,
      extensions: ['pdf', 'doc', 'docx', 'txt'],
    ),
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────
  PlatformFile? _fileFor(String key) {
    switch (key) {
      case 'pitch':     return _pitchFile;
      case 'valuation': return _valuationFile;
      case 'comments':  return _commentsFile;
    }
    return null;
  }

  bool _uploadedFor(String key) {
    switch (key) {
      case 'pitch':     return _pitchUploaded;
      case 'valuation': return _valuationUploaded;
      case 'comments':  return _commentsUploaded;
    }
    return false;
  }

  bool _uploadingFor(String key) {
    switch (key) {
      case 'pitch':     return _pitchUploading;
      case 'valuation': return _valuationUploading;
      case 'comments':  return _commentsUploading;
    }
    return false;
  }

  // ── Pick file ────────────────────────────────────────────────────────────────
  Future<void> _pick(String key, List<String> ext) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
      withData: kIsWeb,         // bytes required on web
      withReadStream: !kIsWeb,  // stream on mobile/desktop
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    // Guard: web needs bytes, mobile needs path
    if (kIsWeb && file.bytes == null) return;
    if (!kIsWeb && file.path == null) return;

    setState(() {
      switch (key) {
        case 'pitch':
          _pitchFile     = file;
          _pitchUploaded = false;
          break;
        case 'valuation':
          _valuationFile     = file;
          _valuationUploaded = false;
          break;
        case 'comments':
          _commentsFile     = file;
          _commentsUploaded = false;
          break;
      }
    });
    // Auto-upload as soon as a file is selected
    await _upload(key);
  }

  // ── Ensure a MongoDB record exists ──────────────────────────────────────────
  Future<bool> _ensureRecord() async {
    if (_sharedState.recordId != null) return true;
    try {
      final result = await ApiService.createFundRaising(
        company:     _sharedState.pitchDeck.company.isNotEmpty
            ? _sharedState.pitchDeck.company
            : 'Untitled',
        sector:      _sharedState.pitchDeck.sector.isNotEmpty
            ? _sharedState.pitchDeck.sector
            : 'Other',
        fundingGoal: _sharedState.pitchDeck.fundingGoal.isNotEmpty
            ? _sharedState.pitchDeck.fundingGoal
            : '0',
        businessIdea: _sharedState.pitchDeck.businessIdea.isNotEmpty
            ? _sharedState.pitchDeck.businessIdea
            : 'To be determined',
      );
      _sharedState.recordId = result['_id'];
      return true;
    } catch (e) {
      _showSnack('Could not create record: $e', isError: true);
      return false;
    }
  }

  // ── Upload a specific file slot ──────────────────────────────────────────────
  Future<void> _upload(String key) async {
    PlatformFile? file = _fileFor(key);
    if (file == null) return;

    // Set uploading state
    setState(() {
      switch (key) {
        case 'pitch':     _pitchUploading     = true; break;
        case 'valuation': _valuationUploading = true; break;
        case 'comments':  _commentsUploading  = true; break;
      }
    });

    try {
      final ok = await _ensureRecord();
      if (!ok) return;

      final recordId = _sharedState.recordId!;

      // Web: use bytes. Mobile/desktop: use File path.
      final ioFile = kIsWeb ? null : File(file.path!);
      final bytes  = kIsWeb ? file.bytes : null;

      switch (key) {
        case 'pitch':
          final res = await ApiService.uploadPitchDeck(
            recordId: recordId,
            file:     ioFile,
            bytes:    bytes,
            fileName: file.name,
            fields: {
              'company':          _sharedState.pitchDeck.company,
              'sector':           _sharedState.pitchDeck.sector,
              'fundingGoal':      _sharedState.pitchDeck.fundingGoal,
              'askAmount':        _sharedState.pitchDeck.askAmount,
              'businessIdea':     _sharedState.pitchDeck.businessIdea,
              'problemStatement': _sharedState.pitchDeck.problemStatement,
              'solution':         _sharedState.pitchDeck.solution,
            },
          );
          _sharedState.pitchDeck.fileUrl  = res['fileUrl'];
          _sharedState.pitchDeck.fileName = file.name;
          setState(() { _pitchUploaded = true; });
          break;

        case 'valuation':
          final res = await ApiService.uploadValuation(
            recordId: recordId,
            file:     ioFile,
            bytes:    bytes,
            fileName: file.name,
            fields: {
              'requiredFunding':  _sharedState.valuation.requiredFunding,
              'equityOffered':    _sharedState.valuation.equityOffered,
              'currentRevenue':   _sharedState.valuation.currentRevenue,
              'expenses':         _sharedState.valuation.expenses,
              'profitMargin':     _sharedState.valuation.profitMargin,
              'growthRate':       _sharedState.valuation.growthRate,
              'impliedValuation': _sharedState.valuation.impliedValuation,
            },
          );
          _sharedState.valuation.fileUrl  = res['fileUrl'];
          _sharedState.valuation.fileName = file.name;
          setState(() { _valuationUploaded = true; });
          break;

        case 'comments':
          // Comments file is stored as pitch deck supporting doc
          final res = await ApiService.uploadPitchDeck(
            recordId: recordId,
            file:     ioFile,
            bytes:    bytes,
            fileName: file.name,
            fields: {
              'businessBackground': _sharedState.comments.businessBackground,
              'experience':         _sharedState.comments.experience,
              'traction':           _sharedState.comments.traction,
              'futurePlan':         _sharedState.comments.futurePlan,
            },
          );
          _sharedState.pitchDeck.fileUrl  = res['fileUrl'];
          setState(() { _commentsUploaded = true; });
          break;
      }
      _showSnack('${key[0].toUpperCase()}${key.substring(1)} uploaded!');
    } catch (e) {
      _showSnack('Upload failed: $e', isError: true);
    } finally {
      setState(() {
        switch (key) {
          case 'pitch':     _pitchUploading     = false; break;
          case 'valuation': _valuationUploading = false; break;
          case 'comments':  _commentsUploading  = false; break;
        }
      });
    }
  }

  // ── Generate AI Report ───────────────────────────────────────────────────────
  Future<void> _generateReport() async {
    if (!_pitchUploaded && !_valuationUploaded && !_commentsUploaded) {
      _showSnack('Please upload at least one document first.', isError: true);
      return;
    }
    setState(() => _isGenerating = true);
    try {
      // Save comments to MongoDB if record exists
      if (_sharedState.recordId != null &&
          _sharedState.comments.businessBackground.isNotEmpty) {
        await ApiService.updateComments(
          recordId: _sharedState.recordId!,
          businessBackground: _sharedState.comments.businessBackground,
        );
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiConclusionScreen(sharedState: _sharedState),
        ),
      );
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle,
          color: Colors.white, size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 3 : 2),
    ));
  }

  int get _uploadedCount =>
      (_pitchUploaded ? 1 : 0) +
      (_valuationUploaded ? 1 : 0) +
      (_commentsUploaded ? 1 : 0);

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A3A6B),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(child: FaIcon(
                                FontAwesomeIcons.sackDollar,
                                color: Colors.white, size: 24)),
                          ),
                          const SizedBox(height: 12),
                          Text('Fund', style: GoogleFonts.montserrat(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                          Text('Manage funding & investments',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Progress card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Documents Uploaded',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text('$_uploadedCount / 3',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _uploadedCount / 3,
                    backgroundColor: AppTheme.divider,
                    color: const Color(0xFF1A3A6B),
                    minHeight: 8,
                  ),
                ),
              ]),
            ),
          ),

          // ── Upload Documents label ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Upload Documents',
                  style: GoogleFonts.montserrat(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Provide your pitch deck, valuation, and comments for analysis.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ),

          // ── Upload tiles ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _slots.map((slot) => _UploadTile(
                  config: slot,
                  file: _fileFor(slot.key),
                  uploaded: _uploadedFor(slot.key),
                  uploading: _uploadingFor(slot.key),
                  onTap: () => _pick(slot.key, slot.extensions),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomCTA(),
    );
  }



  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.08),
          blurRadius: 20, offset: const Offset(0, -4),
        )],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateReport,
          icon: _isGenerating
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
          label: Text(
            _isGenerating ? 'Generating...' : 'Generate AI Report',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── Upload tile ────────────────────────────────────────────────────────────────
class _UploadTile extends StatelessWidget {
  final _SlotConfig config;
  final PlatformFile? file;
  final bool uploaded;
  final bool uploading;
  final VoidCallback onTap;

  const _UploadTile({
    required this.config,
    required this.file,
    required this.uploaded,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: uploaded
                ? AppTheme.success.withOpacity(0.4)
                : hasFile
                    ? AppTheme.primaryLight.withOpacity(0.35)
                    : AppTheme.divider,
            width: uploaded || hasFile ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: uploaded
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              uploaded ? Icons.check_circle_outline_rounded : config.icon,
              color: uploaded ? AppTheme.success : AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(config.title,
                  style: GoogleFonts.inter(fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(
                hasFile ? file!.name : config.subtitle,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: hasFile && !uploaded
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondary,
                    fontWeight: hasFile ? FontWeight.w500 : FontWeight.w400),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: 10),
          if (uploading)
            const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight)))
          else if (uploaded)
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.success, size: 18),
            )
          else
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(
                hasFile ? Icons.upload_rounded : Icons.insert_drive_file_outlined,
                color: AppTheme.primary, size: 17,
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Slot configuration ────────────────────────────────────────────────────────
class _SlotConfig {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> extensions;

  const _SlotConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.extensions,
  });
}