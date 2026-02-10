import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
 
class InteractiveSetupScreen extends StatefulWidget {
  const InteractiveSetupScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveSetupScreen> createState() => _InteractiveSetupScreenState();
}

class _InteractiveSetupScreenState extends State<InteractiveSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  final List<String> _interests = [
    'History Buff',
    'Solo Female',
    'Wheelchair Accessible',
    'Foodie',
    'Adventurer',
    'Culture Lover',
    'Photographer',
  ];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF6A82FB),
                        const Color(0xFFFC5C7D),
                        _bgAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFFFC5C7D),
                        const Color(0xFFD4AF37),
                        _bgAnimation.value,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                // Travel path progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.4, // TODO: Bind to progress
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Positioned(
                              left:
                                  MediaQuery.of(context).size.width * 0.4 - 16,
                              child: Icon(
                                Icons.airplanemode_active,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '1/3',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Persona Avatar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFF0F4C75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Bubble chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children:
                        _interests.map((interest) {
                          final selected = _selected.contains(interest);
                          return ChoiceChip(
                            label: Text(interest),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selected.add(interest);
                                } else {
                                  _selected.remove(interest);
                                }
                              });
                            },
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.7),
                            selectedColor: theme.colorScheme.primary,
                            elevation: 4,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const Spacer(),
                // Next button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed:
                        _selected.isNotEmpty
                            ? () {
                              // TODO: Advance to next onboarding step
                            }
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
