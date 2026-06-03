import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/screens/onboarding/onboarding_flow.dart';
import 'package:mobile_app/screens/traveler/main_navigation_shell.dart';
import 'package:mobile_app/screens/provider/provider_navigation_shell.dart';
import 'package:mobile_app/screens/admin/admin_dashboard_screen.dart';
import 'package:mobile_app/screens/provider_verification_screen.dart';
import 'package:mobile_app/screens/shared/user_profile_view_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_manager.dart';

void main() {
  runApp(const ProviderScope(child: SmartExplorersApp()));
}

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

      // Smart Monochrome light theme
      theme: buildLightTheme(highContrast: themeManager.highContrastEnabled),

      // Eerie Black dark theme
      darkTheme: buildDarkTheme(highContrast: themeManager.highContrastEnabled),

      // Theme mode controlled by ThemeManager
      themeMode: themeManager.currentMode,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeInOutCubic,

      // Accessibility text scaling
      builder: (context, child) {
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
      onGenerateRoute: (settings) {
        if (settings.name == '/user_profile') {
          final args = settings.arguments as Map<String, String>? ?? {};
          return MaterialPageRoute(
            builder:
                (_) => UserProfileViewScreen(
                  userId: args['userId'] ?? '',
                  displayName: args['displayName'],
                  accountType: args['accountType'],
                ),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const MainNavigationShell(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/home': (context) => const MainNavigationShell(),
        '/provider_home': (context) => const ProviderNavigationShell(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/provider_verification': (context) => const ProviderVerificationScreen(),
      },
    );
  }
}
