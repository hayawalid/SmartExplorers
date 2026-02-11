import 'package:flutter/material.dart';
import 'account_type_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('lib/public/onboarding_bg.jpg', fit: BoxFit.cover),
          Container(
            color: Colors.black.withOpacity(
              0.2,
            ), // dark overlay for readability
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Title at the top
                  Text(
                    'TRAVEL\nWITHOUT\nLIMITS',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    'Discover new places,\nmeet new people, and\nshare your adventures with the world.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const Spacer(),
                  // Buttons at the bottom
                  Text(
                    'Do you already have an account?',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to login screen
                    },
                    child: const Text('Log In'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountTypeScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
