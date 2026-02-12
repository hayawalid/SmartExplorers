import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Smart Monochrome Design System
/// Primary: Pure White (#FFFFFF) / Eerie Black (#121212)
/// Accent: Jet Black (#1A1A1A)
class AppDesign {
  AppDesign._();

  // ── Core Palette ──────────────────────────────────────────────────────
  static const Color electricCobalt = Color(0xFF1A1A1A);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color eerieBlack = Color(0xFF121212);
  static const Color offWhite = Color(0xFFF7F7F8);
  static const Color lightGrey = Color(0xFFE8E8EC);
  static const Color midGrey = Color(0xFF9B9BA5);
  static const Color darkGrey = Color(0xFF1E1E24);
  static const Color cardDark = Color(0xFF1A1A20);

  // Status
  static const Color success = Color(0xFF00C566);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFFF3B5C);
  static const Color info = Color(0xFF1A1A1A);

  // Onboarding accent – warm coral-orange pop color
  static const Color onboardingAccent = Color(0xFFE8604C);

  // Navigation tab colors (each tab gets its own accent)
  static const Color navExplore = Color(0xFF4A90D9); // ocean blue
  static const Color navConcierge = Color(0xFF9B59B6); // amethyst purple
  static const Color navItinerary = Color(0xFFE8604C); // coral
  static const Color navSafety = Color(0xFF00C566); // green
  static const Color navProfile = Color(0xFFD4AF37); // gold

  // ── Radius ────────────────────────────────────────────────────────────
  static const double radius = 24.0;
  static final BorderRadius borderRadius = BorderRadius.circular(radius);

  // ── Shadows (light mode only) ─────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ── Glassmorphism Decoration ──────────────────────────────────────────
  static BoxDecoration glassmorphism({bool isDark = false}) {
    return BoxDecoration(
      borderRadius: borderRadius,
      color:
          isDark
              ? Colors.black.withOpacity(0.45)
              : Colors.white.withOpacity(0.65),
      border: Border.all(
        color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),
      ),
    );
  }
}

/// Build the Light Theme
ThemeData buildLightTheme({bool highContrast = false}) {
  final textTheme = _buildTextTheme(isLight: true, highContrast: highContrast);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppDesign.electricCobalt,
      brightness: Brightness.light,
      primary: AppDesign.electricCobalt,
      onPrimary: Colors.white,
      surface: AppDesign.pureWhite,
      onSurface: AppDesign.eerieBlack,
      error: AppDesign.danger,
    ),
    scaffoldBackgroundColor: AppDesign.pureWhite,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppDesign.pureWhite,
      foregroundColor: AppDesign.eerieBlack,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppDesign.eerieBlack,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
      color: AppDesign.pureWhite,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesign.electricCobalt,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDesign.electricCobalt,
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
        side: const BorderSide(color: AppDesign.lightGrey),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDesign.offWhite,
      border: OutlineInputBorder(
        borderRadius: AppDesign.borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppDesign.borderRadius,
        borderSide: const BorderSide(
          color: AppDesign.electricCobalt,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: AppDesign.midGrey),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppDesign.offWhite,
      selectedColor: AppDesign.electricCobalt.withOpacity(0.12),
      labelStyle: textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radius),
      ),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: AppDesign.lightGrey,
      thickness: 0.5,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppDesign.pureWhite,
      selectedItemColor: AppDesign.electricCobalt,
      unselectedItemColor: AppDesign.midGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppDesign.electricCobalt,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
    ),
  );
}

/// Build the Dark Theme
ThemeData buildDarkTheme({bool highContrast = false}) {
  final textTheme = _buildTextTheme(isLight: false, highContrast: highContrast);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppDesign.electricCobalt,
      brightness: Brightness.dark,
      primary: AppDesign.electricCobalt,
      onPrimary: Colors.white,
      surface: AppDesign.eerieBlack,
      onSurface: Colors.white,
      error: AppDesign.danger,
    ),
    scaffoldBackgroundColor: AppDesign.eerieBlack,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppDesign.eerieBlack,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
      color: AppDesign.cardDark,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesign.electricCobalt,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDesign.electricCobalt,
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDesign.darkGrey,
      border: OutlineInputBorder(
        borderRadius: AppDesign.borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppDesign.borderRadius,
        borderSide: const BorderSide(
          color: AppDesign.electricCobalt,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppDesign.darkGrey,
      selectedColor: AppDesign.electricCobalt.withOpacity(0.2),
      labelStyle: textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radius),
      ),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.08),
      thickness: 0.5,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppDesign.eerieBlack,
      selectedItemColor: AppDesign.electricCobalt,
      unselectedItemColor: Colors.white.withOpacity(0.4),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppDesign.electricCobalt,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
    ),
  );
}

/// Typography: Inter for headlines, Roboto Flex (Roboto) for body
TextTheme _buildTextTheme({required bool isLight, required bool highContrast}) {
  final Color base = isLight ? AppDesign.eerieBlack : Colors.white;
  final Color secondary = isLight ? AppDesign.midGrey : Colors.white70;

  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: highContrast ? FontWeight.w800 : FontWeight.w700,
      letterSpacing: -1.5,
      color: base,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: highContrast ? FontWeight.w800 : FontWeight.w700,
      letterSpacing: -1.0,
      color: base,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.5,
      color: base,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.3,
      color: base,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.2,
      color: base,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.2,
      color: base,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: base,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
      color: base,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: base,
      height: 1.55,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: base,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: secondary,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: base,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: secondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: secondary,
    ),
  );
}
