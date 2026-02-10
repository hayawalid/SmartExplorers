import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'traveler_profile_setup_screen.dart';

/// Interactive and fun setup screen with proper theme support
/// Features: Travel interest selection with images, animations, WCAG accessibility
class InteractiveSetupScreen extends StatefulWidget {
  const InteractiveSetupScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveSetupScreen> createState() => _InteractiveSetupScreenState();
}

class _InteractiveSetupScreenState extends State<InteractiveSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Set<String> _selected = {};

  // Travel interests with image placeholders and accessibility descriptions
  final List<InterestOption> _interests = [
    InterestOption(
      id: 'history',
      label: 'History & Archaeology',
      description: 'Ancient temples, pyramids, museums',
      icon: CupertinoIcons.building_2_fill,
      imagePlaceholder: 'history_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFF0F4C75)],
      ),
      semanticHint:
          'Select if you\'re interested in historical sites and museums',
    ),
    InterestOption(
      id: 'adventure',
      label: 'Adventure',
      description: 'Desert safaris, diving, hiking',
      icon: CupertinoIcons.flame_fill,
      imagePlaceholder: 'adventure_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFFf5576c), Color(0xFFf093fb)],
      ),
      semanticHint: 'Select for outdoor activities and adventure sports',
    ),
    InterestOption(
      id: 'culture',
      label: 'Culture & Arts',
      description: 'Local traditions, music, crafts',
      icon: CupertinoIcons.music_note_2,
      imagePlaceholder: 'culture_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      semanticHint: 'Select for cultural experiences and local traditions',
    ),
    InterestOption(
      id: 'food',
      label: 'Food & Cuisine',
      description: 'Local dishes, street food, cooking',
      icon: CupertinoIcons.cart_fill,
      imagePlaceholder: 'food_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFFee0979), Color(0xFFff6a00)],
      ),
      semanticHint: 'Select for culinary experiences and food tours',
    ),
    InterestOption(
      id: 'photography',
      label: 'Photography',
      description: 'Scenic spots, golden hour, hidden gems',
      icon: CupertinoIcons.camera_fill,
      imagePlaceholder: 'photography_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
      semanticHint: 'Select for photo-worthy locations and photography tips',
    ),
    InterestOption(
      id: 'relaxation',
      label: 'Relaxation',
      description: 'Spas, resorts, Nile cruises',
      icon: CupertinoIcons.sparkles,
      imagePlaceholder: 'relaxation_interest',
      gradient: const LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      ),
      semanticHint: 'Select for relaxing experiences and wellness activities',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    children: [
                      // Progress bar
                      Semantics(
                        label: 'Setup progress: Step 1 of 3, 33% complete',
                        child: Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.white12
                                              : Colors.black12,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: 0.33,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '1/3',
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title section
                      Text(
                        'What interests you?',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select all that apply to personalize your Egypt experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Interest grid
                Expanded(
                  child: Semantics(
                    label:
                        'Select your travel interests. ${_selected.length} of ${_interests.length} selected',
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _interests.length,
                      itemBuilder: (context, index) {
                        final interest = _interests[index];
                        final isSelected = _selected.contains(interest.id);
                        return _buildInterestCard(
                          interest,
                          isSelected,
                          isDark,
                          cardColor,
                          textColor,
                          secondaryTextColor,
                          index,
                        );
                      },
                    ),
                  ),
                ),

                // Bottom actions
                _buildBottomActions(
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestCard(
    InterestOption interest,
    bool isSelected,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    int index,
  ) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: interest.label,
      hint: interest.semanticHint,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selected.remove(interest.id);
            } else {
              _selected.add(interest.id);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected ? null : cardColor,
            gradient: isSelected ? interest.gradient : null,
            border: Border.all(
              color:
                  isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white12
                          : Colors.black.withOpacity(0.08)),
              width: 1.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: interest.gradient.colors.first.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern when selected
              if (isSelected)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(painter: _SubtlePatternPainter()),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with image placeholder
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : interest.gradient.colors.first.withOpacity(
                                  0.15,
                                ),
                      ),
                      child: Center(
                        child: Icon(
                          interest.icon,
                          size: 28,
                          color:
                              isSelected
                                  ? Colors.white
                                  : interest.gradient.colors.first,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Label
                    Text(
                      interest.label,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      interest.description,
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 12,
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.8)
                                : secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selection indicator
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white12
                                : Colors.black.withOpacity(0.08)),
                    border:
                        isSelected
                            ? null
                            : Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                              width: 1.5,
                            ),
                  ),
                  child:
                      isSelected
                          ? Icon(
                            CupertinoIcons.checkmark,
                            size: 14,
                            color: interest.gradient.colors.first,
                          )
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final hasSelection = _selected.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Selection count
          Text(
            hasSelection
                ? '${_selected.length} interest${_selected.length > 1 ? 's' : ''} selected'
                : 'Select at least one interest',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              color:
                  hasSelection
                      ? (isDark ? Colors.white70 : const Color(0xFF667eea))
                      : secondaryTextColor,
              fontWeight: hasSelection ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          // Continue button
          Semantics(
            button: true,
            enabled: hasSelection,
            label: 'Continue to next step',
            hint:
                hasSelection
                    ? '${_selected.length} interests selected. Double tap to continue'
                    : 'Select at least one interest to continue',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient:
                    hasSelection
                        ? const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        )
                        : null,
                color:
                    hasSelection
                        ? null
                        : (isDark ? Colors.white12 : Colors.black12),
                boxShadow:
                    hasSelection
                        ? [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed:
                    hasSelection
                        ? () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder:
                                  (_) => const TravelerProfileSetupScreen(),
                            ),
                          );
                        }
                        : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasSelection ? 'Continue' : 'Select Interests',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            hasSelection
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    if (hasSelection) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.arrow_right,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interest option model
class InterestOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final String imagePlaceholder;
  final LinearGradient gradient;
  final String semanticHint;

  InterestOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.imagePlaceholder,
    required this.gradient,
    required this.semanticHint,
  });
}

/// Subtle pattern painter for selected cards
class _SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
