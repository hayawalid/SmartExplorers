import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _featuredDestinations = [
    {
      'name': 'Pyramids of Giza',
      'location': 'Cairo',
      'rating': 4.9,
      'image': '🏛️',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      'name': 'Valley of Kings',
      'location': 'Luxor',
      'rating': 4.8,
      'image': '⚱️',
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
    },
    {
      'name': 'Red Sea Resort',
      'location': 'Hurghada',
      'rating': 4.7,
      'image': '🏖️',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    },
  ];

  final List<Map<String, dynamic>> _verifiedGuides = [
    {
      'name': 'Ahmed Hassan',
      'specialty': 'Ancient History',
      'rating': 5.0,
      'emoji': '👨‍🏫',
    },
    {
      'name': 'Fatima Ali',
      'specialty': 'Photography Tours',
      'rating': 4.9,
      'emoji': '👩‍🎨',
    },
    {
      'name': 'Omar Said',
      'specialty': 'Desert Safari',
      'rating': 4.8,
      'emoji': '🧔',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(textColor, secondaryTextColor),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: _buildSearchBar(
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
              ),

              // Featured destinations
              SliverToBoxAdapter(
                child: _buildSectionTitle('Featured Destinations', textColor),
              ),
              SliverToBoxAdapter(child: _buildFeaturedDestinations(isDark)),

              // Verified guides
              SliverToBoxAdapter(
                child: _buildSectionTitle('Top Verified Guides', textColor),
              ),
              SliverToBoxAdapter(
                child: _buildVerifiedGuides(
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: _buildSectionTitle('Quick Actions', textColor),
              ),
              SliverToBoxAdapter(
                child: _buildQuickActions(
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
              ),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore Egypt',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, color: secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search destinations, guides...',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.slider_horizontal_3,
                color: secondaryTextColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const Text(
            'See all',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF667eea),
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDestinations(bool isDark) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredDestinations.length,
        itemBuilder: (context, index) {
          final dest = _featuredDestinations[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dest['gradient'],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Emoji illustration
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Text(
                          dest['image'],
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Text(
                              dest['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dest['location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  size: 14,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${dest['rating']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'SF Pro Text',
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerifiedGuides(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children:
            _verifiedGuides
                .map(
                  (guide) => _buildGuideCard(
                    guide,
                    isDark,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildGuideCard(
    Map<String, dynamic> guide,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFF2F2F7),
            ),
            child: Center(
              child: Text(guide['emoji'], style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      guide['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 16,
                      color: Color(0xFF4facfe),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  guide['specialty'],
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    size: 14,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${guide['rating']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: const Text(
                  'Book',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final actions = [
      {
        'icon': CupertinoIcons.map_fill,
        'label': 'Plan Trip',
        'color': Color(0xFF667eea),
      },
      {
        'icon': CupertinoIcons.car_fill,
        'label': 'Book Ride',
        'color': Color(0xFFf093fb),
      },
      {
        'icon': CupertinoIcons.camera_fill,
        'label': 'Photo Tour',
        'color': Color(0xFF4facfe),
      },
      {
        'icon': CupertinoIcons.gift_fill,
        'label': 'Experiences',
        'color': Color(0xFFD4AF37),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            actions.map((action) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                    boxShadow:
                        isDark
                            ? null
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (action['color'] as Color).withOpacity(0.2),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.9),
                          fontFamily: 'SF Pro Text',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
