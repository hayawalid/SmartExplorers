import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../widgets/animated_builder.dart';
import '../services/planner_api_service.dart';
import 'itinerary_calendar_screen.dart';

/// Tab 4: Smart Match & Concierge
/// Updated: View Itinerary button + Orbital circles interface
class SmartMatchScreen extends StatefulWidget {
  const SmartMatchScreen({Key? key}) : super(key: key);

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;

  // Profile emojis for the circles
  final List<String> _profileEmojis = [
    '👨‍🦱',
    '👩‍🦰',
    '👨‍🦳',
    '👩‍🦱',
    '👨‍🦲',
    '👩‍🦳',
    '👨',
    '👩',
    '🧑‍🦱',
    '👱‍♀️',
    '👨‍🦰',

    '🧔',
    '👱‍♂️',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
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
                  const SmartExplorersLogo(
                    size: LogoSize.tiny,
                    showText: false,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Concierge',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // View My Itinerary Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                    );
                    try {
                      final itinerary =
                          await PlannerApiService.instance.getMyItinerary();
                      if (!mounted) return;
                      Navigator.pop(context); // dismiss loader
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ItineraryCalendarScreen(itinerary: itinerary),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(context); // dismiss loader
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not load itinerary: $e')),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.calendar, size: 20),
                  label: const Text('View My Itinerary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Matching Circles Section
            Expanded(child: _buildMatchingSection(isDark, text)),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingSection(bool isDark, Color text) {
    return Container(
      color: isDark ? AppDesign.eerieBlack : Colors.white,
      child: Stack(
        children: [
          // Clean orbit visualization - centered and not overlapping with text
          Positioned.fill(
            top: 60,
            bottom: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centerX = constraints.maxWidth / 2;
                final centerY = constraints.maxHeight / 2;

                return AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Outer orbit ring
                        _buildCleanOrbitRing(260, centerX, centerY),
                        // Middle orbit ring
                        _buildCleanOrbitRing(180, centerX, centerY),
                        // Inner orbit ring
                        _buildCleanOrbitRing(100, centerX, centerY),

                        // People on orbits - clean and minimal
                        ..._buildCleanPeopleCircles(centerX, centerY),

                        // Center circle
                        _buildCenterCircle(centerX, centerY),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Text and button at bottom - no overlap
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Column(
              children: [
                Text(
                  "Let's match you with\npeople around you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: text,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 28),
                PulseAnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + _pulseController.value * 0.02;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // Handle start matching
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: const Text(
                        'Start Matching',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
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
    );
  }

  Widget _buildCleanOrbitRing(double diameter, double centerX, double centerY) {
    return Positioned(
      left: centerX - diameter / 2,
      top: centerY - diameter / 2,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE9D5FF).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircle(double centerX, double centerY) {
    return Positioned(
      left: centerX - 28,
      top: centerY - 28,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF9333EA),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            '../backend/static/avatars/haneen.jpg',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCleanPeopleCircles(double centerX, double centerY) {
    // People scattered 360 degrees around orbits with varied sizes
    final people = [
      // Outer ring - 6 people scattered around
      {
        'angle': 20,
        'radius': 130.0,
        'size': 48.0,
        'color': Color(0xFF3B82F6),
        'asset': '../backend/static/avatars/ahmed.jpg',
      },
      {
        'angle': 85,
        'radius': 130.0,
        'size': 38.0,
        'color': Color(0xFFEC4899),
        'emoji': '👩‍🦰',
      },
      {
        'angle': 140,
        'radius': 130.0,
        'size': 52.0,
        'color': Color(0xFF10B981),
        'asset': '../backend/static/avatars/maria.jpg',
      },
      {
        'angle': 200,
        'radius': 130.0,
        'size': 42.0,
        'color': Color(0xFFF59E0B),
        'emoji': '🧔',
      },
      {
        'angle': 260,
        'radius': 130.0,
        'size': 46.0,
        'color': Color(0xFF8B5CF6),
        'asset': '../backend/static/avatars/yuki.jpg',
      },
      {
        'angle': 320,
        'radius': 130.0,
        'size': 40.0,
        'color': Color(0xFFEF4444),
        'emoji': '👨‍🦱',
      },

      // Middle ring - 4 people scattered around
      {
        'angle': 50,
        'radius': 90.0,
        'size': 44.0,
        'color': Color(0xFF06B6D4),
        'asset': '../backend/static/avatars/sarah.jpg',
      },
      {
        'angle': 130,
        'radius': 90.0,
        'size': 36.0,
        'color': Color(0xFF84CC16),
        'emoji': '👱‍♂️',
      },
      {
        'angle': 230,
        'radius': 90.0,
        'size': 50.0,
        'color': Color(0xFFFBBF24),
        'asset': '../backend/static/avatars/david.jpg',
      },
      // {
      //   'angle': 310,
      //   'radius': 90.0,
      //   'size': 40.0,
      //   'color': Color(0xFF14B8A6),
      //   'emoji': '👩‍🦳',
      // },

      // // Inner ring - 3 people scattered around
      // {
      //   'angle': 80,
      //   'radius': 50.0,
      //   'size': 34.0,
      //   'color': Color(0xFFEC4899),
      //   'emoji': '👩‍🦲',
      // },
      {
        'angle': 200,
        'radius': 50.0,
        'size': 38.0,
        'color': Color(0xFF8B5CF6),
        'asset': '../backend/static/avatars/fatima.jpg',
      },
      {
        'angle': 320,
        'radius': 50.0,
        'size': 32.0,
        'color': Color(0xFF3B82F6),
        'emoji': '👩',
      },
    ];

    final widgets = <Widget>[];

    // Add people circles
    for (var entry in people.asMap().entries) {
      final index = entry.key;
      final person = entry.value;
      final angle = person['angle'] as int;
      final radius = person['radius'] as double;
      final size = person['size'] as double;
      final color = person['color'] as Color;
      final asset = person['asset'] as String?;
      final emoji = person['emoji'] as String?;

      final radians = angle * math.pi / 180;
      final x = centerX + radius * math.cos(radians) - size / 2;
      final y = centerY + radius * math.sin(radians) - size / 2;

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + index * 60),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final floatY =
                  math.sin(_orbitController.value * 2 * math.pi + index * 0.4) *
                  2.5;
              final scale =
                  1.0 +
                  math.sin(_orbitController.value * 2 * math.pi + index * 0.6) *
                      0.03;

              return Transform.translate(
                offset: Offset(0, floatY),
                child: Transform.scale(
                  scale: value * scale,
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                ),
              );
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    asset != null
                        ? Image.asset(
                          asset,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        )
                        : Center(
                          child: Text(
                            emoji ?? '👤',
                            style: TextStyle(fontSize: size * 0.5),
                          ),
                        ),
              ),
            ),
          ),
        ),
      );
    }

    // Add location pin icon - top left area
    widgets.add(
      Positioned(
        left: centerX - 180,
        top: centerY - 150,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final floatY =
                math.sin(_orbitController.value * 2 * math.pi + 1.5) * 3;
            return Transform.translate(
              offset: Offset(0, floatY),
              child: Opacity(opacity: value * 0.8, child: child),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFEC4899),
              size: 24,
            ),
          ),
        ),
      ),
    );

    // Add chat icon - bottom right area
    widgets.add(
      Positioned(
        left: centerX + 140,
        top: centerY + 120,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final floatY =
                math.sin(_orbitController.value * 2 * math.pi + 2.8) * 3;
            return Transform.translate(
              offset: Offset(0, floatY),
              child: Opacity(opacity: value * 0.8, child: child),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
        ),
      ),
    );

    return widgets;
  }
}
