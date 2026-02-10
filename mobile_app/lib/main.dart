import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main_navigation_shell.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartExplorers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0F4C75)),
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF64B5F6),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/onboarding',
      routes: {
        '/': (context) => const MainNavigationShell(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/home': (context) => const MainNavigationShell(),
      },
    );
  }
}
