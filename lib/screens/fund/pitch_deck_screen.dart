// lib/screens/fund/pitch_deck_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/fund_raising_model.dart';
import '../../services/api_service.dart';

class PitchDeckScreen extends StatefulWidget {
  final FundRaisingState sharedState;
  const PitchDeckScreen({super.key, required this.sharedState});

  @override
  State<PitchDeckScreen> createState() => _PitchDeckScreenState();
}

class _PitchDeckScreenState extends State<PitchDeckScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyCtrl;
  late TextEditingController _fundingGoalCtrl;
  late TextEditingController _businessIdeaCtrl;
  late TextEditingController _problemCtrl;
  late TextEditingController _solutionCtrl;
  late TextEditingController _marketCtrl;
  late TextEditingController _revenueModelCtrl;
  late TextEditingController _teamCtrl;
  late TextEditingController _askCtrl;

  PitchDeckData get _data => widget.sharedState.pitchDeck;

  static const List<String> _sectors = [
    'FinTech', 'HealthTech', 'EdTech', 'AgriTech', 'CleanTech',
    'E-Commerce', 'SaaS', 'AI/ML', 'Logistics', 'Manufacturing', 'Other',
  ];
  String? _selectedSector;

  // File upload state
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isFileSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _companyCtrl     = TextEditingController(text: _data.company);
    _fundingGoalCtrl = TextEditingController(text: _data.fundingGoal);
    _businessIdeaCtrl = TextEditingController(text: _data.businessIdea);
    _problemCtrl     = TextEditingController(text: _data.problemStatement);
    _solutionCtrl    = TextEditingController(text: _data.solution);
    _marketCtrl      = TextEditingController(text: _data.marketSize);
    _revenueModelCtrl = TextEditingController(text: _data.revenueModel);
    _teamCtrl        = TextEditingController(text: _data.teamDetails);
    _askCtrl         = TextEditingController(text: _data.askAmount);
    _selectedSector  = _data.sector.isNotEmpty ? _data.sector : null;
    _isFileSaved     = _data.fileUrl != null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyCtrl.dispose();
    _fundingGoalCtrl.dispose();
    _businessIdeaCtrl.dispose();
    _problemCtrl.dispose();
    _solutionCtrl.dispose();
    _marketCtrl.dispose();
    _revenueModelCtrl.dispose();
    _teamCtrl.dispose();
    _askCtrl.dispose();
    super.dispose();
  }

  void _syncToModel() {
    _data.company          = _companyCtrl.text.trim();
    _data.fundingGoal      = _fundingGoalCtrl.text.trim();
    _data.sector           = _selectedSector ?? '';
    _data.businessIdea     = _businessIdeaCtrl.text.trim();
    _data.problemStatement = _problemCtrl.text.trim();
    _data.solution         = _solutionCtrl.text.trim();
    _data.marketSize       = _marketCtrl.text.trim();
    _data.revenueModel     = _revenueModelCtrl.text.trim();
    _data.teamDetails      = _teamCtrl.text.trim();
    _data.askAmount        = _askCtrl.text.trim();
  }

  // ── File picker ─────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
      withData: false,
      withReadStream: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _isFileSaved  = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    final recordId = widget.sharedState.recordId;
    if (recordId == null) {
      _showSnack('Please save company info first.', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final response = await ApiService.uploadPitchDeck(
        recordId: recordId,
        file:  kIsWeb ? null : File(_selectedFile!.path!),
        bytes: kIsWeb ? _selectedFile!.bytes : null,
        fileName: _selectedFile!.name,
        fields: {
          'company':          _data.company,
          'sector':           _data.sector,
          'fundingGoal':      _data.fundingGoal,
          'askAmount':        _data.askAmount,
          'businessIdea':     _data.businessIdea,
          'problemStatement': _data.problemStatement,
          'solution':         _data.solution,
          'marketSize':       _data.marketSize,
          'revenueModel':     _data.revenueModel,
          'teamDetails':      _data.teamDetails,
        },
      );
      _data.fileUrl  = response['fileUrl'];
      _data.fileName = _selectedFile!.name;
      setState(() {
        _isFileSaved  = true;
        _isUploading  = false;
      });
      _showSnack('Pitch deck uploaded & saved!');
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack('Upload failed: $e', isError: true);
    }
  }

  // ── Save text-only (no file) ────────────────────────────────────────────────
  Future<void> _saveCompanyInfo() async {
    if (!_formKey.currentState!.validate()) return;
    _syncToModel();

    final recordId = widget.sharedState.recordId;

    try {
      if (recordId == null) {
        // First save → create record on backend
        final result = await ApiService.createFundRaising(
          company:          _data.company,
          sector:           _data.sector,
          fundingGoal:      _data.fundingGoal,
          askAmount:        _data.askAmount,
          businessIdea:     _data.businessIdea,
          problemStatement: _data.problemStatement,
          solution:         _data.solution,
        );
        widget.sharedState.recordId = result['_id'];
      } else {
        await ApiService.updatePitchDeck(recordId: recordId, fields: {
          'company':          _data.company,
          'sector':           _data.sector,
          'fundingGoal':      _data.fundingGoal,
          'askAmount':        _data.askAmount,
          'businessIdea':     _data.businessIdea,
          'problemStatement': _data.problemStatement,
          'solution':         _data.solution,
          'marketSize':       _data.marketSize,
          'revenueModel':     _data.revenueModel,
          'teamDetails':      _data.teamDetails,
        });
      }
      setState(() {});
      _showSnack('Company info saved!');
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 3 : 2),
    ));
  }

  void _savePitchSection({required VoidCallback onSave}) {
    _syncToModel();
    setState(onSave);
    _showSnack('Section saved!');
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A3A6B),
            leading: GestureDetector(
              onTap: () {
                _syncToModel();
                Navigator.pop(context);
              },
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentGold,
              indicatorWeight: 3,
              labelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Company Info'),
                Tab(text: 'Pitch Sections'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCompanyInfoTab(),
            _buildPitchSectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1F3C), Color(0xFF1A3A6B), Color(0xFF2756A8)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: -30, right: -30,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.present_to_all,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pitch Deck',
                          style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Build your investor pitch',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  )),
                  _CompletionRing(
                    percent: _data.completionPercent,
                    completed: _data.completedSections,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Tab 1: Company Info ──────────────────────────────────────────────────────
  Widget _buildCompanyInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionCard(
            title: 'Company Details',
            icon: Icons.business_outlined,
            children: [
              _label('Company Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. TechVenture Inc.',
                  prefixIcon:
                      Icon(Icons.apartment, color: AppTheme.textSecondary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _label('Sector *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSector,
                decoration: InputDecoration(
                  hintText: 'Select sector',
                  hintStyle: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.divider, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.divider, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _sectors
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSector = v),
                validator: (v) => v == null ? 'Select a sector' : null,
              ),
              const SizedBox(height: 16),
              _label('Funding Goal (USD) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fundingGoalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 2000000',
                  prefixIcon: Icon(Icons.attach_money,
                      color: AppTheme.textSecondary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _label('Ask Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _askCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 500000',
                  prefixIcon: Icon(Icons.request_quote_outlined,
                      color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Business Overview',
            icon: Icons.lightbulb_outline,
            children: [
              _label('Business Idea / Executive Summary'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessIdeaCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your startup idea in 2–3 sentences...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── File Upload Card ───────────────────────────────────────────────
          _buildFileUploadCard(),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveCompanyInfo,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: Text('Save Company Info',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── File Upload Card ─────────────────────────────────────────────────────────
  Widget _buildFileUploadCard() {
    final hasFile = _selectedFile != null || _data.fileUrl != null;
    final fileName = _selectedFile?.name ?? _data.fileName ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isFileSaved
              ? AppTheme.success.withValues(alpha: 0.4)
              : const Color(0xFF1A3A6B).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.upload_file,
                color: Color(0xFF1A3A6B), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Upload Pitch Deck File',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('PDF, PPT, or PPTX · Max 20 MB',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ),
          if (_isFileSaved)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
        ]),
        const SizedBox(height: 14),

        // File info or placeholder
        if (hasFile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1A3A6B).withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.description_outlined,
                  color: Color(0xFF1A3A6B), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(fileName,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  if (_selectedFile?.size != null)
                    Text(
                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                ]),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() {
                      _selectedFile = null;
                      _isFileSaved  = false;
                      _data.fileUrl = null;
                      _data.fileName = null;
                    }),
                child: const Icon(Icons.close,
                    color: AppTheme.textSecondary, size: 18),
              ),
            ]),
          )
        else
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.divider, style: BorderStyle.solid),
              ),
              child: Column(children: [
                Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 36),
                const SizedBox(height: 8),
                Text('Tap to select file',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textSecondary)),
                Text('PDF, PPT, PPTX',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6))),
              ]),
            ),
          ),

        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_outlined,
                  size: 16, color: Color(0xFF1A3A6B)),
              label: Text(hasFile ? 'Change File' : 'Browse',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A3A6B))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF1A3A6B), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_selectedFile != null && !_isFileSaved) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload,
                        size: 16, color: Colors.white),
                label: Text(
                    _isUploading ? 'Uploading...' : 'Upload to MongoDB',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A6B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  // ── Tab 2: Pitch Sections ────────────────────────────────────────────────────
  Widget _buildPitchSectionsTab() {
    final sections = [
      _PitchSection(
        number: '01', title: 'Problem Statement',
        hint: 'What pain point does your startup solve?',
        controller: _problemCtrl, isDone: _data.isProblemDone,
        onMark: (done) {
          if (_problemCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isProblemDone = done;
              _data.problemStatement = _problemCtrl.text.trim();
            });
          }
        },
      ),
      _PitchSection(
        number: '02', title: 'Solution',
        hint: 'How does your product/service solve the problem?',
        controller: _solutionCtrl, isDone: _data.isSolutionDone,
        onMark: (done) {
          if (_solutionCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isSolutionDone = done;
              _data.solution = _solutionCtrl.text.trim();
            });
          }
        },
      ),
      _PitchSection(
        number: '03', title: 'Market Size',
        hint: 'TAM, SAM, SOM — quantify your market opportunity',
        controller: _marketCtrl, isDone: _data.isMarketDone,
        onMark: (done) {
          if (_marketCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isMarketDone = done;
              _data.marketSize = _marketCtrl.text.trim();
            });
          }
        },
      ),
      _PitchSection(
        number: '04', title: 'Business Model',
        hint: 'How do you make money? Revenue streams, pricing, etc.',
        controller: _revenueModelCtrl, isDone: _data.isModelDone,
        onMark: (done) {
          if (_revenueModelCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isModelDone = done;
              _data.revenueModel = _revenueModelCtrl.text.trim();
            });
          }
        },
      ),
      _PitchSection(
        number: '05', title: 'Traction',
        hint: 'Key metrics, customers, revenue, partnerships to date',
        controller: TextEditingController(),
        isDone: _data.isTractionDone,
        onMark: (done) => setState(() => _data.isTractionDone = done),
      ),
      _PitchSection(
        number: '06', title: 'Team',
        hint: 'Founders, key hires, advisors, relevant experience',
        controller: _teamCtrl, isDone: _data.isTeamDone,
        onMark: (done) {
          if (_teamCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isTeamDone = done;
              _data.teamDetails = _teamCtrl.text.trim();
            });
          }
        },
      ),
      _PitchSection(
        number: '07', title: 'Financials',
        hint: '3-year projections, burn rate, unit economics',
        controller: TextEditingController(),
        isDone: _data.isFinancialsDone,
        onMark: (done) => setState(() => _data.isFinancialsDone = done),
      ),
      _PitchSection(
        number: '08', title: 'The Ask',
        hint: 'How much are you raising? What milestones will it fund?',
        controller: _askCtrl, isDone: _data.isAskDone,
        onMark: (done) {
          if (_askCtrl.text.trim().isNotEmpty) {
            _savePitchSection(onSave: () {
              _data.isAskDone = done;
              _data.askAmount = _askCtrl.text.trim();
            });
          }
        },
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 1,
      itemBuilder: (context, i) {
        if (i == sections.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 8),
            child: _ProgressSummaryCard(data: _data),
          );
        }
        return _PitchSectionCard(section: sections[i]);
      },
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1A3A6B), size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));
}

