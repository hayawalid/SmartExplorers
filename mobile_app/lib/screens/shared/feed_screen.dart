import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/smart_explorers_logo.dart';
import 'package:mobile_app/models/service_models.dart';
import 'package:mobile_app/screens/shared/service_detail_screen.dart';
import 'package:mobile_app/screens/shared/user_profile_view_screen.dart';
import 'package:mobile_app/services/matching_api_service.dart';
import 'package:mobile_app/services/profile_api_service.dart';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/services/social_api_service.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/api_config.dart';
import 'package:mobile_app/screens/traveler/create_post_screen.dart';
import 'package:mobile_app/screens/shared/travel_space_detail_screen.dart';

/// Social feed with 3 tabs – Posts, Spaces, Providers.
/// Cinematic image cards with glassmorphism overlays.
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeSelected,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSearchSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SearchBottomSheet(),
    );
  }

  void _openNotificationsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isCompactWidth = constraints.maxWidth < 430;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
        final horizontalPadding =
            constraints.maxWidth >= 840
                ? 32.0
                : (isCompactWidth ? 16.0 : 20.0);
        final contentMaxWidth =
            constraints.maxWidth >= 840
                ? 760.0
                : constraints.maxWidth - (horizontalPadding * 2);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(
                    isDark: isDark,
                    isLandscape: isLandscape,
                    isCompactWidth: isCompactWidth,
                    horizontalPadding: horizontalPadding,
                  ),
                  _buildTabBar(
                    isDark: isDark,
                    isLandscape: isLandscape,
                    horizontalPadding: horizontalPadding,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _PostsTab(
                          isDark: isDark,
                          isLandscape: isLandscape,
                          maxContentWidth: contentMaxWidth,
                        ),
                        _SpacesTab(
                          isDark: isDark,
                          isLandscape: isLandscape,
                          maxContentWidth: contentMaxWidth,
                        ),
                        _ProvidersTab(
                          isDark: isDark,
                          isLandscape: isLandscape,
                          maxContentWidth: contentMaxWidth,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required bool isLandscape,
    required bool isCompactWidth,
    required double horizontalPadding,
  }) {
    final logoSize =
        isLandscape
            ? LogoSize.tiny
            : (isCompactWidth ? LogoSize.tiny : LogoSize.small);
    final headerTop = isLandscape ? 4.0 : (isCompactWidth ? 8.0 : 16.0);
    final headerBottom = isLandscape ? 2.0 : (isCompactWidth ? 4.0 : 6.0);
    // FIX: buttons always on the right — sizes stay the same as before
    final controlSize = isLandscape ? 28.0 : (isCompactWidth ? 34.0 : 40.0);
    final controlGap = isLandscape ? 5.0 : (isCompactWidth ? 6.0 : 10.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        headerTop,
        horizontalPadding,
        headerBottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Logo section — constrained so buttons always fit on the right
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SmartExplorersLogo(size: logoSize),
                if (!isLandscape) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Travel stories and trusted experiences',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompactWidth ? 11.0 : 12,
                      height: 1.2,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.68)
                              : AppDesign.midGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Controls always on the RIGHT of the logo ──
          SizedBox(width: controlGap),
          _ThemeModeToggleButton(
            currentThemeMode: widget.currentThemeMode,
            onToggled:
                () => widget.onThemeModeSelected(
                  widget.currentThemeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                ),
            isDark: isDark,
            compact: isLandscape,
          ),
          SizedBox(width: controlGap),
          _GlassIconButton(
            icon: LucideIcons.search,
            isDark: isDark,
            size: controlSize,
            iconColor: isDark ? Colors.white : AppDesign.eerieBlack,
            onTap: _openSearchSheet,
          ),
          SizedBox(width: controlGap),
          _GlassIconButton(
            icon: LucideIcons.bell,
            isDark: isDark,
            size: controlSize,
            iconColor: isDark ? Colors.white : AppDesign.eerieBlack,
            onTap: _openNotificationsSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar({
    required bool isDark,
    required bool isLandscape,
    required double horizontalPadding,
  }) {
    final isCompactWidth = MediaQuery.of(context).size.width < 430;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isLandscape ? 2 : (isCompactWidth ? 6 : 8),
        horizontalPadding,
        0,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? Colors.white : AppDesign.eerieBlack,
        unselectedLabelColor: AppDesign.midGrey,
        indicatorColor: isDark ? Colors.white : AppDesign.eerieBlack,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: isLandscape,
        dividerColor:
            isDark ? Colors.white.withValues(alpha: 0.06) : AppDesign.lightGrey,
        dividerHeight: 0.5,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: TextStyle(
          fontSize: isLandscape ? 12.0 : 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isLandscape ? 12.0 : 13.5,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        tabs: [
          Tab(height: isLandscape ? 30 : null, text: 'Posts'),
          Tab(height: isLandscape ? 30 : null, text: 'Spaces'),
          Tab(height: isLandscape ? 30 : null, text: 'Providers'),
        ],
      ),
    );
  }
}

// ── Glass Icon Button ───────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.isDark,
    required this.size,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final double size;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(icon, size: size * 0.48, color: iconColor),
          ),
        ),
      ),
    );
  }
}

// ── Theme Toggle Button ────────────────────────────────────────────────
class _ThemeModeToggleButton extends StatelessWidget {
  const _ThemeModeToggleButton({
    required this.currentThemeMode,
    required this.onToggled,
    required this.isDark,
    required this.compact,
  });

