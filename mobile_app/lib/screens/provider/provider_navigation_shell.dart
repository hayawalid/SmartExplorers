// ============================================================================
// provider_navigation_shell.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/screens/shared/feed_screen.dart';
import 'package:mobile_app/screens/shared/safety_hub_screen.dart';
import 'package:mobile_app/screens/shared/profile_screen.dart';
import 'package:mobile_app/screens/provider/provider_services_screen.dart';

class ProviderNavigationShell extends StatefulWidget {
  const ProviderNavigationShell({super.key});

  @override
  State<ProviderNavigationShell> createState() => _ProviderNavigationShellState();
}

class _ProviderNavigationShellState extends State<ProviderNavigationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<ProviderNavItem> _navItems = [
    ProviderNavItem(
      icon: LucideIcons.briefcase,
      label: 'Services',
      activeColor: AppDesign.navConcierge,
      semanticLabel: 'Your service offerings',
    ),
    ProviderNavItem(
      icon: LucideIcons.compass,
      label: 'Feed',
      activeColor: AppDesign.navItinerary,
      semanticLabel: 'Social feed and promotions',
    ),
    ProviderNavItem(
      icon: LucideIcons.shield,
      label: 'Safety',
      activeColor: AppDesign.navSafety,
      semanticLabel: 'Emergency SOS and safety',
    ),
    ProviderNavItem(
      icon: LucideIcons.user,
      label: 'Profile',
      activeColor: AppDesign.navProfile,
      semanticLabel: 'Your provider profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              const ProviderServicesScreen(),
              FeedScreen(
                currentThemeMode: ThemeMode.system,
                onThemeModeSelected: (value) {},
                userType: 'service_provider',
              ),
              const SafetyHubScreen(),
              const ProfileScreen(),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _FloatingNavBar(
              items: _navItems,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              isDark: isDark,
            ),
          ),
          if (_currentIndex == 3)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 100,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/provider_verification');
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppDesign.navSafety, AppDesign.navExplore],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppDesign.navSafety.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  final List<ProviderNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A20) : AppDesign.pureWhite;
    final inactive = isDark ? Colors.white38 : AppDesign.midGrey;

    return ClipRRect(
      borderRadius: AppDesign.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: bg.withOpacity(isDark ? 0.85 : 0.92),
            borderRadius: AppDesign.borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: isDark ? [] : AppDesign.mediumShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              final item = items[i];
              final tabColor = isActive ? item.activeColor : inactive;
              return Semantics(
                button: true,
                selected: isActive,
                label: item.semanticLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isActive
                            ? item.activeColor.withOpacity(0.12)
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 22, color: tabColor),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: tabColor,
                              letterSpacing: 0.1,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ProviderNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final String semanticLabel;

  const ProviderNavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.semanticLabel,
  });
}