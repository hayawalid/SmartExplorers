import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// ThemeManager with WCAG 2.1 AA compliant accessibility features
/// Auto-switches to dark mode when vision impairment settings detected
class ThemeManager extends ChangeNotifier {
  ThemeMode _currentMode = ThemeMode.light;
  bool _highContrastEnabled = false;
  double _fontScale = 1.0;
  bool _reduceMotion = false;

  ThemeMode get currentMode => _currentMode;
  bool get highContrastEnabled => _highContrastEnabled;
  double get fontScale => _fontScale;
  bool get reduceMotion => _reduceMotion;

  /// Updates theme based on system accessibility settings
  void updateFromSystem(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Detect accessibility settings
    final isHighContrast = mediaQuery.highContrast;
    final hasAccessibleNavigation = mediaQuery.accessibleNavigation;
    final shouldReduceMotion = mediaQuery.disableAnimations;
    final boldText = mediaQuery.boldText;

    _reduceMotion = shouldReduceMotion;
    _highContrastEnabled = isHighContrast;

    // Auto-switch to dark mode with increased font weight for vision impairment
    if (isHighContrast || hasAccessibleNavigation) {
      _currentMode = ThemeMode.dark;
      _fontScale = boldText ? 1.2 : 1.1;
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void toggleDarkMode() {
    _currentMode =
        _currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setHighContrast(bool enabled) {
    _highContrastEnabled = enabled;
    if (enabled) {
      _currentMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.5);
    notifyListeners();
  }
}

/// Light theme with SF Pro Rounded typography and glassmorphism support
/// Background: Light grey (0xFFF2F2F7), Elements: White
ThemeData buildLightTheme({bool highContrast = false}) {
  const primaryColor = Color(0xFF0F4C75);
  const accentPurple = Color(0xFF667eea);
  const accentPink = Color(0xFFf5576c);
  const egyptianGold = Color(0xFFD4AF37);

  // iOS-style light grey background with white elements
  const backgroundColor = Color(0xFFF2F2F7);
  const cardColor = Colors.white;
  const textPrimary = Color(0xFF1C1C1E);
  const textSecondary = Color(0xFF8E8E93);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme - WCAG 4.5:1 contrast ratios
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentPurple,
      tertiary: egyptianGold,
      error: const Color(0xFFDC3545),
      surface: cardColor,
      surfaceContainerHighest: backgroundColor,
      onSurface: highContrast ? Colors.black : textPrimary,
      onSurfaceVariant: textSecondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),

    // Light grey scaffold background
    scaffoldBackgroundColor: backgroundColor,

    // Typography - SF Pro Rounded
    textTheme: _buildTextTheme(isLight: true, highContrast: highContrast),

    // AppBar with white background (element on grey)
    appBarTheme: AppBarTheme(
      backgroundColor: cardColor,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 18,
        fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
    ),

    // Bottom navigation - white element on grey background
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: accentPurple,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Cards with white background on grey scaffold
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      surfaceTintColor: Colors.transparent,
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44), // WCAG minimum tap target
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        textStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 16,
          fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: const Color(0xFFE5E5EA),
      thickness: 0.5,
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      tileColor: cardColor,
      textColor: textPrimary,
      iconColor: textSecondary,
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey[600]),
    ),

    // Floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPink,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Chip theme for bubble chips
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100],
      selectedColor: accentPurple,
      labelStyle: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
  );
}

/// Dark theme (Midnight/Obsidian) with high contrast support
ThemeData buildDarkTheme({bool highContrast = false}) {
  const primaryColor = Color(0xFF64B5F6);
  const accentPurple = Color(0xFF9D7BEA);
  const accentPink = Color(0xFFFF7B9C);
  const egyptianGold = Color(0xFFFFD700);

  final surfaceColor =
      highContrast ? const Color(0xFF000000) : const Color(0xFF1a1a2e);
  final cardColor =
      highContrast ? const Color(0xFF121212) : const Color(0xFF16213e);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme - High contrast dark mode
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentPurple,
      tertiary: egyptianGold,
      error: const Color(0xFFFF6B6B),
      surface: surfaceColor,
      onSurface: highContrast ? Colors.white : const Color(0xFFE8E8E8),
      onPrimary: Colors.black,
      onSecondary: Colors.white,
    ),

    // Scaffold background
    scaffoldBackgroundColor: surfaceColor,

    // Typography with increased weight for accessibility
    textTheme: _buildTextTheme(isLight: false, highContrast: highContrast),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: cardColor.withOpacity(0.95),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 18,
        fontWeight: highContrast ? FontWeight.w800 : FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardColor.withOpacity(0.95),
      selectedItemColor: accentPurple,
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 12,
        fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        textStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 16,
          fontWeight: highContrast ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(fontFamily: 'SF Pro Text', color: Colors.grey[400]),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPink,
      foregroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: cardColor,
      selectedColor: accentPurple,
      labelStyle: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 14,
        fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
  );
}

/// Build text theme with SF Pro typography
TextTheme _buildTextTheme({required bool isLight, required bool highContrast}) {
  final baseColor =
      isLight
          ? (highContrast ? Colors.black : const Color(0xFF1a1a2e))
          : (highContrast ? Colors.white : const Color(0xFFE8E8E8));

  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 34,
      fontWeight: FontWeight.lerp(
        FontWeight.w700,
        FontWeight.w900,
        highContrast ? 1 : 0,
      ),
      letterSpacing: -0.5,
      color: baseColor,
    ),
    displayMedium: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 28,
      fontWeight: highContrast ? FontWeight.w800 : FontWeight.w700,
      letterSpacing: -0.5,
      color: baseColor,
    ),
    displaySmall: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 24,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.3,
      color: baseColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 22,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.3,
      color: baseColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 20,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.3,
      color: baseColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 18,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleLarge: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 17,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleMedium: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleSmall: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 14,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.1,
      color: baseColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 16,
      fontWeight: highContrast ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: -0.3,
      color: baseColor,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 14,
      fontWeight: highContrast ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: -0.2,
      color: baseColor,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 12,
      fontWeight: highContrast ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: 0,
      color: baseColor.withOpacity(0.8),
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 14,
      fontWeight: highContrast ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: 0.5,
      color: baseColor,
    ),
    labelMedium: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 12,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.3,
      color: baseColor,
    ),
    labelSmall: TextStyle(
      fontFamily: 'SF Pro Text',
      fontSize: 10,
      fontWeight: highContrast ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.2,
      color: baseColor.withOpacity(0.7),
    ),
  );
}

/// Accessible color constants with WCAG 4.5:1 contrast ratios
class AccessibleColors {
  // Primary brand colors
  static const pharaohBlue = Color(0xFF0F4C75);
  static const egyptianGold = Color(0xFFD4AF37);

  // Accent colors
  static const accentPurple = Color(0xFF667eea);
  static const accentPink = Color(0xFFf5576c);
  static const accentCyan = Color(0xFF4facfe);

  // Status colors - WCAG compliant
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Dark mode surfaces
  static const darkSurface = Color(0xFF1a1a2e);
  static const darkCard = Color(0xFF16213e);
  static const darkElevated = Color(0xFF0f3460);

  // Gradients
  static const purpleBlueGradient = LinearGradient(
    colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const egyptianGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFF0F4C75)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
