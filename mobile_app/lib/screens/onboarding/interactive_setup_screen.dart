import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import 'traveler_profile_setup_screen.dart';

/// Interest Selection Screen - Smart Monochrome design system
/// Grid of selectable interest cards with Electric Cobalt accent
class InteractiveSetupScreen extends StatefulWidget {
  const InteractiveSetupScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveSetupScreen> createState() => _InteractiveSetupScreenState();
}

class _InteractiveSetupScreenState extends State<InteractiveSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Set<String> _selected = {};

  final List<InterestOption> _interests = [
    InterestOption(
      id: 'history',
      label: 'History & Archaeology',
      description: 'Ancient temples, pyramids, museums',
      icon: LucideIcons.landmark,
      emoji: '',
    ),
    InterestOption(
      id: 'adventure',
      label: 'Adventure',
      description: 'Desert safaris, diving, hiking',
      icon: LucideIcons.mountain,
      emoji: '',
    ),
    InterestOption(
      id: 'culture',
      label: 'Culture & Arts',
      description: 'Local traditions, music, crafts',
      icon: LucideIcons.palette,
      emoji: '',
    ),
    InterestOption(
      id: 'food',
      label: 'Food & Cuisine',
      description: 'Local dishes, street food, cooking',
      icon: LucideIcons.chefHat,
      emoji: '',
    ),
    InterestOption(
      id: 'photography',
      label: 'Photography',
      description: 'Scenic spots, golden hour, hidden gems',
      icon: LucideIcons.camera,
      emoji: '',
    ),
    InterestOption(
      id: 'relaxation',
      label: 'Relaxation',
      description: 'Spas, resorts, Nile cruises',
      icon: LucideIcons.waves,
      emoji: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : AppDesign.pureWhite;
    final border = isDark ? Colors.white10 : AppDesign.lightGrey;
    final hasSelection = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: 0.33,
                              minHeight: 5,
                              backgroundColor: isDark ? Colors.white12 : AppDesign.lightGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppDesign.electricCobalt,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('1/3',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sub,
                            )),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'What interests you?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply to personalize your experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _interests.length,
                  itemBuilder: (context, index) {
                    final interest = _interests[index];
                    final isSelected = _selected.contains(interest.id);
                    return _buildCard(
                      interest, isSelected, isDark, card, text, sub, border,
                    );
                  },
                ),
              ),

              // Bottom actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Text(
                      hasSelection
                          ? '${_selected.length} interest${_selected.length > 1 ? "s" : ""} selected'
                          : 'Select at least one interest',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasSelection ? AppDesign.electricCobalt : sub,
                        fontWeight: hasSelection ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: hasSelection
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TravelerProfileSetupScreen(),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.electricCobalt,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              isDark ? Colors.white12 : AppDesign.lightGrey,
                          disabledForegroundColor:
                              isDark ? Colors.white38 : AppDesign.midGrey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesign.borderRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hasSelection ? 'Continue' : 'Select Interests',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hasSelection) ...[
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 20),
                            ],
                          ],
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
    );
  }

  Widget _buildCard(
    InterestOption interest,
    bool isSelected,
    bool isDark,
    Color card,
    Color text,
    Color sub,
    Color border,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selected.remove(interest.id);
          } else {
            _selected.add(interest.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppDesign.borderRadius,
          color: isSelected ? AppDesign.electricCobalt : card,
          border: Border.all(
            color: isSelected ? AppDesign.electricCobalt : border,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppDesign.electricCobalt.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : (isDark ? [] : AppDesign.softShadow),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppDesign.electricCobalt.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(interest.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    interest.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    interest.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : sub,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Checkmark
            Positioned(
              top: 12,
              right: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white12 : AppDesign.lightGrey),
                ),
                child: isSelected
                    ? const Icon(LucideIcons.check,
                        size: 14, color: AppDesign.electricCobalt)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InterestOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final String emoji;

  InterestOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.emoji,
  });
}
