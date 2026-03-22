import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── User (Light) Brand Colors ─────────────────────────────────────────────
  static const Color primary       = Color(0xFF1A3A6B);
  static const Color primaryLight  = Color(0xFF2756A8);
  static const Color primaryDark   = Color(0xFF0D1F3C);
  static const Color accent        = Color(0xFF00A8E8);
  static const Color accentGold    = Color(0xFFF5A623);
  static const Color success       = Color(0xFF27AE60);
  static const Color warning       = Color(0xFFF39C12);
  static const Color error         = Color(0xFFE74C3C);
  static const Color surface       = Color(0xFFF4F7FB);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7C93);
  static const Color divider       = Color(0xFFE8EDF2);

  // ── Admin (Dark) Colors ───────────────────────────────────────────────────
  static const Color adminBg           = Color(0xFF0A0A0F); // deep black
  static const Color adminCard         = Color(0xFF13131A); // card bg
  static const Color adminCardAlt      = Color(0xFF1A1A2E); // elevated card
  static const Color adminBorder       = Color(0xFF2A2A3E); // borders
  static const Color adminAccent       = Color(0xFF6C63FF); // purple accent
  static const Color adminAccentGold   = Color(0xFFF5A623); // gold
  static const Color adminTextPrimary  = Color(0xFFEEEEFF); // white-ish
  static const Color adminTextSecond   = Color(0xFF8888AA); // muted
  static const Color adminSuccess      = Color(0xFF27AE60);
  static const Color adminWarning      = Color(0xFFF39C12);
  static const Color adminError        = Color(0xFFE74C3C);
  static const Color adminDivider      = Color(0xFF2A2A3E);

  // ── User Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: textPrimary, letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary, foregroundColor: Colors.white,
        elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
    );
  }

  // ── Admin Dark Theme ──────────────────────────────────────────────────────
  static ThemeData get adminTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary:    adminAccent,
        secondary:  adminAccentGold,
        surface:    adminCard,
        onPrimary:  Colors.white,
        onSurface:  adminTextPrimary,
      ),
      scaffoldBackgroundColor: adminBg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: adminTextPrimary, letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 24, fontWeight: FontWeight.w700, color: adminTextPrimary,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18, fontWeight: FontWeight.w600, color: adminTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: adminTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: adminTextSecond),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5,
          color: adminTextPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: adminCard,
        foregroundColor: adminTextPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: adminTextPrimary, letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: adminTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: adminCard,
        selectedItemColor: adminAccent,
        unselectedItemColor: adminTextSecond,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: adminAccent,
        unselectedLabelColor: adminTextSecond,
        indicatorColor: adminAccent,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: adminCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: adminBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: adminBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: adminAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: adminCardAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminAccent, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: adminTextSecond, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: adminTextSecond, fontSize: 14),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? adminAccent : Colors.transparent),
        side: const BorderSide(color: adminBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? adminAccent : adminTextSecond),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? adminAccent.withValues(alpha: 0.3) : adminBorder),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: adminCardAlt,
        selectedColor: adminAccent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: adminTextPrimary, fontSize: 12),
        side: const BorderSide(color: adminBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: const IconThemeData(color: adminTextSecond, size: 20),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: adminAccent,
        foregroundColor: Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: adminCardAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: adminBorder),
        ),
        textStyle: GoogleFonts.inter(color: adminTextPrimary, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: adminCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: adminBorder),
        ),
        titleTextStyle: GoogleFonts.montserrat(
          color: adminTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(
          color: adminTextSecond, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: adminCardAlt,
        contentTextStyle: GoogleFonts.inter(color: adminTextPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}