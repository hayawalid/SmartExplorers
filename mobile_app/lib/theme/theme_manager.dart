import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeManagerProvider = ChangeNotifierProvider((ref) => ThemeManager());

/// ThemeManager with WCAG 2.1 AA compliant accessibility features
class ThemeManager extends ChangeNotifier {
  ThemeMode _currentMode = ThemeMode.system;
  bool _highContrastEnabled = false;
  double _fontScale = 1.0;
  bool _reduceMotion = false;

  ThemeMode get currentMode => _currentMode;
  bool get highContrastEnabled => _highContrastEnabled;
  double get fontScale => _fontScale;
  bool get reduceMotion => _reduceMotion;

  void updateFromSystem(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isHighContrast = mediaQuery.highContrast;
    final hasAccessibleNavigation = mediaQuery.accessibleNavigation;
    final shouldReduceMotion = mediaQuery.disableAnimations;
    final boldText = mediaQuery.boldText;

    final nextHighContrast = isHighContrast;
    final nextReduceMotion = shouldReduceMotion;
    final nextFontScale = isHighContrast || hasAccessibleNavigation
        ? (boldText ? 1.2 : 1.1)
        : 1.0;

    final shouldNotify =
        _highContrastEnabled != nextHighContrast ||
        _reduceMotion != nextReduceMotion ||
        _fontScale != nextFontScale;

    _reduceMotion = nextReduceMotion;
    _highContrastEnabled = nextHighContrast;
    _fontScale = nextFontScale;

    if (!shouldNotify) return;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void toggleDarkMode() {
    _currentMode = switch (_currentMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    notifyListeners();
  }

  void setHighContrast(bool enabled) {
    _highContrastEnabled = enabled;
    if (enabled) _currentMode = ThemeMode.dark;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.5);
    notifyListeners();
  }
}
