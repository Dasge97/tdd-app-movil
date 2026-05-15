import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Paleta editorial TDD ──────────────────────────────────────────────────────
class TddColors {
  static const bg         = Color(0xFFFAF7F1);
  static const bgElev     = Color(0xFFF3EEE3);
  static const surface    = Color(0xFFF0EBE0);
  static const surface2   = Color(0xFFE7E1D2);

  static const border       = Color(0x17261A12);
  static const borderStrong = Color(0x29261A12);

  static const text  = Color(0xFF1A1612);
  static const text2 = Color(0xFF6F665A);
  static const text3 = Color(0xFF9C9486);
  static const text4 = Color(0xFFC0B8AA);

  static const accent      = Color(0xFF6E2733);
  static const accentInk   = Color(0xFFFAF7F1);
  static const accentSoft  = Color(0x146E2733);
  static const accentRing  = Color(0x386E2733);

  static const favor       = Color(0xFF4F7548);
  static const favorSoft   = Color(0x1A4F7548);
  static const contra      = Color(0xFF9C4232);
  static const contraSoft  = Color(0x1A9C4232);
  static const neutral     = Color(0xFF6F665A);
  static const neutralSoft = Color(0x1A6F665A);

  static const unread = Color(0x0A6E2733);
}

// ── Tipografía ────────────────────────────────────────────────────────────────
class TddTypography {
  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    FontStyle style = FontStyle.normal,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.newsreader(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontStyle: style,
        color: color ?? TddColors.text,
        height: height ?? 1.3,
      );

  static TextStyle sans({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    FontStyle style = FontStyle.normal,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontStyle: style,
        color: color ?? TddColors.text,
        height: height ?? 1.45,
      );

  static TextStyle mono({
    double size = 10.5,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0.06,
    Color? color,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? TddColors.text3,
      );
}

// ── Tema principal ────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => _buildTheme();

  // Kept for backward compat — now uses the same light editorial theme
  static ThemeData get dark => _buildTheme();

  static ThemeData _buildTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge:   TddTypography.serif(size: 56, weight: FontWeight.w500, letterSpacing: -0.04),
      displayMedium:  TddTypography.serif(size: 45, weight: FontWeight.w500, letterSpacing: -0.03),
      displaySmall:   TddTypography.serif(size: 36, weight: FontWeight.w500, letterSpacing: -0.025),
      headlineLarge:  TddTypography.serif(size: 32, weight: FontWeight.w500, letterSpacing: -0.022),
      headlineMedium: TddTypography.serif(size: 28, weight: FontWeight.w500, letterSpacing: -0.02),
      headlineSmall:  TddTypography.serif(size: 24, weight: FontWeight.w500, letterSpacing: -0.018),
      titleLarge:     TddTypography.serif(size: 22, weight: FontWeight.w500, letterSpacing: -0.015),
      titleMedium:    TddTypography.sans(size: 16, weight: FontWeight.w500),
      titleSmall:     TddTypography.sans(size: 14, weight: FontWeight.w500),
      bodyLarge:      TddTypography.sans(size: 16),
      bodyMedium:     TddTypography.sans(size: 15, color: TddColors.text),
      bodySmall:      TddTypography.mono(size: 9.5, color: TddColors.text3),
      labelLarge:     TddTypography.sans(size: 14, weight: FontWeight.w500),
      labelMedium:    TddTypography.mono(size: 10, letterSpacing: 0.1),
      labelSmall:     TddTypography.mono(size: 9, letterSpacing: 0.12),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary:                  TddColors.accent,
        onPrimary:                TddColors.accentInk,
        secondary:                TddColors.text2,
        onSecondary:              TddColors.bg,
        surface:                  TddColors.bg,
        onSurface:                TddColors.text,
        surfaceContainerHighest:  TddColors.surface2,
        outline:                  TddColors.border,
        outlineVariant:           TddColors.borderStrong,
        error:                    TddColors.contra,
      ),
      scaffoldBackgroundColor: TddColors.bg,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: TddColors.bg,
        foregroundColor: TddColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TddTypography.serif(size: 17, weight: FontWeight.w500, letterSpacing: -0.015),
        toolbarHeight: 52,
        shape: const Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TddColors.bg,
        selectedItemColor:   TddColors.text,
        unselectedItemColor: TddColors.text3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      cardTheme: const CardThemeData(
        color: TddColors.bg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
      ),

      dividerTheme: const DividerThemeData(
        color: TddColors.border,
        thickness: 0.5,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: TddColors.borderStrong, width: 0.5),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: TddColors.borderStrong, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: TddColors.accent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        hintStyle: TddTypography.sans(color: TddColors.text4),
        labelStyle: TddTypography.mono(size: 10, letterSpacing: 0.1, color: TddColors.text3),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TddColors.text,
          foregroundColor: TddColors.bg,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TddTypography.sans(size: 14.5, weight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TddColors.text,
          side: const BorderSide(color: TddColors.borderStrong, width: 0.5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: TddTypography.sans(size: 14.5, weight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TddColors.text2,
          textStyle: TddTypography.sans(size: 14),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: TddColors.accentSoft,
        labelStyle: TddTypography.mono(size: 9.5, letterSpacing: 0.08, color: TddColors.accent),
        side: const BorderSide(color: TddColors.accentRing, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        labelPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: TddColors.text,
        contentTextStyle: TddTypography.sans(size: 13.5, color: TddColors.bg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: TddColors.bgElev,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TddColors.borderStrong, width: 0.5),
        ),
        titleTextStyle: TddTypography.serif(size: 19, weight: FontWeight.w500),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TddColors.accent,
        foregroundColor: TddColors.accentInk,
        elevation: 6,
        shape: CircleBorder(),
      ),
    );
  }
}
