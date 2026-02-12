import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Design-system color tokens re-exported for convenience.
/// All screens should use [AppDesign] directly or these aliases.
class AppColors {
  AppColors._();

  static const Color accent = AppDesign.electricCobalt;
  static const Color background = AppDesign.pureWhite;
  static const Color backgroundDark = AppDesign.eerieBlack;
  static const Color surface = AppDesign.pureWhite;
  static const Color surfaceDark = AppDesign.cardDark;
  static const Color textPrimary = AppDesign.eerieBlack;
  static const Color textSecondary = AppDesign.midGrey;
  static const Color border = AppDesign.lightGrey;

  static const Color success = AppDesign.success;
  static const Color warning = AppDesign.warning;
  static const Color danger = AppDesign.danger;
  static const Color info = AppDesign.info;
}
