import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_builder.dart';

/// Tab 4: Smart Match & Active Trip (Concierge)
/// Header: "Current Accepted Itinerary"
/// Horizontal PageView of destination cards with "Match with Service Provider" button
class SmartMatchScreen extends StatefulWidget {
  const SmartMatchScreen({Key? key}) : super(key: key);

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  late final AnimationController _pulseController;
  int _currentPage = 0;

  final List<_TripCard> _trips = const [
    _TripCard(
      title: 'Pyramids of Giza',
      date: 'Mar 14 · Morning',
      location: 'Giza Plateau, Cairo',
      emoji: '🏛️',
      matchStatus: 'Tour Guide Available',
    ),
    _TripCard(
      title: 'Luxor Temple Visit',
      date: 'Mar 15 · Morning',
      location: 'Luxor, Upper Egypt',
      emoji: '⚱️',
      matchStatus: 'Matching…',
    ),
    _TripCard(
      title: 'Red Sea Snorkeling',
      date: 'Mar 16 · Full day',
      location: 'Hurghada',
      emoji: '🐠',
      matchStatus: 'No match yet',
    ),
    _TripCard(
      title: 'Khan el-Khalili',
      date: 'Mar 14 · Evening',
      location: 'Islamic Cairo',
      emoji: '🛍️',
      matchStatus: 'Photographer Available',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.briefcase,
                    color: AppDesign.electricCobalt,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Concierge',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Current Accepted Itinerary',
                style: TextStyle(fontSize: 14, color: sub),
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal PageView of cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _trips.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double factor = 1.0;
                      if (_pageController.position.haveDimensions) {
                        factor = (_pageController.page! - i).abs().clamp(
                          0.0,
                          1.0,
                        );
                      }
                      return Transform.scale(
                        scale: 1 - (factor * 0.08),
                        child: Opacity(
                          opacity: 1 - (factor * 0.3),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCard(_trips[i], isDark, text, sub),
                  );
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_trips.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          active
                              ? AppDesign.electricCobalt
                              : (isDark ? Colors.white24 : AppDesign.lightGrey),
                    ),
                  );
                }),
              ),
            ),

            // Matched providers section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Matched Providers',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: text,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _matchedProviderChip(
                    isDark,
                    text,
                    sub,
                    'Ahmed H.',
                    '👨‍🏫',
                    4.9,
                  ),
                  const SizedBox(width: 10),
                  _matchedProviderChip(
                    isDark,
                    text,
                    sub,
                    'Fatima A.',
                    '👩‍🎨',
                    4.8,
                  ),
                  const SizedBox(width: 10),
                  _matchedProviderChip(isDark, text, sub, 'Omar T.', '🚗', 4.9),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_TripCard trip, bool isDark, Color text, Color sub) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 16),
      decoration: BoxDecoration(
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.mediumShadow,
      ),
      child: ClipRRect(
        borderRadius: AppDesign.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
                          : [const Color(0xFFE8ECFF), const Color(0xFFF0F4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(trip.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
            // Gradient scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        trip.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trip.matchStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Match button with pulse animation
                  PulseAnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + _pulseController.value * 0.03;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(LucideIcons.sparkles, size: 18),
                        label: const Text('Match with Provider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.electricCobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
    );
  }

  Widget _matchedProviderChip(
    bool isDark,
    Color text,
    Color sub,
    String name,
    String emoji,
    double rating,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.cardDark : AppDesign.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFA726)),
              const SizedBox(width: 3),
              Text('$rating', style: TextStyle(fontSize: 11, color: sub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripCard {
  const _TripCard({
    required this.title,
    required this.date,
    required this.location,
    required this.emoji,
    required this.matchStatus,
  });
  final String title, date, location, emoji, matchStatus;
}