  final ThemeMode currentThemeMode;
  final VoidCallback onToggled;
  final bool isDark;
  final bool compact;

  bool get _isDark => currentThemeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 44.0 : 58.0;
    final height = compact ? 24.0 : 32.0;

    return Semantics(
      button: true,
      toggled: _isDark,
      label: _isDark ? 'Dark mode on' : 'Light mode on',
      child: GestureDetector(
        onTap: onToggled,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: width,
              height: height,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment:
                        _isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: height - 4,
                      height: height - 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isDark ? Colors.white : AppDesign.eerieBlack,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        LucideIcons.sun_medium,
                        size: compact ? 10 : 13,
                        color: _isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        LucideIcons.moon,
                        size: compact ? 10 : 13,
                        color: _isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet();

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  static final List<_SearchResultData> _results = [
    const _SearchResultData(
      title: 'Cairo Weekend Explorers',
      subtitle: 'Travel space • 1,243 members',
      type: 'Space',
      icon: LucideIcons.users,
      accent: AppDesign.navExplore,
    ),
    _SearchResultData(
      title: 'Mohamed Ali',
      subtitle: 'Certified Egyptologist & Guide',
      type: 'Provider',
      icon: LucideIcons.search,
      accent: AppDesign.navProfile,
    ),
    const _SearchResultData(
      title: 'Sunrise at the Pyramids',
      subtitle: 'Popular post • 182 likes',
      type: 'Post',
      icon: LucideIcons.newspaper,
      accent: AppDesign.onboardingAccent,
    ),
    const _SearchResultData(
      title: 'Red Sea Divers',
      subtitle: 'Travel space • Trending now',
      type: 'Space',
      icon: LucideIcons.waves,
      accent: AppDesign.navSafety,
    ),
    const _SearchResultData(
      title: 'Verified guides in Luxor',
      subtitle: 'Provider match • 4.9 rating',
      type: 'Provider',
      icon: LucideIcons.badge_check,
      accent: AppDesign.navItinerary,
    ),
  ];

  final List<String> _quickFilters = const [
    'Spaces',
    'Providers',
    'Posts',
    'Verified',
  ];

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredResults =
        _results.where((result) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return result.title.toLowerCase().contains(query) ||
              result.subtitle.toLowerCase().contains(query) ||
              result.type.toLowerCase().contains(query);
        }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _SheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppDesign.eerieBlack,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredResults.length} results',
                      style: TextStyle(fontSize: 13, color: AppDesign.midGrey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search posts, spaces, providers...',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: AppDesign.midGrey,
                    ),
                    suffixIcon:
                        _query.isEmpty
                            ? null
                            : IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: Icon(
                                LucideIcons.x,
                                color: AppDesign.midGrey,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final label = _quickFilters[index];
                    return ActionChip(
                      label: Text(label),
                      onPressed: () {
                        _searchController.text = label;
                        _searchController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: label.length),
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: _quickFilters.length,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    filteredResults.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.search_x,
                                size: 44,
                                color: AppDesign.midGrey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : AppDesign.eerieBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try a different keyword or filter.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppDesign.midGrey,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemBuilder: (context, index) {
                            final result = filteredResults[index];
                            return _SearchResultTile(
                              data: result,
                              isDark: isDark,
                              onTap: () {
                                _searchController.text = result.title;
                                _searchController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: result.title.length),
                                );
                              },
                            );
                          },
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemCount: filteredResults.length,
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationsBottomSheet extends StatefulWidget {
  const _NotificationsBottomSheet();

  @override
  State<_NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<_NotificationsBottomSheet> {
  final List<_NotificationData> _notifications = [
    _NotificationData(
      title: 'New match request',
      subtitle: 'A provider accepted your travel request for Luxor.',
      timeLabel: '2m',
      icon: LucideIcons.badge_check,
      accent: AppDesign.navSafety,
      unread: true,
    ),
    _NotificationData(
      title: 'Travel space update',
      subtitle: 'Cairo Weekend Explorers posted 3 new trip ideas.',
      timeLabel: '18m',
      icon: LucideIcons.users,
      accent: AppDesign.navExplore,
      unread: true,
    ),
    _NotificationData(
      title: 'Saved itinerary reminder',
      subtitle: 'Your Red Sea itinerary starts tomorrow morning.',
      timeLabel: '1h',
      icon: LucideIcons.calendar_clock,
      accent: AppDesign.navItinerary,
      unread: false,
    ),
    _NotificationData(
      title: 'Provider reply',
      subtitle: 'Mohamed Ali replied to your guide booking message.',
      timeLabel: '3h',
      icon: LucideIcons.message_circle,
      accent: AppDesign.navProfile,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((item) => item.unread).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _SheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppDesign.eerieBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unreadCount == 0
                                ? 'You are all caught up'
                                : '$unreadCount unread updates',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppDesign.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final notification in _notifications) {
                            notification.unread = false;
                          }
                        });
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _NotificationTile(
                      data: notification,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          notification.unread = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 10),
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: isDark ? Colors.white24 : AppDesign.lightGrey,
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  final _SearchResultData data;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppDesign.offWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppDesign.lightGrey,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accent.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Icon(data.icon, color: data.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                      ),
                      Text(
                        data.type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: data.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(fontSize: 13, color: AppDesign.midGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  final _NotificationData data;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              data.unread
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppDesign.offWhite)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                data.unread
                    ? data.accent.withValues(alpha: isDark ? 0.22 : 0.16)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppDesign.lightGrey),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accent.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Icon(data.icon, color: data.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                data.unread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                      ),
                      Text(
                        data.timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppDesign.midGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppDesign.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (data.unread) ...[
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppDesign.onboardingAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultData {
  const _SearchResultData({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final Color accent;
}

class _NotificationData {
  _NotificationData({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.accent,
    required this.unread,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final Color accent;
  bool unread;
}

// ── Posts Tab ────────────────────────────────────────────────────────────
class _PostsTab extends StatefulWidget {
  const _PostsTab({
    required this.isDark,
    required this.isLandscape,
    required this.maxContentWidth,
  });

  final bool isDark;
  final bool isLandscape;
  final double maxContentWidth;

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final SocialApiService _socialService = SocialApiService();
  List<_PostData> _allPosts = [];
  List<_PostData> _posts = [];
  bool _loading = true;
  _ExploreSortMode _sortMode = _ExploreSortMode.mostRecent;

  static const _defaultImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/smart_itineraries.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/verified_guides.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final currentUserId = SessionStore.instance.userId;
      final data = await _socialService.getPosts(userId: currentUserId);
      if (data.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _allPosts =
              data.asMap().entries.map((e) {
                final p = e.value;
                final createdAt = p['created_at']?.toString() ?? '';
                final authorName =
                    p['author_name']?.toString() ??
                    p['author_username']?.toString() ??
                    'Traveler';
                final authorHandle =
                    p['author_username'] != null
                        ? '@${p['author_username']}'
                        : '@traveler';
                final authorAvatar = p['author_avatar']?.toString() ?? '';
                final media =
                    p['media_url']?.toString() ??
                    (p['media_urls'] is List
                        ? (p['media_urls'] as List).isNotEmpty
                            ? (p['media_urls'] as List)[0].toString()
                            : ''
                        : '');
                final comments = p['comments'] ?? p['comments_list'] ?? [];
                final likes = p['likes'] ?? p['likes_list'] ?? [];
                return _PostData(
                  id: p['_id']?.toString() ?? '${e.key}',
                  author: authorName,
                  handle: authorHandle,
                  authorAvatar: authorAvatar,
                  authorId: p['author_id']?.toString() ?? '',
                  text:
                      p['caption']?.toString() ?? p['text']?.toString() ?? '',
                  image:
                      media.isNotEmpty
                          ? media
                          : _defaultImages[e.key % _defaultImages.length],
                  createdAt: createdAt,
                  commentsList: comments is List ? comments : [],
                  likesList: likes is List ? likes : [],
                  bookmarked: p['bookmarked'] == true,
                );
              }).toList();
          _posts = _buildSortedPosts(_allPosts);
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _allPosts = [];
        _posts = [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allPosts = [];
        _posts = [];
        _loading = false;
      });
    }
  }

  List<_PostData> _buildSortedPosts(List<_PostData> source) {
    final currentUserId = SessionStore.instance.userId;
    final posts = List<_PostData>.from(source);

    switch (_sortMode) {
      case _ExploreSortMode.oldest:
        posts.sort(
          (a, b) => _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt)),
        );
        break;
      case _ExploreSortMode.mostRecent:
        posts.sort(
          (a, b) => _parseDate(b.createdAt).compareTo(_parseDate(a.createdAt)),
        );
        break;
      case _ExploreSortMode.highestInteractions:
        posts.sort(
          (a, b) => _postInteractions(b).compareTo(_postInteractions(a)),
        );
        break;
      case _ExploreSortMode.mostRelevant:
        if (currentUserId != null) {
          posts.removeWhere((post) => post.authorId == currentUserId);
        }
        posts.sort((a, b) {
          final interactionsDiff =
              _postInteractions(b).compareTo(_postInteractions(a));
          if (interactionsDiff != 0) return interactionsDiff;
          return _parseDate(b.createdAt).compareTo(_parseDate(a.createdAt));
        });
        break;
    }

    return posts;
  }

  DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  int _postInteractions(_PostData post) =>
      post.likesList.length + post.commentsList.length;

  void _applySort(_ExploreSortMode mode) {
    if (_sortMode == mode) return;
    setState(() {
      _sortMode = mode;
      _posts = _buildSortedPosts(_allPosts);
    });
  }

  Future<void> _openCreatePostPage() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    if (created == true && mounted) {
      _loadPosts();
    }
  }

  @override
  void dispose() {
    _socialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // FIX: Reduced from 0.70 → 0.62 so the actions row is never clipped.
    // The card width in landscape = 62% of screen height.
    final landscapeCardSize = screenHeight * 0.62;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.isLandscape ? 14 : 20,
            widget.isLandscape ? 5 : 10,
            widget.isLandscape ? 14 : 20,
            widget.isLandscape ? 3 : 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: widget.isLandscape ? 14 : 18,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
              ),
              _SortMenuButton(
                sortMode: _sortMode,
                isDark: widget.isDark,
                onSelected: _applySort,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _openCreatePostPage,
                icon: Icon(
                  LucideIcons.plus,
                  size: widget.isLandscape ? 13 : 16,
                ),
                label: Text(
                  'Add Post',
                  style: TextStyle(fontSize: widget.isLandscape ? 11 : 14),
                ),
                style:
                    widget.isLandscape
                        ? TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                        : null,
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.newspaper,
                          size: 48,
                          color: AppDesign.midGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: TextStyle(color: AppDesign.midGrey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    scrollDirection:
                        widget.isLandscape ? Axis.horizontal : Axis.vertical,
                    padding: EdgeInsets.fromLTRB(
                      widget.isLandscape ? 10 : 0,
                      0,
                      widget.isLandscape ? 10 : 0,
                      widget.isLandscape
                          ? 0
                          : MediaQuery.of(context).padding.bottom + 100,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, i) {
                      if (widget.isLandscape) {
                        return SizedBox(
                          width: landscapeCardSize,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _PostCard(
                              post: _posts[i],
                              isDark: widget.isDark,
                              isLandscape: true,
                              bookmarked: false,
                              landscapeCardSize: landscapeCardSize,
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: SizedBox(
                          width: widget.maxContentWidth,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: _PostCard(
                              post: _posts[i],
                              isDark: widget.isDark,
                              isLandscape: false,
                              bookmarked: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

enum _ExploreSortMode { oldest, mostRecent, highestInteractions, mostRelevant }

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({
    required this.sortMode,
    required this.isDark,
    required this.onSelected,
  });

  final _ExploreSortMode sortMode;
  final bool isDark;
  final ValueChanged<_ExploreSortMode> onSelected;

  String get _label {
    switch (sortMode) {
      case _ExploreSortMode.oldest:
        return 'Oldest';
      case _ExploreSortMode.mostRecent:
        return 'Most recent';
      case _ExploreSortMode.highestInteractions:
        return 'Top interactions';
      case _ExploreSortMode.mostRelevant:
        return 'Most relevant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : AppDesign.eerieBlack;
    final border = isDark ? Colors.white12 : AppDesign.lightGrey;
    final background = isDark ? AppDesign.cardDark : Colors.white;

    return PopupMenuButton<_ExploreSortMode>(
      tooltip: 'Sort posts',
      onSelected: onSelected,
      color: background,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder:
          (context) => [
            _popupItem(
              value: _ExploreSortMode.oldest,
              selected: sortMode == _ExploreSortMode.oldest,
              label: 'Oldest',
            ),
            _popupItem(
              value: _ExploreSortMode.mostRecent,
              selected: sortMode == _ExploreSortMode.mostRecent,
              label: 'Most recent',
            ),
            _popupItem(
              value: _ExploreSortMode.highestInteractions,
              selected: sortMode == _ExploreSortMode.highestInteractions,
              label: 'Highest interactions',
            ),
            _popupItem(
              value: _ExploreSortMode.mostRelevant,
              selected: sortMode == _ExploreSortMode.mostRelevant,
              label: 'Most relevant',
            ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_down, size: 14, color: foreground),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_ExploreSortMode> _popupItem({
    required _ExploreSortMode value,
    required bool selected,
    required String label,
  }) {
    return PopupMenuItem<_ExploreSortMode>(
      value: value,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (selected) const Icon(LucideIcons.check, size: 16),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.isDark,
    required this.isLandscape,
    required this.bookmarked,
    this.landscapeCardSize,
  });
  final _PostData post;
  final bool isDark;
  final bool isLandscape;
  final bool bookmarked;
  final double? landscapeCardSize;

  @override
  State<_PostCard> createState() => _PostCardState();
}

String _formatTimeAgo(String iso) {
  if (iso.isEmpty) return 'Just now';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return 'Just now';
  }
}

class _PostCardState extends State<_PostCard> {
  late int _likes;
  bool _liked = false;
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likesList.length;
    final currentUserId = SessionStore.instance.userId;
    _liked =
        currentUserId != null && widget.post.likesList.contains(currentUserId);
    _bookmarked = widget.bookmarked;
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookmarked != widget.bookmarked) {
      _bookmarked = widget.bookmarked;
    }
    if (oldWidget.post.likesList.length != widget.post.likesList.length) {
      _likes = widget.post.likesList.length;
    }
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final userId = SessionStore.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to like posts')));
      return;
    }
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    try {
      if (_liked) {
        await SocialApiService().likePost(widget.post.id, userId);
      } else {
        await SocialApiService().unlikePost(widget.post.id, userId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final userId = SessionStore.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to save posts')));
      return;
    }

    final previous = _bookmarked;
    setState(() => _bookmarked = !_bookmarked);

    try {
      if (_bookmarked) {
        await SocialApiService().saveFavorite({
          'user_id': userId,
          'post_id': widget.post.id,
          'author_id': widget.post.authorId,
          'author_name': widget.post.author,
          'author_username':
              widget.post.handle.startsWith('@')
                  ? widget.post.handle.substring(1)
                  : widget.post.handle,
          'author_avatar': widget.post.authorAvatar,
          'text': widget.post.text,
          'media_url': widget.post.image,
          'created_at': widget.post.createdAt,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await SocialApiService().removeFavorite(userId, widget.post.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bookmarked ? 'Post saved' : 'Post removed from saved',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarked = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update saved posts')),
      );
    }
  }

  void _sharePost() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final comments = List<Map<String, dynamic>>.from(
          widget.post.commentsList.map(
            (c) =>
                c is Map
                    ? Map<String, dynamic>.from(c)
                    : {'text': c.toString()},
          ),
        );
        final TextEditingController commentController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: widget.isDark ? AppDesign.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color:
                            widget.isDark
                                ? Colors.white24
                                : AppDesign.lightGrey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Comments (${comments.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            widget.isDark ? Colors.white : AppDesign.eerieBlack,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        comments.isEmpty
                            ? Center(
                              child: Text(
                                'No comments yet',
                                style: TextStyle(color: AppDesign.midGrey),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: comments.length,
                              itemBuilder: (ctx, i) {
                                final c = comments[i];
                                final authorName =
                                    c['author_name'] ??
                                    c['author_username'] ??
                                    'Traveler';
                                final text = c['text']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppDesign.electricCobalt
                                              .withValues(alpha: 0.12),
                                        ),
                                        child: const Icon(LucideIcons.user),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              authorName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    widget.isDark
                                                        ? Colors.white
                                                        : AppDesign.eerieBlack,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              text,
                                              style: TextStyle(
                                                color: AppDesign.midGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              filled: true,
                              fillColor:
                                  widget.isDark
                                      ? AppDesign.cardDark
                                      : AppDesign.offWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;
                            final userId = SessionStore.instance.userId;
                            final username = SessionStore.instance.username;
                            try {
                              await SocialApiService().addComment(
                                widget.post.id,
                                {'author_id': userId, 'text': text},
                              );
                              setModalState(() {
                                comments.insert(0, {
                                  'author_id': userId,
                                  'author_username': username,
                                  'text': text,
                                  'created_at':
                                      DateTime.now().toUtc().toIso8601String(),
                                });
                                commentController.clear();
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add comment: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Increased overhead so the actions row is never clipped.
    // post-header (~44px) + top-padding (8px) + bottom-padding (10px)
    // + actions-row (~28px compact) + gap (8px) + border (2px) = ~100px.
    // Use 120px for a comfortable safety buffer.
    const landscapeOverhead = 120.0;
    final landscapeImageHeight =
        widget.isLandscape && widget.landscapeCardSize != null
            ? widget.landscapeCardSize! - landscapeOverhead
            : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isLandscape ? 0 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isLandscape ? 20 : 28),
        color: widget.isDark ? AppDesign.cardDark : Colors.white,
        border: Border.all(
          color:
              widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppDesign.lightGrey.withValues(alpha: 0.8),
        ),
        boxShadow:
            widget.isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            post: widget.post,
            isDark: widget.isDark,
            bookmarked: _bookmarked,
            onBookmarkTap: _toggleBookmark,
            compact: widget.isLandscape,
          ),
          GestureDetector(
            onDoubleTap: () {
              if (!_liked) _toggleLike();
            },
            child: _PostMedia(
              image: widget.post.image,
              isDark: widget.isDark,
              height:
                  widget.isLandscape
                      ? landscapeImageHeight
                      : (MediaQuery.of(context).size.width < 430 ? 220 : 260),
            ),
          ),
          Padding(
            padding:
                widget.isLandscape
                    ? const EdgeInsets.fromLTRB(12, 8, 12, 10)
                    : const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isLandscape) ...[
                  Text(
                    widget.post.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color:
                          widget.isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppDesign.eerieBlack,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _PostActions(
                  likes: _likes,
                  comments: widget.post.commentsList.length,
                  liked: _liked,
                  onLikeTap: _toggleLike,
                  onCommentsTap: _showComments,
                  onShareTap: _sharePost,
                  compact: widget.isLandscape,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spaces Tab ──────────────────────────────────────────────────────────
class _SpacesTab extends StatefulWidget {
  const _SpacesTab({
    required this.isDark,
    required this.isLandscape,
    required this.maxContentWidth,
  });
  final bool isDark;
  final bool isLandscape;
  final double maxContentWidth;

  @override
  State<_SpacesTab> createState() => _SpacesTabState();
}

class _SpacesTabState extends State<_SpacesTab> {
  final SocialApiService _socialService = SocialApiService();
  List<_SpaceData> _spaces = [];
  bool _loading = true;

  static const _defaultImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/smart_itineraries.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/verified_guides.jpg',
  ];

  static final _fallbackSpaces = [
    _SpaceData(
      name: 'Cairo Weekend Explorers',
      members: 1243,
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
      tag: 'Popular',
    ),
    _SpaceData(
      name: 'Luxor & Upper Egypt',
      members: 876,
      image: 'lib/public/smart_itineraries.jpg',
      tag: 'Active',
    ),
    _SpaceData(
      name: 'Red Sea Divers',
      members: 2100,
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
      tag: 'Trending',
    ),
    _SpaceData(
      name: 'Solo Female Travelers',
      members: 654,
      image: 'lib/public/verified_guides.jpg',
      tag: 'Safe',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final data = await _socialService.getTravelSpaces();
      if (data.isNotEmpty) {
        setState(() {
          _spaces =
              data.asMap().entries.map((e) {
                final s = e.value;
                return _SpaceData(
                  name: s['name'] ?? 'Space',
                  members:
                      (s['member_count'] as num?)?.toInt() ??
                      (s['members'] as num?)?.toInt() ??
                      0,
                  image: _defaultImages[e.key % _defaultImages.length],
                  tag: s['tag'] ?? 'Active',
                );
              }).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _spaces = _fallbackSpaces;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _socialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 48, color: AppDesign.midGrey),
            const SizedBox(height: 12),
            Text(
              'No travel spaces yet',
              style: TextStyle(color: AppDesign.midGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      scrollDirection: widget.isLandscape ? Axis.horizontal : Axis.vertical,
      padding: EdgeInsets.fromLTRB(
        widget.isLandscape ? 20 : 0,
        8,
        widget.isLandscape ? 20 : 0,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: _spaces.length,
      itemBuilder:
          (context, i) => Center(
            child: SizedBox(
              width: widget.isLandscape ? 340 : widget.maxContentWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isLandscape ? 24 : 20,
                ),
                child: _SpaceCard(space: _spaces[i], isDark: widget.isDark),
              ),
            ),
          ),
    );
  }
}

class _SpaceCard extends StatefulWidget {
  const _SpaceCard({required this.space, required this.isDark});
  final _SpaceData space;
  final bool isDark;

  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends State<_SpaceCard> {
  bool _joined = false;

  void _toggleJoin() {
    HapticFeedback.lightImpact();
    setState(() => _joined = !_joined);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _joined
              ? 'Joined ${widget.space.name}'
              : 'Left ${widget.space.name}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openSpaceDetail() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TravelSpaceDetailScreen(
              spaceName: widget.space.name,
              memberCount: widget.space.members,
              image: widget.space.image,
              tag: widget.space.tag,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSpaceDetail,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              widget.isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _LoadingBlurImage(
                key: ValueKey(widget.space.image),
                image: widget.space.image,
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withValues(alpha: 0.45)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.space.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.space.members} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleJoin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    _joined
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _joined ? 'Joined' : 'Join',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Providers Tab ───────────────────────────────────────────────────────
class _ProvidersTab extends StatefulWidget {
  const _ProvidersTab({
    required this.isDark,
    required this.isLandscape,
    required this.maxContentWidth,
  });
  final bool isDark;
  final bool isLandscape;
  final double maxContentWidth;

  @override
  State<_ProvidersTab> createState() => _ProvidersTabState();
}

enum _BrowseMode { providers, services }

class _ProvidersTabState extends State<_ProvidersTab> {
  final MatchingApiService _matchingService = MatchingApiService();
  final ProfileApiService _profileService = ProfileApiService();
  final ServicesApiService _servicesService = ServicesApiService();

  _BrowseMode _mode = _BrowseMode.providers;
  String _searchQuery = '';
  bool _loadingProviders = true;
  bool _loadingServices = true;
  String? _providerError;
  String? _serviceError;
  List<_ProviderResult> _providers = [];
  List<Service> _services = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _loadServices();
  }

  @override
  void dispose() {
    _matchingService.dispose();
    _profileService.dispose();
    _servicesService.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });

    try {
      final username = SessionStore.instance.username;
      if (username == null || username.isEmpty) {
        throw Exception('No active session found.');
      }

      final user = await _profileService.getUserByUsername(username);
      final email = user['email']?.toString() ?? '';
      if (email.isEmpty) {
        throw Exception('Could not resolve your account email.');
      }

      final result = await _matchingService.findMatches(
        userEmail: email,
        includeProviders: true,
        includeTravelers: false,
        topK: 20,
      );

      final rawMatches =
          (result['matches'] as List? ?? const []).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _providers =
            rawMatches
                .where(
                  (match) =>
                      match['account_type']?.toString() == 'service_provider',
                )
                .map(_ProviderResult.fromJson)
                .toList();
        _loadingProviders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _providerError = e.toString().replaceFirst('Exception: ', '');
        _loadingProviders = false;
      });
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _serviceError = null;
    });

    try {
      final userId = SessionStore.instance.userId ?? 'user_001';
      final rawServices = await _servicesService.discoverServices(
        userId: userId,
        limit: 40,
      );

      if (!mounted) return;
      setState(() {
        _services = rawServices.map(Service.fromJson).toList();
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serviceError = 'Failed to load services: $e';
        _loadingServices = false;
      });
    }
  }

  List<_ProviderResult> get _filteredProviders {
    if (_searchQuery.isEmpty) return _providers;
    final query = _searchQuery.toLowerCase();
    return _providers.where((provider) {
      return provider.name.toLowerCase().contains(query) ||
          provider.email.toLowerCase().contains(query) ||
          provider.bio.toLowerCase().contains(query) ||
          provider.serviceType.toLowerCase().contains(query) ||
          provider.matchReasons.any(
            (reason) => reason.toLowerCase().contains(query),
          ) ||
          provider.commonInterests.any(
            (interest) => interest.toLowerCase().contains(query),
          );
    }).toList();
  }

  List<Service> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    final query = _searchQuery.toLowerCase();
    return _services.where((service) {
      return service.serviceName.toLowerCase().contains(query) ||
          service.serviceType.toLowerCase().contains(query) ||
          (service.description ?? '').toLowerCase().contains(query) ||
          service.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          (service.providerName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _openProviderProfile(_ProviderResult provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => UserProfileViewScreen(
              userId: provider.id,
              displayName: provider.name,
              accountType: 'service_provider',
            ),
      ),
    );
  }

  void _openServiceDetail(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surface = isDark ? AppDesign.cardDark : AppDesign.offWhite;
    final card = isDark ? AppDesign.cardDark : Colors.white;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white70 : AppDesign.midGrey;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : AppDesign.lightGrey;

    final providers = _filteredProviders;
    final services = _filteredServices;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.isLandscape ? 24 : 20,
            10,
            widget.isLandscape ? 24 : 20,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Providers & Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    _mode == _BrowseMode.providers
                        ? _loadProviders
                        : _loadServices,
                icon: const Icon(LucideIcons.refresh_cw, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLandscape ? 24 : 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Providers',
                    isSelected: _mode == _BrowseMode.providers,
                    isDark: isDark,
                    color: AppDesign.navConcierge,
                    icon: LucideIcons.users,
                    onTap: () => setState(() => _mode = _BrowseMode.providers),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: 'Services',
                    isSelected: _mode == _BrowseMode.services,
                    isDark: isDark,
                    color: AppDesign.navExplore,
                    icon: LucideIcons.briefcase,
                    onTap: () => setState(() => _mode = _BrowseMode.services),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLandscape ? 24 : 20,
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText:
                  _mode == _BrowseMode.providers
                      ? 'Search providers'
                      : 'Search services',
              prefixIcon: Icon(LucideIcons.search, color: muted),
              filled: true,
              fillColor: surface,
              hintStyle: TextStyle(color: muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppDesign.navConcierge,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLandscape ? 24 : 20,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _mode == _BrowseMode.providers
                  ? '${providers.length} providers available'
                  : '${services.length} services available',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child:
                _mode == _BrowseMode.providers
                    ? _buildProvidersView(
                      providers,
                      isDark: isDark,
                      card: card,
                      text: text,
                      muted: muted,
                      border: border,
                    )
                    : _buildServicesView(
                      services,
                      isDark: isDark,
                      card: card,
                      text: text,
                      muted: muted,
                      border: border,
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildProvidersView(
    List<_ProviderResult> providers, {
    required bool isDark,
    required Color card,
    required Color text,
    required Color muted,
    required Color border,
  }) {
    if (_loadingProviders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_providerError != null) {
      return _EmptyState(
        title: 'Providers unavailable',
        message: _providerError!,
        icon: LucideIcons.users,
        onRetry: _loadProviders,
      );
    }

    if (providers.isEmpty) {
      return _EmptyState(
        title: 'No providers found',
        message: 'Try a different search term or refresh the results.',
        icon: LucideIcons.users,
        onRetry: _loadProviders,
      );
    }

    return ListView.separated(
      key: const ValueKey('providers'),
      padding: EdgeInsets.fromLTRB(
        widget.isLandscape ? 24 : 20,
        0,
        widget.isLandscape ? 24 : 20,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ProviderCard(
          provider: providers[index],
          isDark: isDark,
          card: card,
          text: text,
          muted: muted,
          border: border,
          onTap: () => _openProviderProfile(providers[index]),
        );
      },
    );
  }

  Widget _buildServicesView(
    List<Service> services, {
    required bool isDark,
    required Color card,
    required Color text,
    required Color muted,
    required Color border,
  }) {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_serviceError != null) {
      return _EmptyState(
        title: 'Services unavailable',
        message: _serviceError!,
        icon: LucideIcons.briefcase,
        onRetry: _loadServices,
      );
    }

    if (services.isEmpty) {
      return _EmptyState(
        title: 'No services found',
        message: 'Try a different search term or refresh the results.',
        icon: LucideIcons.search,
        onRetry: _loadServices,
      );
    }

    return ListView.separated(
      key: const ValueKey('services'),
      padding: EdgeInsets.fromLTRB(
        widget.isLandscape ? 24 : 20,
        0,
        widget.isLandscape ? 24 : 20,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ServiceCard(
          service: services[index],
          isDark: isDark,
          card: card,
          text: text,
          muted: muted,
          border: border,
          onTap: () => _openServiceDetail(services[index]),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppDesign.eerieBlack);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
    required this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white54 : AppDesign.midGrey;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: muted),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isDark,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.onTap,
  });

  final _ProviderResult provider;
  final bool isDark;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreColor =
        provider.score >= 0.8
            ? AppDesign.success
            : provider.score >= 0.6
            ? AppDesign.warning
            : AppDesign.danger;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(label: provider.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          color: text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                            label: 'Service Provider',
                            color: AppDesign.navConcierge,
                          ),
                          if (provider.serviceType.isNotEmpty)
                            _Chip(
                              label: provider.serviceType.replaceAll('_', ' '),
                              color: scoreColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${(provider.score * 100).round()}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (provider.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                provider.email,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            if (provider.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                provider.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, height: 1.35),
              ),
            ],
            if (provider.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    provider.matchReasons.take(3).map((reason) {
                      return _Chip(label: reason, color: AppDesign.navSafety);
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.isDark,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.onTap,
  });

  final Service service;
  final bool isDark;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppDesign.navExplore.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.briefcase,
                    color: AppDesign.navExplore,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: TextStyle(
                          color: text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.providerName ?? 'Unknown provider',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (service.rating > 0)
                  _Chip(
                    label: service.rating.toStringAsFixed(1),
                    color: AppDesign.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.serviceType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                service.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, height: 1.35),
              ),
            ],
            if (service.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    service.tags.take(4).map((tag) {
                      return _Chip(label: tag, color: AppDesign.navExplore);
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppDesign.navConcierge, AppDesign.navExplore],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProviderResult {
  const _ProviderResult({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.score,
    required this.accountType,
    required this.commonInterests,
    required this.matchReasons,
    required this.serviceType,
  });

  final String id;
  final String name;
  final String email;
  final String bio;
  final double score;
  final String accountType;
  final List<String> commonInterests;
  final List<String> matchReasons;
  final String serviceType;

  factory _ProviderResult.fromJson(Map<String, dynamic> json) {
    return _ProviderResult(
      id: json['user_id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? 'Unknown Provider',
      email: json['email']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      score: ((json['match_score'] ?? 0) as num).toDouble(),
      accountType: json['account_type']?.toString() ?? 'service_provider',
      commonInterests:
          (json['common_interests'] as List?)?.cast<String>() ?? const [],
      matchReasons:
          (json['match_reasons'] as List?)?.cast<String>() ?? const [],
      serviceType: json['service_type']?.toString() ?? '',
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.isDark,
    required this.bookmarked,
    required this.onBookmarkTap,
    this.compact = false,
  });

  final _PostData post;
  final bool isDark;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 13.0 : 18.0;
    return Padding(
      padding:
          compact
              ? const EdgeInsets.fromLTRB(12, 8, 12, 6)
              : const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppDesign.electricCobalt,
                  AppDesign.electricCobalt.withValues(alpha: 0.38),
                ],
              ),
            ),
            child:
                post.authorAvatar.isNotEmpty
                    ? CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: NetworkImage(post.authorAvatar),
                    )
                    : CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor:
                          isDark ? AppDesign.cardDark : Colors.white,
                      child: Text(
                        post.author.isNotEmpty ? post.author[0] : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10 : 14,
                          color: AppDesign.electricCobalt,
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11 : 14,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
                Text(
                  '${post.handle} · ${_formatTimeAgo(post.createdAt)}',
                  style: TextStyle(
                    fontSize: compact ? 9 : 12,
                    color: AppDesign.midGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBookmarkTap,
            child: Icon(
              bookmarked ? CupertinoIcons.bookmark_fill : LucideIcons.bookmark,
              size: compact ? 14 : 18,
              color: bookmarked ? const Color(0xFFFFC107) : AppDesign.midGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({
    required this.image,
    required this.isDark,
    required this.height,
  });

  final String image;
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          _LoadingBlurImage(
            key: ValueKey(image),
            image: image,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isDark ? 0.08 : 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.likes,
    required this.comments,
    required this.liked,
    required this.onLikeTap,
    required this.onCommentsTap,
    required this.onShareTap,
    this.compact = false,
  });

  final int likes;
  final int comments;
  final bool liked;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onShareTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 10,
      runSpacing: compact ? 4 : 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ActionPill(
          icon: liked ? LucideIcons.heart_off : LucideIcons.heart,
          label: '$likes',
          active: liked,
          activeColor: AppDesign.danger,
          onTap: onLikeTap,
          compact: compact,
        ),
        _ActionPill(
          icon: LucideIcons.message_circle,
          label: '$comments',
          onTap: onCommentsTap,
          compact: compact,
        ),
        _ActionPill(
          icon: LucideIcons.share,
          label: 'Share',
          onTap: onShareTap,
          compact: compact,
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? activeColor ?? AppDesign.electricCobalt : AppDesign.midGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color:
              active
                  ? color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
            color:
                active
                    ? color.withValues(alpha: 0.22)
                    : AppDesign.lightGrey.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 16, color: color),
            SizedBox(width: compact ? 3 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlurImage extends StatefulWidget {
  const _LoadingBlurImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<_LoadingBlurImage> createState() => _LoadingBlurImageState();
}

class _LoadingBlurImageState extends State<_LoadingBlurImage> {
  bool _revealed = false;

  Widget _fallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppDesign.lightGrey.withValues(alpha: 0.18),
      child: Center(
        child: Icon(
          LucideIcons.image_off,
          size: 22,
          color: AppDesign.midGrey.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.image;
    Widget img;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      img = Image.network(
        src,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
            }
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                child: AnimatedOpacity(
                  opacity: _revealed ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 180),
                  child: child,
                ),
              );
            },
          );
        },
      );
    } else if (src.startsWith('/')) {
      img = Image.network(
        '${ApiConfig.baseUrl}$src',
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
            }
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                child: AnimatedOpacity(
                  opacity: _revealed ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 180),
                  child: child,
                ),
              );
            },
          );
        },
      );
    } else {
      img = Image.asset(
        src,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
            }
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                child: AnimatedOpacity(
                  opacity: _revealed ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 180),
                  child: child,
                ),
              );
            },
          );
        },
      );
    }

    return img;
  }
}

// ── Data Classes ────────────────────────────────────────────────────────
class _PostData {
  final String id;
  final String author;
  final String handle;
  final String authorAvatar;
  final String authorId;
  final String text;
  final String image;
  final String createdAt;
  final List<dynamic> commentsList;
  final List<dynamic> likesList;
  final bool bookmarked;
  _PostData({
    required this.id,
    required this.author,
    required this.handle,
    required this.authorAvatar,
    required this.authorId,
    required this.text,
    required this.image,
    required this.createdAt,
    required this.commentsList,
    required this.likesList,
    required this.bookmarked,
  });
}

class _SpaceData {
  final String name, image, tag;
  final int members;
  _SpaceData({
    required this.name,
    required this.members,
    required this.image,
    required this.tag,
  });
}
