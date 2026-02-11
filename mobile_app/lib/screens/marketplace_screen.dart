import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../services/marketplace_api_service.dart';

/// Service provider marketplace with WCAG accessibility support
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceApiService _marketplaceService = MarketplaceApiService();
  late Future<List<ServiceProvider>> _providersFuture;

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tour Guides',
    'Drivers',
    'Hotels',
    'Restaurants',
    'Activities',
  ];

  final List<ServiceProvider> _providers = [
    ServiceProvider(
      id: '1',
      name: 'Ahmed Hassan',
      category: 'Tour Guide',
      specialty: 'Ancient History Expert',
      rating: 4.9,
      reviews: 247,
      price: '\$50/hr',
      emoji: '👨‍🏫',
      isVerified: true,
      isFeatured: true,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      description:
          'Certified Egyptologist with 15 years of experience. Fluent in English, French, and Arabic.',
    ),
    ServiceProvider(
      id: '2',
      name: 'Fatima Ali',
      category: 'Tour Guide',
      specialty: 'Photography Tours',
      rating: 4.8,
      reviews: 189,
      price: '\$65/hr',
      emoji: '👩‍🎨',
      isVerified: true,
      isFeatured: false,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      description:
          'Professional photographer offering photo tours at iconic Egyptian sites.',
    ),
    ServiceProvider(
      id: '3',
      name: 'Nile View Hotel',
      category: 'Hotels',
      specialty: 'Luxury Accommodation',
      rating: 4.7,
      reviews: 523,
      price: '\$120/night',
      emoji: '🏨',
      isVerified: true,
      isFeatured: true,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      description:
          '5-star hotel with stunning Nile views. Pool, spa, and rooftop restaurant.',
    ),
    ServiceProvider(
      id: '4',
      name: 'Omar\'s Taxi Service',
      category: 'Drivers',
      specialty: 'Airport & City Tours',
      rating: 4.9,
      reviews: 412,
      price: '\$30/trip',
      emoji: '🚗',
      isVerified: true,
      isFeatured: false,
      gradient: [Color(0xFFD4AF37), Color(0xFF0F4C75)],
      description:
          'Licensed driver with air-conditioned vehicle. English speaking.',
    ),
    ServiceProvider(
      id: '5',
      name: 'Pharaoh\'s Kitchen',
      category: 'Restaurants',
      specialty: 'Traditional Egyptian',
      rating: 4.6,
      reviews: 876,
      price: '\$\$',
      emoji: '🍽️',
      isVerified: true,
      isFeatured: false,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      description:
          'Authentic Egyptian cuisine in a historic setting near Khan el-Khalili.',
    ),
    ServiceProvider(
      id: '6',
      name: 'Red Sea Diving Center',
      category: 'Activities',
      specialty: 'Scuba Diving',
      rating: 4.8,
      reviews: 334,
      price: '\$75/dive',
      emoji: '🤿',
      isVerified: true,
      isFeatured: true,
      gradient: [Color(0xFF667eea), Color(0xFF00f2fe)],
      description:
          'PADI certified diving center. Beginner courses and advanced dives available.',
    ),
  ];

  List<ServiceProvider> get _filteredProviders {
    if (_selectedCategory == 'All') return _providers;
    return _providers
        .where(
          (p) =>
              p.category == _selectedCategory ||
              (_selectedCategory == 'Tour Guides' &&
                  p.category == 'Tour Guide'),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _providersFuture = _loadProviders();
  }

  Future<List<ServiceProvider>> _loadProviders() async {
    final data = await _marketplaceService.getListings(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (data.isEmpty) return _filteredProviders;
    return data.map(ServiceProvider.fromJson).toList();
  }

  @override
  void dispose() {
    _marketplaceService.dispose();
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
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(textColor, isDark)),

            // Search bar
            SliverToBoxAdapter(
              child: _buildSearchBar(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: _buildCategories(isDark, textColor, secondaryTextColor),
            ),

            // Featured section
            SliverToBoxAdapter(
              child: _buildFeaturedSection(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),
            ),

            // All providers grid
            SliverToBoxAdapter(child: _buildAllProvidersHeader(textColor)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder<List<ServiceProvider>>(
                  future: _providersFuture,
                  builder: (context, snapshot) {
                    final providers = snapshot.data ?? _filteredProviders;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: providers.length,
                      itemBuilder:
                          (context, index) => _buildProviderCard(
                            providers[index],
                            isDark,
                            cardColor,
                            textColor,
                            secondaryTextColor,
                          ),
                    );
                  },
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Filter options',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.slider_horizontal_3,
                color: textColor,
                size: 22,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        textField: true,
        label: 'Search for services or providers',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 50,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE5E5EA),
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
              Icon(CupertinoIcons.search, color: secondaryTextColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search guides, hotels, activities...',
                    hintStyle: TextStyle(
                      color: secondaryTextColor,
                      fontFamily: 'SF Pro Text',
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Semantics(
            button: true,
            label: 'Filter by $category',
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _providersFuture = _loadProviders();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF667eea)
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFE5E5EA)),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF667eea)
                            : (isDark
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFFD1D1D6)),
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : textColor),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final featured = _providers.where((p) => p.isFeatured).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Semantics(
            header: true,
            child: Text(
              'Featured',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            itemBuilder:
                (context, index) => _buildFeaturedCard(
                  featured[index],
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(
    ServiceProvider provider,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Semantics(
      button: true,
      label:
          '${provider.name}, ${provider.specialty}, rated ${provider.rating} stars, ${provider.price}',
      child: GestureDetector(
        onTap: () => _navigateToProviderDetail(provider),
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: provider.gradient),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Opacity(
                        opacity: 0.2,
                        child: Text(
                          provider.emoji,
                          style: const TextStyle(fontSize: 150),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    provider.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          provider.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (provider.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            CupertinoIcons.checkmark_seal_fill,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      provider.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Text(
                            provider.specialty,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.star_fill,
                                size: 16,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ' (${provider.reviews})',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  provider.price,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
          ),
        ),
      ),
    );
  }

  Widget _buildAllProvidersHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              _selectedCategory == 'All' ? 'All Services' : _selectedCategory,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_filteredProviders.length})',
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(
    ServiceProvider provider,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Semantics(
      button: true,
      label:
          '${provider.name}, ${provider.specialty}, rated ${provider.rating} stars',
      child: GestureDetector(
        onTap: () => _navigateToProviderDetail(provider),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE5E5EA),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: provider.gradient),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Text(
                    provider.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isVerified)
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 14,
                            color: Color(0xFF4facfe),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.specialty,
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.rating}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          provider.price,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4facfe),
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

  void _navigateToProviderDetail(ServiceProvider provider) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ProviderDetailScreen(provider: provider),
      ),
    );
  }
}

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String specialty;
  final double rating;
  final int reviews;
  final String price;
  final String emoji;
  final bool isVerified;
  final bool isFeatured;
  final List<Color> gradient;
  final String description;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.emoji,
    required this.isVerified,
    required this.isFeatured,
    required this.gradient,
    required this.description,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'Service',
      specialty: json['specialty']?.toString() ?? 'General',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['review_count'] as num?)?.toInt() ?? 0,
      price: json['price_text']?.toString() ?? '\$',
      emoji: '⭐',
      isVerified: json['is_verified'] == true,
      isFeatured: json['featured_flag'] == true,
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
      description: json['description']?.toString() ?? '',
    );
  }
}

/// Provider detail screen with CupertinoPageRoute transition
class ProviderDetailScreen extends StatelessWidget {
  final ServiceProvider provider;

  const ProviderDetailScreen({Key? key, required this.provider})
    : super(key: key);

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
      body: CustomScrollView(
        slivers: [
          // App bar with gradient header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: backgroundColor,
            leading: Semantics(
              button: true,
              label: 'Go back',
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.back, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: provider.gradient),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        provider.emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (provider.isVerified) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label: 'Verified provider',
                              child: const Icon(
                                CupertinoIcons.checkmark_seal_fill,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and price row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.star_fill,
                                size: 18,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${provider.rating}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                ' (${provider.reviews} reviews)',
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          provider.price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4facfe),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Book button
                  Semantics(
                    button: true,
                    label: 'Book ${provider.name} now',
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: provider.gradient),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: provider.gradient.first.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {},
                          child: const Center(
                            child: Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact button
                  Semantics(
                    button: true,
                    label: 'Send message to ${provider.name}',
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : const Color(0xFFD1D1D6),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {},
                          child: Center(
                            child: Text(
                              'Send Message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
