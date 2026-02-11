import 'package:flutter/material.dart';
import 'auth_choice_screen.dart';

/// Main onboarding flow entry point (just launches WelcomeScreen)
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start with AuthChoiceScreen
    return const AuthChoiceScreen();
  }
}
