import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../services/auth_api_service.dart';

class TravelerProfileSetupScreen extends StatefulWidget {
  const TravelerProfileSetupScreen({super.key});

  @override
  State<TravelerProfileSetupScreen> createState() =>
      _TravelerProfileSetupScreenState();
}

class _TravelerProfileSetupScreenState extends State<TravelerProfileSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthApiService _authService = AuthApiService();

  // New dropdown selections
  String _selectedCountry = '';
  String _selectedLanguage = '';
  List<String> _selectedAccessibility = [];
  final List<String> _selectedInterests = [];

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _countries = [
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'China', 'flag': '🇨🇳'},
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'India', 'flag': '🇮🇳'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Sweden', 'flag': '🇸🇪'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
  ];

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Arabic', 'native': 'العربية'},
    {'name': 'Spanish', 'native': 'Español'},
    {'name': 'French', 'native': 'Français'},
    {'name': 'German', 'native': 'Deutsch'},
    {'name': 'Italian', 'native': 'Italiano'},
    {'name': 'Japanese', 'native': '日本語'},
    {'name': 'Chinese', 'native': '中文'},
    {'name': 'Portuguese', 'native': 'Português'},
    {'name': 'Russian', 'native': 'Русский'},
  ];

  final List<Map<String, dynamic>> _accessibilityOptions = [
    {
      'name': 'Wheelchair Access',
      'icon': '♿',
      'desc': 'Requires wheelchair-accessible venues',
    },
    {
      'name': 'Visual Assistance',
      'icon': '👁️',
      'desc': 'Audio descriptions & guide support',
    },
    {
      'name': 'Hearing Assistance',
      'icon': '👂',
      'desc': 'Sign language or written guides',
    },
    {
      'name': 'Mobility Support',
      'icon': '🦯',
      'desc': 'Limited walking, needs rest stops',
    },
    {
      'name': 'Dietary Restrictions',
      'icon': '🍽️',
      'desc': 'Allergies or special diet needs',
    },
    {
      'name': 'Sensory Sensitivity',
      'icon': '🔇',
      'desc': 'Quiet environments preferred',
    },
  ];

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Ancient History', 'icon': '🏛️', 'color': Color(0xFF667EEA)},
    {'name': 'Photography', 'icon': '📷', 'color': Color(0xFFF093FB)},
    {'name': 'Adventure', 'icon': '🧗', 'color': Color(0xFF11998E)},
    {'name': 'Food & Cuisine', 'icon': '🍽️', 'color': Color(0xFFD4AF37)},
    {'name': 'Art & Culture', 'icon': '🎨', 'color': Color(0xFF764BA2)},
    {'name': 'Nature', 'icon': '🌿', 'color': Color(0xFF38EF7D)},
    {'name': 'Shopping', 'icon': '🛍️', 'color': Color(0xFFF5576C)},
    {'name': 'Nightlife', 'icon': '🌙', 'color': Color(0xFF4FACFE)},
    {'name': 'Beaches', 'icon': '🏖️', 'color': Color(0xFF00F2FE)},
    {'name': 'Desert Safari', 'icon': '🐪', 'color': Color(0xFFB8860B)},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _fadeController.reset();
      _fadeController.forward();
      HapticFeedback.mediumImpact();
    } else {
      try {
        await _saveTravelerProfile();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Signup failed: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveTravelerProfile() async {
    await _authService.signup(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      accountType: 'traveler',
      phoneNumber: _phoneController.text.trim(),
      countryOfOrigin: _selectedCountry,
      preferredLanguage: _selectedLanguage,
      travelInterests: _selectedInterests,
      accessibilityNeeds: _selectedAccessibility,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _fadeController.reset();
      _fadeController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _emailController.text.isNotEmpty &&
            _usernameController.text.isNotEmpty &&
            _passwordController.text.length >= 8 &&
            _nameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 1:
        return _selectedCountry.isNotEmpty && _selectedLanguage.isNotEmpty;
      case 2:
        return true; // Accessibility is optional
      case 3:
        return _selectedInterests.length >= 3;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final cardColor = isDark ? AppDesign.cardDark : AppDesign.pureWhite;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final subtitleColor = isDark ? Colors.white54 : AppDesign.midGrey;
    final accentGradient = const [AppDesign.electricCobalt, Color(0xFF1A3FCC)];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(isDark),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark, textColor, subtitleColor),
                _buildProgressIndicator(isDark, accentGradient),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      child: _buildCurrentStep(
                        isDark,
                        textColor,
                        subtitleColor,
                        cardColor,
                        accentGradient,
                      ),
                    ),
                  ),
                ),

                _buildContinueButton(isDark, accentGradient, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.electricCobalt.withOpacity(isDark ? 0.08 : 0.05),
            isDark ? AppDesign.eerieBlack : AppDesign.pureWhite,
          ],
          begin: Alignment.topCenter,
          end: Alignment.center,
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
    final stepTitles = ['Profile', 'Origin', 'Access', 'Interests'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(LucideIcons.arrowLeft, color: textColor, size: 20),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stepTitles[_currentStep],
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark, List<Color> accentGradient) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color:
                          isActive
                              ? AppDesign.electricCobalt
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
                if (index < 3)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted
                              ? AppDesign.electricCobalt
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08)),
                    ),
                    child:
                        isCompleted
                            ? const Icon(
                              LucideIcons.check,
                              size: 6,
                              color: Colors.white,
                            )
                            : null,
                  ),
              ],
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
    List<Color> accentGradient,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentGradient,
        );
      case 1:
        return _buildOriginLanguageStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentGradient,
        );
      case 2:
        return _buildAccessibilityStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentGradient,
        );
      case 3:
        return _buildInterestsStep(
          isDark,
          textColor,
          subtitleColor,
          accentGradient,
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
    List<Color> accentGradient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppDesign.electricCobalt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.userPlus,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, Explorer!",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Let's personalize your journey",
                          style: TextStyle(fontSize: 15, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Avatar placeholder
        Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentGradient[0].withValues(alpha: 0.2),
                      accentGradient[1].withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: accentGradient[0].withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.user,
                      size: 50,
                      color: isDark ? Colors.white54 : Colors.black26,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: accentGradient),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        _buildAnimatedTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'your@email.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 100,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Choose a unique username',
          icon: LucideIcons.atSign,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 150,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'At least 8 characters',
          icon: LucideIcons.lock,
          obscureText: true,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 200,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'How should we call you?',
          icon: LucideIcons.user,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 250,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'For emergency contact',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 300,
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
    TextInputType? keyboardType,
    bool obscureText = false,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: textColor, fontSize: 16),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            labelStyle: TextStyle(
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: const Color(0xFF667EEA), size: 22),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginLanguageStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    List<Color> accentGradient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppDesign.electricCobalt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.globe,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Where are you from?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Helps us match you with guides',
                    style: TextStyle(fontSize: 15, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Country dropdown
        Text(
          'Country of Origin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 10),
        _buildDropdownSelector(
          value: _selectedCountry,
          hint: 'Select your country',
          icon: LucideIcons.flag,
          items: _countries.map((c) => '${c['flag']} ${c['name']}').toList(),
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _selectedCountry = value ?? '');
          },
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
        ),

        const SizedBox(height: 24),

        // Language dropdown
        Text(
          'Preferred Language',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 10),
        _buildDropdownSelector(
          value: _selectedLanguage,
          hint: 'Select preferred language',
          icon: LucideIcons.messageSquare,
          items:
              _languages.map((l) => '${l['name']} (${l['native']})').toList(),
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _selectedLanguage = value ?? '');
          },
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
        ),

        const SizedBox(height: 24),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF11998E).withValues(alpha: isDark ? 0.15 : 0.08),
                const Color(0xFF38EF7D).withValues(alpha: isDark ? 0.15 : 0.08),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.info,
                  color: Color(0xFF11998E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why we ask this',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "We'll match you with guides who speak your language",
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSelector({
    required String value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
              value.isNotEmpty
                  ? const Color(0xFF667EEA).withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06)),
          width: value.isNotEmpty ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: AppDesign.electricCobalt, size: 22),
              ),
              Text(
                hint,
                style: TextStyle(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black38,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              LucideIcons.chevronDown,
              color: isDark ? Colors.white70 : AppDesign.midGrey,
              size: 18,
            ),
          ),
          dropdownColor: cardColor,
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(color: textColor, fontSize: 16),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      icon,
                      color: AppDesign.electricCobalt,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items:
              items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAccessibilityStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    List<Color> accentGradient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppDesign.electricCobalt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.heart,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Any accessibility needs?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "We'll ensure your comfort (optional)",
                    style: TextStyle(fontSize: 15, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        ...List.generate(_accessibilityOptions.length, (index) {
          final option = _accessibilityOptions[index];
          final isSelected = _selectedAccessibility.contains(option['name']);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 80)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(40 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedAccessibility.remove(option['name']);
                  } else {
                    _selectedAccessibility.add(option['name']);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:
                      isSelected
                          ? const Color(
                            0xFFF093FB,
                          ).withValues(alpha: isDark ? 0.2 : 0.1)
                          : cardColor,
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFFF093FB)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF093FB,
                              ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFF093FB).withValues(alpha: 0.2)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          option['icon'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? const Color(0xFFF093FB)
                                      : textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option['desc'],
                            style: TextStyle(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected
                                ? const Color(0xFFF093FB)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFFF093FB)
                                  : (isDark ? Colors.white30 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                LucideIcons.check,
                                size: 14,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Skip note
        Center(
          child: TextButton(
            onPressed: _nextStep,
            child: Text(
              'Skip for now',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    List<Color> accentGradient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppDesign.electricCobalt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What excites you?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick at least 3 interests',
                    style: TextStyle(fontSize: 15, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Selected count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _selectedInterests.length >= 3
                    ? const Color(
                      0xFF38EF7D,
                    ).withValues(alpha: isDark ? 0.2 : 0.1)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_selectedInterests.length} selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  _selectedInterests.length >= 3
                      ? const Color(0xFF38EF7D)
                      : subtitleColor,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _interests.asMap().entries.map((entry) {
                final index = entry.key;
                final interest = entry.value;
                final isSelected = _selectedInterests.contains(
                  interest['name'],
                );
                final color = interest['color'] as Color;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest['name']);
                        } else {
                          _selectedInterests.add(interest['name']);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                )
                                : null,
                        color:
                            isSelected
                                ? null
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04)),
                        border: Border.all(
                          color:
                              isSelected
                                  ? color
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1)),
                          width: isSelected ? 0 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
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
                              color: isSelected ? Colors.white : textColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueButton(
    bool isDark,
    List<Color> accentGradient,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: AnimatedOpacity(
        opacity: _canContinue ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: _canContinue ? _nextStep : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppDesign.electricCobalt,
              borderRadius: AppDesign.borderRadius,
              boxShadow:
                  _canContinue
                      ? [
                        BoxShadow(
                          color: AppDesign.electricCobalt.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep == 3 ? 'Start Exploring' : 'Continue',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentStep == 3
                      ? LucideIcons.sparkles
                      : LucideIcons.arrowRight,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
