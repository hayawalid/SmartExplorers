// ============================================================================
// provider_profile_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/smart_explorers_logo.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/profile_api_service.dart';
import 'package:mobile_app/services/api_config.dart';
import '../onboarding/onboarding_flow.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ProfileApiService _profileService = ProfileApiService();

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

  final List<PortfolioItem> _fallbackPortfolio = [
    PortfolioItem(id: '1', title: 'Pyramids Tour', likes: 234, category: 'Tours'),
    PortfolioItem(id: '2', title: 'Luxor Temple', likes: 189, category: 'Historical'),
    PortfolioItem(id: '3', title: 'Nile Sunset', likes: 312, category: 'Scenic'),
    PortfolioItem(id: '4', title: 'Valley of Kings', likes: 276, category: 'Tours'),
    PortfolioItem(id: '5', title: 'Abu Simbel', likes: 445, category: 'Historical'),
    PortfolioItem(id: '6', title: 'Cairo Market', likes: 156, category: 'Culture'),
    PortfolioItem(id: '7', title: 'Desert Safari', likes: 298, category: 'Adventure'),
    PortfolioItem(id: '8', title: 'Sphinx at Dawn', likes: 523, category: 'Tours'),
    PortfolioItem(id: '9', title: 'Traditional Dinner', likes: 187, category: 'Culture'),
  ];

  final List<Credential> _fallbackCredentials = [
    Credential(title: 'Certified Egyptologist', issuer: 'Ministry of Tourism - Egypt', date: 'March 2018', isVerified: true, icon: '🎓'),
    Credential(title: 'First Aid Certified', issuer: 'Red Crescent Society', date: 'June 2023', isVerified: true, icon: '🏥'),
    Credential(title: 'Licensed Tour Guide', issuer: 'Egyptian Tourism Authority', date: 'January 2020', isVerified: true, icon: '📜'),
    Credential(title: 'Child Safety Training', issuer: 'UNICEF Egypt', date: 'September 2022', isVerified: true, icon: '🛡️'),
  ];

  final List<ProviderReview> _fallbackReviews = [
    ProviderReview(id: '1', reviewerName: 'Sarah M.', content: 'Ahmed made our trip absolutely magical! His knowledge of ancient Egypt is unparalleled.', rating: 5.0, date: DateTime(2026, 2, 10), helpful: 42),
    ProviderReview(id: '2', reviewerName: 'James L.', content: 'Professional, punctual, and incredibly passionate. Best guide we\'ve ever had!', rating: 5.0, date: DateTime(2026, 2, 5), helpful: 38),
    ProviderReview(id: '3', reviewerName: 'Maria G.', content: 'Great tour of the pyramids. Ahmed was very patient with our children.', rating: 4.5, date: DateTime(2026, 1, 28), helpful: 25),
    ProviderReview(id: '4', reviewerName: 'David K.', content: 'Excellent experience overall. Would highly recommend for any Egypt trip.', rating: 5.0, date: DateTime(2026, 1, 20), helpful: 31),
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
      final username = SessionStore.instance.username ?? ApiConfig.demoProviderUsername;
      final user = await _profileService.getUserByUsername(username);
      final userId = user['_id'] as String;
      
      // Only fetch provider-specific data, NOT traveler data
      final providerProfile = await _profileService.getProviderProfile(userId);
      final portfolio = await _profileService.getProviderPortfolio(userId);
      final credentials = await _profileService.getProviderCredentials(userId);
      final reviews = await _profileService.getProviderReviews(userId);
      
      if (mounted) {
        setState(() {
          _provider = ProviderProfile.fromJson(providerProfile ?? user);
          _portfolio = portfolio.map(PortfolioItem.fromJson).toList();
          _credentials = credentials.map(Credential.fromJson).toList();
          _reviews = reviews.map(ProviderReview.fromJson).toList();
        });
      }
    } catch (e) {
      // Silent fail - keep fallback data
      debugPrint('Error loading provider data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileService.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final cardColor = isDark ? AppDesign.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final subtitleColor = isDark ? Colors.white54 : AppDesign.midGrey;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: cardColor.withOpacity(0.95),
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
                const SizedBox(width: 8),
                Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: textColor)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.settings, color: textColor),
                onPressed: () => _showSettingsSheet(isDark, textColor, subtitleColor, cardColor),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            _buildProfileHeader(isDark, cardColor, textColor, subtitleColor),
            _buildTabBar(isDark, cardColor, textColor, subtitleColor),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPortfolioTab(isDark, cardColor, textColor, subtitleColor),
                  _buildCredentialsTab(isDark, cardColor, textColor, subtitleColor),
                  _buildReviewsTab(isDark, cardColor, textColor, subtitleColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppDesign.navConcierge, AppDesign.onboardingAccent]),
                  boxShadow: [BoxShadow(color: AppDesign.navConcierge.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: cardColor),
                  child: const Icon(LucideIcons.user, size: 40, color: AppDesign.navConcierge),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('${_provider.completedTours}', 'Tours', textColor, subtitleColor),
                    _buildStatColumn('${_provider.reviewCount}', 'Reviews', textColor, subtitleColor),
                    _buildStatColumn('${_provider.rating}', 'Rating', textColor, subtitleColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_provider.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
              if (_provider.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppDesign.success.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.badgeCheck, size: 14, color: AppDesign.success),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppDesign.success)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppDesign.navConcierge.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_provider.serviceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppDesign.navConcierge)),
          ),
          const SizedBox(height: 12),
          Text(_provider.bio, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _provider.languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Text('🌐 $lang', style: TextStyle(fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/provider_verification');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppDesign.navSafety, AppDesign.navExplore],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Verification Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => HapticFeedback.lightImpact(),
            icon: const Icon(LucideIcons.edit2, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: isDark ? Colors.white24 : AppDesign.lightGrey),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color textColor, Color subtitleColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: subtitleColor)),
      ],
    );
  }

  Widget _buildTabBar(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      color: cardColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppDesign.navConcierge,
        indicatorWeight: 2,
        labelColor: textColor,
        unselectedLabelColor: subtitleColor,
        tabs: const [
          Tab(text: 'Portfolio'),
          Tab(text: 'Credentials'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _portfolio.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppDesign.navConcierge, width: 2),
                      ),
                      child: const Icon(LucideIcons.plus, color: AppDesign.navConcierge, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor)),
                  ],
                ),
              ),
            );
          }
          final item = _portfolio[index - 1];
          final gradients = [
            [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            [AppDesign.navConcierge, AppDesign.onboardingAccent],
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
                  Center(child: Text(_getCategoryEmoji(item.category), style: const TextStyle(fontSize: 40))),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.heart, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${item.likes}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
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
      case 'Tours': return '🏛️';
      case 'Historical': return '⚱️';
      case 'Scenic': return '🌅';
      case 'Culture': return '🎭';
      case 'Adventure': return '🏜️';
      default: return '📷';
    }
  }

  Widget _buildCredentialsTab(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return ListView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppDesign.navConcierge.withOpacity(0.5), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppDesign.navConcierge.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(LucideIcons.plus, color: AppDesign.navConcierge, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Upload New Credential', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
        ),
        ..._credentials.asMap().entries.map((entry) {
          final cred = entry.value;
          final index = entry.key;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(30 * (1 - value), 0), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppDesign.navConcierge.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(cred.icon, style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cred.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                        const SizedBox(height: 4),
                        Text(cred.issuer, style: TextStyle(fontSize: 13, color: subtitleColor)),
                        const SizedBox(height: 2),
                        Text('Issued: ${cred.date}', style: TextStyle(fontSize: 12, color: subtitleColor.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  if (cred.isVerified)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppDesign.success.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.badgeCheck, size: 20, color: AppDesign.success),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewsTab(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return ListView(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppDesign.navConcierge.withOpacity(isDark ? 0.15 : 0.1),
                AppDesign.onboardingAccent.withOpacity(isDark ? 0.15 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text('${_provider.rating}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: textColor)),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _provider.rating.floor()
                            ? LucideIcons.star
                            : (index < _provider.rating ? LucideIcons.star : LucideIcons.star),
                        size: 18,
                        color: const Color(0xFFD4AF37),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text('${_provider.reviewCount} reviews', style: TextStyle(fontSize: 14, color: subtitleColor)),
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
        ..._reviews.asMap().entries.map((entry) {
          final review = entry.value;
          final index = entry.key;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppDesign.navExplore.withOpacity(0.5),
                            AppDesign.navConcierge.withOpacity(0.5),
                          ]),
                        ),
                        child: Center(
                          child: Text(review.reviewerName[0],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.reviewerName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                            Text(_formatDate(review.date), style: TextStyle(fontSize: 12, color: subtitleColor)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text('${review.rating}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review.content, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.thumbsUp, size: 16, color: AppDesign.midGrey),
                      const SizedBox(width: 6),
                      Text('${review.helpful} found this helpful', style: TextStyle(fontSize: 13, color: subtitleColor)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRatingBar(String label, double percent, bool isDark, Color subtitleColor) {
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
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8860B)]),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showSettingsSheet(bool isDark, Color textColor, Color subtitleColor, Color cardColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: subtitleColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: subtitleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsItem(LucideIcons.user, 'Edit Profile', textColor, subtitleColor),
                  _buildSettingsItem(LucideIcons.bell, 'Notifications', textColor, subtitleColor),
                  _buildSettingsItem(LucideIcons.lock, 'Privacy', textColor, subtitleColor),
                  _buildSettingsItem(LucideIcons.helpCircle, 'Help & Support', textColor, subtitleColor),
                  _buildSettingsItem(LucideIcons.logOut, 'Log Out', AppDesign.danger, subtitleColor, isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color textColor, Color subtitleColor, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppDesign.danger : textColor),
      title: Text(title, style: TextStyle(color: isDestructive ? AppDesign.danger : textColor)),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: subtitleColor),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context); // Close the settings bottom sheet
        
        if (isDestructive && title == 'Log Out') {
          _showLogoutConfirmation();
        }
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: AppDesign.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // Clear session
    SessionStore.instance.clear();
    
    // Navigate to onboarding and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      (route) => false,
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
  ProviderProfile({required this.name, required this.serviceType, required this.bio, required this.rating, required this.reviewCount, required this.completedTours, required this.isVerified, required this.languages, required this.memberSince});
  factory ProviderProfile.fromJson(Map<String, dynamic> json) => ProviderProfile(
    name: json['full_legal_name']?.toString() ?? json['full_name']?.toString() ?? 'Unknown',
    serviceType: json['service_type']?.toString() ?? 'Service',
    bio: json['bio']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    completedTours: (json['completed_tours_count'] as num?)?.toInt() ?? 0,
    isVerified: json['verified_flag'] == true,
    languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    memberSince: json['member_since']?.toString() ?? 'Unknown',
  );
}

class PortfolioItem {
  final String id;
  final String title;
  final int likes;
  final String category;
  PortfolioItem({required this.id, required this.title, required this.likes, required this.category});
  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    id: json['_id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Untitled',
    likes: (json['like_count'] as num?)?.toInt() ?? 0,
    category: json['category']?.toString() ?? 'General',
  );
}

class Credential {
  final String title;
  final String issuer;
  final String date;
  final bool isVerified;
  final String icon;
  Credential({required this.title, required this.issuer, required this.date, required this.isVerified, required this.icon});
  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
    title: json['title']?.toString() ?? 'Credential',
    issuer: json['issuer']?.toString() ?? 'Issuer',
    date: json['date']?.toString() ?? '',
    isVerified: json['is_verified'] == true,
    icon: json['icon']?.toString() ?? '🎓',
  );
}

class ProviderReview {
  final String id;
  final String reviewerName;
  final String content;
  final double rating;
  final DateTime date;
  final int helpful;
  ProviderReview({required this.id, required this.reviewerName, required this.content, required this.rating, required this.date, required this.helpful});
  factory ProviderReview.fromJson(Map<String, dynamic> json) => ProviderReview(
    id: json['_id']?.toString() ?? '',
    reviewerName: json['reviewer_name']?.toString() ?? 'Anonymous',
    content: json['content']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    helpful: (json['helpful_count'] as num?)?.toInt() ?? 0,
  );
}