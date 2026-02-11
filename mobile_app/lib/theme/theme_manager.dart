import 'package:flutter/material.dart';

/// ThemeManager with WCAG 2.1 AA compliant accessibility features
class ThemeManager extends ChangeNotifier {
  ThemeMode _currentMode = ThemeMode.light;
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

    _reduceMotion = shouldReduceMotion;
    _highContrastEnabled = isHighContrast;

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
    if (enabled) _currentMode = ThemeMode.dark;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.5);
    notifyListeners();
  }
}
