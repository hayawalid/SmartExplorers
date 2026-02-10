import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'traveler_profile_setup_screen.dart';
import 'provider_profile_setup_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({Key? key}) : super(key: key);

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  AnimationController? _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _card1Slide;
  late Animation<Offset> _card2Slide;

  int? _hoveredCard;
  int? _pressedCard;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _card1Slide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _card2Slide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background particles
          ...List.generate(8, (i) => _buildFloatingOrb(i, isDark)),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Animated Title Section
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ShaderMask(
                            shaderCallback:
                                (bounds) => LinearGradient(
                                  colors:
                                      isDark
                                          ? [
                                            const Color(0xFF667EEA),
                                            const Color(0xFFD4AF37),
                                          ]
                                          : [
                                            const Color(0xFF4F46E5),
                                            const Color(0xFFD97706),
                                          ],
                                ).createShader(bounds),
                            child: Text(
                              'SmartExplorers',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'How would you like to experience Egypt?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Cards
                  Expanded(
                    child: Column(
                      children: [
                        // Traveler Card
                        Expanded(
                          child: SlideTransition(
                            position: _card1Slide,
                            child: _buildInteractiveCard(
                              index: 0,
                              isDark: isDark,
                              title: 'Explorer',
                              subtitle:
                                  'Discover Egypt with verified guides, curated experiences, and real-time safety features',
                              emoji: '🌍',
                              gradientColors:
                                  isDark
                                      ? [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ]
                                      : [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF8B5CF6),
                                      ],
                              features: [
                                'Verified Guides',
                                'Safety Alerts',
                                'Custom Itineraries',
                              ],
                              onTap: () => _navigateToTravelerSetup(context),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Provider Card
                        Expanded(
                          child: SlideTransition(
                            position: _card2Slide,
                            child: _buildInteractiveCard(
                              index: 1,
                              isDark: isDark,
                              title: 'Service Provider',
                              subtitle:
                                  'Join our network of trusted tourism professionals and grow your business',
                              emoji: '⭐',
                              gradientColors:
                                  isDark
                                      ? [
                                        const Color(0xFFF093FB),
                                        const Color(0xFFF5576C),
                                      ]
                                      : [
                                        const Color(0xFFEC4899),
                                        const Color(0xFFF43F5E),
                                      ],
                              features: [
                                'Get Verified',
                                'Reach Tourists',
                                'Earn More',
                              ],
                              onTap: () => _navigateToProviderSetup(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom hint
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Text(
                        'You can always change this later',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingOrb(int index, bool isDark) {
    final colors = [
      const Color(0xFF667EEA),
      const Color(0xFFF093FB),
      const Color(0xFFD4AF37),
      const Color(0xFF764BA2),
      const Color(0xFFF5576C),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final controller = _floatController;
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final offset =
            math.sin((controller.value + index * 0.15) * math.pi * 2) * 30;
        final size = 100.0 + (index % 3) * 50;
        final left = (index * 45.0) % MediaQuery.of(context).size.width;
        final top = (index * 80.0) % (MediaQuery.of(context).size.height * 0.6);

        return Positioned(
          left: left,
          top: top + offset,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors[index].withOpacity(isDark ? 0.15 : 0.08),
                  colors[index].withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveCard({
    required int index,
    required bool isDark,
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> gradientColors,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredCard == index;
    final isPressed = _pressedCard == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedCard = index),
      onTapUp: (_) {
        setState(() => _pressedCard = null);
        onTap();
      },
      onTapCancel: () => setState(() => _pressedCard = null),
      onLongPressStart: (_) => setState(() => _hoveredCard = index),
      onLongPressEnd: (_) => setState(() => _hoveredCard = null),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredCard = index),
        onExit: (_) => setState(() => _hoveredCard = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.identity()
                ..scale(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(isHovered ? 0.4 : 0.2),
                  blurRadius: isHovered ? 30 : 20,
                  offset: Offset(0, isHovered ? 15 : 10),
                  spreadRadius: isHovered ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(isHovered ? 0.4 : 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background emoji pattern
                      Positioned(
                        right: -20,
                        top: -20,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isHovered ? 1.0 : 0.6,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: isHovered ? 1.1 : 1.0,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 120),
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      isHovered ? 0.35 : 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: AnimatedRotation(
                                    duration: const Duration(milliseconds: 300),
                                    turns: isHovered ? 0.05 : 0,
                                    child: const Icon(
                                      CupertinoIcons.arrow_right,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Feature pills
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 200),
                              offset: Offset(0, isHovered ? 0 : 0.1),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isHovered ? 1.0 : 0.8,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      features
                                          .map(
                                            (feature) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                feature,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
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
      ),
    );
  }

  void _navigateToTravelerSetup(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const TravelerProfileSetupScreen()),
    );
  }

  void _navigateToProviderSetup(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ProviderProfileSetupScreen()),
    );
  }
}
