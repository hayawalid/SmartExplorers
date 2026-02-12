import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import 'itinerary_planner_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'smart_match_screen.dart';
import 'safety_hub_screen.dart';

/// Main navigation shell – 5-tab floating bottom bar
/// Each tab has a unique accent color
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  static const _tabs = <_NavTab>[
    _NavTab(
      icon: LucideIcons.compass,
      activeIcon: LucideIcons.compass,
      label: 'Explore',
      semanticLabel: 'Community Feed',
      activeColor: AppDesign.navExplore,
    ),
    _NavTab(
      icon: LucideIcons.briefcase,
      activeIcon: LucideIcons.briefcase,
      label: 'Concierge',
      semanticLabel: 'Accepted trips and matching',
      activeColor: AppDesign.navConcierge,
    ),
    _NavTab(
      icon: LucideIcons.sparkles,
      activeIcon: LucideIcons.sparkles,
      label: 'Itinerary',
      semanticLabel: 'AI Itinerary Planner',
      activeColor: AppDesign.navItinerary,
    ),
    _NavTab(
      icon: LucideIcons.shield,
      activeIcon: LucideIcons.shield,
      label: 'Safety',
      semanticLabel: 'Emergency services',
      activeColor: AppDesign.navSafety,
    ),
    _NavTab(
      icon: LucideIcons.user,
      activeIcon: LucideIcons.user,
      label: 'Profile',
      semanticLabel: 'Account management',
      activeColor: AppDesign.navProfile,
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

  void _onTabTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppDesign.eerieBlack : AppDesign.pureWhite,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                FeedScreen(),
                SmartMatchScreen(),
                ItineraryPlannerScreen(),
                SafetyHubScreen(),
                ProfileScreen(),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: _FloatingNavBar(
                tabs: _tabs,
                currentIndex: _currentIndex,
                onTap: _onTabTap,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating Nav Bar ────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  final List<_NavTab> tabs;
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
              color:
                  isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
            ),
            boxShadow: isDark ? [] : AppDesign.mediumShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              final tab = tabs[i];
              final tabColor = isActive ? tab.activeColor : inactive;
              return Semantics(
                button: true,
                selected: isActive,
                label: tab.semanticLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color:
                            isActive
                                ? tab.activeColor.withOpacity(0.12)
                                : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            size: 22,
                            color: tabColor,
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              color: tabColor,
                              letterSpacing: 0.1,
                            ),
                            child: Text(tab.label),
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

// ── Data class ──────────────────────────────────────────────────────────
class _NavTab {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.semanticLabel,
    required this.activeColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String semanticLabel;
  final Color activeColor;
}
