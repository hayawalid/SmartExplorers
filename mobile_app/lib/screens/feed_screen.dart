import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import 'dart:convert';
import '../services/social_api_service.dart';
import '../services/session_store.dart';
import '../services/api_config.dart';
import '../services/marketplace_api_service.dart';
import 'create_post_screen.dart';
import 'write_review_screen.dart';
import 'travel_space_detail_screen.dart';

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
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
        final horizontalPadding = constraints.maxWidth >= 840 ? 32.0 : 20.0;
        final contentMaxWidth =
            constraints.maxWidth >= 840 ? 760.0 : constraints.maxWidth;

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
    required double horizontalPadding,
  }) {
    final logoSize = isLandscape ? LogoSize.tiny : LogoSize.small;
    final headerTop = isLandscape ? 8.0 : 16.0;
    final headerBottom = isLandscape ? 2.0 : 6.0;
    final controlSize = isLandscape ? 36.0 : 40.0;
    final controlGap = isLandscape ? 8.0 : 10.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        headerTop,
        horizontalPadding,
        headerBottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmartExplorersLogo(size: logoSize),
                const SizedBox(height: 2),
                Text(
                  isLandscape
                      ? 'Curated travel stories, spaces, guides'
                      : 'Travel stories and trusted experiences',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLandscape ? 11.5 : 12,
                    height: 1.2,
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.68)
                            : AppDesign.midGrey,
                  ),
                ),
              ],
            ),
          ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
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
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Spaces'),
          Tab(text: 'Providers'),
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
            child: Icon(icon, size: 18, color: iconColor),
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
    final width = compact ? 54.0 : 58.0;
    final height = compact ? 30.0 : 32.0;

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
                      padding: const EdgeInsets.only(left: 7),
                      child: Icon(
                        LucideIcons.sun_medium,
                        size: compact ? 12 : 13,
                        color: _isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Icon(
                        LucideIcons.moon,
                        size: compact ? 12 : 13,
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
      // If feed is empty, show empty state (do not display static fallback cards)
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
                final comments =
                    p['comments'] ??
                    p['comments_list'] ??
                    p['comments_list'] ??
                    [];
                final likes = p['likes'] ?? p['likes_list'] ?? [];
                return _PostData(
                  id: p['_id']?.toString() ?? '${e.key}',
                  author: authorName,
                  handle: authorHandle,
                  authorAvatar: authorAvatar,
                  authorId: p['author_id']?.toString() ?? '',
                  text: p['caption']?.toString() ?? p['text']?.toString() ?? '',
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
      // empty feed
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
          final interactionsDiff = _postInteractions(
            b,
          ).compareTo(_postInteractions(a));
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
                  'Posts',
                  style: TextStyle(
                    fontSize: 18,
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
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: _openCreatePostPage,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Post'),
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
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      MediaQuery.of(context).padding.bottom + 100,
                    ),
                    itemCount: _posts.length,
                    itemBuilder:
                        (context, i) => Center(
                          child: SizedBox(
                            width: widget.maxContentWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.isLandscape ? 24 : 20,
                              ),
                              child: _PostCard(
                                post: _posts[i],
                                isDark: widget.isDark,
                                isLandscape: widget.isLandscape,
                                bookmarked: false,
                              ),
                            ),
                          ),
                        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  });
  final _PostData post;
  final bool isDark;
  final bool isLandscape;
  final bool bookmarked;

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
      // revert on error
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
          content: Text(_bookmarked ? 'Post saved' : 'Post removed from saved'),
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
      isScrollControlled: true,
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

  void _openPostDetail() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (ctx, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppDesign.cardDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
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
                      ClipRRect(
                        child: _LoadingBlurImage(
                          key: ValueKey(widget.post.image),
                          image: widget.post.image,
                          width: double.infinity,
                          height: 320,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                widget.post.authorAvatar.isNotEmpty
                                    ? CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(
                                        widget.post.authorAvatar,
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppDesign.electricCobalt
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        widget.post.author.isNotEmpty
                                            ? widget.post.author[0]
                                            : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppDesign.electricCobalt,
                                        ),
                                      ),
                                    ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.post.author,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color:
                                              widget.isDark
                                                  ? Colors.white
                                                  : AppDesign.eerieBlack,
                                        ),
                                      ),
                                      Text(
                                        '${widget.post.handle} · ${_formatTimeAgo(widget.post.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppDesign.midGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.post.text,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color:
                                    widget.isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppDesign.eerieBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.heart,
                                  size: 18,
                                  color: AppDesign.midGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_likes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppDesign.midGrey,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Icon(
                                  LucideIcons.message_circle,
                                  size: 18,
                                  color: AppDesign.midGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.post.commentsList.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppDesign.midGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useSplitLayout =
        widget.isLandscape || MediaQuery.of(context).size.width >= 640;

    return GestureDetector(
      onTap: _openPostDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
            if (useSplitLayout)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        onDoubleTap: () {
                          if (!_liked) _toggleLike();
                        },
                        child: _PostMedia(
                          image: widget.post.image,
                          isDark: widget.isDark,
                          height: 320,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _PostHeader(
                              post: widget.post,
                              isDark: widget.isDark,
                              bookmarked: _bookmarked,
                              onBookmarkTap: _toggleBookmark,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.post.text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.55,
                                color:
                                    widget.isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppDesign.eerieBlack,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PostActions(
                              likes: _likes,
                              comments: widget.post.commentsList.length,
                              liked: _liked,
                              onLikeTap: _toggleLike,
                              onCommentsTap: _showComments,
                              onShareTap: _sharePost,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _PostHeader(
                post: widget.post,
                isDark: widget.isDark,
                bookmarked: _bookmarked,
                onBookmarkTap: _toggleBookmark,
              ),
              GestureDetector(
                onDoubleTap: () {
                  if (!_liked) _toggleLike();
                },
                child: _PostMedia(
                  image: widget.post.image,
                  isDark: widget.isDark,
                  height: 300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _PostActions(
                      likes: _likes,
                      comments: widget.post.commentsList.length,
                      liked: _liked,
                      onLikeTap: _toggleLike,
                      onCommentsTap: _showComments,
                      onShareTap: _sharePost,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: _spaces.length,
      itemBuilder:
          (context, i) => Center(
            child: SizedBox(
              width: widget.maxContentWidth,
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
          _joined ? 'Joined ${widget.space.name}' : 'Left ${widget.space.name}',
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

class _ProvidersTabState extends State<_ProvidersTab> {
  final MarketplaceApiService _marketplaceService = MarketplaceApiService();
  final SocialApiService _socialService = SocialApiService();
  List<_ProviderData> _providers = [];
  bool _loading = true;

  static const _defaultImages = [
    'lib/public/verified_guides.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/smart_itineraries.jpg',
  ];

  static final _fallbackProviders = [
    _ProviderData(
      name: 'Mohamed Ali',
      specialty: 'Certified Egyptologist & Guide',
      rating: 4.9,
      reviews: 142,
      image: 'lib/public/verified_guides.jpg',
      verified: true,
    ),
    _ProviderData(
      name: 'Fatima Hassan',
      specialty: 'Desert Safari Expert',
      rating: 4.8,
      reviews: 89,
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
      verified: true,
    ),
    _ProviderData(
      name: 'Youssef Kamel',
      specialty: 'Photography Tours',
      rating: 4.7,
      reviews: 67,
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
      verified: false,
    ),
    _ProviderData(
      name: 'Nour Adel',
      specialty: 'Culinary & Heritage Tours',
      rating: 4.9,
      reviews: 210,
      image: 'lib/public/smart_itineraries.jpg',
      verified: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      // Try ranked/verified endpoint first (sorted by verification score)
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/profiles/providers/verified/ranked?limit=50',
      );
      final response = await _socialService.httpClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && mounted) {
          setState(() {
            _providers = data.asMap().entries.map((e) {
              final p = e.value as Map<String, dynamic>;
              final score = (p['verification_score'] as num?)?.toDouble() ?? 0.0;
              final level = p['verification_level'] as String? ?? 'basic';
              return _ProviderData(
                name: p['full_name']?.toString() ?? 'Provider',
                specialty: (p['business_name']?.toString().isNotEmpty == true
                    ? p['business_name'].toString()
                    : p['service_type']?.toString()) ?? 'Service',
                rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
                reviews: (p['review_count'] as num?)?.toInt() ?? 0,
                image: _defaultImages[e.key % _defaultImages.length],
                verified: level == 'verified' || level == 'trusted',
                verificationScore: score,
                verificationLevel: level,
              );
            }).toList();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback to marketplace listings
    try {
      final data = await _marketplaceService.getListings();
      if (data.isNotEmpty && mounted) {
        setState(() {
          _providers = data.asMap().entries.map((e) {
            final p = e.value;
            return _ProviderData(
              name: p['name']?.toString() ?? 'Provider',
              specialty: p['specialty']?.toString() ?? p['category']?.toString() ?? 'Service',
              rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
              reviews: (p['review_count'] as num?)?.toInt() ?? 0,
              image: _defaultImages[e.key % _defaultImages.length],
              verified: p['is_verified'] == true,
            );
          }).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _providers = _fallbackProviders;
      _loading = false;
    });
  }

  Future<void> _openWriteReviewPage() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const WriteReviewScreen()));
    if (created == true && mounted) {
      _loadProviders();
    }
  }

  @override
  void dispose() {
    _marketplaceService.dispose();
    _socialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Providers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openWriteReviewPage,
                icon: const Icon(LucideIcons.pen_line, size: 16),
                label: const Text('Add Review'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _providers.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.briefcase,
                          size: 48,
                          color: AppDesign.midGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No providers yet',
                          style: TextStyle(color: AppDesign.midGrey),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _loading = true);
                      await _loadProviders();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: _providers.length,
                      itemBuilder:
                          (context, i) => Center(
                            child: SizedBox(
                              width: widget.maxContentWidth,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: widget.isLandscape ? 24 : 20,
                                ),
                                child: _ProviderCard(
                                  provider: _providers[i],
                                  isDark: widget.isDark,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.isDark});
  final _ProviderData provider;
  final bool isDark;

  Color _scoreBadgeColor(double score) {
    if (score >= 80) return const Color(0xFF00C566);
    if (score >= 60) return const Color(0xFF1A1A1A);
    if (score >= 40) return const Color(0xFFFFA726);
    return const Color(0xFF9B9BA5);
  }

  void _showProviderDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (ctx, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppDesign.cardDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color:
                                isDark ? Colors.white24 : AppDesign.lightGrey,
                          ),
                        ),
                      ),
                      ClipRRect(
                        child: _LoadingBlurImage(
                          key: ValueKey(provider.image),
                          image: provider.image,
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : AppDesign.eerieBlack,
                                    ),
                                  ),
                                ),
                                if (provider.verified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppDesign.success.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.badge_check,
                                          size: 14,
                                          color: AppDesign.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppDesign.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider.specialty,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppDesign.midGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 18,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${provider.rating}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : AppDesign.eerieBlack,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${provider.reviews} reviews)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppDesign.midGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Booking request sent to ${provider.name}',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Book This Guide',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => WriteReviewScreen(
                                                providerName: provider.name,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.pen_line),
                                    label: const Text('Write Review'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProviderDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppDesign.cardDark : Colors.white,
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
        ),
        child: Row(
          children: [
            // Provider photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: _LoadingBlurImage(
                key: ValueKey(provider.image),
                image: provider.image,
                width: 110,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  isDark ? Colors.white : AppDesign.eerieBlack,
                            ),
                          ),
                        ),
                        if (provider.verified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppDesign.success.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              LucideIcons.badge_check,
                              size: 14,
                              color: AppDesign.success,
                            ),
                          ),
                        if (provider.verificationScore > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: _scoreBadgeColor(provider.verificationScore).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${provider.verificationScore.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _scoreBadgeColor(provider.verificationScore),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.specialty,
                      style: TextStyle(fontSize: 12, color: AppDesign.midGrey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.rating}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${provider.reviews})',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppDesign.midGrey,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showProviderDetail(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppDesign.electricCobalt.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            child: Text(
                              'View',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppDesign.electricCobalt,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.isDark,
    required this.bookmarked,
    required this.onBookmarkTap,
  });

  final _PostData post;
  final bool isDark;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                      radius: 18,
                      backgroundImage: NetworkImage(post.authorAvatar),
                    )
                    : CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          isDark ? AppDesign.cardDark : Colors.white,
                      child: Text(
                        post.author.isNotEmpty ? post.author[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppDesign.electricCobalt,
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
                Text(
                  '${post.handle} · ${_formatTimeAgo(post.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
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
              size: 18,
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
  });

  final int likes;
  final int comments;
  final bool liked;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ActionPill(
          icon: liked ? LucideIcons.heart_off : LucideIcons.heart,
          label: '$likes',
          active: liked,
          activeColor: AppDesign.danger,
          onTap: onLikeTap,
        ),
        _ActionPill(
          icon: LucideIcons.message_circle,
          label: '$comments',
          onTap: onCommentsTap,
        ),
        _ActionPill(icon: LucideIcons.share, label: 'Share', onTap: onShareTap),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? activeColor ?? AppDesign.electricCobalt : AppDesign.midGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

class _ProviderData {
  final String name, specialty, image;
  final double rating;
  final int reviews;
  final bool verified;
  final double verificationScore;
  final String verificationLevel;
  _ProviderData({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.verified,
    this.verificationScore = 0,
    this.verificationLevel = 'basic',
  });
}
