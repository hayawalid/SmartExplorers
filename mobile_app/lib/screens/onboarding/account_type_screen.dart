import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'traveler_profile_setup_screen.dart';
import 'provider_profile_setup_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({Key? key}) : super(key: key);

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
            colors: [Color(0xFF0F4C75), Color(0xFF1a1a2e), Color(0xFFD4AF37)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'Join as...',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Choose how you want to explore Egypt',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Bento Grid Cards
                    Expanded(
                      child: Column(
                        children: [
                          // Traveler Card (Large)
                          Expanded(
                            flex: 3,
                            child: _buildBentoCard(
                              context: context,
                              title: "I'm exploring Egypt",
                              subtitle: 'Find guides, book tours, stay safe',
                              icon: CupertinoIcons.airplane,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              illustration: '✈️',
                              onTap: () => _navigateToTravelerSetup(context),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Provider Card (Large)
                          Expanded(
                            flex: 3,
                            child: _buildBentoCard(
                              context: context,
                              title: 'I offer tourism services',
                              subtitle:
                                  'Get verified, reach travelers, grow business',
                              icon: CupertinoIcons.briefcase_fill,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                              illustration: '🎯',
                              onTap: () => _navigateToProviderSetup(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required String illustration,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Illustration (top right)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Text(
                      illustration,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),

                  // Content (bottom left)
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),

                        // Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: Icon(icon, color: Colors.white, size: 30),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SF Pro Display',
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'SF Pro Text',
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Arrow
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 20,
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
