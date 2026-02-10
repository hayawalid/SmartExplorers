import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'feature_showcase_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _floatingController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _floatingAnimation;
  // Controls delayed button appearance animation
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    // Gradient animation (8 seconds)
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
    // Floating elements animation (3 seconds)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware gradient colors
    final gradientStart1 =
        isDark ? const Color(0xFF6A82FB) : const Color(0xFF8E9EFC);
    final gradientEnd1 =
        isDark ? const Color(0xFF0F4C75) : const Color(0xFF3D6A8F);
    final gradientStart2 =
        isDark ? const Color(0xFFFC5C7D) : const Color(0xFFFF8FA3);
    final gradientEnd2 =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFFE5C76B);
    final gradientStart3 =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFFE5C76B);
    final gradientEnd3 =
        isDark ? const Color(0xFF6A82FB) : const Color(0xFF8E9EFC);

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        gradientStart1,
                        gradientEnd1,
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        gradientStart2,
                        gradientEnd2,
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        gradientStart3,
                        gradientEnd3,
                        _gradientAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),
          // Floating geometric shapes (background)
          ..._buildFloatingShapes(isDark),
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // 3D Glassmorphic logo
                  _buildGlassmorphicLogo(isDark),
                  const SizedBox(height: 40),
                  // Title
                  _buildTitle(isDark),
                  const SizedBox(height: 12),
                  // Subtitle
                  _buildSubtitle(isDark),
                  const Spacer(flex: 3),
                  // CTA Button
                  _buildGetStartedButton(context, isDark),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicLogo(bool isDark) {
    final logoGradient =
        isDark
            ? const [Color(0xFFFFFFFF), Color(0xB3FFFFFF)]
            : const [Color(0xFFFFFFFF), Color(0xE6FFFFFF)];
    final shadowOpacity = isDark ? 0.2 : 0.15;
    final glowOpacity = isDark ? 0.3 : 0.4;

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _floatingAnimation.value),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: logoGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(shadowOpacity),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(glowOpacity),
                  blurRadius: 20,
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.4 : 0.6),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.location_fill,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(bool isDark) {
    final titleColors =
        isDark
            ? const [Colors.white, Color(0xFFFFE082)]
            : const [Colors.white, Color(0xFFFFF3C4)];

    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(colors: titleColors).createShader(bounds),
      child: const Text(
        'SmartExplorers',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          fontFamily: 'SF Pro Display',
          letterSpacing: -1,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Safe Tourism for Everyone in Egypt',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'SF Pro Text',
          color: isDark ? const Color(0xE6FFFFFF) : Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context, bool isDark) {
    final buttonGradient =
        isDark
            ? const [Color(0xFFFFFFFF), Color(0xCCFFFFFF)]
            : const [Color(0xFFFFFFFF), Color(0xE6FFFFFF)];
    final buttonTextColor =
        isDark ? const Color(0xFF0F4C75) : const Color(0xFF3D6A8F);

    return AnimatedOpacity(
      opacity: _showButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(colors: buttonGradient),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _navigateToFeatures(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Text',
                        color: buttonTextColor,
                        letterSpacing: 0.5,
                      ),
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

  List<Widget> _buildFloatingShapes(bool isDark) {
    final shapeOpacity = isDark ? 0.15 : 0.2;
    final gradientOpacity1 = isDark ? 0.3 : 0.4;
    final gradientOpacity2 = isDark ? 0.1 : 0.15;

    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          final offset =
              20 *
              math.sin((_floatingAnimation.value + index * 0.2) * 2 * math.pi);
          return Positioned(
            left: 30.0 + index * 70,
            top: 100.0 + offset + index * 50,
            child: Opacity(
              opacity: shapeOpacity,
              child: Transform.rotate(
                angle: _floatingAnimation.value * 2 * math.pi,
                child: Container(
                  width: 60 + index * 10.0,
                  height: 60 + index * 10.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(gradientOpacity1),
                        Colors.white.withOpacity(gradientOpacity2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _navigateToFeatures(BuildContext context) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => const FeatureShowcaseScreen()),
    );
  }
}
