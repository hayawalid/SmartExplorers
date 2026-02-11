import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/session_store.dart';
import '../services/profile_api_service.dart';
import '../services/api_config.dart';

/// Profile Screen with Posts & Reviews sections
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ProfileApiService _profileService = ProfileApiService();
  late TabController _tabController;

  String _name = 'Sarah Johnson';
  String _username = '@sarahtravels';
  String _bio = 'Solo traveler | History enthusiast';
  int _trips = 12;
  int _reviewsCount = 24;
  int _photos = 89;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  // Dummy posts for the profile
  static final _myPosts = [
    _ProfilePost(
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
      caption: 'Sunrise at the Pyramids of Giza',
      likes: 142,
      comments: 23,
      timeAgo: '2h',
    ),
    _ProfilePost(
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
      caption: 'Cruising on the Nile at sunset',
      likes: 89,
      comments: 11,
      timeAgo: '5h',
    ),
    _ProfilePost(
      image: 'lib/public/smart_itineraries.jpg',
      caption: 'Planning the perfect week in Egypt',
      likes: 203,
      comments: 34,
      timeAgo: '2d',
    ),
    _ProfilePost(
      image: 'lib/public/verified_guides.jpg',
      caption: 'Met an incredible local guide in Luxor',
      likes: 56,
      comments: 8,
      timeAgo: '1w',
    ),
  ];

  // Dummy reviews
  static const _myReviews = [
    _ProfileReview(
      providerName: 'Mohamed Ali',
      rating: 5,
      text:
          'Absolutely phenomenal guide. Deep knowledge of ancient history and very patient with our group. Highly recommended!',
      date: 'Jan 15, 2026',
      location: 'Luxor Temple',
    ),
    _ProfileReview(
      providerName: 'Fatima Hassan',
      rating: 4,
      text:
          'Great desert safari experience. The sunset views were incredible. Would love to go again.',
      date: 'Dec 28, 2025',
      location: 'White Desert',
    ),
    _ProfileReview(
      providerName: 'Youssef Kamel',
      rating: 5,
      text:
          'The photography tour was amazing. Youssef knows all the best angles and times for perfect shots.',
      date: 'Dec 10, 2025',
      location: 'Islamic Cairo',
    ),
    _ProfileReview(
      providerName: 'Nour Adel',
      rating: 4,
      text:
          'Wonderful culinary tour through the old markets. The food was authentic and delicious.',
      date: 'Nov 22, 2025',
      location: 'Khan El Khalili',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: _name);
    _bioController = TextEditingController(text: _bio);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final username =
          SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      setState(() {
        _name = user['full_name'] ?? _name;
        _username = '@${user['username'] ?? 'sarahtravels'}';
        _bio = user['bio'] ?? _bio;
        _trips = user['trips_count'] ?? _trips;
        _reviewsCount = user['reviews_count'] ?? _reviewsCount;
        _photos = user['photos_count'] ?? _photos;
        _nameController.text = _name;
        _bioController.text = _bio;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _profileService.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Save
        _name = _nameController.text;
        _bio = _bioController.text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _isEditing = !_isEditing;
    });
    HapticFeedback.lightImpact();
  }

  void _showSignOutDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Sign Out'),
                onPressed: () {
                  Navigator.pop(ctx);
                  SessionStore.instance.clear();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/onboarding', (_) => false);
                },
              ),
            ],
          ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : AppDesign.pureWhite;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder:
              (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(isDark, text, sub, card),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabDelegate(
                    tabController: _tabController,
                    isDark: isDark,
                  ),
                ),
              ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsGrid(isDark, text, sub),
              _buildReviewsList(isDark, text, sub, card),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color text, Color sub, Color card) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              Icon(LucideIcons.user, color: text, size: 24),
              const SizedBox(width: 10),
              Text(
                'Profile',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: text),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.settings, color: sub, size: 22),
                onPressed: () => _showSnack('Settings coming soon'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Avatar + info card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: AppDesign.borderRadius,
            boxShadow: isDark ? [] : AppDesign.softShadow,
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppDesign.electricCobalt.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  LucideIcons.user,
                  size: 36,
                  color: AppDesign.electricCobalt,
                ),
              ),
              const SizedBox(height: 14),
              if (_isEditing) ...[
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ] else
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              const SizedBox(height: 4),
              Text(_username, style: TextStyle(fontSize: 14, color: sub)),
              const SizedBox(height: 6),
              if (_isEditing)
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _bioController,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: sub, height: 1.4),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                )
              else
                Text(
                  _bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: sub, height: 1.4),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Trips', '$_trips', text, sub),
                  _divider(isDark),
                  _stat('Reviews', '$_reviewsCount', text, sub),
                  _divider(isDark),
                  _stat('Photos', '$_photos', text, sub),
                ],
              ),
              const SizedBox(height: 20),
              // Edit Profile / Sign Out row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppDesign.offWhite,
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppDesign.lightGrey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditing
                                  ? LucideIcons.check
                                  : LucideIcons.edit2,
                              size: 16,
                              color: text,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'Save Profile' : 'Edit Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showSignOutDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppDesign.danger.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppDesign.danger.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.logOut,
                            size: 16,
                            color: AppDesign.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppDesign.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostsGrid(bool isDark, Color text, Color sub) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, i) {
        final post = _myPosts[i];
        return GestureDetector(
          onTap: () => _showPostDetail(context, post, isDark, text, sub),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(post.image, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.caption,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.heart,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            LucideIcons.messageCircle,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
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
        );
      },
    );
  }

  void _showPostDetail(
    BuildContext context,
    _ProfilePost post,
    bool isDark,
    Color text,
    Color sub,
  ) {
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
                    color: isDark ? AppDesign.cardDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // Drag handle
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
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          post.image,
                          width: double.infinity,
                          height: 380,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.caption,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.timeAgo,
                              style: TextStyle(fontSize: 13, color: sub),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(LucideIcons.heart, size: 18, color: sub),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likes} likes',
                                  style: TextStyle(fontSize: 14, color: text),
                                ),
                                const SizedBox(width: 20),
                                Icon(
                                  LucideIcons.messageCircle,
                                  size: 18,
                                  color: sub,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.comments} comments',
                                  style: TextStyle(fontSize: 14, color: text),
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

  Widget _buildReviewsList(bool isDark, Color text, Color sub, Color card) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: _myReviews.length,
      itemBuilder: (context, i) {
        final review = _myReviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            boxShadow:
                isDark
                    ? []
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Provider avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppDesign.offWhite,
                    child: Text(
                      review.providerName[0],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.providerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: text,
                          ),
                        ),
                        Text(
                          review.location,
                          style: TextStyle(fontSize: 12, color: sub),
                        ),
                      ],
                    ),
                  ),
                  Text(review.date, style: TextStyle(fontSize: 11, color: sub)),
                ],
              ),
              const SizedBox(height: 12),
              // Stars
              Row(
                children: List.generate(5, (si) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      si < review.rating ? LucideIcons.star : LucideIcons.star,
                      size: 14,
                      color:
                          si < review.rating
                              ? const Color(0xFFFFC107)
                              : (isDark ? Colors.white24 : AppDesign.lightGrey),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                review.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppDesign.eerieBlack,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, Color text, Color sub) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? Colors.white10 : AppDesign.lightGrey,
    );
  }
}

// ── Sticky Tab Delegate ────────────────────────────────────────────────
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;

  _StickyTabDelegate({required this.tabController, required this.isDark});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppDesign.eerieBlack : AppDesign.pureWhite,
      child: TabBar(
        controller: tabController,
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
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [Tab(text: 'Posts'), Tab(text: 'Reviews')],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabDelegate oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.tabController != tabController;
}

// ── Data Classes ────────────────────────────────────────────────────────
class _ProfilePost {
  final String image, caption, timeAgo;
  final int likes, comments;
  _ProfilePost({
    required this.image,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class _ProfileReview {
  final String providerName, text, date, location;
  final int rating;
  const _ProfileReview({
    required this.providerName,
    required this.rating,
    required this.text,
    required this.date,
    required this.location,
  });
}
