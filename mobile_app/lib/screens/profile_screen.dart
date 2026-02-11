import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../services/session_store.dart';
import '../services/profile_api_service.dart';
import '../services/api_config.dart';

/// Instagram-style Profile Screen with WCAG 2.1 AA accessibility compliance
/// Features: Image grid tab, Reviews tab with filters/sorting, iOS modern design
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ProfileApiService _profileService = ProfileApiService();

  // Review filter and sort state
  String _selectedFilter = 'All';
  String _selectedSort = 'Most Recent';

  final List<String> _filterOptions = [
    'All',
    'Places',
    'Guides',
    'Experiences',
  ];
  final List<String> _sortOptions = [
    'Most Recent',
    'Highest Rated',
    'Lowest Rated',
    'Most Helpful',
  ];

  // Sample user data
  final UserProfile _fallbackUser = UserProfile(
    name: 'Sarah Johnson',
    username: '@sarahtravels',
    bio:
        'Solo traveler | History enthusiast | Capturing Egypt\'s magic one photo at a time',
    avatarUrl: '',
    isVerified: true,
    tripsCount: 12,
    reviewsCount: 24,
    photosCount: 89,
    rating: 4.9,
    memberSince: 'March 2024',
  );

  // Sample photos for grid
  final List<TravelPhoto> _fallbackPhotos = [
    TravelPhoto(id: '1', location: 'Pyramids of Giza', likes: 324),
    TravelPhoto(id: '2', location: 'Luxor Temple', likes: 256),
    TravelPhoto(id: '3', location: 'Nile Cruise', likes: 189),
    TravelPhoto(id: '4', location: 'Valley of Kings', likes: 412),
    TravelPhoto(id: '5', location: 'Abu Simbel', likes: 567),
    TravelPhoto(id: '6', location: 'Alexandria Library', likes: 145),
    TravelPhoto(id: '7', location: 'Khan el-Khalili', likes: 298),
    TravelPhoto(id: '8', location: 'Karnak Temple', likes: 376),
    TravelPhoto(id: '9', location: 'Siwa Oasis', likes: 234),
  ];

  // Sample reviews
  List<UserReview> _fallbackReviews = [
    UserReview(
      id: '1',
      type: 'Guides',
      title: 'Amazing Guide Experience',
      content:
          'Ahmed was incredibly knowledgeable about Egyptian history. Made our Giza tour unforgettable!',
      rating: 5.0,
      date: DateTime(2026, 2, 5),
      helpfulCount: 42,
      providerName: 'Ahmed Hassan Tours',
    ),
    UserReview(
      id: '2',
      type: 'Places',
      title: 'Breathtaking Views',
      content:
          'The sunrise at Abu Simbel was the highlight of my trip. Worth waking up at 3am!',
      rating: 5.0,
      date: DateTime(2026, 1, 28),
      helpfulCount: 67,
      providerName: 'Abu Simbel Temple',
    ),
    UserReview(
      id: '3',
      type: 'Experiences',
      title: 'Nile Dinner Cruise',
      content:
          'Beautiful evening with traditional music and delicious food. The city lights from the water were magical.',
      rating: 4.5,
      date: DateTime(2026, 1, 15),
      helpfulCount: 23,
      providerName: 'Nile Pharaoh Cruises',
    ),
    UserReview(
      id: '4',
      type: 'Guides',
      title: 'Good but rushed',
      content:
          'The guide was friendly but we felt a bit rushed through the museum. Would have liked more time.',
      rating: 3.5,
      date: DateTime(2026, 1, 10),
      helpfulCount: 15,
      providerName: 'Cairo Museum Tours',
    ),
    UserReview(
      id: '5',
      type: 'Places',
      title: 'Hidden Gem!',
      content:
          'Siwa Oasis is absolutely stunning. The desert scenery and salt lakes are otherworldly.',
      rating: 5.0,
      date: DateTime(2025, 12, 20),
      helpfulCount: 89,
      providerName: 'Siwa Oasis',
    ),
  ];

  late UserProfile _user;
  late List<TravelPhoto> _photos;
  late List<UserReview> _reviews;

  List<UserReview> get _filteredAndSortedReviews {
    var reviews =
        _selectedFilter == 'All'
            ? List<UserReview>.from(_reviews)
            : _reviews.where((r) => r.type == _selectedFilter).toList();

    switch (_selectedSort) {
      case 'Most Recent':
        reviews.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Highest Rated':
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest Rated':
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'Most Helpful':
        reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
    }
    return reviews;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _user = _fallbackUser;
    _photos = _fallbackPhotos;
    _reviews = _fallbackReviews;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final username =
          SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      final userId = user['_id'] as String;
      final photos = await _profileService.getUserPhotos(userId);
      final reviews = await _profileService.getUserReviews(userId);

      setState(() {
        _user = UserProfile.fromJson(user);
        _photos = photos.map(TravelPhoto.fromJson).toList();
        _reviews = reviews.map(UserReview.fromJson).toList();
      });
    } catch (_) {
      // Keep fallback data on error
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: cardColor.withOpacity(0.95),
                elevation: 0,
                title: Text(
                  _user.username,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: textColor,
                  ),
                ),
                actions: [
                  Semantics(
                    button: true,
                    label: 'Settings',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.line_horizontal_3,
                        color: textColor,
                        size: 24,
                      ),
                      onPressed: () => _showSettingsSheet(context),
                    ),
                  ),
                ],
              ),
            ],
        body: Column(
          children: [
            // Profile Header
            Container(
              color: cardColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Stats Row
                  Row(
                    children: [
                      // Avatar
                      _buildAvatar(isDark),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: _buildStatsRow(textColor, secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name and Bio
                  Row(
                    children: [
                      Text(
                        _user.name,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (_user.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 16,
                          color: Color(0xFF007AFF),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user.bio,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile Button
                  _buildEditProfileButton(isDark, textColor),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: cardColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: textColor,
                indicatorWeight: 1,
                labelColor: textColor,
                unselectedLabelColor: secondaryTextColor,
                tabs: [
                  Semantics(
                    label: 'Photos tab, ${_photos.length} photos',
                    child: Tab(
                      icon: Icon(CupertinoIcons.square_grid_2x2, size: 24),
                    ),
                  ),
                  Semantics(
                    label: 'Reviews tab, ${_reviews.length} reviews',
                    child: Tab(icon: Icon(CupertinoIcons.text_quote, size: 24)),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Photos Grid Tab
                  _buildPhotosGrid(isDark, cardColor),
                  // Reviews Tab
                  _buildReviewsTab(
                    isDark,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Semantics(
      label: '${_user.name}\'s profile picture',
      image: true,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child:
                _user.avatarUrl.isNotEmpty
                    ? Image.network(
                      _user.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Center(
                            child: Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                    )
                    : const Center(
                      child: Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildStatsRow(Color textColor, Color secondaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(
          '${_user.photosCount}',
          'Photos',
          textColor,
          secondaryTextColor,
        ),
        _buildStatColumn(
          '${_user.tripsCount}',
          'Trips',
          textColor,
          secondaryTextColor,
        ),
        _buildStatColumn(
          '${_user.reviewsCount}',
          'Reviews',
          textColor,
          secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    String value,
    String label,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Semantics(
      label: '$value $label',
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(bool isDark, Color textColor) {
    return Semantics(
      button: true,
      label: 'Edit profile',
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          onPressed: () {
            // Navigate to edit profile
          },
        ),
      ),
    );
  }

  Widget _buildPhotosGrid(bool isDark, Color cardColor) {
    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.camera,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No photos yet',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return Semantics(
          label: 'Photo from ${photo.location}, ${photo.likes} likes',
          button: true,
          child: GestureDetector(
            onTap: () => _showPhotoDetail(photo),
            child: Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder gradient based on index
                  if (photo.mediaUrl != null && photo.mediaUrl!.isNotEmpty)
                    Image.network(
                      photo.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getPhotoGradient(index),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 32,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getPhotoGradient(index),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.photo,
                          size: 32,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  // Location overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black54],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        photo.location,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  List<Color> _getPhotoGradient(int index) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFFD4AF37), const Color(0xFF0F4C75)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFee0979), const Color(0xFFff6a00)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildReviewsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final filteredReviews = _filteredAndSortedReviews;

    return Column(
      children: [
        // Filters and Sort
        Container(
          color: cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Filter dropdown
              Expanded(
                child: Semantics(
                  label:
                      'Filter reviews by category. Currently: $_selectedFilter',
                  button: true,
                  child: _buildDropdownButton(
                    value: _selectedFilter,
                    items: _filterOptions,
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedFilter = value);
                    },
                    isDark: isDark,
                    textColor: textColor,
                    icon: CupertinoIcons.line_horizontal_3_decrease,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sort dropdown
              Expanded(
                child: Semantics(
                  label: 'Sort reviews. Currently: $_selectedSort',
                  button: true,
                  child: _buildDropdownButton(
                    value: _selectedSort,
                    items: _sortOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedSort = value);
                    },
                    isDark: isDark,
                    textColor: textColor,
                    icon: CupertinoIcons.arrow_up_arrow_down,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filteredReviews.length} ${filteredReviews.length == 1 ? 'review' : 'reviews'}',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child:
              filteredReviews.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.text_quote,
                          size: 64,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews found',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(
                        filteredReviews[index],
                        isDark,
                        cardColor,
                        textColor,
                        secondaryTextColor,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(icon, size: 16, color: textColor),
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          items:
              items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    UserReview review,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Semantics(
      label:
          'Review: ${review.title}, rated ${review.rating} out of 5 stars, for ${review.providerName}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(review.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review.type,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(review.type),
                    ),
                  ),
                ),
                const Spacer(),
                // Rating
                _buildRatingStars(review.rating),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              review.title,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            // Provider name
            Text(
              review.providerName,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                color: const Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Text(
              review.content,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                color: textColor.withOpacity(0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Footer
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(review.date),
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.hand_thumbsup,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${review.helpfulCount} helpful',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            CupertinoIcons.star_fill,
            size: 14,
            color: Color(0xFFFFB800),
          );
        } else if (index < rating) {
          return const Icon(
            CupertinoIcons.star_lefthalf_fill,
            size: 14,
            color: Color(0xFFFFB800),
          );
        } else {
          return Icon(CupertinoIcons.star, size: 14, color: Colors.grey[400]);
        }
      }),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'Places':
        return const Color(0xFF4facfe);
      case 'Guides':
        return const Color(0xFF667eea);
      case 'Experiences':
        return const Color(0xFFf5576c);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showPhotoDetail(TravelPhoto photo) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient:
                                photo.mediaUrl == null ||
                                        photo.mediaUrl!.isEmpty
                                    ? LinearGradient(
                                      colors: _getPhotoGradient(
                                        int.tryParse(photo.id) ?? 0,
                                      ),
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              photo.mediaUrl != null &&
                                      photo.mediaUrl!.isNotEmpty
                                  ? Image.network(
                                    photo.mediaUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              CupertinoIcons.photo,
                                              size: 64,
                                              color: Colors.white70,
                                            ),
                                  )
                                  : const Icon(
                                    CupertinoIcons.photo,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          photo.location,
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.heart_fill,
                              size: 18,
                              color: Color(0xFFf5576c),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${photo.likes} likes',
                              style: const TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 14,
                                color: Colors.white70,
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

  void _showSettingsSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Settings'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to settings
                },
                child: const Text('Account Settings'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to saved
                },
                child: const Text('Saved Places'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to help
                },
                child: const Text('Help & Support'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation(context);
                },
                child: const Text('Log Out'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Sign Out'),
                onPressed: () {
                  Navigator.pop(context);
                  // Handle logout
                },
              ),
            ],
          ),
    );
  }
}

/// User profile model
class UserProfile {
  final String name;
  final String username;
  final String bio;
  final String avatarUrl;
  final bool isVerified;
  final int tripsCount;
  final int reviewsCount;
  final int photosCount;
  final double rating;
  final String memberSince;

  UserProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.isVerified,
    required this.tripsCount,
    required this.reviewsCount,
    required this.photosCount,
    required this.rating,
    required this.memberSince,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['full_name']?.toString() ?? 'Unknown',
      username: json['username']?.toString() ?? '@user',
      bio: json['bio']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      isVerified: json['verified_flag'] == true,
      tripsCount: (json['trips_count'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      photosCount: (json['photos_count'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      memberSince: json['member_since']?.toString() ?? 'Unknown',
    );
  }
}

/// Travel photo model
class TravelPhoto {
  final String id;
  final String location;
  final int likes;
  final String? mediaUrl;

  TravelPhoto({
    required this.id,
    required this.location,
    required this.likes,
    this.mediaUrl,
  });

  factory TravelPhoto.fromJson(Map<String, dynamic> json) {
    return TravelPhoto(
      id: json['_id']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Unknown',
      likes: (json['like_count'] as num?)?.toInt() ?? 0,
      mediaUrl: json['media_url']?.toString(),
    );
  }
}

/// User review model
class UserReview {
  final String id;
  final String type;
  final String title;
  final String content;
  final double rating;
  final DateTime date;
  final int helpfulCount;
  final String providerName;

  UserReview({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.rating,
    required this.date,
    required this.helpfulCount,
    required this.providerName,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['_id']?.toString() ?? '',
      type: json['review_type']?.toString() ?? 'Experiences',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      date:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      providerName: json['provider_name']?.toString() ?? '',
    );
  }
}
