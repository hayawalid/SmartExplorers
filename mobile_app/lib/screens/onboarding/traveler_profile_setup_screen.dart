import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class TravelerProfileSetupScreen extends StatefulWidget {
  const TravelerProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<TravelerProfileSetupScreen> createState() =>
      _TravelerProfileSetupScreenState();
}

class _TravelerProfileSetupScreenState extends State<TravelerProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountry = 'United States';
  final List<String> _selectedInterests = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Germany',
    'France',
    'Canada',
    'Australia',
    'Japan',
    'China',
    'Brazil',
    'India',
  ];

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Ancient History', 'icon': '🏛️'},
    {'name': 'Photography', 'icon': '📷'},
    {'name': 'Adventure', 'icon': '🧗'},
    {'name': 'Food & Cuisine', 'icon': '🍽️'},
    {'name': 'Art & Culture', 'icon': '🎨'},
    {'name': 'Nature', 'icon': '🌿'},
    {'name': 'Shopping', 'icon': '🛍️'},
    {'name': 'Nightlife', 'icon': '🌙'},
    {'name': 'Beaches', 'icon': '🏖️'},
    {'name': 'Desert Safari', 'icon': '🐪'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _animController.reset();
      _animController.forward();
    } else {
      // Navigate to home/main app
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final accentColor = const Color(0xFF667EEA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            _buildHeader(context, isDark, textColor, subtitleColor),

            // Progress indicator
            _buildProgressIndicator(isDark, accentColor),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(
                    isDark,
                    textColor,
                    subtitleColor,
                    cardColor,
                    accentColor,
                  ),
                ),
              ),
            ),

            // Continue button
            _buildContinueButton(isDark, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
                _animController.reset();
                _animController.forward();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
              ),
              child: Icon(CupertinoIcons.back, color: textColor),
            ),
          ),
          const Spacer(),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color:
                    isActive
                        ? accentColor
                        : (isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color accentColor,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(isDark, textColor, subtitleColor, cardColor);
      case 1:
        return _buildCountryStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentColor,
        );
      case 2:
        return _buildInterestsStep(
          isDark,
          textColor,
          subtitleColor,
          accentColor,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Let's get to know you",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: CupertinoIcons.person_fill,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _buildCountryStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Where are you from?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your home country',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 30),
        ..._countries.map(
          (country) => _buildCountryOption(
            country,
            isDark,
            textColor,
            cardColor,
            accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCountryOption(
    String country,
    bool isDark,
    Color textColor,
    Color cardColor,
    Color accentColor,
  ) {
    final isSelected = _selectedCountry == country;
    return GestureDetector(
      onTap: () => setState(() => _selectedCountry = country),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected
                  ? accentColor.withOpacity(isDark ? 0.2 : 0.1)
                  : cardColor,
          border: Border.all(
            color:
                isSelected
                    ? accentColor
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Text(
              country,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(CupertinoIcons.checkmark_circle_fill, color: accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "What excites you?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your travel interests (choose 3+)',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _interests.map((interest) {
                final isSelected = _selectedInterests.contains(
                  interest['name'],
                );
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['name']);
                      } else {
                        _selectedInterests.add(interest['name']);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color:
                          isSelected
                              ? accentColor.withOpacity(isDark ? 0.3 : 0.15)
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.04)),
                      border: Border.all(
                        color:
                            isSelected
                                ? accentColor
                                : (isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.1)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          interest['icon'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          interest['name'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? accentColor : textColor,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white60 : Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [accentColor, const Color(0xFF764BA2)],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _nextStep,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _currentStep < 2 ? 'Continue' : 'Start Exploring',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
