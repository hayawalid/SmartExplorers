import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/provider_navigation_shell.dart';
import 'theme/theme_manager.dart';

void main() {
  runApp(const ProviderScope(child: SmartExplorersApp()));
}

/// Global ThemeManager provider
final themeManagerProvider = ChangeNotifierProvider((ref) => ThemeManager());

class SmartExplorersApp extends ConsumerStatefulWidget {
  const SmartExplorersApp({super.key});

  @override
  ConsumerState<SmartExplorersApp> createState() => _SmartExplorersAppState();
}

class _SmartExplorersAppState extends ConsumerState<SmartExplorersApp> {
  @override
  Widget build(BuildContext context) {
    final themeManager = ref.watch(themeManagerProvider);

    return MaterialApp(
      title: 'SmartExplorers',
      debugShowCheckedModeBanner: false,

      // Light theme with SF Pro Rounded and glassmorphism
      theme: buildLightTheme(highContrast: themeManager.highContrastEnabled),

      // Dark theme (Midnight/Obsidian) with high contrast support
      darkTheme: buildDarkTheme(highContrast: themeManager.highContrastEnabled),

      // Theme mode controlled by ThemeManager
      themeMode: themeManager.currentMode,

      // Accessibility text scaling
      builder: (context, child) {
        // Auto-detect accessibility settings and update theme
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(themeManagerProvider).updateFromSystem(context);
        });

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(themeManager.fontScale)),
          child: child!,
        );
      },

      initialRoute: '/onboarding',
      routes: {
        '/': (context) => const MainNavigationShell(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/home': (context) => const MainNavigationShell(),
        '/provider_home': (context) => const ProviderNavigationShell(),
      },
    );
  }
}
