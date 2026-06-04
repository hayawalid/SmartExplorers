// ============================================================================
// feed_screen.dart
// ============================================================================
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
import 'package:mobile_app/screens/provider/create_service_screen.dart';
import 'package:mobile_app/services/notifications_api_service.dart';

/// Social feed with 3 tabs – Posts, Spaces, and either Providers (traveler)
/// or Requests (service provider).
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeSelected,
    required this.userType, // 'traveler' or 'service_provider'
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final String userType;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<String> _tabLabels;
  late final List<Widget> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _initTabs();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  void _initTabs() {
    final isProvider = widget.userType == 'service_provider';
    if (isProvider) {
      _tabLabels = ['Posts', 'Spaces', 'Requests'];
      _tabWidgets = [
        _PostsTab(isProvider: true),
        const _SpacesTab(),
        const _RequestsTab(),
      ];
    } else {
      _tabLabels = ['Posts', 'Spaces', 'Providers'];
      _tabWidgets = [
        _PostsTab(isProvider: false),
        const _SpacesTab(),
        const _ProvidersTab(),
      ];
    }
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
            constraints.maxWidth >= 840 ? 32.0 : (isCompactWidth ? 16.0 : 20.0);
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
                      children: _tabWidgets,
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
        tabs:
            _tabLabels
                .map(
                  (label) => Tab(height: isLandscape ? 30 : null, text: label),
                )
                .toList(),
      ),
    );
  }
}

// ==================== Glass Icon Button ====================
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

// ==================== Theme Toggle Button ====================
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

// ==================== Search Bottom Sheet ====================
// (Full implementation uses real data from backend)
class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet();

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allResults = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final newQuery = _searchController.text;
      if (newQuery != _query) {
        setState(() => _query = newQuery);
        _performSearch(newQuery);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _allResults = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final social = SocialApiService();
      final spacesFuture = social.getTravelSpaces();
      final postsFuture = social.getPosts(userId: SessionStore.instance.userId);
      final matching = MatchingApiService();
      final username = SessionStore.instance.username;
      String? email;
      if (username != null) {
        final profile = ProfileApiService();
        final user = await profile.getUserByUsername(username);
        email = user['email'] as String?;
      }
      List<dynamic> providers = [];
      if (email != null) {
        final matchRes = await matching.findMatches(
          userEmail: email,
          includeProviders: true,
          includeTravelers: false,
          topK: 20,
        );
        providers = (matchRes['matches'] as List?) ?? [];
      }
      final spaces = await spacesFuture;
      final posts = await postsFuture;
      final all = [
        ...spaces.map((s) => {...s, '_type': 'space'}),
        ...posts.map((p) => {...p, '_type': 'post'}),
        ...providers.map((p) => {...p, '_type': 'provider'}),
      ];
      setState(() {
        _allResults =
            all.where((item) {
              final title =
                  (item['name'] ?? item['full_name'] ?? item['title'] ?? '')
                      .toLowerCase();
              return title.contains(query.toLowerCase());
            }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                child: Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
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
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _allResults.isEmpty && _query.isNotEmpty
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
                                style: TextStyle(color: AppDesign.midGrey),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _allResults.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = _allResults[i];
                            final type = item['_type'] as String;
                            String title = '';
                            String subtitle = '';
                            IconData icon = LucideIcons.search;
                            Color accent = AppDesign.navExplore;
                            VoidCallback? onTap;
                            if (type == 'space') {
                              title = item['name'] ?? 'Space';
                              subtitle = '${item['member_count'] ?? 0} members';
                              icon = LucideIcons.users;
                              accent = AppDesign.navExplore;
                              onTap =
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TravelSpaceDetailScreen(
                                            spaceName: title,
                                            memberCount:
                                                item['member_count'] ?? 0,
                                            image: item['image_url'] ?? '',
                                            tag: item['tag'] ?? 'Travel',
                                          ),
                                    ),
                                  );
                            } else if (type == 'post') {
                              title = item['author_name'] ?? 'User';
                              subtitle = item['text'] ?? '';
                              icon = LucideIcons.newspaper;
                              accent = AppDesign.onboardingAccent;
                              onTap = () {
                                // Open post detail (same as _PostCard detail)
                                // We'll just dismiss and let the feed handle? For simplicity, show a snackbar.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Open post detail: $title'),
                                  ),
                                );
                              };
                            } else {
                              title = item['full_name'] ?? 'Provider';
                              subtitle = item['service_type'] ?? '';
                              icon = LucideIcons.badge_check;
                              accent = AppDesign.navConcierge;
                              onTap =
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => UserProfileViewScreen(
                                            userId: item['user_id'] ?? '',
                                            displayName: title,
                                            accountType: 'service_provider',
                                          ),
                                    ),
                                  );
                            }
                            return _SearchResultTile(
                              title: title,
                              subtitle: subtitle,
                              type: type.toUpperCase(),
                              icon: icon,
                              accent: accent,
                              isDark: isDark,
                              onTap: onTap ?? () {},
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });
  final String title, subtitle, type;
  final IconData icon;
  final Color accent;
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
                color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Icon(icon, color: accent, size: 20),
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
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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

