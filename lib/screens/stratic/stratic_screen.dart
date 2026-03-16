// lib/screens/stratic/stratic_screen.dart
//
// ALL-IN-ONE: upload all 7 documents from a single screen.
// Each slot expands inline — no separate upload screen needed.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/stratic_model.dart';
import '../../services/api_service.dart';
import 'stratic_conclusion_screen.dart';

class StraticScreen extends StatefulWidget {
  const StraticScreen({super.key});
  @override
  State<StraticScreen> createState() => _StraticScreenState();
}

class _StraticScreenState extends State<StraticScreen>
    with TickerProviderStateMixin {

  final StraticState _state = StraticState();
  String? _expandedKey;
  final Map<String, bool> _uploading = {};

  static const Color _blue     = Color(0xFF1A3A6B);
  static const Color _blueDark = Color(0xFF0D2040);

  static const List<_Cfg> _slots = [
    _Cfg(key: 'team',        label: 'Team',          shortLabel: 'Team',
        hint: 'Upload team org chart, bios, LinkedIn profiles, org structure doc',
        icon: FontAwesomeIcons.peopleGroup,
        color: Color(0xFF1A3A6B), light: Color(0xFFE8EDF8)),
    _Cfg(key: 'businessDev', label: 'Business Dev',  shortLabel: 'Biz Dev',
        hint: 'Upload business plan, product roadmap, pitch deck, vision document',
        icon: FontAwesomeIcons.codeBranch,
        color: Color(0xFF2756A8), light: Color(0xFFEAF0FA)),
    _Cfg(key: 'risk',        label: 'Risk',          shortLabel: 'Risk',
        hint: 'Upload risk register, SWOT analysis, risk mitigation plan',
        icon: FontAwesomeIcons.shieldHalved,
        color: Color(0xFFC0392B), light: Color(0xFFFAEAE8)),
    _Cfg(key: 'operation',   label: 'Operation',     shortLabel: 'Ops',
        hint: 'Upload operations manual, process flows, KPI dashboard, resource plan',
        icon: FontAwesomeIcons.gears,
        color: Color(0xFF0D6E8A), light: Color(0xFFE6F4F8)),
    _Cfg(key: 'policy',      label: 'Policy',        shortLabel: 'Policy',
        hint: 'Upload compliance docs, regulatory filings, internal policy handbook',
        icon: FontAwesomeIcons.fileContract,
        color: Color(0xFF7B3F00), light: Color(0xFFF7EDE4)),
    _Cfg(key: 'challenges',  label: 'Challenges',    shortLabel: 'Challng.',
        hint: 'Upload challenge report, problem analysis, proposed solutions doc',
        icon: FontAwesomeIcons.triangleExclamation,
        color: Color(0xFFE67E22), light: Color(0xFFFEF0E4)),
    _Cfg(key: 'profile',     label: 'Profile',       shortLabel: 'Profile',
        hint: 'Upload company profile, about us, brochure, registration docs',
        icon: FontAwesomeIcons.buildingUser,
        color: Color(0xFF2E7D32), light: Color(0xFFE8F5E9)),
  ];

  ModuleFileSlot _slotFor(String key) {
    switch (key) {
      case 'team':        return _state.team;
      case 'businessDev': return _state.businessDev;
      case 'risk':        return _state.risk;
      case 'operation':   return _state.operation;
      case 'policy':      return _state.policy;
      case 'challenges':  return _state.challenges;
      case 'profile':     return _state.profile;
      default:            return ModuleFileSlot(key: key);
    }
  }

  Future<bool> _ensureRecord() async {
    if (_state.recordId != null) return true;
    try {
      final r = await ApiService.createModuleRecord(module: 'stratic');
      _state.recordId = r['_id'] as String?;
      return true;
    } catch (e) {
      _snack('Error creating record: $e', error: true);
      return false;
    }
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xlsx', 'txt', 'jpg', 'png'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() => _uploading[key] = true);
    try {
      if (!await _ensureRecord()) return;
      await ApiService.uploadModuleFile(
        module:   'stratic',
        recordId: _state.recordId!,
        slotKey:  key,
        file:     kIsWeb ? null : File(file.path!),
        bytes:    kIsWeb ? file.bytes : null,
        fileName: file.name,
      );
      final slot = _slotFor(key);
      slot.fileName   = file.name;
      slot.isUploaded = true;
      final currentIndex = _slots.indexWhere((s) => s.key == key);
      final nextEmpty = _slots.skip(currentIndex + 1)
          .firstWhere((s) => !_slotFor(s.key).isUploaded,
              orElse: () => _slots.first);
      setState(() {
        _uploading[key] = false;
        _expandedKey = nextEmpty.key == key ? null : nextEmpty.key;
      });
      _snack('${_slots.firstWhere((s) => s.key == key).label} uploaded ✓');
    } catch (e) {
      setState(() => _uploading[key] = false);
      _snack('Upload failed: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  int get _uploadedCount => _state.uploadedCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(slivers: [

        // ── App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          elevation: 0,
          backgroundColor: _blueDark,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_blueDark, _blue],
                ),
              ),
              child: Stack(children: [
                Positioned(top: -40, right: -40,
                    child: Container(width: 220, height: 220,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05)))),
                Positioned(bottom: 10, right: 20,
                    child: Text('7 DOCS',
                        style: GoogleFonts.montserrat(
                            fontSize: 42, fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.07)))),
                SafeArea(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: FaIcon(
                            FontAwesomeIcons.chartLine,
                            color: Colors.white, size: 22)),
                      ),
                      const SizedBox(height: 10),
                      Text('Strategic Planning',
                          style: GoogleFonts.montserrat(
                              fontSize: 26, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Upload all documents here — no back & forth',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                )),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(child: _progressStrip()),

        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: _blue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withOpacity(0.18))),
            child: Row(children: [
              Icon(Icons.touch_app_rounded, color: _blue, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Tap any document to expand and upload — all in one place',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _blueDark, fontWeight: FontWeight.w500),
              )),
            ]),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              List.generate(_slots.length, (i) {
                final cfg        = _slots[i];
                final slot       = _slotFor(cfg.key);
                final isExpanded = _expandedKey == cfg.key;
                final isUploading = _uploading[cfg.key] == true;
                return _SlotCard(
                  index:       i + 1,
                  cfg:         cfg,
                  slot:        slot,
                  isExpanded:  isExpanded,
                  isUploading: isUploading,
                  onTap: () => setState(() =>
                      _expandedKey = isExpanded ? null : cfg.key),
                  onUpload:  () => _pickFile(cfg.key),
                  onReplace: () => _pickFile(cfg.key),
                );
              }),
            ),
          ),
        ),
      ]),
      bottomSheet: _bottomCta(),
    );
  }

  Widget _progressStrip() {
    final count = _uploadedCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3EE)),
        boxShadow: [BoxShadow(
            color: _blue.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Documents Uploaded',
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text('$count / 7',
                key: ValueKey(count),
                style: GoogleFonts.montserrat(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: count == 7 ? AppTheme.success : _blue)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: List.generate(7, (i) {
          final cfg    = _slots[i];
          final done   = _slotFor(cfg.key).isUploaded;
          final active = _expandedKey == cfg.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() =>
                  _expandedKey = active ? null : cfg.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
                height: 8,
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.success
                      : active ? cfg.color : const Color(0xFFDDE3EE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        })),
        const SizedBox(height: 8),
        Row(children: List.generate(7, (i) {
          final cfg  = _slots[i];
          final done = _slotFor(cfg.key).isUploaded;
          return Expanded(
            child: Text(cfg.shortLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 8,
                    color: done ? AppTheme.success : const Color(0xFF9EA8B8),
                    fontWeight: done ? FontWeight.w700 : FontWeight.w400),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        })),
      ]),
    );
  }

  Widget _bottomCta() {
    final count = _uploadedCount;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: _blue.withOpacity(0.1),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (count > 0 && count < 7) ...[
          Text('$count of 7 uploaded — you can still generate the report',
              style: GoogleFonts.inter(
                  fontSize: 11, color: _blue, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StraticConclusionScreen(state: _state)));
              setState(() {});
            },
            icon: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
            label: Text(
              count == 7
                  ? 'Generate AI Strategy Report'
                  : count == 0
                      ? 'Generate AI Strategy Report'
                      : 'Generate with $count / 7 docs',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: count == 7 ? _blueDark : _blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Reusable slot card ─────────────────────────────────────────────────────────
class _SlotCard extends StatelessWidget {
  final int            index;
  final _Cfg           cfg;
  final ModuleFileSlot slot;
  final bool           isExpanded;
  final bool           isUploading;
  final VoidCallback   onTap;
  final VoidCallback   onUpload;
  final VoidCallback   onReplace;

  const _SlotCard({
    required this.index,
    required this.cfg,
    required this.slot,
    required this.isExpanded,
    required this.isUploading,
    required this.onTap,
    required this.onUpload,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final done = slot.isUploaded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppTheme.success.withOpacity(0.45)
              : isExpanded
                  ? cfg.color.withOpacity(0.5)
                  : const Color(0xFFDDE3EE),
          width: done || isExpanded ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(
          color: (done ? AppTheme.success : cfg.color)
              .withOpacity(isExpanded ? 0.1 : 0.04),
          blurRadius: isExpanded ? 14 : 6,
          offset: const Offset(0, 3),
        )],
      ),
      child: Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.success.withOpacity(0.12)
                      : isExpanded
                          ? cfg.color.withOpacity(0.12)
                          : cfg.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: done
                      ? Icon(Icons.check_rounded,
                          color: AppTheme.success, size: 20)
                      : isUploading
                          ? SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: cfg.color))
                          : FaIcon(cfg.icon,
                              color: isExpanded
                                  ? cfg.color
                                  : cfg.color.withOpacity(0.7),
                              size: 17),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: done
                            ? AppTheme.success.withOpacity(0.1)
                            : cfg.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(child: Text('$index',
                          style: GoogleFonts.montserrat(
                              fontSize: 9, fontWeight: FontWeight.w800,
                              color: done ? AppTheme.success : cfg.color))),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(cfg.label,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    done
                        ? slot.fileName ?? 'Uploaded ✓'
                        : isUploading
                            ? 'Uploading...'
                            : 'PDF, DOCX, TXT — tap to upload',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: done
                            ? AppTheme.success
                            : isUploading
                                ? cfg.color
                                : const Color(0xFF9EA8B8),
                        fontWeight:
                            done ? FontWeight.w600 : FontWeight.w400),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              )),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: done
                        ? AppTheme.success.withOpacity(0.1)
                        : isExpanded
                            ? cfg.color.withOpacity(0.1)
                            : const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: done ? AppTheme.success : cfg.color,
                    size: 18,
                  ),
                ),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Column(children: [
                  Divider(height: 1, color: cfg.color.withOpacity(0.15)),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: cfg.light,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: cfg.color, size: 15),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cfg.hint,
                          style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF555555),
                              height: 1.55))),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: isUploading
                          ? Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: cfg.color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cfg.color)),
                                const SizedBox(width: 10),
                                Text('Uploading...',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: cfg.color,
                                        fontWeight: FontWeight.w600)),
                              ]))
                          : done
                              ? OutlinedButton.icon(
                                  onPressed: onReplace,
                                  icon: Icon(Icons.swap_horiz_rounded,
                                      size: 16, color: cfg.color),
                                  label: Text('Replace File',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: cfg.color)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: cfg.color.withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ))
                              : ElevatedButton.icon(
                                  onPressed: onUpload,
                                  icon: const Icon(Icons.upload_rounded,
                                      size: 16, color: Colors.white),
                                  label: Text('Choose File to Upload',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cfg.color,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  )),
                    ),
                  ),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _Cfg {
  final String   key, label, hint, shortLabel;
  final IconData icon;
  final Color    color, light;
  const _Cfg({
    required this.key, required this.label, required this.hint,
    required this.shortLabel, required this.icon,
    required this.color, required this.light,
  });
}