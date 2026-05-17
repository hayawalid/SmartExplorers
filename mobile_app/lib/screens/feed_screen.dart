import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/social_api_service.dart';
import '../services/marketplace_api_service.dart';
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
  late TabController _tabController;

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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isLandscape ? 12 : 16,
        horizontalPadding,
        6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmartExplorersLogo(size: LogoSize.small),
                const SizedBox(height: 4),
                Text(
                  isLandscape
                      ? 'Curated travel stories, spaces, and trusted guides'
                      : 'Travel stories and trusted experiences',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLandscape ? 13 : 12,
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
          const SizedBox(width: 12),
          _ThemeModeMenuButton(
            currentThemeMode: widget.currentThemeMode,
            onSelected: widget.onThemeModeSelected,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _GlassIconButton(
            icon: LucideIcons.search,
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Search coming soon'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          _GlassIconButton(
            icon: LucideIcons.bell,
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No new notifications'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
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
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
            child: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : AppDesign.eerieBlack,
            ),
          ),
        ),
      ),
    );
  }
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
  List<_PostData> _posts = [];
  bool _loading = true;

  static const _defaultImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/verified_guides.jpg',
    'lib/public/smart_itineraries.jpg',
  ];

  static final _fallbackPosts = [
    _PostData(
      author: 'Jana Ghoniem',
      handle: '@jana_explorer',
      text:
          'Sunrise at the Pyramids of Giza – nothing compares to seeing these wonders in person.',
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
      likes: 142,
      comments: 23,
      timeAgo: '2h',
    ),
    _PostData(
      author: 'Sarah Ahmed',
      handle: '@sarah_explorer',
      text:
          'Cruising on the Nile at sunset. Egypt truly is the gift of the river. 🌅',
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
      likes: 89,
      comments: 11,
      timeAgo: '5h',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await _socialService.getPosts();
      if (data.isNotEmpty) {
        setState(() {
          _posts =
              data.asMap().entries.map((e) {
                final p = e.value;
                return _PostData(
                  author: p['author_name'] ?? p['full_name'] ?? 'Traveler',
                  handle: '@${p['username'] ?? 'user'}',
                  text: p['content'] ?? p['text'] ?? '',
                  image: _defaultImages[e.key % _defaultImages.length],
                  likes: (p['likes'] as num?)?.toInt() ?? 0,
                  comments: (p['comments_count'] as num?)?.toInt() ?? 0,
                  timeAgo: p['time_ago'] ?? _timeAgo(p['created_at']),
                );
              }).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _posts = _fallbackPosts;
      _loading = false;
    });
  }

  String _timeAgo(dynamic dateStr) {
    if (dateStr == null) return 'now';
    try {
      final date = DateTime.parse(dateStr.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (_) {
      return 'now';
    }
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
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.newspaper, size: 48, color: AppDesign.midGrey),
            const SizedBox(height: 12),
            Text('No posts yet', style: TextStyle(color: AppDesign.midGrey)),
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
                ),
              ),
            ),
          ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.isDark,
    required this.isLandscape,
  });
  final _PostData post;
  final bool isDark;
  final bool isLandscape;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int _likes;
  bool _liked = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() => _bookmarked = !_bookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_bookmarked ? 'Post saved' : 'Post removed from saved'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      builder:
          (ctx) => Container(
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
                          widget.isDark ? Colors.white24 : AppDesign.lightGrey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Comments (${widget.post.comments})',
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (ctx, i) {
                      final names = ['Ahmed', 'Sara', 'Mohamed'];
                      final comments = [
                        'Amazing shot! 😍',
                        'Egypt is on my bucket list!',
                        'Great recommendation, thanks for sharing!',
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  widget.isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : AppDesign.offWhite,
                              child: Text(
                                names[i][0],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      widget.isDark
                                          ? Colors.white
                                          : AppDesign.eerieBlack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    names[i],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color:
                                          widget.isDark
                                              ? Colors.white
                                              : AppDesign.eerieBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comments[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          widget.isDark
                                              ? Colors.white70
                                              : AppDesign.eerieBlack,
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
              ],
            ),
          ),
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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppDesign.electricCobalt
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    widget.post.author[0],
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
                                        '${widget.post.handle} · ${widget.post.timeAgo}',
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
                                  LucideIcons.messageCircle,
                                  size: 18,
                                  color: AppDesign.midGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.post.comments}',
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
                              comments: widget.post.comments,
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
                      comments: widget.post.comments,
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
      final data = await _marketplaceService.getListings();
      if (data.isNotEmpty) {
        setState(() {
          _providers =
              data.asMap().entries.map((e) {
                final p = e.value;
                return _ProviderData(
                  name: p['name']?.toString() ?? 'Provider',
                  specialty:
                      p['specialty']?.toString() ??
                      p['category']?.toString() ??
                      'Service',
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
    setState(() {
      _providers = _fallbackProviders;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _marketplaceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.briefcase, size: 48, color: AppDesign.midGrey),
            const SizedBox(height: 12),
            Text(
              'No providers yet',
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
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.isDark});
  final _ProviderData provider;
  final bool isDark;

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
                                          LucideIcons.badgeCheck,
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Booking request sent to ${provider.name}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                              LucideIcons.badgeCheck,
                              size: 14,
                              color: AppDesign.success,
                            ),
                          ),
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

class _ThemeModeMenuButton extends StatelessWidget {
  const _ThemeModeMenuButton({
    required this.currentThemeMode,
    required this.onSelected,
    required this.isDark,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onSelected;
  final bool isDark;

  IconData get _icon => switch (currentThemeMode) {
    ThemeMode.system => LucideIcons.monitor,
    ThemeMode.dark => LucideIcons.moon,
    ThemeMode.light => LucideIcons.sunMedium,
  };

  String get _label => switch (currentThemeMode) {
    ThemeMode.system => 'System',
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme: $_label',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: isDark ? AppDesign.cardDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  const Icon(LucideIcons.monitor, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'System',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppDesign.eerieBlack,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  const Icon(LucideIcons.sunMedium, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Light',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppDesign.eerieBlack,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  const Icon(LucideIcons.moonStar, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Dark',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppDesign.eerieBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
            child: Icon(
              _icon,
              size: 18,
              color: isDark ? Colors.white70 : AppDesign.eerieBlack,
            ),
          ),
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
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? AppDesign.cardDark : Colors.white,
              child: Text(
                post.author[0],
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
                  '${post.handle} · ${post.timeAgo}',
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
              LucideIcons.bookmark,
              size: 18,
              color: bookmarked ? AppDesign.electricCobalt : AppDesign.midGrey,
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
          icon: liked ? LucideIcons.heartOff : LucideIcons.heart,
          label: '$likes',
          active: liked,
          activeColor: AppDesign.danger,
          onTap: onLikeTap,
        ),
        _ActionPill(
          icon: LucideIcons.messageCircle,
          label: '$comments',
          onTap: onCommentsTap,
        ),
        _ActionPill(
          icon: LucideIcons.share2,
          label: 'Share',
          onTap: onShareTap,
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
    return Image.asset(
      widget.image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) {
          if (!_revealed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _revealed = true);
              }
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
}

// ── Data Classes ────────────────────────────────────────────────────────
class _PostData {
  final String author, handle, text, image, timeAgo;
  final int likes, comments;
  _PostData({
    required this.author,
    required this.handle,
    required this.text,
    required this.image,
    required this.likes,
    required this.comments,
    required this.timeAgo,
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
  _ProviderData({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.verified,
  });
}
