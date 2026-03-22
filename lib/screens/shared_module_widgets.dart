// lib/screens/shared_module_widgets.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Section card ──────────────────────────────────────────────────────────────
class ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.15)),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1A1F36))),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
        ])),
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

// ── Chat CTA button ───────────────────────────────────────────────────────────
class ModuleChatButton extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const ModuleChatButton({
    super.key,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          Text(sub, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
      ]),
    ),
  );
}

// ── Result tile ───────────────────────────────────────────────────────────────
class ModuleResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const ModuleResultTile(this.label, this.value, this.color, {super.key, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
      ]),
    );
    return wide ? SizedBox(width: double.infinity, child: inner) : Expanded(child: inner);
  }
}

// ── Deadline row ──────────────────────────────────────────────────────────────
class ModuleDeadlineRow extends StatelessWidget {
  final String label;
  final String date;

  const ModuleDeadlineRow(this.label, this.date, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12))),
      Text(date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
    ]),
  );
}