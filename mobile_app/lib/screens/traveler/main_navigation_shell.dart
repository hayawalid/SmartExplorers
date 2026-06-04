import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_manager.dart';
import 'package:mobile_app/screens/traveler/itinerary_planner_screen.dart';
import 'package:mobile_app/screens/shared/feed_screen.dart';
import 'package:mobile_app/screens/shared/profile_screen.dart';
import 'package:mobile_app/screens/traveler/smart_match_screen.dart';
import 'package:mobile_app/screens/shared/safety_hub_screen.dart';

/// Main navigation shell – 5-tab floating bottom bar
/// Each tab has a unique accent color
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  bool _navExpanded = false;

  static const _tabs = <_NavTab>[
    _NavTab(
      icon: LucideIcons.compass,
      activeIcon: LucideIcons.compass,
      label: 'Explore',
      semanticLabel: 'Community Feed',
      activeColor: AppDesign.navExplore,
    ),
    _NavTab(
      icon: LucideIcons.star,
      activeIcon: LucideIcons.star,
      label: 'Match',
      semanticLabel: 'Open Smart Match',
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
    final themeManager = ref.watch(themeManagerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompactWidth = MediaQuery.of(context).size.width < 430;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppDesign.eerieBlack : AppDesign.pureWhite,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FeedScreen(
                  currentThemeMode: themeManager.currentMode,
                  onThemeModeSelected: themeManager.setThemeMode,
                  userType: 'traveler',
                ),
                const SmartMatchScreen(),
                ItineraryPlannerScreen(),
                SafetyHubScreen(),
                ProfileScreen(),
              ],
            ),
            Positioned(
              left: isCompactWidth ? 12 : 20,
              right: isCompactWidth ? 12 : 20,
              bottom: MediaQuery.of(context).padding.bottom + (isCompactWidth ? 8 : 12),
              child: _FloatingNavBar(
                tabs: _tabs,
                currentIndex: _currentIndex,
                expanded: _navExpanded,
                onTap: _onTabTap,
                onToggleExpanded: () => setState(() => _navExpanded = !_navExpanded),
                isDark: isDark,
                isCompactWidth: isCompactWidth,
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
    required this.expanded,
    required this.onTap,
    required this.onToggleExpanded,
    required this.isDark,
    required this.isCompactWidth,
  });

  final List<_NavTab> tabs;
  final int currentIndex;
  final bool expanded;
  final ValueChanged<int> onTap;
  final VoidCallback onToggleExpanded;
  final bool isDark;
  final bool isCompactWidth;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A20) : AppDesign.pureWhite;
    final inactive = isDark ? Colors.white38 : AppDesign.midGrey;
    final navHeight = isCompactWidth ? 60.0 : 72.0;
    final collapsedSize = isCompactWidth ? 54.0 : 58.0;
    final expandedWidth = MediaQuery.of(context).size.width - 24;

    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: onToggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: expanded ? expandedWidth : collapsedSize,
          height: collapsedSize,
          decoration: BoxDecoration(
            color: bg.withOpacity(isDark ? 0.85 : 0.92),
            borderRadius: BorderRadius.circular(collapsedSize / 2),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
            ),
            boxShadow: isDark ? [] : AppDesign.mediumShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(collapsedSize / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child:
                  expanded
                      ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: List.generate(tabs.length, (i) {
                            final isActive = i == currentIndex;
                            final tab = tabs[i];
                            final tabColor = isActive ? tab.activeColor : inactive;
                            return Expanded(
                              flex: isActive ? 2 : 1,
                              child: Semantics(
                                button: true,
                                selected: isActive,
                                label: tab.semanticLabel,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    onTap(i);
                                    onToggleExpanded();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                    height: navHeight,
                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                    padding: EdgeInsets.symmetric(horizontal: isActive ? 14 : 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(navHeight / 2),
                                      color:
                                          isActive
                                              ? tab.activeColor.withOpacity(0.12)
                                              : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          isActive ? tab.activeIcon : tab.icon,
                                          size: isCompactWidth ? 20 : 22,
                                          color: tabColor,
                                        ),
                                        AnimatedSize(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOutCubic,
                                          child:
                                              isActive
                                                  ? Padding(
                                                    padding: const EdgeInsets.only(left: 6),
                                                    child: Text(
                                                      tab.label,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: isCompactWidth ? 9.5 : 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: tabColor,
                                                      ),
                                                    ),
                                                  )
                                                  : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                      : Center(
                        child: Icon(
                          tabs[currentIndex].activeIcon,
                          size: isCompactWidth ? 20 : 22,
                          color: tabs[currentIndex].activeColor,
                        ),
                      ),
            ),
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
