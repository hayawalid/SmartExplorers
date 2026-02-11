import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Social feed with 3 tabs – Posts, Spaces, Providers.
/// Cinematic image cards with glassmorphism overlays.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(isDark: isDark),
                    _SpacesTab(isDark: isDark),
                    _ProvidersTab(isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            'Explore',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppDesign.eerieBlack,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
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

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? Colors.white : AppDesign.eerieBlack,
        unselectedLabelColor: AppDesign.midGrey,
        indicatorColor: isDark ? Colors.white : AppDesign.eerieBlack,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
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
class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.isDark});
  final bool isDark;

  static final _posts = [
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
    _PostData(
      author: 'Ahmed Hassan',
      handle: '@ahmed_adventurer',
      text:
          'Just booked a verified local guide for Luxor through SmartExplorers. Can\'t wait!',
      image: 'lib/public/verified_guides.jpg',
      likes: 56,
      comments: 8,
      timeAgo: '1d',
    ),
    _PostData(
      author: 'Mohamed Ali',
      handle: '@mohamed_guide',
      text:
          'Planning the perfect week in Egypt — AI itineraries make everything seamless.',
      image: 'lib/public/smart_itineraries.jpg',
      likes: 203,
      comments: 34,
      timeAgo: '2d',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _posts.length,
      itemBuilder: (context, i) => _PostCard(post: _posts[i], isDark: isDark),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.isDark});
  final _PostData post;
  final bool isDark;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.isDark ? AppDesign.cardDark : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
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
                        AppDesign.electricCobalt.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        widget.isDark ? AppDesign.cardDark : Colors.white,
                    child: Text(
                      widget.post.author[0],
                      style: TextStyle(
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
                        widget.post.author,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              widget.isDark
                                  ? Colors.white
                                  : AppDesign.eerieBlack,
                        ),
                      ),
                      Text(
                        '${widget.post.handle} · ${widget.post.timeAgo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppDesign.midGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: Icon(
                    _bookmarked ? LucideIcons.bookmark : LucideIcons.bookmark,
                    size: 18,
                    color:
                        _bookmarked
                            ? AppDesign.electricCobalt
                            : AppDesign.midGrey,
                  ),
                ),
              ],
            ),
          ),

          // Image — portrait aspect
          GestureDetector(
            onDoubleTap: () {
              if (!_liked) _toggleLike();
            },
            child: ClipRRect(
              child: Stack(
                children: [
                  Image.asset(
                    widget.post.image,
                    width: double.infinity,
                    height: 340,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text + actions
          Padding(
            padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _liked ? LucideIcons.heartOff : LucideIcons.heart,
                            size: 18,
                            color:
                                _liked ? AppDesign.danger : AppDesign.midGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$_likes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  _liked ? FontWeight.w600 : FontWeight.w400,
                              color:
                                  _liked ? AppDesign.danger : AppDesign.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: _showComments,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 18,
                            color: AppDesign.midGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.post.comments}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppDesign.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _sharePost,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.share2,
                            size: 16,
                            color: AppDesign.midGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppDesign.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
class _SpacesTab extends StatelessWidget {
  const _SpacesTab({required this.isDark});
  final bool isDark;

  static final _spaces = [
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
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _spaces.length,
      itemBuilder:
          (context, i) => _SpaceCard(space: _spaces[i], isDark: isDark),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleJoin,
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
              Image.asset(widget.space.image, fit: BoxFit.cover),
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
class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab({required this.isDark});
  final bool isDark;

  static final _providers = [
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
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _providers.length,
      itemBuilder:
          (context, i) =>
              _ProviderCard(provider: _providers[i], isDark: isDark),
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
                        child: Image.asset(
                          provider.image,
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
    return Container(
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
            child: Image.asset(
              provider.image,
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
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
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
