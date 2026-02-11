import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/profile_api_service.dart';
import '../services/api_config.dart';

/// Provider Profile Screen with 3 tabs: Portfolio, Credentials, Reviews
/// Designed for service providers to showcase their work and qualifications
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileApiService _profileService = ProfileApiService();

  // Provider data
  final ProviderProfile _fallbackProvider = ProviderProfile(
    name: 'Ahmed Hassan',
    serviceType: 'Tour Guide',
    bio:
        'Certified Egyptologist with 10+ years of experience. Passionate about sharing the rich history of ancient Egypt with travelers from around the world.',
    rating: 4.9,
    reviewCount: 127,
    completedTours: 342,
    isVerified: true,
    languages: ['Arabic', 'English', 'French'],
    memberSince: 'January 2022',
  );

  // Portfolio images
  final List<PortfolioItem> _fallbackPortfolio = [
    PortfolioItem(
      id: '1',
      title: 'Pyramids Tour',
      likes: 234,
      category: 'Tours',
    ),
    PortfolioItem(
      id: '2',
      title: 'Luxor Temple',
      likes: 189,
      category: 'Historical',
    ),
    PortfolioItem(
      id: '3',
      title: 'Nile Sunset',
      likes: 312,
      category: 'Scenic',
    ),
    PortfolioItem(
      id: '4',
      title: 'Valley of Kings',
      likes: 276,
      category: 'Tours',
    ),
    PortfolioItem(
      id: '5',
      title: 'Abu Simbel',
      likes: 445,
      category: 'Historical',
    ),
    PortfolioItem(
      id: '6',
      title: 'Cairo Market',
      likes: 156,
      category: 'Culture',
    ),
    PortfolioItem(
      id: '7',
      title: 'Desert Safari',
      likes: 298,
      category: 'Adventure',
    ),
    PortfolioItem(
      id: '8',
      title: 'Sphinx at Dawn',
      likes: 523,
      category: 'Tours',
    ),
    PortfolioItem(
      id: '9',
      title: 'Traditional Dinner',
      likes: 187,
      category: 'Culture',
    ),
  ];

  // Credentials
  final List<Credential> _fallbackCredentials = [
    Credential(
      title: 'Certified Egyptologist',
      issuer: 'Ministry of Tourism - Egypt',
      date: 'March 2018',
      isVerified: true,
      icon: '🎓',
    ),
    Credential(
      title: 'First Aid Certified',
      issuer: 'Red Crescent Society',
      date: 'June 2023',
      isVerified: true,
      icon: '🏥',
    ),
    Credential(
      title: 'Licensed Tour Guide',
      issuer: 'Egyptian Tourism Authority',
      date: 'January 2020',
      isVerified: true,
      icon: '📜',
    ),
    Credential(
      title: 'Child Safety Training',
      issuer: 'UNICEF Egypt',
      date: 'September 2022',
      isVerified: true,
      icon: '🛡️',
    ),
  ];

  // Reviews
  final List<ProviderReview> _fallbackReviews = [
    ProviderReview(
      id: '1',
      reviewerName: 'Sarah M.',
      content:
          'Ahmed made our trip absolutely magical! His knowledge of ancient Egypt is unparalleled.',
      rating: 5.0,
      date: DateTime(2026, 2, 10),
      helpful: 42,
    ),
    ProviderReview(
      id: '2',
      reviewerName: 'James L.',
      content:
          'Professional, punctual, and incredibly passionate. Best guide we\'ve ever had!',
      rating: 5.0,
      date: DateTime(2026, 2, 5),
      helpful: 38,
    ),
    ProviderReview(
      id: '3',
      reviewerName: 'Maria G.',
      content:
          'Great tour of the pyramids. Ahmed was very patient with our children.',
      rating: 4.5,
      date: DateTime(2026, 1, 28),
      helpful: 25,
    ),
    ProviderReview(
      id: '4',
      reviewerName: 'David K.',
      content:
          'Excellent experience overall. Would highly recommend for any Egypt trip.',
      rating: 5.0,
      date: DateTime(2026, 1, 20),
      helpful: 31,
    ),
  ];

  late ProviderProfile _provider;
  late List<PortfolioItem> _portfolio;
  late List<Credential> _credentials;
  late List<ProviderReview> _reviews;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _provider = _fallbackProvider;
    _portfolio = _fallbackPortfolio;
    _credentials = _fallbackCredentials;
    _reviews = _fallbackReviews;
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      final user = await _profileService.getUserByUsername(
        ApiConfig.demoProviderUsername,
      );
      final userId = user['_id'] as String;
      final providerProfile = await _profileService.getProviderProfile(userId);
      final portfolio = await _profileService.getProviderPortfolio(userId);
      final credentials = await _profileService.getProviderCredentials(userId);
      final reviews = await _profileService.getProviderReviews(userId);

      setState(() {
        _provider = ProviderProfile.fromJson(providerProfile ?? user);
        _portfolio = portfolio.map(PortfolioItem.fromJson).toList();
        _credentials = credentials.map(Credential.fromJson).toList();
        _reviews = reviews.map(ProviderReview.fromJson).toList();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: cardColor.withValues(alpha: 0.95),
                elevation: 0,
                title: Text(
                  'My Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: textColor,
                  ),
                ),
                actions: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed:
                        () => _showSettingsSheet(
                          context,
                          isDark,
                          textColor,
                          subtitleColor,
                          cardColor,
                        ),
                    child: Icon(
                      CupertinoIcons.gear,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
        body: Column(
          children: [
            // Profile Header
            _buildProfileHeader(isDark, cardColor, textColor, subtitleColor),

            // Tab Bar
            _buildTabBar(isDark, cardColor, textColor, subtitleColor),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPortfolioTab(
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor,
                  ),
                  _buildCredentialsTab(
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor,
                  ),
                  _buildReviewsTab(isDark, cardColor, textColor, subtitleColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with gradient border
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF093FB).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF093FB).withValues(alpha: 0.3),
                          const Color(0xFFF5576C).withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      '${_provider.completedTours}',
                      'Tours',
                      textColor,
                      subtitleColor,
                    ),
                    _buildStatColumn(
                      '${_provider.reviewCount}',
                      'Reviews',
                      textColor,
                      subtitleColor,
                    ),
                    _buildStatColumn(
                      '${_provider.rating}',
                      'Rating',
                      textColor,
                      subtitleColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and verified badge
          Row(
            children: [
              Text(
                _provider.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (_provider.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38EF7D), Color(0xFF11998E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // Service type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF093FB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _provider.serviceType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF093FB),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bio
          Text(
            _provider.bio,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
          ),

          const SizedBox(height: 12),

          // Languages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _provider.languages.map((lang) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🌐 $lang',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),

          // Edit Profile Button
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String value,
    String label,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: subtitleColor)),
      ],
    );
  }

  Widget _buildTabBar(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      color: cardColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFF093FB),
        indicatorWeight: 2,
        labelColor: textColor,
        unselectedLabelColor: subtitleColor,
        tabs: [
          Semantics(
            label: 'Portfolio tab',
            child: Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.photo_fill_on_rectangle_fill, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Portfolio',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            label: 'Credentials tab',
            child: Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.doc_text_fill, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Credentials',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            label: 'Reviews tab',
            child: Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.star_fill, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Reviews',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _portfolio.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add new photo button
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Implement photo upload
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF093FB),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: Color(0xFFF093FB),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = _portfolio[index - 1];
          final gradients = [
            [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            [const Color(0xFFF093FB), const Color(0xFFF5576C)],
            [const Color(0xFF11998E), const Color(0xFF38EF7D)],
            [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
            [const Color(0xFFD4AF37), const Color(0xFFB8860B)],
          ];

          return GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients[(index - 1) % gradients.length],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder with emoji based on category
                  Center(
                    child: Text(
                      _getCategoryEmoji(item.category),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  // Overlay with info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.heart_fill,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likes}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Tours':
        return '🏛️';
      case 'Historical':
        return '⚱️';
      case 'Scenic':
        return '🌅';
      case 'Culture':
        return '🎭';
      case 'Adventure':
        return '🏜️';
      default:
        return '📷';
    }
  }

  Widget _buildCredentialsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Upload new credential button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Implement credential upload
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF093FB).withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF093FB).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.plus,
                    color: Color(0xFFF093FB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Upload New Credential',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Credentials list
        ..._credentials.asMap().entries.map((entry) {
          final cred = entry.value;
          final index = entry.key;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        cred.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cred.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cred.issuer,
                          style: TextStyle(fontSize: 13, color: subtitleColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Issued: ${cred.date}',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cred.isVerified)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38EF7D).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 20,
                        color: Color(0xFF38EF7D),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReviewsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF093FB).withValues(alpha: isDark ? 0.15 : 0.1),
                const Color(0xFFF5576C).withValues(alpha: isDark ? 0.15 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    '${_provider.rating}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _provider.rating.floor()
                            ? CupertinoIcons.star_fill
                            : (index < _provider.rating
                                ? CupertinoIcons.star_lefthalf_fill
                                : CupertinoIcons.star),
                        size: 18,
                        color: const Color(0xFFD4AF37),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_provider.reviewCount} reviews',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar('5', 0.85, isDark, subtitleColor),
                    _buildRatingBar('4', 0.10, isDark, subtitleColor),
                    _buildRatingBar('3', 0.03, isDark, subtitleColor),
                    _buildRatingBar('2', 0.01, isDark, subtitleColor),
                    _buildRatingBar('1', 0.01, isDark, subtitleColor),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reviews list
        ..._reviews.asMap().entries.map((entry) {
          final review = entry.value;
          final index = entry.key;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Reviewer avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withValues(alpha: 0.5),
                              const Color(0xFF764BA2).withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            review.reviewerName[0],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.reviewerName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              _formatDate(review.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            size: 16,
                            color: Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.hand_thumbsup,
                        size: 16,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${review.helpful} found this helpful',
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRatingBar(
    String label,
    double percent,
    bool isDark,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: subtitleColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showSettingsSheet(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 400,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: subtitleColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: subtitleColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildSettingsItem(
                        icon: CupertinoIcons.person_crop_circle,
                        title: 'Edit Profile',
                        onTap: () {},
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildSettingsItem(
                        icon: CupertinoIcons.bell,
                        title: 'Notifications',
                        onTap: () {},
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildSettingsItem(
                        icon: CupertinoIcons.lock,
                        title: 'Privacy',
                        onTap: () {},
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildSettingsItem(
                        icon: CupertinoIcons.question_circle,
                        title: 'Help & Support',
                        onTap: () {},
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _buildSettingsItem(
                        icon: CupertinoIcons.square_arrow_right,
                        title: 'Log Out',
                        onTap: () {},
                        textColor: const Color(0xFFF5576C),
                        subtitleColor: subtitleColor,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
    required Color subtitleColor,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: subtitleColor.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive ? const Color(0xFFF5576C) : textColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? const Color(0xFFF5576C) : textColor,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 18, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}

// Data models
class ProviderProfile {
  final String name;
  final String serviceType;
  final String bio;
  final double rating;
  final int reviewCount;
  final int completedTours;
  final bool isVerified;
  final List<String> languages;
  final String memberSince;

  ProviderProfile({
    required this.name,
    required this.serviceType,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.completedTours,
    required this.isVerified,
    required this.languages,
    required this.memberSince,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      name:
          json['full_legal_name']?.toString() ??
          json['full_name']?.toString() ??
          'Unknown',
      serviceType: json['service_type']?.toString() ?? 'Service',
      bio: json['bio']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      completedTours: (json['completed_tours_count'] as num?)?.toInt() ?? 0,
      isVerified: json['verified_flag'] == true,
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      memberSince: json['member_since']?.toString() ?? 'Unknown',
    );
  }
}

class PortfolioItem {
  final String id;
  final String title;
  final int likes;
  final String category;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.likes,
    required this.category,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      likes: (json['like_count'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'General',
    );
  }
}

class Credential {
  final String title;
  final String issuer;
  final String date;
  final bool isVerified;
  final String icon;

  Credential({
    required this.title,
    required this.issuer,
    required this.date,
    required this.isVerified,
    required this.icon,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      title: json['title']?.toString() ?? 'Credential',
      issuer: json['issuer']?.toString() ?? 'Issuer',
      date: json['date']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      icon: json['icon']?.toString() ?? '🎓',
    );
  }
}

class ProviderReview {
  final String id;
  final String reviewerName;
  final String content;
  final double rating;
  final DateTime date;
  final int helpful;

  ProviderReview({
    required this.id,
    required this.reviewerName,
    required this.content,
    required this.rating,
    required this.date,
    required this.helpful,
  });

  factory ProviderReview.fromJson(Map<String, dynamic> json) {
    return ProviderReview(
      id: json['_id']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? 'Anonymous',
      content: json['content']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      date:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      helpful: (json['helpful_count'] as num?)?.toInt() ?? 0,
    );
  }
}
