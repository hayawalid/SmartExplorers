import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

/// SmartExplorers brand logo – compass icon + text.
/// Use across all pages for consistent identity.
class SmartExplorersLogo extends StatelessWidget {
  const SmartExplorersLogo({
    Key? key,
    this.size = LogoSize.small,
    this.showText = true,
    this.color,
    this.lightMode = true,
  }) : super(key: key);

  final LogoSize size;
  final bool showText;
  final Color? color;
  final bool lightMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ??
        (lightMode
            ? (isDark ? Colors.white : AppDesign.eerieBlack)
            : Colors.white);

    final double iconSize;
    final double fontSize;
    final double spacing;

    switch (size) {
      case LogoSize.tiny:
        iconSize = 16;
        fontSize = 13;
        spacing = 4;
        break;
      case LogoSize.small:
        iconSize = 20;
        fontSize = 15;
        spacing = 6;
        break;
      case LogoSize.medium:
        iconSize = 26;
        fontSize = 20;
        spacing = 8;
        break;
      case LogoSize.large:
        iconSize = 34;
        fontSize = 28;
        spacing = 10;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.compass, size: iconSize, color: effectiveColor),
        if (showText) ...[
          SizedBox(width: spacing),
          Text(
            'SmartExplorers',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

enum LogoSize { tiny, small, medium, large }