// ==================== Notifications Bottom Sheet ====================
class _NotificationsBottomSheet extends StatefulWidget {
  const _NotificationsBottomSheet();

  @override
  State<_NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<_NotificationsBottomSheet> {
  final NotificationsApiService _notifService = NotificationsApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _notifService.getNotifications();
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    await _notifService.markAsRead(id);
    setState(() {
      final index = _notifications.indexWhere((n) => n['_id'] == id);
      if (index != -1) _notifications[index]['is_read'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount =
        _notifications.where((n) => n['is_read'] == false).length;

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
                      onPressed: () async {
                        await _notifService.markAllRead();
                        await _loadNotifications();
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _notifications.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.bell_off,
                                size: 44,
                                color: AppDesign.midGrey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications',
                                style: TextStyle(color: AppDesign.midGrey),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _notifications.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final n = _notifications[i];
                            return _NotificationTile(
                              title: n['title'] ?? '',
                              subtitle: n['body'] ?? '',
                              timeLabel: _formatTimeAgo(n['created_at']),
                              icon: _iconForType(n['type']),
                              accent: _colorForType(n['type']),
                              unread: n['is_read'] == false,
                              onTap: () {
                                _markRead(n['_id']);
                                // Navigate based on notification data
                                final data = n['data'] as Map<String, dynamic>?;
                                if (data != null) {
                                  if (data.containsKey('post_id')) {
                                    // Navigate to post detail (simplified)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Open post: ${data['post_id']}',
                                        ),
                                      ),
                                    );
                                  } else if (data.containsKey(
                                    'conversation_id',
                                  )) {
                                    // Navigate to messaging
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Open chat: ${data['conversation_id']}',
                                        ),
                                      ),
                                    );
                                  } else if (data.containsKey('booking_id')) {
                                    // Navigate to booking detail
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Booking: ${data['booking_id']}',
                                        ),
                                      ),
                                    );
                                  }
                                }
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

  String _formatTimeAgo(String? iso) {
    if (iso == null) return 'Now';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'booking_update':
        return LucideIcons.calendar_check;
      case 'new_message':
        return LucideIcons.message_circle;
      case 'review_received':
        return LucideIcons.star;
      default:
        return LucideIcons.bell;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'booking_update':
        return AppDesign.success;
      case 'new_message':
        return AppDesign.electricCobalt;
      case 'review_received':
        return AppDesign.navExplore;
      default:
        return AppDesign.midGrey;
    }
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.accent,
    required this.unread,
    required this.onTap,
  });
  final String title, subtitle, timeLabel;
  final IconData icon;
  final Color accent;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              unread
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppDesign.offWhite)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                unread
                    ? accent.withValues(alpha: isDark ? 0.22 : 0.16)
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
                color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Icon(icon, color: accent, size: 20),
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
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppDesign.midGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppDesign.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
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

