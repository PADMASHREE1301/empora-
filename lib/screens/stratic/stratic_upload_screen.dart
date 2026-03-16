// lib/screens/stratic/stratic_upload_screen.dart
//
// Uses the new /api/stratic endpoint — data is now stored in its own
// MongoDB 'stratics' collection instead of inside 'fundraisings'.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/stratic_model.dart';
import '../../services/api_service.dart';

class StraticUploadScreen extends StatefulWidget {
  final String          title;
  final String          subtitle;
  final String          hint;
  final Color           color;
  final IconData        icon;
  final ModuleFileSlot  slot;
  final StraticState    state;

  const StraticUploadScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.color,
    required this.icon,
    required this.slot,
    required this.state,
  });

  @override
  State<StraticUploadScreen> createState() => _StraticUploadScreenState();
}

class _StraticUploadScreenState extends State<StraticUploadScreen> {
  bool _isUploading = false;
  bool _isUploaded  = false;

  @override
  void initState() {
    super.initState();
    _isUploaded = widget.slot.isUploaded;
  }

  // ── Ensure a stratic record exists in MongoDB ──────────────────────────────
  Future<bool> _ensureRecord() async {
    if (widget.state.recordId != null) return true;
    try {
      // Creates a new record in the 'stratics' collection
      final result = await ApiService.createModuleRecord(module: 'stratic');
      widget.state.recordId = result['_id'] as String?;
      return true;
    } catch (e) {
      _snack('Failed to create record: $e', error: true);
      return false;
    }
  }

  // ── Pick + upload ──────────────────────────────────────────────────────────
  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xlsx', 'xls', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() => _isUploading = true);

    try {
      final ok = await _ensureRecord();
      if (!ok) return;

      // Uploads to /api/stratic/:id/upload → saved in 'stratics' collection
      await ApiService.uploadModuleFile(
        module:   'stratic',
        recordId: widget.state.recordId!,
        slotKey:  widget.slot.key,
        file:     kIsWeb ? null : File(file.path!),
        bytes:    kIsWeb ? file.bytes : null,
        fileName: file.name,
      );

      widget.slot
        ..fileName   = file.name
        ..isUploaded = true;

      setState(() => _isUploaded = true);
      _snack('${widget.title} document uploaded!');
    } catch (e) {
      _snack('Upload failed: $e', error: true);
    } finally {
      setState(() => _isUploading = false);
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
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _hintCard(),
                  const SizedBox(height: 20),
                  _uploadTile(),
                  const SizedBox(height: 28),
                  _continueBtn(),
                  if (_isUploaded) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isUploading ? null : _pick,
                      child: Text(
                        'Replace with a different file',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: widget.color,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.color.withOpacity(0.85), widget.color],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 10),
                Text(widget.title,
                    style: GoogleFonts.montserrat(
                        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(widget.subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white.withOpacity(0.72))),
              ],
            ),
          ),
        ),
      );

  Widget _hintCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.color.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lightbulb_outline_rounded, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What to include',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w700, color: widget.color)),
                  const SizedBox(height: 4),
                  Text(widget.hint,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _uploadTile() {
    final fileName = widget.slot.fileName;
    return GestureDetector(
      onTap: _isUploading ? null : _pick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUploaded
                ? AppTheme.success.withOpacity(0.5)
                : fileName != null
                    ? widget.color.withOpacity(0.4)
                    : AppTheme.divider,
            width: _isUploaded || fileName != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.07),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _isUploaded
                    ? AppTheme.success.withOpacity(0.1)
                    : widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: _isUploading
                  ? Padding(
                      padding: const EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    )
                  : Icon(
                      _isUploaded
                          ? Icons.check_circle_outline_rounded
                          : fileName != null
                              ? Icons.insert_drive_file_rounded
                              : Icons.upload_file_rounded,
                      color: _isUploaded ? AppTheme.success : widget.color,
                      size: 26,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'Tap to upload document',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isUploaded
                        ? 'Saved to stratics collection ✓'
                        : _isUploading
                            ? 'Uploading...'
                            : 'PDF, DOCX, PPTX, XLSX, TXT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _isUploaded
                          ? AppTheme.success
                          : _isUploading
                              ? widget.color
                              : AppTheme.textSecondary,
                      fontWeight: _isUploaded ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isUploading)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _isUploaded
                      ? AppTheme.success.withOpacity(0.12)
                      : widget.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _isUploaded ? Icons.check_rounded : Icons.add_rounded,
                  color: _isUploaded ? AppTheme.success : widget.color,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _continueBtn() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isUploaded ? () => Navigator.pop(context) : null,
          icon: Icon(
            _isUploaded ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
            color: Colors.white, size: 18,
          ),
          label: Text(
            _isUploaded ? 'Continue' : 'Upload a file to continue',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isUploaded ? widget.color : widget.color.withOpacity(0.35),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
}