import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'itinerary_planner_screen.dart';
import 'feed_screen.dart';
import 'marketplace_screen.dart';
import 'safety_dashboard_screen.dart';
import 'profile_screen.dart';

/// Main navigation shell with 5 tabs and WCAG accessibility support
/// Initial landing screen is AI Itinerary Planning Chat (index 0)
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with TickerProviderStateMixin {
  // Start on AI Chat (Itinerary) as per requirements
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimController;

  final List<NavItem> _navItems = [
    NavItem(
      icon: CupertinoIcons.chat_bubble_2_fill,
      label: 'Itinerary',
      activeColor: const Color(0xFF667eea),
      semanticLabel: 'AI Itinerary Planning Chat',
    ),
    NavItem(
      icon: CupertinoIcons.photo_fill_on_rectangle_fill,
      label: 'Feed',
      activeColor: const Color(0xFFf093fb),
      semanticLabel: 'Social feed with photos and promotions',
    ),
    NavItem(
      icon: CupertinoIcons.cart_fill,
      label: 'Marketplace',
      activeColor: const Color(0xFF4facfe),
      semanticLabel: 'Service provider marketplace',
    ),
    NavItem(
      icon: CupertinoIcons.shield_fill,
      label: 'Safety',
      activeColor: const Color(0xFFf5576c),
      semanticLabel: 'Emergency SOS and safety status center',
    ),
    NavItem(
      icon: CupertinoIcons.person_fill,
      label: 'Profile',
      activeColor: const Color(0xFFD4AF37),
      semanticLabel: 'Personal travel portfolio and reviews',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Page content with 5-tab navigation
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: const [
              ItineraryPlannerScreen(), // Tab 0: AI Chat-to-Plan Itinerary
              FeedScreen(), // Tab 1: Instagram-style feed
              MarketplaceScreen(), // Tab 2: Service providers
              SafetyDashboardScreen(), // Tab 3: Emergency SOS
              ProfileScreen(), // Tab 4: User profile
            ],
          ),

          // Bottom navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: _buildFloatingNavBar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    final navBarColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final inactiveIconColor =
        isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF8E8E93);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _navItems.length,
          (index) => _buildNavItem(index, isDark, inactiveIconColor),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark, Color inactiveIconColor) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    // WCAG 2.1 AA: Wrap with Semantics for accessibility
    return Semantics(
      button: true,
      selected: isActive,
      label: item.semanticLabel,
      hint: isActive ? 'Currently selected' : 'Double tap to navigate',
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          // WCAG 2.1 AA: Minimum 44x44pt tap target
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 20 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color:
                  isActive
                      ? item.activeColor.withOpacity(0.15)
                      : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    item.icon,
                    size: isActive ? 26 : 24,
                    color: isActive ? item.activeColor : inactiveIconColor,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: isActive ? null : 0,
                    child: AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.activeColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Text',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item model with WCAG accessibility support
class NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final String semanticLabel;

  NavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.semanticLabel,
  });
}
