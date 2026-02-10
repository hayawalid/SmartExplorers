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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF0F4C75)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and progress
              _buildHeader(context),

              // Progress indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),

              // Continue button
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(CupertinoIcons.back, color: Colors.white),
            ),
          ),
          const Spacer(),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'SF Pro Text',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color:
                    index <= _currentStep
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildCountryStep();
      case 2:
        return _buildInterestsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Let's get to know you",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 40),
        _buildGlassTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: CupertinoIcons.person_fill,
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildCountryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Where are you from?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your home country',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 30),
        ..._countries.map((country) => _buildCountryOption(country)),
      ],
    );
  }

  Widget _buildCountryOption(String country) {
    final isSelected = _selectedCountry == country;
    return GestureDetector(
      onTap: () => setState(() => _selectedCountry = country),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              country,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'SF Pro Text',
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "What excites you?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your travel interests (choose 3+)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
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
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'SF Pro Text',
                            fontWeight: FontWeight.w500,
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'SF Pro Text',
              ),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFE0E0E0)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _nextStep,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _currentStep < 2 ? 'Continue' : 'Start Exploring',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                    fontFamily: 'SF Pro Text',
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
