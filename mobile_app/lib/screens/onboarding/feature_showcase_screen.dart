import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'account_type_screen.dart';

/// Interactive feature showcase with haphazard stacked deck design
/// Cards appear messily stacked with random rotations
class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  // Card deck state
  List<int> _cardOrder = [];
  int _viewedCount = 0;

  // Swipe animation
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _swipeRotation;

  // Entrance animation
  late AnimationController _entranceController;

  // Subtle breathing animation for top card
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  // Swipe tracking
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  // Random rotations for haphazard look (-8 to +8 degrees)
  late List<double> _cardRotations;
  // Random offsets for messier stacking
  late List<Offset> _cardOffsets;

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
    _initializeCardDeck();
    _initializeAnimations();
    _entranceController.forward();
  }

  void _initializeCardDeck() {
    final random = math.Random(42); // Fixed seed for consistent haphazard look
    _cardOrder = List.generate(_features.length, (i) => i);

    // Generate random rotations between -8 and +8 degrees
    _cardRotations = List.generate(
      _features.length,
      (_) => (random.nextDouble() - 0.5) * 16 * math.pi / 180,
    );

    // Generate random offsets for messier stacking
    _cardOffsets = List.generate(
      _features.length,
      (_) => Offset(
        (random.nextDouble() - 0.5) * 12,
        (random.nextDouble() - 0.5) * 8,
      ),
    );
  }

  void _initializeAnimations() {
    // Swipe animation controller
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _swipeRotation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSwipeComplete();
      }
    });

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Subtle breathing animation for top card
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _entranceController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  void _onSwipeComplete() {
    setState(() {
      // Move top card to bottom of deck
      final topCard = _cardOrder.removeAt(0);
      _cardOrder.add(topCard);
      _viewedCount++;
      _dragOffset = Offset.zero;
    });
    _swipeController.reset();
  }

  void _onPanStart(DragStartDetails details) {
    if (_swipeController.isAnimating) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);

    final velocity = details.velocity.pixelsPerSecond;
    final distance = _dragOffset.distance;
    final velocityMagnitude = velocity.distance;

    // Threshold for completing swipe
    const distanceThreshold = 100.0;
    const velocityThreshold = 800.0;

    if (distance > distanceThreshold || velocityMagnitude > velocityThreshold) {
      // Complete the swipe - animate card off screen and to bottom
      _triggerSwipeAnimation();
    } else {
      // Snap back
      _snapBack();
    }
  }

  void _triggerSwipeAnimation() {
    // Haptic feedback on card snap
    HapticFeedback.mediumImpact();

    // Determine swipe direction and animate off screen
    final direction = _dragOffset / _dragOffset.distance;
    final targetOffset = direction * 500;

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _swipeRotation = Tween<double>(
      begin: _dragOffset.dx * 0.001,
      end: _dragOffset.dx * 0.003,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _swipeController.forward();
  }

  void _snapBack() {
    // Light haptic for snap back
    HapticFeedback.lightImpact();

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack),
    );

    _swipeRotation = Tween<double>(
      begin: _dragOffset.dx * 0.001,
      end: 0,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack),
    );

    _swipeController.forward().then((_) {
      _swipeController.reset();
      setState(() => _dragOffset = Offset.zero);
    });
  }

  void _tapToSwipe() {
    // Allow tap to advance card
    _dragOffset = const Offset(150, -50);
    _triggerSwipeAnimation();
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

    // Get current top card's gradient for background
    final topFeatureIndex = _cardOrder.isNotEmpty ? _cardOrder.first : 0;
    final currentFeature = _features[topFeatureIndex];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated blurred gradient background
          _buildAnimatedBackground(currentFeature, isDark),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with title and progress
                _buildHeader(isDark, textColor, secondaryTextColor),

                // Stacked card deck
                Expanded(
                  child: _buildCardDeck(
                    isDark,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                  ),
                ),

                // Bottom actions
                _buildBottomActions(context, isDark, cardColor, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(FeatureData feature, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            feature.gradient.colors[0].withValues(alpha: isDark ? 0.4 : 0.3),
            feature.gradient.colors[1].withValues(alpha: isDark ? 0.3 : 0.2),
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                feature.accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color secondaryTextColor) {
    final topFeatureIndex = _cardOrder.isNotEmpty ? _cardOrder.first : 0;
    final currentFeature = _features[topFeatureIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Progress indicators
          Row(
            children: List.generate(_features.length, (index) {
              final viewed =
                  index < _viewedCount % _features.length ||
                  (_viewedCount >= _features.length);
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _features.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color:
                        index == 0 || viewed
                            ? currentFeature.accentColor
                            : (isDark ? Colors.white24 : Colors.black12),
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
          const SizedBox(height: 8),
          // Hint
          AnimatedOpacity(
            opacity: _viewedCount == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              'Swipe cards to explore features',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDeck(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children:
              List.generate(_cardOrder.length, (stackIndex) {
                    // stackIndex 0 = top card, higher = further back
                    final featureIndex = _cardOrder[stackIndex];
                    final feature = _features[featureIndex];
                    final isTopCard = stackIndex == 0;

                    // Calculate depth effects
                    final depthScale = 1.0 - (stackIndex * 0.05);
                    final depthOffset = stackIndex * 12.0;
                    final depthOpacity = 1.0 - (stackIndex * 0.15);

                    // Apply entrance animation
                    final entranceProgress = _entranceController.value;
                    final staggeredEntrance = Curves.easeOutBack.transform(
                      (entranceProgress - (stackIndex * 0.1)).clamp(0.0, 1.0),
                    );

                    // Get haphazard rotation and offset for this card
                    final baseRotation = _cardRotations[featureIndex];
                    final baseOffset = _cardOffsets[featureIndex];

                    // For top card: apply drag offset and rotation
                    Offset cardOffset = Offset(
                      baseOffset.dx + depthOffset * 0.3,
                      depthOffset + baseOffset.dy,
                    );
                    double cardRotation = baseRotation;
                    double cardScale = depthScale;

                    if (isTopCard) {
                      if (_swipeController.isAnimating) {
                        cardOffset = cardOffset + _swipeAnimation.value;
                        cardRotation = baseRotation + _swipeRotation.value;
                      } else if (_isDragging) {
                        cardOffset = cardOffset + _dragOffset;
                        cardRotation = baseRotation + (_dragOffset.dx * 0.001);
                      }
                    }

                    // Apply entrance animation
                    cardOffset = Offset(
                      cardOffset.dx,
                      cardOffset.dy + (100 * (1 - staggeredEntrance)),
                    );
                    cardScale *= staggeredEntrance;

                    return Positioned(
                      child: AnimatedBuilder(
                        animation:
                            isTopCard
                                ? _breatheController
                                : const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          final breatheScale =
                              isTopCard &&
                                      !_isDragging &&
                                      !_swipeController.isAnimating
                                  ? _breatheAnimation.value
                                  : 1.0;

                          final scale = cardScale * breatheScale;
                          return Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.identity()
                                  ..setEntry(0, 3, cardOffset.dx)
                                  ..setEntry(1, 3, cardOffset.dy)
                                  ..rotateZ(cardRotation)
                                  ..setEntry(0, 0, scale)
                                  ..setEntry(1, 1, scale)
                                  ..setEntry(2, 2, scale),
                            child: Opacity(
                              opacity: depthOpacity.clamp(0.0, 1.0),
                              child:
                                  isTopCard
                                      ? GestureDetector(
                                        onPanStart: _onPanStart,
                                        onPanUpdate: _onPanUpdate,
                                        onPanEnd: _onPanEnd,
                                        onTap: _tapToSwipe,
                                        child: _buildFeatureCard(
                                          feature,
                                          featureIndex,
                                          isDark,
                                          cardColor,
                                          textColor,
                                          secondaryTextColor,
                                          isTopCard: true,
                                        ),
                                      )
                                      : _buildFeatureCard(
                                        feature,
                                        featureIndex,
                                        isDark,
                                        cardColor,
                                        textColor,
                                        secondaryTextColor,
                                        isTopCard: false,
                                      ),
                            ),
                          );
                        },
                      ),
                    );
                  }).reversed
                  .toList(), // Reversed so top card is rendered last (on top)
        );
      },
    );
  }

  Widget _buildFeatureCard(
    FeatureData feature,
    int index,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor, {
    required bool isTopCard,
  }) {
    // Fixed card size for consistent stacking
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 64;
    final cardHeight = cardWidth * 1.3;

    return Semantics(
      label: '${feature.title}. ${feature.subtitle}. ${feature.description}',
      hint: isTopCard ? 'Swipe to see next feature' : null,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: feature.accentColor.withOpacity(isTopCard ? 0.3 : 0.15),
              blurRadius: isTopCard ? 30 : 20,
              offset: const Offset(0, 12),
              spreadRadius: isTopCard ? 2 : 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Gradient header with icon
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: feature.gradient),
                  child: Stack(
                    children: [
                      // Dot pattern background
                      Positioned.fill(
                        child: CustomPaint(painter: DotPatternPainter()),
                      ),
                      // Icon centered
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
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
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.photo,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    feature.imagePlaceholder,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Text',
                                      fontSize: 11,
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
                      // Decorative circles
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 16,
                        child: Container(
                          width: 48,
                          height: 48,
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
              // Content section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: feature.accentColor.withOpacity(0.12),
                        ),
                        child: Text(
                          feature.subtitle,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: feature.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Expanded(
                        child: Text(
                          feature.description,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 13,
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final topFeatureIndex = _cardOrder.isNotEmpty ? _cardOrder.first : 0;
    final currentFeature = _features[topFeatureIndex];
    final hasSeenAll = _viewedCount >= _features.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Cards remaining indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.rectangle_stack,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                hasSeenAll
                    ? 'All features explored!'
                    : '${_features.length - (_viewedCount % _features.length)} cards remaining',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
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
              // Get Started button (always visible, encouraged after seeing all)
              Semantics(
                button: true,
                label: 'Get started with SmartExplorers',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: currentFeature.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: currentFeature.accentColor.withOpacity(
                          hasSeenAll ? 0.5 : 0.3,
                        ),
                        blurRadius: hasSeenAll ? 20 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    onPressed: () => _navigateToAccountType(context),
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
    HapticFeedback.mediumImpact();
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