// ==================== Posts Tab ====================
class _PostsTab extends StatefulWidget {
  const _PostsTab({required this.isProvider});
  final bool isProvider;
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
                    (p['media_urls'] is List &&
                            (p['media_urls'] as List).isNotEmpty
                        ? (p['media_urls'] as List)[0].toString()
                        : '');
                final comments = p['comments'] ?? p['comments_list'] ?? [];
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
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
        if (currentUserId != null)
          posts.removeWhere((post) => post.authorId == currentUserId);
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
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true && mounted) _loadPosts();
  }

  @override
  void dispose() {
    _socialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final landscapeCardSize = MediaQuery.of(context).size.height * 0.62;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 14 : 20,
            isLandscape ? 5 : 10,
            isLandscape ? 14 : 20,
            isLandscape ? 3 : 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
              ),
              _SortMenuButton(
                sortMode: _sortMode,
                isDark: isDark,
                onSelected: _applySort,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _openCreatePostPage,
                icon: Icon(LucideIcons.plus, size: isLandscape ? 13 : 16),
                label: Text(
                  'Add Post',
                  style: TextStyle(fontSize: isLandscape ? 11 : 14),
                ),
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
                        isLandscape ? Axis.horizontal : Axis.vertical,
                    padding: EdgeInsets.fromLTRB(
                      isLandscape ? 10 : 0,
                      0,
                      isLandscape ? 10 : 0,
                      isLandscape
                          ? 0
                          : MediaQuery.of(context).padding.bottom + 100,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, i) {
                      if (isLandscape) {
                        return SizedBox(
                          width: landscapeCardSize,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _PostCard(
                              post: _posts[i],
                              isDark: isDark,
                              isLandscape: true,
                              bookmarked: false,
                              landscapeCardSize: landscapeCardSize,
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 40,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _PostCard(
                              post: _posts[i],
                              isDark: isDark,
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
      onSelected: onSelected,
      color: background,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder:
          (context) => [
            _popupItem(
              _ExploreSortMode.oldest,
              sortMode == _ExploreSortMode.oldest,
              'Oldest',
            ),
            _popupItem(
              _ExploreSortMode.mostRecent,
              sortMode == _ExploreSortMode.mostRecent,
              'Most recent',
            ),
            _popupItem(
              _ExploreSortMode.highestInteractions,
              sortMode == _ExploreSortMode.highestInteractions,
              'Highest interactions',
            ),
            _popupItem(
              _ExploreSortMode.mostRelevant,
              sortMode == _ExploreSortMode.mostRelevant,
              'Most relevant',
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

  PopupMenuItem<_ExploreSortMode> _popupItem(
    _ExploreSortMode value,
    bool selected,
    String label,
  ) {
    return PopupMenuItem(
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
    return '${dt.day}/${dt.month}';
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

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    try {
      if (_liked)
        await SocialApiService().likePost(widget.post.id, userId);
      else
        await SocialApiService().unlikePost(widget.post.id, userId);
    } catch (_) {
      setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_bookmarked ? 'Post saved' : 'Post removed from saved'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      setState(() => _bookmarked = previous);
    }
  }

  void _sharePost() {
    /* share logic */
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
                            if (userId == null) return;
                            await SocialApiService().addComment(
                              widget.post.id,
                              {'author_id': userId, 'text': text},
                            );
                            setModalState(() {
                              comments.insert(0, {
                                'author_id': userId,
                                'text': text,
                                'created_at':
                                    DateTime.now().toUtc().toIso8601String(),
                              });
                              commentController.clear();
                            });
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
  final int likes, comments;
  final bool liked;
  final VoidCallback onLikeTap, onCommentsTap, onShareTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 10,
      runSpacing: compact ? 4 : 10,
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
  final double? width, height;
  final BoxFit fit;
  @override
  State<_LoadingBlurImage> createState() => _LoadingBlurImageState();
}

class _LoadingBlurImageState extends State<_LoadingBlurImage> {
  bool _revealed = false;
  Widget _fallback() => Container(
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
        errorBuilder: (_, __, ___) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                  child: AnimatedOpacity(
                    opacity: _revealed ? 1.0 : 0.88,
                    duration: const Duration(milliseconds: 180),
                    child: child,
                  ),
                ),
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
        errorBuilder: (_, __, ___) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                  child: AnimatedOpacity(
                    opacity: _revealed ? 1.0 : 0.88,
                    duration: const Duration(milliseconds: 180),
                    child: child,
                  ),
                ),
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
        errorBuilder: (_, __, ___) => _fallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            if (!_revealed)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _revealed = true);
              });
          }
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18.0, end: _revealed ? 0.0 : 18.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                  child: AnimatedOpacity(
                    opacity: _revealed ? 1.0 : 0.88,
                    duration: const Duration(milliseconds: 180),
                    child: child,
                  ),
                ),
          );
        },
      );
    }
    return img;
  }
}

