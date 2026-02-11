import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'auth_choice_screen.dart';

/// Feature showcase – swipeable photo cards with glassmorphism text overlays.
/// Each card uses a real image from lib/public/.
class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  List<int> _cardOrder = [];
  int _viewedCount = 0;

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _swipeRotation;
  late AnimationController _entranceController;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late List<double> _cardRotations;
  late List<Offset> _cardOffsets;

  final List<_Feature> _features = [
    _Feature(
      title: 'AI Travel Assistant',
      subtitle: 'Your Personal Egypt Guide',
      description:
          'Get instant, intelligent help from the moment you land to your departure.',
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _Feature(
      title: 'Verified Guides',
      subtitle: 'Trust & Transparency',
      description:
          'Every guide is verified with government ID, face recognition, and background checks.',
      image: 'lib/public/verified_guides.jpg',
      gradient: const [Color(0xFFD4AF37), Color(0xFF0F4C75)],
    ),
    _Feature(
      title: 'Smart Itineraries',
      subtitle: 'AI-Powered Planning',
      description:
          'Create personalized travel plans based on your interests, pace, and accessibility needs.',
      image: 'lib/public/smart_itineraries.jpg',
      gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    _Feature(
      title: 'Safety First',
      subtitle: '24/7 Protection',
      description:
          'Real-time GPS tracking, one-tap panic button, and instant emergency alerts.',
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
      gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initDeck();
    _initAnimations();
    _entranceController.forward();
  }

  void _initDeck() {
    final rng = math.Random(42);
    _cardOrder = List.generate(_features.length, (i) => i);
    _cardRotations = List.generate(
      _features.length,
      (_) => (rng.nextDouble() - 0.5) * 14 * math.pi / 180,
    );
    _cardOffsets = List.generate(
      _features.length,
      (_) =>
          Offset((rng.nextDouble() - 0.5) * 10, (rng.nextDouble() - 0.5) * 6),
    );
  }

  void _initAnimations() {
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
    _swipeController.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onSwipeComplete();
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.015).animate(
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
      _cardOrder.add(_cardOrder.removeAt(0));
      _viewedCount++;
      _dragOffset = Offset.zero;
    });
    _swipeController.reset();
  }

  void _onPanStart(DragStartDetails d) {
    if (_swipeController.isAnimating) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isDragging) return;
    setState(() => _dragOffset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    if (_dragOffset.distance > 100 ||
        d.velocity.pixelsPerSecond.distance > 800) {
      _triggerSwipe();
    } else {
      _snapBack();
    }
  }

  void _triggerSwipe() {
    HapticFeedback.mediumImpact();
    final dir = _dragOffset / _dragOffset.distance;
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: dir * 500).animate(
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

  void _tapSwipe() {
    _dragOffset = const Offset(150, -50);
    _triggerSwipe();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topIdx = _cardOrder.isNotEmpty ? _cardOrder.first : 0;
    final topFeature = _features[topIdx];
    final hasSeenAll = _viewedCount >= _features.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background from top card image
            Image.asset(topFeature.image, fit: BoxFit.cover),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(child: _buildDeck()),
                  _buildBottom(context, topFeature, hasSeenAll),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Progress dots
          Row(
            children: List.generate(_features.length, (i) {
              final viewed =
                  i < _viewedCount % _features.length ||
                  _viewedCount >= _features.length;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(
                    right: i < _features.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color:
                        (i == 0 || viewed)
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text(
            'Discover SmartExplorers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _viewedCount == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              'Swipe cards to explore features',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeck() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children:
              List.generate(_cardOrder.length, (si) {
                final fi = _cardOrder[si];
                final feature = _features[fi];
                final isTop = si == 0;
                final depthScale = 1.0 - si * 0.05;
                final depthY = si * 12.0;
                final depthOp = (1.0 - si * 0.15).clamp(0.0, 1.0);
                final entrance = Curves.easeOutBack.transform(
                  (_entranceController.value - si * 0.1).clamp(0.0, 1.0),
                );
                final rot = _cardRotations[fi];
                final off = _cardOffsets[fi];

                Offset coff = Offset(off.dx + depthY * 0.3, depthY + off.dy);
                double crot = rot;
                double cscale = depthScale;

                if (isTop) {
                  if (_swipeController.isAnimating) {
                    coff = coff + _swipeAnimation.value;
                    crot = rot + _swipeRotation.value;
                  } else if (_isDragging) {
                    coff = coff + _dragOffset;
                    crot = rot + _dragOffset.dx * 0.001;
                  }
                }
                coff = Offset(coff.dx, coff.dy + 100 * (1 - entrance));
                cscale *= entrance;

                return Positioned(
                  child: AnimatedBuilder(
                    animation:
                        isTop
                            ? _breatheController
                            : const AlwaysStoppedAnimation(1.0),
                    builder: (context, _) {
                      final bs =
                          isTop && !_isDragging && !_swipeController.isAnimating
                              ? _breatheAnimation.value
                              : 1.0;
                      final s = cscale * bs;
                      return Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(0, 3, coff.dx)
                              ..setEntry(1, 3, coff.dy)
                              ..rotateZ(crot)
                              ..scale(s),
                        child: Opacity(
                          opacity: depthOp,
                          child:
                              isTop
                                  ? GestureDetector(
                                    onPanStart: _onPanStart,
                                    onPanUpdate: _onPanUpdate,
                                    onPanEnd: _onPanEnd,
                                    onTap: _tapSwipe,
                                    child: _card(feature),
                                  )
                                  : _card(feature),
                        ),
                      );
                    },
                  ),
                );
              }).reversed.toList(),
        );
      },
    );
  }

  Widget _card(_Feature f) {
    final w = MediaQuery.of(context).size.width - 64;
    final h = w * 1.3;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed photo
            Image.asset(f.image, fit: BoxFit.cover),

            // Bottom gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),

            // Glass text overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
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
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            f.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          f.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(
    BuildContext context,
    _Feature topFeature,
    bool hasSeenAll,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Text(
            hasSeenAll
                ? 'All features explored!'
                : '${_features.length - (_viewedCount % _features.length)} cards remaining',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                onPressed: () => _goNext(context),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: topFeature.gradient),
                  boxShadow: [
                    BoxShadow(
                      color: topFeature.gradient.first.withValues(
                        alpha: hasSeenAll ? 0.5 : 0.3,
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
                    children: const [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.arrow_right_circle_fill,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  onPressed: () => _goNext(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goNext(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => const AuthChoiceScreen()),
    );
  }
}

class _Feature {
  final String title, subtitle, description, image;
  final List<Color> gradient;
  _Feature({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.gradient,
  });
}
