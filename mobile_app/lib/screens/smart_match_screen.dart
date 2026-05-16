import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../widgets/animated_builder.dart';
import '../services/planner_api_service.dart';
import '../services/matching_api_service.dart';
import '../services/profile_api_service.dart';
import '../services/session_store.dart';
import '../services/api_config.dart';
import 'itinerary_calendar_screen.dart';
import 'user_profile_view_screen.dart';

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

  // Matching state
  final MatchingApiService _matchingService = MatchingApiService();
  final ProfileApiService _profileService = ProfileApiService();
  bool _isMatching = false;
  bool _showResults = false;
  List<Map<String, dynamic>> _matches = [];
  final Set<String> _accepted = {};
  final Set<String> _rejected = {};
  String? _matchError;

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
    _matchingService.dispose();
    _profileService.dispose();
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
                  if (_showResults)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _showResults = false;
                          _matches = [];
                          _accepted.clear();
                          _rejected.clear();
                          _matchError = null;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppDesign.darkGrey
                              : AppDesign.lightGrey,
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 20,
                          color: text,
                        ),
                      ),
                    )
                  else
                    const SmartExplorersLogo(
                      size: LogoSize.tiny,
                      showText: false,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _showResults ? 'Match Results' : 'Concierge',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: text),
                  ),
                  if (_showResults) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesign.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_matches.length} found',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!_showResults) ...[
              // View My Itinerary Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                      try {
                        final itinerary =
                            await PlannerApiService.instance.getMyItinerary();
                        if (!mounted) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ItineraryCalendarScreen(itinerary: itinerary),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not load itinerary: $e'),
                          ),
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
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 96,
              ),
            ] else ...[
              // ── Match Results List ──
              Expanded(child: _buildMatchResults(isDark, text)),
            ],
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
                      onPressed: _isMatching ? null : _startMatching,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black54,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: _isMatching
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Finding Matches...',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
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

  // ── Start Matching Logic ──
  Future<void> _startMatching() async {
    setState(() {
      _isMatching = true;
      _matchError = null;
      _matches = [];
    });
    HapticFeedback.mediumImpact();

    try {
      // 1. Get current user email from profile
      final username = SessionStore.instance.username ?? '';
      final profileRes = await _profileService.getUserByUsername(username);
      final userEmail = profileRes?['email'] as String? ?? '';
      if (userEmail.isEmpty) {
        throw Exception('Could not resolve user email');
      }

      // 2. Find matches (backend auto-trains if needed)
      final result = await _matchingService.findMatches(userEmail: userEmail);
      final rawMatches = (result['matches'] as List?) ?? [];

      setState(() {
        _matches = rawMatches.cast<Map<String, dynamic>>();
        _showResults = true;
        _isMatching = false;
      });
    } catch (e) {
      setState(() {
        _isMatching = false;
        _matchError = e.toString().replaceFirst('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Matching failed: $_matchError'),
            backgroundColor: AppDesign.danger,
          ),
        );
      }
    }
  }

  // ── Match Results View ──
  Widget _buildMatchResults(bool isDark, Color text) {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: text.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No matches found',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text)),
            const SizedBox(height: 8),
            Text('Try adjusting your preferences',
                style:
                    TextStyle(fontSize: 14, color: text.withOpacity(0.5))),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _showResults = false),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildMatchCard(match, isDark, text);
      },
    );
  }

  Widget _buildMatchCard(
      Map<String, dynamic> match, bool isDark, Color text) {
    final userId = match['user_id']?.toString() ?? '';
    final name = match['full_name']?.toString() ?? 'Unknown';
    final accountType = match['account_type']?.toString() ?? 'traveler';
    final email = match['email']?.toString() ?? '';
    final bio = match['bio']?.toString() ?? '';
    final matchScore = ((match['match_score'] ?? 0) as num).toDouble();
    final scorePercent = (matchScore * 100).round();
    final budgetCompat =
        ((match['budget_compatibility'] ?? 0) as num).toDouble();
    final safetyScore = ((match['safety_score'] ?? 0) as num).toDouble();
    final commonInterests =
        (match['common_interests'] as List?)?.cast<String>() ?? [];
    final commonLanguages =
        (match['common_languages'] as List?)?.cast<String>() ?? [];
    final matchReasons =
        (match['match_reasons'] as List?)?.cast<String>() ?? [];
    final profilePic = match['profile_picture_url']?.toString();

    final isAccepted = _accepted.contains(userId);
    final isRejected = _rejected.contains(userId);

    // Score color
    Color scoreColor;
    if (scorePercent >= 80) {
      scoreColor = AppDesign.success;
    } else if (scorePercent >= 60) {
      scoreColor = AppDesign.warning;
    } else {
      scoreColor = AppDesign.danger;
    }

    return AnimatedOpacity(
      opacity: isRejected ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppDesign.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isAccepted
              ? Border.all(color: AppDesign.success, width: 2)
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row: Avatar + Name + Score ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scoreColor.withOpacity(0.4),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profilePic != null && profilePic.isNotEmpty
                          ? Image.network(
                              profilePic.startsWith('http')
                                  ? profilePic
                                  : '${ApiConfig.baseUrl}/$profilePic',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: scoreColor.withOpacity(0.15),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: scoreColor.withOpacity(0.15),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accountType == 'service_provider'
                                    ? AppDesign.navConcierge.withOpacity(0.15)
                                    : AppDesign.electricCobalt
                                        .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                accountType == 'service_provider'
                                    ? 'Service Provider'
                                    : 'Traveler',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accountType == 'service_provider'
                                      ? AppDesign.navConcierge
                                      : AppDesign.electricCobalt,
                                ),
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: text.withOpacity(0.4),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Match Score Badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scoreColor.withOpacity(0.2),
                          scoreColor.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                          color: scoreColor.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$scorePercent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: scoreColor.withOpacity(0.7),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bio ──
            if (bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  bio,
                  style: TextStyle(
                    fontSize: 13,
                    color: text.withOpacity(0.6),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Stats Row: Budget & Safety ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildStatChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Budget',
                    value: '${(budgetCompat * 100).round()}%',
                    color: AppDesign.success,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatChip(
                    icon: Icons.shield_rounded,
                    label: 'Safety',
                    value: '${(safetyScore * 100).round()}%',
                    color: AppDesign.electricCobalt,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // ── Common Interests ──
            if (commonInterests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Interests',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: text.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: commonInterests.take(5).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppDesign.navConcierge.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppDesign.offWhite
                                  : AppDesign.eerieBlack,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // ── Common Languages ──
            if (commonLanguages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded,
                        size: 14, color: text.withOpacity(0.4)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        commonLanguages.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: text.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Match Reasons ──
            if (matchReasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: matchReasons.take(2).map((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: AppDesign.success),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 12,
                                color: text.withOpacity(0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 14),
            // ── Action Buttons ──
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  // Reject
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.close_rounded,
                      label: 'Reject',
                      color: AppDesign.danger,
                      isActive: isRejected,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _accepted.remove(userId);
                          if (isRejected) {
                            _rejected.remove(userId);
                          } else {
                            _rejected.add(userId);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.check_rounded,
                      label: 'Accept',
                      color: AppDesign.success,
                      isActive: isAccepted,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _rejected.remove(userId);
                          if (isAccepted) {
                            _accepted.remove(userId);
                          } else {
                            _accepted.add(userId);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View Profile
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      color: AppDesign.navConcierge,
                      isActive: false,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileViewScreen(
                              userId: userId,
                              displayName: name,
                              accountType: accountType,
                            ),
                          ),
                        );
                      },
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.15)
                : (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: color.withOpacity(0.3))
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? color
                    : (isDark ? Colors.white60 : Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? color
                      : (isDark ? Colors.white60 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
