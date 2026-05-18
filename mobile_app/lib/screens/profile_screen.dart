import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/session_store.dart';
import '../services/profile_api_service.dart';
import '../services/social_api_service.dart';
import '../services/api_config.dart';

/// Profile Screen with Posts & Reviews sections
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ProfileApiService _profileService = ProfileApiService();
  final SocialApiService _socialService = SocialApiService();
  late TabController _tabController;
  late final VoidCallback _favoritesTabListener;

  String _name = 'User';
  String _username = '@user';
  String _bio = '';
  String? _avatarUrl;
  int _trips = 0;
  int _reviewsCount = 0;
  int _photos = 0;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  List<_ProfilePost> _myPosts = [];
  List<_ProfileReview> _myReviews = [];
  List<_ProfileFavorite> _myFavorites = [];
  bool _loadingPosts = true;
  bool _loadingReviews = true;
  bool _loadingFavorites = true;

  static const _defaultImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/smart_itineraries.jpg',
    'lib/public/verified_guides.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesTabListener = () {
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        _loadUserFavorites();
      }
    };
    _tabController.addListener(_favoritesTabListener);
    _nameController = TextEditingController(text: _name);
    _bioController = TextEditingController(text: _bio);
    _loadProfile();
    _loadUserPosts();
    _loadUserReviews();
    _loadUserFavorites();
  }

  Future<void> _loadProfile() async {
    try {
      final username =
          SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      setState(() {
        _name = user['full_name'] ?? _name;
        _username = '@${user['username'] ?? 'user'}';
        _bio = user['bio'] ?? _bio;
        _avatarUrl =
            user['avatar_url']?.toString() ??
            user['profile_picture_url']?.toString();
        _trips = user['trips_count'] ?? _trips;
        _reviewsCount = user['reviews_count'] ?? _reviewsCount;
        _photos = user['photos_count'] ?? _photos;
        _nameController.text = _name;
        _bioController.text = _bio;
        SessionStore.instance.avatarUrl = _avatarUrl;
      });
    } catch (_) {}
  }

  Future<void> _loadUserPosts() async {
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        // Fetch traveler profile including posts (backend returns `posts` when include_posts=true)
        final profile = await _profileService.getTravelerProfile(userId);
        if (profile != null &&
            profile['posts'] is List &&
            (profile['posts'] as List).isNotEmpty) {
          final posts = profile['posts'] as List;
          setState(() {
            _myPosts =
                posts.take(4).toList().asMap().entries.map((e) {
                  final p = e.value as Map<String, dynamic>;
                  return _ProfilePost(
                    id: p['_id']?.toString() ?? '${e.key}',
                    image:
                        p['media_url']?.toString() ??
                        _defaultImages[e.key % _defaultImages.length],
                    caption: p['caption'] ?? p['text'] ?? 'Post',
                    likes:
                        (p['likes'] is List)
                            ? (p['likes'] as List).length
                            : (p['like_count'] as num?)?.toInt() ?? 0,
                    comments:
                        (p['comments'] is List)
                            ? (p['comments'] as List).length
                            : (p['comment_count'] as num?)?.toInt() ?? 0,
                    timeAgo: p['created_at']?.toString() ?? 'now',
                  );
                }).toList();
            _photos = _myPosts.length;
            _loadingPosts = false;
          });
          return;
        }
      }
      // Fallback: try loading from social posts
      final posts = await _socialService.getPosts(authorId: userId);
      setState(() {
        _myPosts =
            posts.take(4).toList().asMap().entries.map((e) {
              final p = e.value;
              return _ProfilePost(
                id: p['_id']?.toString() ?? '${e.key}',
                image:
                    p['media_url']?.toString() ??
                    _defaultImages[e.key % _defaultImages.length],
                caption: p['content'] ?? p['text'] ?? 'Post',
                likes:
                    (p['likes'] is List)
                        ? (p['likes'] as List).length
                        : (p['likes_count'] as num?)?.toInt() ?? 0,
                comments:
                    (p['comments'] is List)
                        ? (p['comments'] as List).length
                        : (p['comments_count'] as num?)?.toInt() ?? 0,
                timeAgo: p['created_at']?.toString() ?? 'now',
              );
            }).toList();
        _photos = _myPosts.length;
        _loadingPosts = false;
      });
    } catch (_) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        final favorites = await _socialService.getFavorites(userId);
        if (!mounted) return;
        setState(() {
          final defaultImageCount = _defaultImages.length;
          _myFavorites =
              favorites.asMap().entries.map((entry) {
                final index = entry.key;
                final favorite = entry.value;
                return _ProfileFavorite(
                  id:
                      favorite['_id']?.toString() ??
                      favorite['post_id']?.toString() ??
                      '',
                  postId: favorite['post_id']?.toString() ?? '',
                  image:
                      favorite['media_url']?.toString() ??
                      _defaultImages[index % defaultImageCount],
                  caption:
                      favorite['text']?.toString() ??
                      favorite['caption']?.toString() ??
                      'Saved post',
                  savedAt: favorite['saved_at']?.toString() ?? 'now',
                );
              }).toList();
          _loadingFavorites = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingFavorites = false);
  }

  Widget _buildImage(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder:
            (_, __, ___) => Container(
              color: AppDesign.lightGrey.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.imageOff),
            ),
      );
    }
    if (source.startsWith('/')) {
      return Image.network('${ApiConfig.baseUrl}$source', fit: fit);
    }
    return Image.asset(source, fit: fit);
  }

  ImageProvider<Object>? _avatarProvider(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    if (value.startsWith('/')) {
      return NetworkImage('${ApiConfig.baseUrl}$value');
    }
    return AssetImage(value);
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked == null) {
        return;
      }

      final uploadedUrl = await _socialService.uploadMedia(File(picked.path));
      final userId = SessionStore.instance.userId;
      if (userId == null) {
        return;
      }

      final updated = await _profileService.updateUser(userId, {
        'avatar_url': uploadedUrl,
        'profile_picture_url': uploadedUrl,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = updated['avatar_url']?.toString() ?? uploadedUrl;
        SessionStore.instance.avatarUrl = _avatarUrl;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $error')),
      );
    }
  }

  Future<void> _loadUserReviews() async {
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        final reviews = await _profileService.getUserReviews(userId);
        if (reviews.isNotEmpty) {
          setState(() {
            _myReviews =
                reviews.map((r) {
                  return _ProfileReview(
                    providerName:
                        r['provider_name'] ?? r['target_name'] ?? 'Provider',
                    rating: (r['rating'] as num?)?.toInt() ?? 5,
                    text: r['text'] ?? r['content'] ?? '',
                    date:
                        r['date'] ??
                        r['created_at']?.toString().substring(0, 10) ??
                        '',
                    location: r['location'] ?? r['service_name'] ?? '',
                  );
                }).toList();
            _loadingReviews = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _loadingReviews = false);
  }

  @override
  void dispose() {
    _profileService.dispose();
    _socialService.dispose();
    _tabController.removeListener(_favoritesTabListener);
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

  Future<void> _removeFavorite(_ProfileFavorite favorite) async {
    final shouldRemove = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Remove from favorites?'),
            content: const Text(
              'This will remove the saved post from your favorites only.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Remove'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (shouldRemove != true) return;

    final userId = SessionStore.instance.userId;
    if (userId == null) return;

    try {
      final removed = await _socialService.removeFavorite(
        userId,
        favorite.postId,
      );
      if (!mounted) return;
      if (removed) {
        setState(() {
          _myFavorites.removeWhere((item) => item.postId == favorite.postId);
        });
        _showSnack('Removed from favorites');
      } else {
        _showSnack('Could not remove favorite');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not remove favorite');
    }
  }

  Future<void> _confirmDeletePost(_ProfilePost post) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Delete post?'),
            content: const Text(
              'This will permanently delete the post from your profile and the database.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    final userId = SessionStore.instance.userId;
    if (userId == null) return;

    try {
      await _socialService.deletePost(post.id, userId);
      if (!mounted) return;
      setState(() {
        _myPosts.removeWhere((item) => item.id == post.id);
        _photos = _myPosts.length;
      });
      _showSnack('Post deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete post');
    }
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
              _buildFavoritesGrid(isDark, text, sub, card),
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
              const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
              const SizedBox(width: 8),
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
                backgroundImage: _avatarProvider(
                  _avatarUrl ?? SessionStore.instance.avatarUrl,
                ),
                child:
                    _avatarProvider(
                              _avatarUrl ?? SessionStore.instance.avatarUrl,
                            ) ==
                            null
                        ? Icon(
                          LucideIcons.user,
                          size: 36,
                          color:
                              isDark ? Colors.white : AppDesign.electricCobalt,
                        )
                        : null,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _uploadProfilePicture,
                  icon: const Icon(LucideIcons.image),
                  label: const Text('Upload profile picture'),
                ),
              ],
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
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.camera, size: 48, color: sub),
            const SizedBox(height: 12),
            Text('No posts yet', style: TextStyle(color: sub, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'Your travel photos will appear here',
              style: TextStyle(color: sub, fontSize: 13),
            ),
          ],
        ),
      );
    }
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
                _buildImage(post.image),
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
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    color: isDark ? AppDesign.cardDark : Colors.white,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeletePost(post);
                      }
                    },
                    itemBuilder:
                        (ctx) => const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash2, size: 16),
                                SizedBox(width: 8),
                                Text('Delete post'),
                              ],
                            ),
                          ),
                        ],
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
                        child: SizedBox(
                          width: double.infinity,
                          height: 380,
                          child: _buildImage(post.image),
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
    if (_loadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.star, size: 48, color: sub),
            const SizedBox(height: 12),
            Text('No reviews yet', style: TextStyle(color: sub, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'Reviews you leave will appear here',
              style: TextStyle(color: sub, fontSize: 13),
            ),
          ],
        ),
      );
    }
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

  Widget _buildFavoritesGrid(bool isDark, Color text, Color sub, Color card) {
    if (_loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bookmark, size: 48, color: sub),
            const SizedBox(height: 12),
            Text(
              'No saved posts yet',
              style: TextStyle(color: sub, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Posts you save from Explore will appear here',
              style: TextStyle(color: sub, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _myFavorites.length,
      itemBuilder: (context, i) {
        final favorite = _myFavorites[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(favorite.image),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                  color: isDark ? AppDesign.cardDark : Colors.white,
                  onSelected: (value) {
                    if (value == 'remove_favorite') {
                      _removeFavorite(favorite);
                    }
                  },
                  itemBuilder:
                      (ctx) => const [
                        PopupMenuItem<String>(
                          value: 'remove_favorite',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 16),
                              SizedBox(width: 8),
                              Text('Remove from favorites'),
                            ],
                          ),
                        ),
                      ],
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
                      favorite.caption,
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
                          LucideIcons.bookmark,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Saved',
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
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Reviews'),
          Tab(text: 'Favorites'),
        ],
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
  final String id;
  final String image, caption, timeAgo;
  final int likes, comments;
  _ProfilePost({
    required this.id,
    required this.image,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class _ProfileFavorite {
  final String id;
  final String postId;
  final String image;
  final String caption;
  final String savedAt;
  const _ProfileFavorite({
    required this.id,
    required this.postId,
    required this.image,
    required this.caption,
    required this.savedAt,
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
