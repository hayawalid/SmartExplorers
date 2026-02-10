import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'account_type_screen.dart';

/// Interactive feature showcase with modern iOS design
/// Supports image placeholders for each feature
class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<FeatureData> _features = [
    FeatureData(
      title: 'AI Travel Assistant',
      subtitle: 'Your Personal Egypt Guide',
      description:
          'Get instant, intelligent help from the moment you land to your departure. Ask anything about Egypt in natural language.',
      icon: CupertinoIcons.sparkles,
      gradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF667eea),
      // Placeholder for actual image asset
      imagePlaceholder: 'ai_assistant',
    ),
    FeatureData(
      title: 'Safety First',
      subtitle: '24/7 Protection',
      description:
          'Real-time GPS tracking, one-tap panic button, and instant emergency alerts keep you safe throughout your journey.',
      icon: CupertinoIcons.shield_lefthalf_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF11998e),
      imagePlaceholder: 'safety_features',
    ),
    FeatureData(
      title: 'Verified Providers',
      subtitle: 'Trust & Transparency',
      description:
          'Every guide is verified with government ID, face recognition, and background checks. Your safety is guaranteed.',
      icon: CupertinoIcons.checkmark_seal_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFF0F4C75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFFD4AF37),
      imagePlaceholder: 'verified_providers',
    ),
    FeatureData(
      title: 'Smart Itineraries',
      subtitle: 'AI-Powered Planning',
      description:
          'Create personalized travel plans based on your interests, pace, and accessibility needs. Your perfect Egypt awaits.',
      icon: CupertinoIcons.map_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFFf5576c),
      imagePlaceholder: 'smart_itineraries',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
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
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header with progress
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    // Progress indicators
                    Row(
                      children: List.generate(_features.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < _features.length - 1 ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color:
                                  index <= _currentPage
                                      ? _features[_currentPage].accentColor
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.black12),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Discover SmartExplorers',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Feature cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return _buildFeatureCard(
                      _features[index],
                      index,
                      isDark,
                      cardColor,
                      textColor,
                      secondaryTextColor,
                    );
                  },
                ),
              ),

              // Bottom actions
              _buildBottomActions(context, isDark, cardColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    FeatureData feature,
    int index,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Image placeholder card
          Expanded(
            flex: 3,
            child: ScaleTransition(
              scale:
                  _currentPage == index
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: feature.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: feature.accentColor.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Grid pattern background
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CustomPaint(painter: DotPatternPainter()),
                      ),
                    ),
                    // Image placeholder content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              feature.icon,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Image placeholder label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.photo,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Image: ${feature.imagePlaceholder}',
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Text',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Decorative elements
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Text content
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Subtitle chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: feature.accentColor.withOpacity(0.15),
                  ),
                  child: Text(
                    feature.subtitle,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: feature.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    feature.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 16,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final isLastPage = _currentPage == _features.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Page indicators with swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLastPage)
                Text(
                  'Swipe to explore',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              if (!isLastPage) const SizedBox(width: 8),
              Row(
                children: List.generate(_features.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          _currentPage == index
                              ? _features[_currentPage].accentColor
                              : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              // Skip button
              Semantics(
                button: true,
                label: 'Skip onboarding',
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  onPressed: () => _navigateToAccountType(context),
                ),
              ),
              const Spacer(),
              // Continue/Get Started button
              Semantics(
                button: true,
                label:
                    isLastPage
                        ? 'Get started with SmartExplorers'
                        : 'Continue to next feature',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _features[_currentPage].gradient,
                    boxShadow: [
                      BoxShadow(
                        color: _features[_currentPage].accentColor.withOpacity(
                          0.4,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? CupertinoIcons.arrow_right_circle_fill
                              : CupertinoIcons.chevron_right,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    onPressed: () {
                      if (isLastPage) {
                        _navigateToAccountType(context);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToAccountType(BuildContext context) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => const AccountTypeScreen()),
    );
  }
}

/// Feature data model
class FeatureData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String imagePlaceholder;

  FeatureData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.imagePlaceholder,
  });
}

/// Dot pattern painter for subtle background texture
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const dotRadius = 2.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
