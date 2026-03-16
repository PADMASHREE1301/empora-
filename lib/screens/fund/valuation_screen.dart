// lib/screens/fund/valuation_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/fund_raising_model.dart';
import '../../services/api_service.dart';

class ValuationScreen extends StatefulWidget {
  final FundRaisingState sharedState;
  const ValuationScreen({super.key, required this.sharedState});

  @override
  State<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fundingCtrl;
  late TextEditingController _equityCtrl;
  late TextEditingController _revenueCtrl;
  late TextEditingController _expensesCtrl;
  late TextEditingController _profitCtrl;
  late TextEditingController _growthCtrl;

  ValuationData get _data => widget.sharedState.valuation;

  bool _calculated  = false;
  bool _isSaving    = false;
  bool _isUploading = false;
  bool _isFileSaved = false;

  // File upload state
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _fundingCtrl  = TextEditingController(text: _data.requiredFunding);
    _equityCtrl   = TextEditingController(text: _data.equityOffered);
    _revenueCtrl  = TextEditingController(text: _data.currentRevenue);
    _expensesCtrl = TextEditingController(text: _data.expenses);
    _profitCtrl   = TextEditingController(text: _data.profitMargin);
    _growthCtrl   = TextEditingController(text: _data.growthRate);
    _calculated   = _data.currentRevenue.isNotEmpty;
    _isFileSaved  = _data.fileUrl != null;
  }

  @override
  void dispose() {
    _fundingCtrl.dispose();
    _equityCtrl.dispose();
    _revenueCtrl.dispose();
    _expensesCtrl.dispose();
    _profitCtrl.dispose();
    _growthCtrl.dispose();
    super.dispose();
  }

  void _syncToModel() {
    _data.requiredFunding  = _fundingCtrl.text.trim();
    _data.equityOffered    = _equityCtrl.text.trim();
    _data.currentRevenue   = _revenueCtrl.text.trim();
    _data.expenses         = _expensesCtrl.text.trim();
    _data.profitMargin     = _profitCtrl.text.trim();
    _data.growthRate       = _growthCtrl.text.trim();
    _data.impliedValuation = _valuation != null ? _valuation!.toStringAsFixed(0) : '';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _syncToModel();
    setState(() => _calculated = true);
  }

  // ── Save text fields to MongoDB ──────────────────────────────────────────
  Future<void> _saveValuation() async {
    if (!_formKey.currentState!.validate()) return;
    _syncToModel();

    final recordId = widget.sharedState.recordId;
    if (recordId == null) {
      _showSnack('Please save Pitch Deck info first.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.updateValuation(
        recordId: recordId,
        fields: {
          'requiredFunding':  _data.requiredFunding,
          'equityOffered':    _data.equityOffered,
          'currentRevenue':   _data.currentRevenue,
          'expenses':         _data.expenses,
          'profitMargin':     _data.profitMargin,
          'growthRate':       _data.growthRate,
          'impliedValuation': _data.impliedValuation,
        },
      );
      _showSnack('Valuation saved successfully!');
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── File picker ──────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // Word (.doc/.docx) and Excel (.xls/.xlsx) only
      allowedExtensions: ['doc', 'docx', 'xls', 'xlsx'],
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

  // ── Upload file to MongoDB ───────────────────────────────────────────────
  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    final recordId = widget.sharedState.recordId;
    if (recordId == null) {
      _showSnack('Please save Pitch Deck info first.', isError: true);
      return;
    }

    // Validate file type
    final ext = _selectedFile!.name.split('.').last.toLowerCase();
    if (!['doc', 'docx', 'xls', 'xlsx'].contains(ext)) {
      _showSnack(
        'Invalid file format. Only Word (.doc/.docx) and Excel (.xls/.xlsx) are allowed.',
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      _syncToModel();
      final response = await ApiService.uploadValuation(
        recordId: recordId,
        file:  kIsWeb ? null : File(_selectedFile!.path!),
        bytes: kIsWeb ? _selectedFile!.bytes : null,
        fileName: _selectedFile!.name,
        fields: {
          'requiredFunding':  _data.requiredFunding,
          'equityOffered':    _data.equityOffered,
          'currentRevenue':   _data.currentRevenue,
          'expenses':         _data.expenses,
          'profitMargin':     _data.profitMargin,
          'growthRate':       _data.growthRate,
          'impliedValuation': _data.impliedValuation,
        },
      );
      _data.fileUrl  = response['fileUrl'];
      _data.fileName = _selectedFile!.name;
      setState(() {
        _isFileSaved  = true;
        _isUploading  = false;
      });
      _showSnack('Valuation file uploaded successfully!');
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack('Upload failed: $e', isError: true);
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
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        ),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  double? get _revenueVal  => double.tryParse(_revenueCtrl.text);
  double? get _growthVal   => double.tryParse(_growthCtrl.text);
  double? get _expensesVal => double.tryParse(_expensesCtrl.text);
  double? get _equityVal   => double.tryParse(_equityCtrl.text);

  int get _multiple {
    final g = _growthVal ?? 0;
    return g > 50 ? 10 : g > 20 ? 7 : 5;
  }

  double? get _valuation {
    if (_revenueVal == null || _growthVal == null) return null;
    return _revenueVal! * _multiple;
  }

  double? get _impliedEquity {
    if (_valuation == null || _equityVal == null) return null;
    return _valuation! * (_equityVal! / 100);
  }

  double? get _netProfit {
    if (_revenueVal == null || _expensesVal == null) return null;
    return _revenueVal! - _expensesVal!;
  }

  String _fmt(double? v) {
    if (v == null) return '--';
    if (v.abs() >= 1000000) return '\$${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2756A8),
            leading: GestureDetector(
              onTap: () {
                _syncToModel();
                Navigator.pop(context);
              },
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
                    colors: [Color(0xFF1A3A6B), Color(0xFF2756A8), Color(0xFF00A8E8)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
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
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(Icons.show_chart,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Valuation',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  Text('Financial analysis & funding terms',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70)),
                                ],
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result card (shown after calculation)
                    if (_calculated && _valuation != null) ...[
                      _buildResultCard(),
                      const SizedBox(height: 20),
                    ],

                    _buildFormCard(
                      title: 'Funding Requirements',
                      icon: Icons.monetization_on_outlined,
                      color: const Color(0xFF2756A8),
                      children: [
                        _buildRow(
                          child1: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Required Funding (USD)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fundingCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '2000000',
                                  prefixIcon: Icon(Icons.attach_money,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                          child2: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Equity Offered (%)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _equityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '15',
                                  prefixIcon: Icon(Icons.pie_chart_outline,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0 || n > 100) return '1–100';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFormCard(
                      title: 'Financial Metrics',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF2756A8),
                      children: [
                        _buildRow(
                          child1: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Annual Revenue (USD)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _revenueCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '1000000',
                                  prefixIcon: Icon(Icons.trending_up,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          child2: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Annual Expenses (USD)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _expensesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '600000',
                                  prefixIcon: Icon(Icons.trending_down,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildRow(
                          child1: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Profit Margin (%)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _profitCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '40',
                                  prefixIcon: Icon(Icons.percent,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                              ),
                            ],
                          ),
                          child2: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Annual Growth Rate (%)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _growthCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '35',
                                  prefixIcon: Icon(Icons.rocket_launch_outlined,
                                      color: AppTheme.textSecondary, size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calculate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined, color: Colors.white),
                        label: Text('Calculate Valuation',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2756A8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Save to MongoDB button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveValuation,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                            _isSaving ? 'Saving...' : 'Save Valuation to Database',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── File Upload Card ────────────────────────────────────
                    _buildFileUploadCard(),

                    const SizedBox(height: 16),
                    _buildMethodCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── File Upload Card (Word / Excel) ────────────────────────────────────────
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
              ? AppTheme.success.withOpacity(0.4)
              : const Color(0xFF2756A8).withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2756A8).withOpacity(0.06),
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
              color: const Color(0xFF2756A8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.upload_file,
                color: Color(0xFF2756A8), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Upload Valuation Document',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('Word (.doc/.docx) or Excel (.xls/.xlsx) · Max 20 MB',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ),
          if (_isFileSaved)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
        ]),
        const SizedBox(height: 14),

        if (hasFile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2756A8).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2756A8).withOpacity(0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.description_outlined,
                  color: Color(0xFF2756A8), size: 22),
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
                            fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedFile = null;
                  _isFileSaved  = false;
                  _data.fileUrl  = null;
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
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(children: [
                Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.textSecondary.withOpacity(0.5), size: 36),
                const SizedBox(height: 8),
                Text('Tap to select file',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textSecondary)),
                Text('Word or Excel document',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.6))),
              ]),
            ),
          ),

        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_outlined,
                  size: 16, color: Color(0xFF2756A8)),
              label: Text(hasFile ? 'Change File' : 'Browse',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2756A8))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2756A8), width: 1.5),
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
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload, size: 16, color: Colors.white),
                label: Text(
                    _isUploading ? 'Uploading...' : 'Upload to MongoDB',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2756A8),
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

  Widget _buildResultCard() {
    final valStr    = _fmt(_valuation);
    final equityStr = _fmt(_impliedEquity);
    final netStr    = _fmt(_netProfit);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A6B), Color(0xFF2756A8), Color(0xFF00A8E8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2756A8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.auto_graph, color: Colors.white60, size: 16),
          const SizedBox(width: 6),
          Text('Estimated Company Valuation',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(valStr,
            style: GoogleFonts.montserrat(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('Using ${_multiple}x Revenue Multiple',
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 20),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          _ResultChip(label: 'Equity Value', value: equityStr, icon: Icons.pie_chart_outline),
          const SizedBox(width: 12),
          _ResultChip(label: 'Net Profit', value: netStr, icon: Icons.account_balance_outlined),
        ]),
      ]),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
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

  Widget _buildMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2756A8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.info_outline, color: Color(0xFF2756A8), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Revenue Multiple Method',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 13)),
            const SizedBox(height: 6),
            _methodRow('Growth > 50%', '10× revenue multiple'),
            _methodRow('Growth 20–50%', '7× revenue multiple'),
            _methodRow('Growth < 20%', '5× revenue multiple'),
          ]),
        ),
      ]),
    );
  }

  Widget _methodRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Container(
          width: 4, height: 4,
          decoration: const BoxDecoration(
              color: Color(0xFF2756A8), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label → ',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildRow({required Widget child1, required Widget child2}) {
    return Row(children: [
      Expanded(child: child1),
      const SizedBox(width: 12),
      Expanded(child: child2),
    ]);
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}

class _ResultChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ResultChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ]),
      ),
    );
  }
}