// ==================== Spaces Tab ====================
class _SpacesTab extends StatefulWidget {
  const _SpacesTab();
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
              data
                  .asMap()
                  .entries
                  .map(
                    (e) => _SpaceData(
                      name: e.value['name'] ?? 'Space',
                      members: (e.value['member_count'] as num?)?.toInt() ?? 0,
                      image: _defaultImages[e.key % _defaultImages.length],
                      tag: e.value['tag'] ?? 'Active',
                    ),
                  )
                  .toList();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_spaces.isEmpty)
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
    return ListView.builder(
      scrollDirection: isLandscape ? Axis.horizontal : Axis.vertical,
      padding: EdgeInsets.fromLTRB(
        isLandscape ? 20 : 0,
        8,
        isLandscape ? 20 : 0,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: _spaces.length,
      itemBuilder:
          (context, i) => Center(
            child: SizedBox(
              width: isLandscape ? 340 : MediaQuery.of(context).size.width - 40,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 24 : 20,
                ),
                child: _SpaceCard(space: _spaces[i], isDark: isDark),
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
      ),
    );
  }

  void _openSpaceDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TravelSpaceDetailScreen(
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

// ==================== Providers Tab (traveler only) ====================
class _ProvidersTab extends StatefulWidget {
  const _ProvidersTab();
  @override
  State<_ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<_ProvidersTab> {
  final MatchingApiService _matchingService = MatchingApiService();
  final ProfileApiService _profileService = ProfileApiService();
  final ServicesApiService _servicesService = ServicesApiService();
  String _searchQuery = '';
  bool _loadingProviders = true;
  String? _providerError;
  List<_ProviderResult> _providers = [];
  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });
    try {
      final username = SessionStore.instance.username;
      if (username == null || username.isEmpty)
        throw Exception('No active session.');
      final user = await _profileService.getUserByUsername(username);
      final email = user['email']?.toString() ?? '';
      if (email.isEmpty)
        throw Exception('Could not resolve your account email.');
      final result = await _matchingService.findMatches(
        userEmail: email,
        includeProviders: true,
        includeTravelers: false,
        topK: 20,
      );
      final rawMatches =
          (result['matches'] as List? ?? []).cast<Map<String, dynamic>>();
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

  List<_ProviderResult> get _filteredProviders {
    if (_searchQuery.isEmpty) return _providers;
    final query = _searchQuery.toLowerCase();
    return _providers
        .where(
          (provider) =>
              provider.name.toLowerCase().contains(query) ||
              provider.email.toLowerCase().contains(query) ||
              provider.bio.toLowerCase().contains(query) ||
              provider.serviceType.toLowerCase().contains(query),
        )
        .toList();
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

  @override
  void dispose() {
    _matchingService.dispose();
    _profileService.dispose();
    _servicesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final providers = _filteredProviders;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 24 : 20,
            10,
            isLandscape ? 24 : 20,
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
                onPressed: _loadProviders,
                icon: const Icon(LucideIcons.refresh_cw, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isLandscape ? 24 : 20),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search providers',
              prefixIcon: Icon(LucideIcons.search, color: AppDesign.midGrey),
              filled: true,
              fillColor: isDark ? AppDesign.cardDark : AppDesign.offWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child:
              _loadingProviders
                  ? const Center(child: CircularProgressIndicator())
                  : _providerError != null
                  ? _EmptyState(
                    title: 'Providers unavailable',
                    message: _providerError!,
                    icon: LucideIcons.users,
                    onRetry: _loadProviders,
                  )
                  : providers.isEmpty
                  ? _EmptyState(
                    title: 'No providers found',
                    message: 'Try a different search term or refresh.',
                    icon: LucideIcons.users,
                    onRetry: _loadProviders,
                  )
                  : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      isLandscape ? 24 : 20,
                      0,
                      isLandscape ? 24 : 20,
                      MediaQuery.of(context).padding.bottom + 100,
                    ),
                    itemCount: providers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder:
                        (context, i) => _ProviderCard(
                          provider: providers[i],
                          isDark: isDark,
                          onTap: () => _openProviderProfile(providers[i]),
                        ),
                  ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isDark,
    required this.onTap,
  });
  final _ProviderResult provider;
  final bool isDark;
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppDesign.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppDesign.lightGrey,
          ),
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
                          color: isDark ? Colors.white : AppDesign.eerieBlack,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
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
                style: TextStyle(color: AppDesign.midGrey, fontSize: 12),
              ),
            ],
            if (provider.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                provider.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppDesign.midGrey, height: 1.35),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
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
  final String id, name, email, bio, serviceType;
  final double score;
  const _ProviderResult({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.score,
    required this.serviceType,
  });
  factory _ProviderResult.fromJson(Map<String, dynamic> json) =>
      _ProviderResult(
        id: json['user_id']?.toString() ?? '',
        name: json['full_name']?.toString() ?? 'Unknown Provider',
        email: json['email']?.toString() ?? '',
        bio: json['bio']?.toString() ?? '',
        score: ((json['match_score'] ?? 0) as num).toDouble(),
        serviceType: json['service_type']?.toString() ?? '',
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
    required this.onRetry,
  });
  final String title, message;
  final IconData icon;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 54,
              color: isDark ? Colors.white54 : AppDesign.midGrey,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppDesign.eerieBlack,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppDesign.midGrey,
                height: 1.4,
              ),
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

