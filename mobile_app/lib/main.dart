import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/provider_navigation_shell.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_profile_view_screen.dart';
import 'theme/app_theme.dart';
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

      // Smart Monochrome light theme
      theme: buildLightTheme(highContrast: themeManager.highContrastEnabled),

      // Eerie Black dark theme
      darkTheme: buildDarkTheme(highContrast: themeManager.highContrastEnabled),

      // Theme mode controlled by ThemeManager
      themeMode: themeManager.currentMode,

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
      },
    );
  }
}
