import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import 'traveler_profile_setup_screen.dart';
import 'provider_profile_setup_screen.dart';

/// Account Type Selection - Smart Monochrome design system
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({Key? key}) : super(key: key);

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(LucideIcons.arrowLeft, size: 20, color: text),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Join SmartExplorers',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How would you like to experience Egypt?',
                  style: TextStyle(fontSize: 15, color: sub, height: 1.4),
                ),

                const SizedBox(height: 40),

                // Explorer card
                _typeCard(
                  isDark: isDark,
                  card: card,
                  border: border,
                  text: text,
                  sub: sub,
                  icon: LucideIcons.compass,
                  emoji: '',
                  title: 'Explorer',
                  description: 'Discover Egypt with verified guides, curated itineraries, and real-time safety features.',
                  features: ['Verified Guides', 'Safety Alerts', 'Custom Plans'],
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TravelerProfileSetupScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Provider card
                _typeCard(
                  isDark: isDark,
                  card: card,
                  border: border,
                  text: text,
                  sub: sub,
                  icon: LucideIcons.briefcase,
                  emoji: '',
                  title: 'Service Provider',
                  description: 'Join our network of trusted tourism professionals and grow your business.',
                  features: ['Get Verified', 'Reach Tourists', 'Earn More'],
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderProfileSetupScreen(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Bottom hint
                Center(
                  child: Text(
                    'You can always change this later',
                    style: TextStyle(fontSize: 13, color: sub),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required bool isDark,
    required Color card,
    required Color border,
    required Color text,
    required Color sub,
    required IconData icon,
    required String emoji,
    required String title,
    required String description,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: card,
          borderRadius: AppDesign.borderRadius,
          border: Border.all(color: border, width: 1.2),
          boxShadow: isDark ? [] : AppDesign.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppDesign.electricCobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: text,
                          )),
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                            fontSize: 13,
                            color: sub,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 20, color: sub),
              ],
            ),
            const SizedBox(height: 16),
            // Feature pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.electricCobalt.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppDesign.electricCobalt,
                    )),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