// ==================== Requests Tab (service provider only) ====================
class _RequestsTab extends StatefulWidget {
  const _RequestsTab();
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final ServicesApiService _servicesService = ServicesApiService();
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _confirmedRequests = [];
  bool _isLoading = true;
  String? _error;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final providerId = SessionStore.instance.userId;
    if (providerId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Provider ID not found';
      });
      return;
    }
    try {
      final bookings = await _servicesService.getBookings(
        providerId: providerId,
      );
      setState(() {
        _pendingRequests =
            bookings
                .where((b) => (b['status'] ?? 'pending') == 'pending')
                .toList();
        _confirmedRequests =
            bookings
                .where((b) => (b['status'] ?? 'pending') != 'pending')
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load bookings: ${e.toString()}';
      });
    }
  }

  Future<void> _handleAcceptRequest(Map<String, dynamic> request) async {
    HapticFeedback.mediumImpact();
    setState(() => _processingId = request['_id']);
    try {
      await _servicesService.updateBookingStatus(
        bookingId: request['_id'],
        status: 'confirmed',
        providerResponse: 'accepted',
      );
      setState(() {
        _pendingRequests.removeWhere((r) => r['_id'] == request['_id']);
        _confirmedRequests.add({...request, 'status': 'confirmed'});
        _processingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Request accepted!'),
          backgroundColor: AppDesign.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _processingId = null);
    }
  }

  Future<void> _handleDeclineRequest(Map<String, dynamic> request) async {
    setState(() => _processingId = request['_id']);
    try {
      await _servicesService.updateBookingStatus(
        bookingId: request['_id'],
        status: 'declined',
        providerResponse: 'declined',
      );
      setState(() {
        _pendingRequests.removeWhere((r) => r['_id'] == request['_id']);
        _processingId = null;
      });
    } catch (e) {
      setState(() => _processingId = null);
    }
  }

  @override
  void dispose() {
    _servicesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.triangle_alert, size: 48, color: AppDesign.danger),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Pending (${_pendingRequests.length})'),
              Tab(text: 'Confirmed (${_confirmedRequests.length})'),
            ],
            indicatorColor: AppDesign.navConcierge,
            labelColor: isDark ? Colors.white : AppDesign.eerieBlack,
            unselectedLabelColor: AppDesign.midGrey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(_pendingRequests, isDark, false),
                _buildList(_confirmedRequests, isDark, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> requests,
    bool isDark,
    bool isConfirmed,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: AppDesign.midGrey),
            const SizedBox(height: 12),
            Text(
              isConfirmed ? 'No confirmed bookings' : 'No pending requests',
              style: TextStyle(color: AppDesign.midGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : AppDesign.lightGrey,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      req['traveler_username']?[0]?.toUpperCase() ?? '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['traveler_username'] ?? 'Traveler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          req['service_name'] ?? 'Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppDesign.midGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    req['price'] ?? 'On request',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppDesign.navSafety,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                req['special_requests'] ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppDesign.midGrey,
                ),
              ),
              if (!isConfirmed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _processingId == req['_id']
                                ? null
                                : () => _handleDeclineRequest(req),
                        child:
                            _processingId == req['_id']
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDesign.danger,
                          side: const BorderSide(color: AppDesign.danger),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _processingId == req['_id']
                                ? null
                                : () => _handleAcceptRequest(req),
                        child:
                            _processingId == req['_id']
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ==================== Data Classes ====================
class _PostData {
  final String id,
      author,
      handle,
      authorAvatar,
      authorId,
      text,
      image,
      createdAt;
  final List<dynamic> commentsList, likesList;
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
