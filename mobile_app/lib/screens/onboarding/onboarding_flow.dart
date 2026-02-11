import 'package:flutter/material.dart';
import 'feature_showcase_screen.dart';

/// Entry-point widget for the on-boarding experience.
/// Shows the swipeable feature cards first, then routes to the auth screen.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureShowcaseScreen();
  }
}
