import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../services/profile_api_service.dart';
import '../../services/api_config.dart';

class ProviderProfileSetupScreen extends StatefulWidget {
  const ProviderProfileSetupScreen({super.key});

  @override
  State<ProviderProfileSetupScreen> createState() =>
      _ProviderProfileSetupScreenState();
}

class _ProviderProfileSetupScreenState extends State<ProviderProfileSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedService = '';
  final ProfileApiService _profileService = ProfileApiService();

  // Verification state
  bool _idScanning = false;
  bool _idCaptured = false;
  bool _selfieCapturing = false;
  bool _selfieCaptured = false;
  double _scanProgress = 0.0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _celebrationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Tour Guide',
      'icon': '🎯',
      'desc': 'Lead tours and experiences',
      'color': Color(0xFF667EEA),
    },
    {
      'name': 'Driver',
      'icon': '🚗',
      'desc': 'Transportation services',
      'color': Color(0xFF11998E),
    },
    {
      'name': 'Photographer',
      'icon': '📸',
      'desc': 'Capture memories',
      'color': Color(0xFFF093FB),
    },
    {
      'name': 'Interpreter',
      'icon': '🗣️',
      'desc': 'Language assistance',
      'color': Color(0xFFD4AF37),
    },
    {
      'name': 'Local Expert',
      'icon': '🏺',
      'desc': 'Share local knowledge',
      'color': Color(0xFFF5576C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _celebrationController.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _fadeController.reset();
      _fadeController.forward();
      HapticFeedback.mediumImpact();
    } else {
      await _saveProviderProfile();
      // Navigate to provider home
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/provider_home', (route) => false);
    }
  }

  Future<void> _saveProviderProfile() async {
    final user = await _profileService.getUserByUsername(
      ApiConfig.demoProviderUsername,
    );
    final userId = user['_id'] as String;

    String verificationStatus = 'pending';
    if (_idCaptured && _selfieCaptured) {
      verificationStatus = 'verified';
    } else if (_idCaptured) {
      verificationStatus = 'id_captured';
    }

    final payload = {
      'full_legal_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
      'service_type': _selectedService.toLowerCase().replaceAll(' ', '_'),
      'verification_status': verificationStatus,
      'verified_flag': _idCaptured && _selfieCaptured,
    };

    await _profileService.upsertProviderProfile(userId, payload);
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

  Future<void> _startIdScan() async {
    setState(() => _idScanning = true);
    HapticFeedback.lightImpact();

    // Simulate scanning with progress
    _scanController.reset();
    _scanController.forward();

    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _scanProgress = i / 100);
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _idScanning = false;
      _idCaptured = true;
    });
    _celebrationController.forward(from: 0);
  }

  Future<void> _startSelfieCapture() async {
    setState(() => _selfieCapturing = true);
    HapticFeedback.lightImpact();

    // Countdown simulation
    for (int i = 3; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      HapticFeedback.selectionClick();
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _selfieCapturing = false;
      _selfieCaptured = true;
    });
    _celebrationController.forward(from: 0);
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 1:
        return _selectedService.isNotEmpty;
      case 2:
        return _idCaptured && _selfieCaptured;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final accentGradient = const [Color(0xFFF093FB), Color(0xFFF5576C)];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background gradient
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
            (_selectedService.isNotEmpty
                    ? _services.firstWhere(
                          (s) => s['name'] == _selectedService,
                        )['color']
                        as Color
                    : const Color(0xFFF093FB))
                .withValues(alpha: isDark ? 0.15 : 0.08),
            isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA),
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
    final stepTitles = ['Profile', 'Service', 'Verify', 'Review'];

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
              child: Icon(CupertinoIcons.back, color: textColor, size: 20),
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
                      gradient:
                          isActive
                              ? LinearGradient(colors: accentGradient)
                              : null,
                      color:
                          isActive
                              ? null
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
                      gradient:
                          isCompleted
                              ? LinearGradient(colors: accentGradient)
                              : null,
                      color:
                          isCompleted
                              ? null
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08)),
                    ),
                    child:
                        isCompleted
                            ? const Icon(
                              CupertinoIcons.checkmark,
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
  ) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(isDark, textColor, subtitleColor, cardColor);
      case 1:
        return _buildServiceTypeStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
        );
      case 2:
        return _buildVerificationStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
        );
      case 3:
        return _buildReviewStep(isDark, textColor, subtitleColor, cardColor);
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

        // Animated title
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_crop_circle_badge_plus,
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
                          "Let's get started!",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tell us about yourself',
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

        // Profile picture placeholder
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
                      const Color(0xFFF093FB).withValues(alpha: 0.2),
                      const Color(0xFFF5576C).withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFF093FB).withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_fill,
                      size: 50,
                      color: isDark ? Colors.white54 : Colors.black26,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
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
          controller: _nameController,
          label: 'Full Legal Name',
          hint: 'As it appears on your ID',
          icon: CupertinoIcons.person_fill,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 100,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+20 xxx xxx xxxx',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          delay: 200,
        ),

        const SizedBox(height: 16),

        _buildAnimatedTextField(
          controller: _bioController,
          label: 'Short Bio',
          hint: 'Tell travelers why they should choose you...',
          icon: CupertinoIcons.text_quote,
          maxLines: 3,
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
    int maxLines = 1,
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
          maxLines: maxLines,
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
              child: Icon(icon, color: const Color(0xFFF093FB), size: 22),
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

  Widget _buildServiceTypeStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.briefcase_fill,
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
                    "What's your expertise?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your primary service',
                    style: TextStyle(fontSize: 15, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        ...List.generate(_services.length, (index) {
          final service = _services[index];
          final isSelected = _selectedService == service['name'];
          final color = service['color'] as Color;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(50 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedService = service['name']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      isSelected
                          ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                          : cardColor,
                  border: Border.all(
                    color:
                        isSelected
                            ? color
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.15 : 0.04,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? color.withValues(alpha: 0.2)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          service['icon'],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service['desc'],
                            style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected
                                  ? color
                                  : (isDark ? Colors.white30 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                CupertinoIcons.checkmark,
                                size: 16,
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
      ],
    );
  }

  Widget _buildVerificationStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.shield_lefthalf_fill,
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
                    "Verify your identity",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help travelers trust you',
                    style: TextStyle(fontSize: 15, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ID Scanner Card
        _buildIdScannerCard(isDark, textColor, subtitleColor, cardColor),

        const SizedBox(height: 20),

        // Selfie Capture Card
        _buildSelfieCaptureCard(isDark, textColor, subtitleColor, cardColor),

        const SizedBox(height: 24),

        // Security note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA).withValues(alpha: isDark ? 0.15 : 0.08),
                const Color(0xFF764BA2).withValues(alpha: isDark ? 0.15 : 0.08),
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
                  CupertinoIcons.lock_shield_fill,
                  color: Color(0xFF667EEA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your data is encrypted',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'We never share your personal information',
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

  Widget _buildIdScannerCard(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return GestureDetector(
      onTap: _idCaptured ? null : _startIdScan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color:
              _idCaptured
                  ? const Color(
                    0xFF38EF7D,
                  ).withValues(alpha: isDark ? 0.2 : 0.1)
                  : cardColor,
          border: Border.all(
            color:
                _idCaptured
                    ? const Color(0xFF38EF7D)
                    : (_idScanning
                        ? const Color(0xFFD4AF37)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08))),
            width: _idCaptured || _idScanning ? 3 : 1,
          ),
          boxShadow:
              _idCaptured
                  ? [
                    BoxShadow(
                      color: const Color(0xFF38EF7D).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Stack(
          children: [
            if (!_idCaptured)
              // ID Rectangle Guide
              Center(
                child: Container(
                  width: 280,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _idScanning
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.8)
                              : (isDark ? Colors.white24 : Colors.black12),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corner guides
                      ..._buildCornerGuides(_idScanning),

                      // Scanning line
                      if (_idScanning)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * 160,
                              left: 8,
                              right: 8,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFFD4AF37),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Center content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.creditcard,
                              size: _idScanning ? 36 : 42,
                              color:
                                  _idScanning
                                      ? const Color(0xFFD4AF37)
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black26),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _idScanning ? 'Scanning...' : 'Tap to scan ID',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:
                                    _idScanning
                                        ? const Color(0xFFD4AF37)
                                        : subtitleColor,
                              ),
                            ),
                            if (_idScanning) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120,
                                child: LinearProgressIndicator(
                                  value: _scanProgress,
                                  backgroundColor:
                                      isDark ? Colors.white12 : Colors.black12,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFD4AF37),
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_idCaptured)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38EF7D).withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 48,
                        color: Color(0xFF38EF7D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ID Verified!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Government ID captured successfully',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),

            // Label
            Positioned(
              top: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _idCaptured
                          ? const Color(0xFF38EF7D).withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _idCaptured
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.creditcard_fill,
                      size: 14,
                      color:
                          _idCaptured ? const Color(0xFF38EF7D) : subtitleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Government ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            _idCaptured
                                ? const Color(0xFF38EF7D)
                                : subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerGuides(bool isActive) {
    final color = isActive ? const Color(0xFFD4AF37) : Colors.white38;
    const size = 20.0;
    const thickness = 3.0;

    return [
      // Top left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4)),
          ),
        ),
      ),
      // Top right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(4)),
          ),
        ),
      ),
      // Bottom left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
      ),
      // Bottom right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSelfieCaptureCard(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return GestureDetector(
      onTap: _selfieCaptured ? null : _startSelfieCapture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color:
              _selfieCaptured
                  ? const Color(
                    0xFF38EF7D,
                  ).withValues(alpha: isDark ? 0.2 : 0.1)
                  : cardColor,
          border: Border.all(
            color:
                _selfieCaptured
                    ? const Color(0xFF38EF7D)
                    : (_selfieCapturing
                        ? const Color(0xFFF093FB)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08))),
            width: _selfieCaptured || _selfieCapturing ? 3 : 1,
          ),
          boxShadow:
              _selfieCaptured
                  ? [
                    BoxShadow(
                      color: const Color(0xFF38EF7D).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Stack(
          children: [
            if (!_selfieCaptured)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Face outline
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _selfieCapturing
                                  ? const Color(0xFFF093FB)
                                  : (isDark ? Colors.white24 : Colors.black12),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.person_fill,
                            size: 50,
                            color:
                                _selfieCapturing
                                    ? const Color(0xFFF093FB)
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black12),
                          ),
                          if (_selfieCapturing)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, _) {
                                return Container(
                                  width: 100 * value,
                                  height: 100 * value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF093FB,
                                      ).withValues(alpha: 1 - value),
                                      width: 3,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selfieCapturing ? 'Hold still...' : 'Tap to take selfie',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color:
                            _selfieCapturing
                                ? const Color(0xFFF093FB)
                                : subtitleColor,
                      ),
                    ),
                    if (_selfieCapturing) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Capturing in 3...2...1...',
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ],
                ),
              ),

            if (_selfieCaptured)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38EF7D).withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 40,
                        color: Color(0xFF38EF7D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selfie Captured!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Face verification complete',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),

            // Label
            Positioned(
              top: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _selfieCaptured
                          ? const Color(0xFF38EF7D).withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selfieCaptured
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.camera_fill,
                      size: 14,
                      color:
                          _selfieCaptured
                              ? const Color(0xFF38EF7D)
                              : subtitleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Selfie Verification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            _selfieCaptured
                                ? const Color(0xFF38EF7D)
                                : subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Success header
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38EF7D), Color(0xFF11998E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38EF7D).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "You're all set! 🎉",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your profile before going live',
                style: TextStyle(fontSize: 16, color: subtitleColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Profile summary card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile header
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty
                              ? 'Your Name'
                              : _nameController.text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (_services.firstWhere(
                                      (s) => s['name'] == _selectedService,
                                      orElse:
                                          () => {
                                            'color': const Color(0xFFF093FB),
                                          },
                                    )['color']
                                    as Color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedService.isEmpty
                                ? 'Service Type'
                                : _selectedService,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  _services.firstWhere(
                                        (s) => s['name'] == _selectedService,
                                        orElse:
                                            () => {
                                              'color': const Color(0xFFF093FB),
                                            },
                                      )['color']
                                      as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38EF7D).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 24,
                      color: Color(0xFF38EF7D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Divider(
                color:
                    isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.06),
              ),

              const SizedBox(height: 16),

              // Stats preview
              Row(
                children: [
                  _buildStatItem(
                    '📞',
                    'Phone',
                    _phoneController.text.isEmpty ? 'Not set' : 'Verified',
                    isDark,
                    textColor,
                    subtitleColor,
                  ),
                  _buildStatItem(
                    '🪪',
                    'ID',
                    _idCaptured ? 'Verified' : 'Pending',
                    isDark,
                    textColor,
                    subtitleColor,
                  ),
                  _buildStatItem(
                    '🤳',
                    'Selfie',
                    _selfieCaptured ? 'Verified' : 'Pending',
                    isDark,
                    textColor,
                    subtitleColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bio preview
        if (_bioController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.text_quote,
                      size: 18,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _bioController.text,
                  style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String emoji,
    String label,
    String value,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    final isVerified = value == 'Verified';
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: subtitleColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isVerified ? const Color(0xFF38EF7D) : subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(
    bool isDark,
    List<Color> accentGradient,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: _canContinue ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _canContinue ? _nextStep : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accentGradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _canContinue
                          ? [
                            BoxShadow(
                              color: accentGradient[0].withValues(alpha: 0.4),
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
                      _currentStep == 3
                          ? 'Start Accepting Requests'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentStep == 3
                          ? CupertinoIcons.rocket_fill
                          : CupertinoIcons.arrow_right,
                      color: Colors.white,
                      size: 20,
                    ),
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
