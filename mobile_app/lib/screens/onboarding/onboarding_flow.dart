import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Main onboarding flow entry point (just launches WelcomeScreen)
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