// ── Data class ───────────────────────────────────────────────────────────────
class _PitchSection {
  final String number, title, hint;
  final TextEditingController controller;
  final bool isDone;
  final Function(bool) onMark;
  const _PitchSection({
    required this.number, required this.title, required this.hint,
    required this.controller, required this.isDone, required this.onMark,
  });
}

// ── Expandable card ──────────────────────────────────────────────────────────
class _PitchSectionCard extends StatefulWidget {
  final _PitchSection section;
  // ignore: unused_element_parameter
  const _PitchSectionCard({super.key, required this.section});
  @override
  State<_PitchSectionCard> createState() => _PitchSectionCardState();
}

class _PitchSectionCardState extends State<_PitchSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: s.isDone
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.divider,
          width: s.isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: s.isDone
                ? AppTheme.success.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: s.isDone
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : const Color(0xFF1A3A6B).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(s.number,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.isDone
                              ? AppTheme.success
                              : const Color(0xFF1A3A6B))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(s.title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary))),
              GestureDetector(
                onTap: () => s.onMark(!s.isDone),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    s.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(s.isDone),
                    color: s.isDone
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppTheme.textSecondary, size: 20,
              ),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, color: AppTheme.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [
              TextField(
                controller: s.controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: s.hint,
                  hintStyle: GoogleFonts.inter(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.divider)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A3A6B), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (s.controller.text.trim().isNotEmpty) {
                      s.onMark(true);
                      setState(() => _expanded = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A6B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Mark as Done',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Completion ring ──────────────────────────────────────────────────────────
class _CompletionRing extends StatelessWidget {
  final double percent;
  final int completed;
  const _CompletionRing({required this.percent, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(
          value: percent,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
          strokeWidth: 4,
        ),
        Text('$completed/8',
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    );
  }
}

// ── Progress summary ─────────────────────────────────────────────────────────
class _ProgressSummaryCard extends StatelessWidget {
  final PitchDeckData data;
  const _ProgressSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = (data.completionPercent * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A6B).withValues(alpha: 0.08),
            const Color(0xFF2756A8).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFF1A3A6B).withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$pct%',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A3A6B))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pitch Deck Progress',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: data.completionPercent,
                backgroundColor: AppTheme.divider,
                color: pct == 100 ? AppTheme.success : const Color(0xFF1A3A6B),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 4),
            Text('${data.completedSections}/8 sections completed',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        )),
      ]),
    );
  }
}