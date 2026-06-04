// ============================================================================
// profile_screen.dart  —  fully dynamic, orientation-aware, glassmorphic theme
// ============================================================================
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/smart_explorers_logo.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/profile_api_service.dart';
import 'package:mobile_app/services/social_api_service.dart';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/services/api_config.dart';
import 'package:mobile_app/screens/traveler/create_post_screen.dart';
import 'package:mobile_app/screens/shared/settings_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Unified Profile Screen – adapts tabs and content based on userType.
/// Traveler: Posts, Reviews (reviews left BY the traveler), Favorites
/// Provider: Portfolio, Credentials, Reviews (overall rating + reviews OF the provider)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  @override
  bool get wantKeepAlive => true;

  final ProfileApiService _profileService = ProfileApiService();
  final SocialApiService _socialService = SocialApiService();
  late TabController _tabController;
  late final VoidCallback _tabListener;

  // User data
  String _name = 'User';
  String _username = '@user';
  String _bio = '';
  String? _avatarUrl;
  int _trips = 0;
  int _reviewsCount = 0;
  int _photos = 0;
  bool _isEditing = false;
  bool _isSavingProfile = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  // Traveler data
  List<_ProfilePost> _myPosts = [];
  List<_ProfileReview> _myReviews = [];
  List<_ProfileFavorite> _myFavorites = [];
  bool _loadingPosts = true;
  bool _loadingReviews = true;
  bool _loadingFavorites = true;

  // Provider data
  List<_PortfolioItem> _portfolio = [];
  List<_CredentialItem> _credentials = [];
  bool _loadingPortfolio = true;
  bool _loadingCredentials = true;
  double _providerRating = 0.0;
  int _providerReviewCount = 0;
  int _completedTours = 0;
  bool _isVerified = false;
  // Provider reviews (reviews OF the provider by travellers)
  List<_ProviderReview> _providerReviews = [];
  bool _loadingProviderReviews = true;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  bool get _isProvider => SessionStore.instance.accountType == 'service_provider';

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
    _tabListener = () {
      if (!_isProvider && _tabController.index == 2 && !_tabController.indexIsChanging) {
        _loadUserFavorites();
      }
    };
    _tabController.addListener(_tabListener);
    _nameController = TextEditingController(text: _name);
    _bioController = TextEditingController(text: _bio);
    _loadProfile();
    if (_isProvider) {
      _loadProviderData();
    } else {
      _loadUserPosts();
      _loadUserReviews();
      _loadUserFavorites();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _profileService.dispose();
    _socialService.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      final username = SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      if (!mounted) return;
      setState(() {
        _name = user['full_name'] ?? _name;
        _username = '@${user['username'] ?? 'user'}';
        _bio = user['bio'] ?? _bio;
        _avatarUrl = user['avatar_url']?.toString() ?? user['profile_picture_url']?.toString();
        _trips = user['trips_count'] ?? _trips;
        _reviewsCount = user['reviews_count'] ?? _reviewsCount;
        _photos = user['photos_count'] ?? _photos;
        _nameController.text = _name;
        _bioController.text = _bio;
        SessionStore.instance.avatarUrl = _avatarUrl;
      });
    } catch (_) {}
  }

  Future<void> _loadProviderData() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    try {
      final profile = await _profileService.getProviderProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _providerRating = (profile['rating'] as num?)?.toDouble() ?? 0.0;
          _providerReviewCount = (profile['review_count'] as num?)?.toInt() ?? 0;
          _completedTours = (profile['completed_tours_count'] as num?)?.toInt() ?? 0;
          _isVerified = profile['verified_flag'] == true;
        });
      }
      await Future.wait([
        _loadPortfolio(),
        _loadCredentials(),
        _loadProviderReviews(),
      ]);
    } catch (_) {}
  }

  Future<void> _loadPortfolio() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    try {
      final items = await _profileService.getProviderPortfolio(userId);
      if (!mounted) return;
      setState(() {
        _portfolio = items.map((i) => _PortfolioItem(
          id: i['_id']?.toString() ?? '',
          title: i['title']?.toString() ?? 'Untitled',
          likes: (i['likes'] as num?)?.toInt() ?? 0,
          category: i['category']?.toString() ?? 'General',
          imageUrl: i['image_url']?.toString() ?? i['media_url']?.toString() ?? '',
          caption: i['caption']?.toString() ?? i['text']?.toString() ?? '',
        )).toList();
        _loadingPortfolio = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPortfolio = false);
    }
  }

  Future<void> _loadCredentials() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    try {
      final creds = await _profileService.getProviderCredentials(userId);
      if (!mounted) return;
      setState(() {
        _credentials = creds.map((c) => _CredentialItem(
          id: c['_id']?.toString() ?? '',
          title: c['title']?.toString() ?? 'Credential',
          issuer: c['issuer']?.toString() ?? '',
          date: c['date_issued']?.toString() ?? '',
          isVerified: c['is_verified'] == true,
          icon: c['icon']?.toString() ?? '🎓',
          certificateUrl: c['certificate_url']?.toString() ?? '',
        )).toList();
        _loadingCredentials = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCredentials = false);
    }
  }

  /// Loads reviews FOR this provider (written by travellers about this provider)
  Future<void> _loadProviderReviews() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    try {
      final reviews = await _profileService.getProviderReviews(userId);
      if (!mounted) return;
      setState(() {
        _providerReviews = reviews.map((r) => _ProviderReview(
          authorName: r['author_name']?.toString() ?? r['author_username']?.toString() ?? 'Traveler',
          authorAvatar: r['author_avatar']?.toString() ?? '',
          rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
          title: r['title']?.toString() ?? '',
          text: r['text']?.toString() ?? r['content']?.toString() ?? '',
          date: _formatDate(r['created_at']?.toString() ?? ''),
          location: r['location']?.toString() ?? '',
          helpful: (r['helpful'] as num?)?.toInt() ?? 0,
        )).toList();
        // Recompute average if not set by profile endpoint
        if (_providerReviews.isNotEmpty && _providerRating == 0.0) {
          final sum = _providerReviews.fold(0.0, (acc, r) => acc + r.rating);
          _providerRating = sum / _providerReviews.length;
          _providerReviewCount = _providerReviews.length;
        }
        _loadingProviderReviews = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProviderReviews = false);
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final userId = SessionStore.instance.userId;
      List<Map<String, dynamic>> posts = [];
      if (userId != null) {
        final profile = await _profileService.getTravelerProfile(userId);
        if (profile != null && profile['posts'] is List && (profile['posts'] as List).isNotEmpty) {
          posts = (profile['posts'] as List).cast<Map<String, dynamic>>();
        }
      }
      if (posts.isEmpty) {
        posts = await _socialService.getPosts(authorId: userId);
      }
      if (!mounted) return;
      setState(() {
        _myPosts = posts.take(30).toList().asMap().entries.map((e) {
          final p = e.value;
          return _ProfilePost(
            id: p['_id']?.toString() ?? '${e.key}',
            image: p['media_url']?.toString() ?? _defaultImages[e.key % _defaultImages.length],
            caption: p['caption'] ?? p['text'] ?? 'Post',
            likes: (p['likes'] is List) ? (p['likes'] as List).length : (p['like_count'] as num?)?.toInt() ?? 0,
            comments: (p['comments'] is List) ? (p['comments'] as List).length : (p['comment_count'] as num?)?.toInt() ?? 0,
            timeAgo: p['created_at']?.toString() ?? 'now',
          );
        }).toList();
        _photos = _myPosts.length;
        _loadingPosts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        final favorites = await _socialService.getFavorites(userId);
        if (!mounted) return;
        setState(() {
          _myFavorites = favorites.asMap().entries.map((e) {
            final fav = e.value;
            return _ProfileFavorite(
              id: fav['_id']?.toString() ?? fav['post_id']?.toString() ?? '${e.key}',
              postId: fav['post_id']?.toString() ?? '',
              image: fav['media_url']?.toString() ?? _defaultImages[e.key % _defaultImages.length],
              caption: fav['text']?.toString() ?? fav['caption']?.toString() ?? 'Saved post',
              savedAt: fav['saved_at']?.toString() ?? 'now',
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

  /// Traveler reviews: reviews written BY this traveler
  Future<void> _loadUserReviews() async {
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        final reviews = await _profileService.getUserReviews(userId);
        if (!mounted) return;
        setState(() {
          _myReviews = reviews.map((r) => _ProfileReview(
            providerName: r['provider_name'] ?? r['target_name'] ?? 'Provider',
            rating: (r['rating'] as num?)?.toInt() ?? 5,
            text: r['text'] ?? r['content'] ?? '',
            date: _formatDate(r['created_at']?.toString() ?? r['date'] ?? ''),
            location: r['location'] ?? r['service_name'] ?? '',
          )).toList();
          _loadingReviews = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingReviews = false);
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  // ── Image Helpers ──────────────────────────────────────────────────
  Widget _buildImage(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(source, fit: fit, errorBuilder: (_, __, ___) => _imageFallback());
    }
    if (source.startsWith('/')) {
      return Image.network('${ApiConfig.baseUrl}$source', fit: fit, errorBuilder: (_, __, ___) => _imageFallback());
    }
    return Image.asset(source, fit: fit, errorBuilder: (_, __, ___) => _imageFallback());
  }

  Widget _imageFallback() => Container(
    color: AppDesign.lightGrey.withValues(alpha: 0.15),
    alignment: Alignment.center,
    child: const Icon(LucideIcons.imageOff, color: AppDesign.midGrey),
  );

  ImageProvider<Object>? _avatarProvider(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return NetworkImage(value);
    if (value.startsWith('/')) return NetworkImage('${ApiConfig.baseUrl}$value');
    return AssetImage(value);
  }

  // ── Actions ────────────────────────────────────────────────────────
  Future<void> _uploadProfilePicture() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 88);
      if (picked == null) return;
      final uploadedUrl = await _socialService.uploadMedia(File(picked.path));
      final userId = SessionStore.instance.userId;
      if (userId == null) return;
      final updated = await _profileService.updateUser(userId, {'avatar_url': uploadedUrl, 'profile_picture_url': uploadedUrl});
      if (!mounted) return;
      setState(() {
        _avatarUrl = updated['avatar_url']?.toString() ?? uploadedUrl;
        SessionStore.instance.avatarUrl = _avatarUrl;
      });
      _showSnack('Profile picture updated');
    } catch (e) {
      if (mounted) _showSnack('Failed to update picture: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    setState(() => _isSavingProfile = true);
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        await _profileService.updateUser(userId, {
          'full_name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
        });
      }
      if (!mounted) return;
      setState(() {
        _name = _nameController.text.trim();
        _bio = _bioController.text.trim();
        _isEditing = false;
      });
      _showSnack('Profile saved');
    } catch (e) {
      if (mounted) _showSnack('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _toggleEdit() {
    HapticFeedback.lightImpact();
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _showSignOutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign Out'),
            onPressed: () {
              Navigator.pop(ctx);
              SessionStore.instance.clear();
              Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
            },
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onSignOut: _showSignOutDialog,
          onEditProfile: () {
            Navigator.pop(context);
            setState(() => _isEditing = true);
          },
        ),
      ),
    );
  }

  // ── Portfolio: open CreatePostScreen ──────────────────────────────
  Future<void> _openCreatePostAsPortfolio() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true && mounted) {
      _loadPortfolio();
      _loadUserPosts();
    }
  }

  Future<void> _uploadCredential() async {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final dateController = TextEditingController();
    File? file;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: isDark ? AppDesign.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Credential'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(controller: issuerController, decoration: const InputDecoration(labelText: 'Issuer *')),
              const SizedBox(height: 12),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Issue Date (YYYY-MM-DD) *')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setModalState(() => file = File(picked.path));
                  }
                },
                icon: const Icon(LucideIcons.upload),
                label: Text(file == null ? 'Select Certificate Image' : 'Image Selected ✓'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (file == null || titleController.text.isEmpty || issuerController.text.isEmpty || dateController.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                final userId = SessionStore.instance.userId;
                if (userId == null) return;
                setState(() => _isUploading = true);
                try {
                  final uploadUrl = await _socialService.uploadMedia(file!);
                  final response = await http.post(
                    Uri.parse('${ApiConfig.baseUrl}/api/v1/providers/credentials'),
                    headers: {
                      if (SessionStore.instance.accessToken != null) 'Authorization': 'Bearer ${SessionStore.instance.accessToken}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'provider_id': userId,
                      'title': titleController.text.trim(),
                      'issuer': issuerController.text.trim(),
                      'date_issued': dateController.text.trim(),
                      'certificate_url': uploadUrl,
                    }),
                  );
                  if (response.statusCode == 200) {
                    await _loadCredentials();
                    _showSnack('Credential added');
                  } else {
                    _showSnack('Upload failed: ${response.statusCode}');
                  }
                } catch (e) {
                  _showSnack('Failed: $e');
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(_ProfileFavorite favorite) async {
    final shouldRemove = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Remove from favorites?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Remove'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (shouldRemove != true) return;
    final userId = SessionStore.instance.userId;
    if (userId == null) return;
    try {
      final removed = await _socialService.removeFavorite(userId, favorite.postId);
      if (!mounted) return;
      if (removed) {
        setState(() => _myFavorites.removeWhere((f) => f.postId == favorite.postId));
        _showSnack('Removed from favorites');
      }
    } catch (_) {
      _showSnack('Could not remove favorite');
    }
  }

  Future<void> _confirmDeletePost(_ProfilePost post) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete post?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(ctx, true)),
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
        _myPosts.removeWhere((p) => p.id == post.id);
        _photos = _myPosts.length;
      });
      _showSnack('Post deleted');
    } catch (_) {
      _showSnack('Failed to delete post');
    }
  }

  // ── Main Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : AppDesign.pureWhite;

    final tabs = _isProvider
        ? [const Tab(text: 'Portfolio'), const Tab(text: 'Credentials'), const Tab(text: 'Reviews')]
        : [const Tab(text: 'Posts'), const Tab(text: 'Reviews'), const Tab(text: 'Favorites')];

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: isLandscape
                ? Row(
                    children: [
                      // In landscape: sidebar with avatar + stats
                      SizedBox(
                        width: 240,
                        child: _buildProfileSidebar(isDark, text, sub, card),
                      ),
                      Container(width: 1, color: isDark ? Colors.white12 : AppDesign.lightGrey),
                      Expanded(
                        child: Column(
                          children: [
                            _buildTabBarWidget(isDark, tabs),
                            Expanded(child: _buildTabViews(isDark, text, sub, card)),
                          ],
                        ),
                      ),
                    ],
                  )
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(child: _buildProfileHeader(isDark, text, sub, card)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabDelegate(tabController: _tabController, isDark: isDark, tabs: tabs),
                      ),
                    ],
                    body: _buildTabViews(isDark, text, sub, card),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTabBarWidget(bool isDark, List<Tab> tabs) {
    return Container(
      color: isDark ? AppDesign.eerieBlack : AppDesign.pureWhite,
      child: TabBar(
        controller: _tabController,
        tabs: tabs,
        labelColor: isDark ? Colors.white : AppDesign.eerieBlack,
        unselectedLabelColor: AppDesign.midGrey,
        indicatorColor: isDark ? Colors.white : AppDesign.eerieBlack,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppDesign.lightGrey,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _buildTabViews(bool isDark, Color text, Color sub, Color card) {
    return TabBarView(
      controller: _tabController,
      children: _isProvider
          ? [
              _buildPortfolioTab(isDark, text, sub, card),
              _buildCredentialsTab(isDark, text, sub, card),
              _buildProviderReviewsTab(isDark, text, sub, card),
            ]
          : [
              _buildPostsGrid(isDark, text, sub),
              _buildTravelerReviewsList(isDark, text, sub, card),
              _buildFavoritesGrid(isDark, text, sub, card),
            ],
    );
  }

  // ── Profile Sidebar (landscape) ─────────────────────────────────────
  Widget _buildProfileSidebar(bool isDark, Color text, Color sub, Color card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
              IconButton(icon: Icon(LucideIcons.settings, color: sub, size: 20), onPressed: _openSettings),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isEditing ? _uploadProfilePicture : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppDesign.electricCobalt.withValues(alpha: 0.12),
                  backgroundImage: _avatarProvider(_avatarUrl ?? SessionStore.instance.avatarUrl),
                  child: _avatarProvider(_avatarUrl ?? SessionStore.instance.avatarUrl) == null
                      ? Icon(LucideIcons.user, size: 32, color: isDark ? Colors.white : AppDesign.electricCobalt)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppDesign.electricCobalt),
                      child: const Icon(LucideIcons.camera, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _isEditing
              ? TextField(controller: _nameController, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text))
              : Text(_name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(_username, style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 12),
          if (_isProvider) _buildRatingBadge(),
          const SizedBox(height: 16),
          _buildStatsRow(isDark, text, sub),
          const SizedBox(height: 20),
          _buildActionButtons(isDark, text),
        ],
      ),
    );
  }

  // ── Profile Header (portrait) ───────────────────────────────────────
  Widget _buildProfileHeader(bool isDark, Color text, Color sub, Color card) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
              const SizedBox(width: 8),
              Text('Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: text)),
              const Spacer(),
              IconButton(icon: Icon(LucideIcons.settings, color: sub, size: 22), onPressed: _openSettings),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: AppDesign.borderRadius,
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : AppDesign.lightGrey),
            boxShadow: isDark ? [] : AppDesign.softShadow,
          ),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _isEditing ? _uploadProfilePicture : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppDesign.electricCobalt.withValues(alpha: 0.12),
                      backgroundImage: _avatarProvider(_avatarUrl ?? SessionStore.instance.avatarUrl),
                      child: _avatarProvider(_avatarUrl ?? SessionStore.instance.avatarUrl) == null
                          ? Icon(LucideIcons.user, size: 36, color: isDark ? Colors.white : AppDesign.electricCobalt)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppDesign.electricCobalt),
                          child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Name
              _isEditing
                  ? SizedBox(width: 200, child: TextField(controller: _nameController, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)))
                  : Text(_name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 4),
              Text(_username, style: TextStyle(fontSize: 14, color: sub)),
              const SizedBox(height: 6),
              // Bio
              _isEditing
                  ? SizedBox(width: 260, child: TextField(controller: _bioController, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 13, color: sub)))
                  : Text(_bio, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub, height: 1.4)),
              // Provider rating badge
              if (_isProvider) ...[
                const SizedBox(height: 12),
                _buildRatingBadge(),
              ],
              const SizedBox(height: 20),
              _buildStatsRow(isDark, text, sub),
              const SizedBox(height: 20),
              // Verification button for providers
              if (_isProvider) ...[
                _buildGlassButton(
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/provider_verification'),
                  icon: LucideIcons.shieldCheck,
                  label: _isVerified ? 'Verified Provider' : 'Get Verified',
                  color: _isVerified ? AppDesign.success : AppDesign.navSafety,
                ),
                const SizedBox(height: 12),
              ],
              _buildActionButtons(isDark, text),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppDesign.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppDesign.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, size: 16, color: AppDesign.warning),
          const SizedBox(width: 6),
          Text(
            '${_providerRating.toStringAsFixed(1)} · $_providerReviewCount reviews',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppDesign.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color text, Color sub) {
    final stats = _isProvider
        ? [_stat('Tours', '$_completedTours', text, sub), _stat('Reviews', '$_providerReviewCount', text, sub), _stat('Rating', _providerRating.toStringAsFixed(1), text, sub)]
        : [_stat('Trips', '$_trips', text, sub), _stat('Reviews', '$_reviewsCount', text, sub), _stat('Photos', '$_photos', text, sub)];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: stats);
  }

  Widget _buildActionButtons(bool isDark, Color text) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isSavingProfile ? null : _toggleEdit,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.offWhite,
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppDesign.lightGrey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSavingProfile)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Icon(_isEditing ? LucideIcons.check : LucideIcons.edit2, size: 16, color: text),
                      const SizedBox(width: 8),
                      Text(_isEditing ? 'Save Profile' : 'Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showSignOutDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppDesign.danger.withValues(alpha: 0.08),
              border: Border.all(color: AppDesign.danger.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.logOut, size: 16, color: AppDesign.danger),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppDesign.danger)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required bool isDark,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color text, Color sub) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }

  // ── Traveler: Posts Grid ────────────────────────────────────────────
  Widget _buildPostsGrid(bool isDark, Color text, Color sub) {
    if (_loadingPosts) return const Center(child: CircularProgressIndicator());
    if (_myPosts.isEmpty) {
      return _emptyState(
        icon: LucideIcons.camera,
        title: 'No posts yet',
        message: 'Your travel photos will appear here',
        actionLabel: 'Create Post',
        onAction: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
          if (created == true && mounted) _loadUserPosts();
        },
        sub: sub,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: _myPosts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return GestureDetector(
                onTap: () async {
                  final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
                  if (created == true && mounted) _loadUserPosts();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : AppDesign.offWhite,
                    border: Border.all(
                      color: AppDesign.electricCobalt.withValues(alpha: 0.4),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppDesign.electricCobalt.withValues(alpha: 0.12)),
                        child: const Icon(LucideIcons.plus, color: AppDesign.electricCobalt),
                      ),
                      const SizedBox(height: 8),
                      Text('Add Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppDesign.electricCobalt)),
                    ],
                  ),
                ),
              );
            }
            final post = _myPosts[i - 1];
            return GestureDetector(
              onTap: () => _showPostDetail(post, isDark),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  _buildImage(post.image),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.9)),
                      color: isDark ? AppDesign.cardDark : Colors.white,
                      onSelected: (v) { if (v == 'delete') _confirmDeletePost(post); },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 16), SizedBox(width: 8), Text('Delete post')])),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 10, right: 10, bottom: 10,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(post.caption, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(LucideIcons.heart, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${post.likes}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(width: 10),
                        const Icon(LucideIcons.messageCircle, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${post.comments}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void _showPostDetail(_ProfilePost post, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(controller: scrollController, padding: EdgeInsets.zero, children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isDark ? Colors.white24 : AppDesign.lightGrey))),
            ClipRRect(child: SizedBox(width: double.infinity, height: 340, child: _buildImage(post.image))),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.caption, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppDesign.eerieBlack)),
              const SizedBox(height: 8),
              Text(_formatDate(post.timeAgo), style: const TextStyle(fontSize: 13, color: AppDesign.midGrey)),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(LucideIcons.heart, size: 18, color: AppDesign.midGrey),
                const SizedBox(width: 6),
                Text('${post.likes} likes', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppDesign.eerieBlack)),
                const SizedBox(width: 20),
                const Icon(LucideIcons.messageCircle, size: 18, color: AppDesign.midGrey),
                const SizedBox(width: 6),
                Text('${post.comments} comments', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppDesign.eerieBlack)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  // ── Traveler: Reviews List ─────────────────────────────────────────
  /// Shows only reviews WRITTEN BY the traveler
  Widget _buildTravelerReviewsList(bool isDark, Color text, Color sub, Color card) {
    if (_loadingReviews) return const Center(child: CircularProgressIndicator());
    if (_myReviews.isEmpty) {
      return _emptyState(
        icon: LucideIcons.star,
        title: 'No reviews yet',
        message: 'Reviews you leave for providers will appear here',
        actionLabel: 'Write a Review',
        onAction: () async {
          await Navigator.pushNamed(context, '/write_review');
          _loadUserReviews();
        },
        sub: sub,
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 100),
      itemCount: _myReviews.length,
      itemBuilder: (context, i) {
        final review = _myReviews[i];
        return _ReviewCard(
          isDark: isDark,
          authorName: review.providerName,
          subtitle: review.location,
          text: review.text,
          date: review.date,
          rating: review.rating.toDouble(),
          card: card,
        );
      },
    );
  }

  // ── Traveler: Favorites Grid ───────────────────────────────────────
  Widget _buildFavoritesGrid(bool isDark, Color text, Color sub, Color card) {
    if (_loadingFavorites) return const Center(child: CircularProgressIndicator());
    if (_myFavorites.isEmpty) {
      return _emptyState(
        icon: LucideIcons.bookmark,
        title: 'No saved posts yet',
        message: 'Posts you save from the feed will appear here',
        sub: sub,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: _myFavorites.length,
          itemBuilder: (context, i) {
            final fav = _myFavorites[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(fit: StackFit.expand, children: [
                _buildImage(fav.image),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    color: isDark ? AppDesign.cardDark : Colors.white,
                    onSelected: (v) { if (v == 'remove') _removeFavorite(fav); },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'remove', child: Row(children: [Icon(LucideIcons.trash2, size: 16), SizedBox(width: 8), Text('Remove')])),
                    ],
                  ),
                ),
                Positioned(
                  left: 10, right: 10, bottom: 10,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fav.caption, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    const Row(children: [
                      Icon(LucideIcons.bookmark, size: 12, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Saved', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ]),
                  ]),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  // ── Provider: Portfolio Tab ─────────────────────────────────────────
  Widget _buildPortfolioTab(bool isDark, Color text, Color sub, Color card) {
    if (_loadingPortfolio) return const Center(child: CircularProgressIndicator());
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 3;
        return GridView.builder(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossCount, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: _portfolio.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              // Add new portfolio item → opens CreatePostScreen
              return GestureDetector(
                onTap: _openCreatePostAsPortfolio,
                child: Container(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppDesign.navConcierge, width: 2)),
                      child: const Icon(LucideIcons.plus, color: AppDesign.navConcierge, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub)),
                  ]),
                ),
              );
            }
            final item = _portfolio[i - 1];
            return GestureDetector(
              onTap: () => _showPortfolioDetail(item, isDark),
              child: Stack(fit: StackFit.expand, children: [
                item.imageUrl.isNotEmpty
                    ? _buildImage(item.imageUrl)
                    : Container(color: AppDesign.navConcierge.withValues(alpha: 0.2), child: Center(child: Text(_categoryEmoji(item.category), style: const TextStyle(fontSize: 32)))),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Row(children: [
                      const Icon(LucideIcons.heart, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${item.likes}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Tours': return '🏛️';
      case 'Historical': return '⚱️';
      case 'Scenic': return '🌅';
      case 'Culture': return '🎭';
      case 'Adventure': return '🏜️';
      default: return '📷';
    }
  }

  void _showPortfolioDetail(_PortfolioItem item, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(controller: scroll, padding: EdgeInsets.zero, children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isDark ? Colors.white24 : AppDesign.lightGrey))),
            if (item.imageUrl.isNotEmpty)
              SizedBox(width: double.infinity, height: 260, child: _buildImage(item.imageUrl)),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppDesign.eerieBlack)),
              const SizedBox(height: 6),
              Text(item.category, style: const TextStyle(fontSize: 13, color: AppDesign.midGrey)),
              if (item.caption.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.caption, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppDesign.eerieBlack, height: 1.5)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                const Icon(LucideIcons.heart, size: 18, color: AppDesign.danger),
                const SizedBox(width: 8),
                Text('${item.likes} likes', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppDesign.eerieBlack)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  // ── Provider: Credentials Tab ───────────────────────────────────────
  Widget _buildCredentialsTab(bool isDark, Color text, Color sub, Color card) {
    if (_loadingCredentials) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 20),
      children: [
        // Add credential button
        GestureDetector(
          onTap: _uploadCredential,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppDesign.navConcierge.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppDesign.navConcierge.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.plus, color: AppDesign.navConcierge, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Upload New Credential', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
                ]),
              ),
            ),
          ),
        ),
        if (_credentials.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              Icon(LucideIcons.badgeCheck, size: 48, color: sub),
              const SizedBox(height: 12),
              Text('No credentials yet', style: TextStyle(color: sub, fontSize: 16)),
            ]),
          )
        else
          ..._credentials.asMap().entries.map((entry) {
            final cred = entry.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.lightGrey),
                  ),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: AppDesign.navConcierge.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(cred.icon, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cred.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text)),
                      const SizedBox(height: 4),
                      Text(cred.issuer, style: TextStyle(fontSize: 13, color: sub)),
                      const SizedBox(height: 2),
                      Text('Issued: ${cred.date}', style: TextStyle(fontSize: 12, color: sub.withValues(alpha: 0.7))),
                    ])),
                    if (cred.isVerified)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppDesign.success.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.badgeCheck, size: 20, color: AppDesign.success),
                      ),
                  ]),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Provider: Reviews Tab ───────────────────────────────────────────
  /// Shows overall rating summary + individual reviews left FOR this provider
  Widget _buildProviderReviewsTab(bool isDark, Color text, Color sub, Color card) {
    if (_loadingProviderReviews) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 100),
      children: [
        // Overall rating summary card
        _buildProviderRatingSummary(isDark, text, sub),
        const SizedBox(height: 16),

        if (_providerReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              Icon(LucideIcons.star, size: 48, color: sub),
              const SizedBox(height: 12),
              Text('No reviews yet', style: TextStyle(color: sub, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Reviews from travelers will appear here', style: TextStyle(color: sub, fontSize: 13), textAlign: TextAlign.center),
            ]),
          )
        else
          ..._providerReviews.map((review) => _ReviewCard(
            isDark: isDark,
            authorName: review.authorName,
            subtitle: review.location.isNotEmpty ? review.location : 'Traveler Review',
            text: review.text,
            date: review.date,
            rating: review.rating,
            card: card,
            helpful: review.helpful,
            showHelpful: true,
          )),
      ],
    );
  }

  Widget _buildProviderRatingSummary(bool isDark, Color text, Color sub) {
    // Compute rating distribution
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _providerReviews) {
      final key = r.rating.round().clamp(1, 5);
      distribution[key] = (distribution[key] ?? 0) + 1;
    }
    final total = _providerReviews.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.lightGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big rating number
              Column(
                children: [
                  Text(
                    _providerRating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: text, height: 1),
                  ),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      LucideIcons.star,
                      size: 14,
                      color: i < _providerRating.round() ? AppDesign.warning : (isDark ? Colors.white24 : AppDesign.lightGrey),
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text('$_providerReviewCount reviews', style: TextStyle(fontSize: 12, color: sub)),
                ],
              ),
              const SizedBox(width: 24),
              // Rating bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = distribution[star] ?? 0;
                    final fraction = total > 0 ? count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Text('$star', style: TextStyle(fontSize: 12, color: sub)),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.star, size: 10, color: AppDesign.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white12 : AppDesign.lightGrey,
                              valueColor: const AlwaysStoppedAnimation(AppDesign.warning),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 24, child: Text('$count', style: TextStyle(fontSize: 12, color: sub))),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Helpers ─────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color sub,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: sub),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: sub)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub.withValues(alpha: 0.7), height: 1.4)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Review Card (shared between traveler + provider tabs) ─────────────
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.isDark,
    required this.authorName,
    required this.subtitle,
    required this.text,
    required this.date,
    required this.rating,
    required this.card,
    this.helpful = 0,
    this.showHelpful = false,
  });

  final bool isDark;
  final String authorName, subtitle, text, date;
  final double rating;
  final Color card;
  final int helpful;
  final bool showHelpful;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.lightGrey),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.offWhite,
                child: Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppDesign.eerieBlack)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(authorName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppDesign.eerieBlack)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppDesign.midGrey)),
              ])),
              Text(date, style: const TextStyle(fontSize: 11, color: AppDesign.midGrey)),
            ]),
            const SizedBox(height: 12),
            Row(children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(LucideIcons.star, size: 14, color: i < rating.round() ? AppDesign.warning : (isDark ? Colors.white24 : AppDesign.lightGrey)),
            ))),
            const SizedBox(height: 10),
            Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white.withValues(alpha: 0.85) : AppDesign.eerieBlack)),
            if (showHelpful && helpful > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(LucideIcons.thumbsUp, size: 14, color: AppDesign.midGrey),
                const SizedBox(width: 6),
                Text('$helpful found helpful', style: const TextStyle(fontSize: 12, color: AppDesign.midGrey)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Sticky Tab Delegate ────────────────────────────────────────────────
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;
  final List<Tab> tabs;

  _StickyTabDelegate({required this.tabController, required this.isDark, required this.tabs});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: isDark ? AppDesign.eerieBlack.withValues(alpha: 0.9) : AppDesign.pureWhite.withValues(alpha: 0.9),
          child: TabBar(
            controller: tabController,
            tabs: tabs,
            labelColor: isDark ? Colors.white : AppDesign.eerieBlack,
            unselectedLabelColor: AppDesign.midGrey,
            indicatorColor: isDark ? Colors.white : AppDesign.eerieBlack,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppDesign.lightGrey,
            dividerHeight: 0.5,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabDelegate old) =>
      old.isDark != isDark || old.tabController != tabController;
}

// ── Data Classes ─────────────────────────────────────────────────────
class _ProfilePost {
  final String id, image, caption, timeAgo;
  final int likes, comments;
  _ProfilePost({required this.id, required this.image, required this.caption, required this.likes, required this.comments, required this.timeAgo});
}

class _ProfileFavorite {
  final String id, postId, image, caption, savedAt;
  const _ProfileFavorite({required this.id, required this.postId, required this.image, required this.caption, required this.savedAt});
}

class _ProfileReview {
  final String providerName, text, date, location;
  final int rating;
  const _ProfileReview({required this.providerName, required this.rating, required this.text, required this.date, required this.location});
}

class _PortfolioItem {
  final String id, title, category, imageUrl, caption;
  final int likes;
  _PortfolioItem({required this.id, required this.title, required this.likes, required this.category, required this.imageUrl, required this.caption});
}

class _CredentialItem {
  final String id, title, issuer, date, icon, certificateUrl;
  final bool isVerified;
  _CredentialItem({required this.id, required this.title, required this.issuer, required this.date, required this.isVerified, required this.icon, required this.certificateUrl});
}

class _ProviderReview {
  final String authorName, authorAvatar, title, text, date, location;
  final double rating;
  final int helpful;
  const _ProviderReview({
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.title,
    required this.text,
    required this.date,
    required this.location,
    required this.helpful,
  });
}