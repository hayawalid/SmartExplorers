import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'account_type_screen.dart';

class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  final List<FeatureData> _features = [
    FeatureData(
      title: 'AI Travel Assistant',
      description:
          'Your personal Egypt guide powered by AI. Get instant help from airport to departure.',
      icon: CupertinoIcons.chat_bubble_2_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      illustration: '🤖',
    ),
    FeatureData(
      title: 'Safety First',
      description:
          'Real-time GPS tracking, panic button, and emergency alerts keep you safe 24/7.',
      icon: CupertinoIcons.shield_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      ),
      illustration: '🛡️',
    ),
    FeatureData(
      title: 'Verified Providers',
      description:
          'All guides verified with ID, face match, and background checks. Your safety is guaranteed.',
      icon: CupertinoIcons.checkmark_seal_fill,
      gradient: const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
      illustration: '✅',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Title
              const Text(
                'Welcome to SmartExplorers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                ),
              ),

              const SizedBox(height: 50),

              // Feature cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return _buildFeatureCard(_features[index], index);
                  },
                ),
              ),

              // Page indicators
              _buildPageIndicators(),

              const SizedBox(height: 30),

              // Action buttons
              _buildActionButtons(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeatureData feature, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page ?? 0) - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }

        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 500,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: feature.gradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(painter: GridPatternPainter()),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Text(
                              feature.illustration,
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Icon
                        Icon(feature.icon, size: 50, color: Colors.white),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          feature.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Description
                        Text(
                          feature.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'SF Pro Text',
                            height: 1.5,
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
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _features.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: _currentPage == index ? 30 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          // Skip button
          Expanded(
            child: TextButton(
              onPressed: () => _navigateToAccountType(context),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Next/Get Started button
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE0E0E0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    if (_currentPage < _features.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _navigateToAccountType(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        _currentPage < _features.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F4C75),
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

class FeatureData {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final String illustration;

  FeatureData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.illustration,
  });
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
