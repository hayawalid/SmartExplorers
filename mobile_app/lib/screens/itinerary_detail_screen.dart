import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'itinerary_planner_screen.dart';

/// Full-screen detail view for itinerary items with Hero animation
/// WCAG 2.1 AA compliant with proper Semantics and contrast ratios
class ItineraryDetailScreen extends StatefulWidget {
  final ItineraryItem item;

  const ItineraryDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    // Delay content animation for Hero to complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // Auto-switch to dark mode for high contrast
    final effectiveIsDark = isDark || mediaQuery.highContrast;

    final backgroundColor =
        effectiveIsDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final cardColor = effectiveIsDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = effectiveIsDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor =
        effectiveIsDark ? Colors.white70 : const Color(0xFF6B7280);

    const accentBlue = Color(0xFF667eea);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // Hero image area
              SliverToBoxAdapter(
                child: _buildHeroImage(effectiveIsDark, accentBlue),
              ),

              // Content
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(
                      effectiveIsDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                      accentBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: mediaQuery.padding.top + 8,
            left: 16,
            child: _buildBackButton(effectiveIsDark),
          ),

          // Quick edit button
          Positioned(
            top: mediaQuery.padding.top + 8,
            right: 16,
            child: _buildQuickEditButton(effectiveIsDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(bool isDark, Color accentBlue) {
    return Hero(
      tag: 'itinerary_${widget.item.id}',
      child: Container(
        height: 350,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                widget.item.isAccepted
                    ? [
                      accentBlue.withOpacity(0.4),
                      const Color(0xFF764ba2).withOpacity(0.6),
                    ]
                    : [
                      const Color(0xFF667eea).withOpacity(0.3),
                      const Color(0xFFf5576c).withOpacity(0.4),
                    ],
          ),
        ),
        child: Stack(
          children: [
            // Emoji/Image centered
            Center(
              child: Semantics(
                image: true,
                label: widget.item.altText,
                child: Text(
                  widget.item.imageEmoji,
                  style: const TextStyle(fontSize: 120),
                ),
              ),
            ),

            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark
                          ? const Color(0xFF0A0A0F)
                          : const Color(0xFFF8F9FA)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return Semantics(
      button: true,
      label: 'Go back',
      hint: 'Return to itinerary list',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              ),
              child: Icon(
                CupertinoIcons.back,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickEditButton(bool isDark) {
    return Semantics(
      button: true,
      label: 'Quick edit',
      hint: 'Modify this activity',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showQuickEditSheet(isDark);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              ),
              child: Icon(
                CupertinoIcons.pencil,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and time
          _buildTitleSection(textColor, subtitleColor, accentBlue),

          const SizedBox(height: 24),

          // Location card
          _buildInfoCard(
            icon: CupertinoIcons.location_solid,
            title: 'Location',
            content: widget.item.location,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),

          const SizedBox(height: 16),

          // Time card
          _buildInfoCard(
            icon: CupertinoIcons.clock,
            title: 'Duration',
            content: widget.item.time,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),

          const SizedBox(height: 16),

          // Cost card
          _buildInfoCard(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'Estimated Cost',
            content: widget.item.estimatedCost,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),

          const SizedBox(height: 24),

          // Description
          _buildDescriptionSection(textColor, subtitleColor),

          const SizedBox(height: 24),

          // Accessibility section
          _buildAccessibilitySection(
            isDark,
            cardColor,
            textColor,
            subtitleColor,
            accentBlue,
          ),

          const SizedBox(height: 24),

          // Tags
          _buildTagsSection(textColor, subtitleColor, accentBlue),

          const SizedBox(height: 32),

          // Action buttons
          _buildActionButtons(isDark, accentBlue),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildTitleSection(
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Day ${widget.item.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentBlue,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Title
        Semantics(
          header: true,
          child: Text(
            widget.item.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'SF Pro Display',
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Semantics(
      label: '$title: $content',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF667eea), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: 'SF Pro Text',
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

  Widget _buildDescriptionSection(Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'About This Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: widget.item.description,
          child: Text(
            widget.item.description,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.85),
              fontFamily: 'SF Pro Text',
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    return Semantics(
      container: true,
      label:
          'Accessibility information. Rating: ${widget.item.accessibilityRating} out of 5. ${widget.item.accessibilityNotes}',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility Rating',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < widget.item.accessibilityRating
                                  ? CupertinoIcons.star_fill
                                  : CupertinoIcons.star,
                              size: 20,
                              color:
                                  index < widget.item.accessibilityRating
                                      ? const Color(0xFF4CAF50)
                                      : subtitleColor.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    color: Color(0xFF4CAF50),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.accessibilityNotes,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.85),
                        fontFamily: 'SF Pro Text',
                        height: 1.4,
                      ),
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

  Widget _buildTagsSection(
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              widget.item.tags.map((tag) {
                return Semantics(
                  label: 'Category: $tag',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: accentBlue,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, Color accentBlue) {
    return Row(
      children: [
        // Find Guide button
        Expanded(
          child: Semantics(
            button: true,
            label: 'Find a verified guide for this activity',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // Navigate to guide finder
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_badge_plus_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Find a Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Share button
        Semantics(
          button: true,
          label: 'Share this activity',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Share functionality
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                CupertinoIcons.share,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickEditSheet(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
        final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subtitleColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Quick Edit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modify this activity in your itinerary',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 24),

                // Edit options
                _buildEditOption(
                  icon: CupertinoIcons.clock,
                  label: 'Change Time',
                  isDark: isDark,
                  textColor: textColor,
                ),
                _buildEditOption(
                  icon: CupertinoIcons.calendar,
                  label: 'Move to Different Day',
                  isDark: isDark,
                  textColor: textColor,
                ),
                _buildEditOption(
                  icon: CupertinoIcons.arrow_2_squarepath,
                  label: 'Find Alternative Activity',
                  isDark: isDark,
                  textColor: textColor,
                ),
                _buildEditOption(
                  icon: CupertinoIcons.trash,
                  label: 'Remove from Itinerary',
                  isDark: isDark,
                  textColor: textColor,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textColor,
    bool isDestructive = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      isDestructive
                          ? const Color(0xFFf5576c).withOpacity(0.15)
                          : const Color(0xFF667eea).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isDestructive
                          ? const Color(0xFFf5576c)
                          : const Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? const Color(0xFFf5576c) : textColor,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
