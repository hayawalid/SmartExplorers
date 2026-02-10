import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class ProviderProfileSetupScreen extends StatefulWidget {
  const ProviderProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProviderProfileSetupScreen> createState() =>
      _ProviderProfileSetupScreenState();
}

class _ProviderProfileSetupScreenState extends State<ProviderProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedService = 'Tour Guide';
  bool _idUploaded = false;
  bool _selfieUploaded = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _services = [
    {'name': 'Tour Guide', 'icon': '🎯', 'desc': 'Lead tours and experiences'},
    {'name': 'Driver', 'icon': '🚗', 'desc': 'Transportation services'},
    {'name': 'Photographer', 'icon': '📸', 'desc': 'Capture memories'},
    {'name': 'Interpreter', 'icon': '🗣️', 'desc': 'Language assistance'},
    {'name': 'Local Expert', 'icon': '🏺', 'desc': 'Share local knowledge'},
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
    _bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
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
    final accentColor = const Color(0xFFF093FB);
    final accentGradient = [const Color(0xFFF093FB), const Color(0xFFF5576C)];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
            _buildContinueButton(isDark, accentGradient),
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
            'Step ${_currentStep + 1} of 4',
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
        children: List.generate(4, (index) {
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
        return _buildServiceTypeStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentColor,
        );
      case 2:
        return _buildIdVerificationStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          accentColor,
        );
      case 3:
        return _buildReviewStep(
          isDark,
          textColor,
          subtitleColor,
          cardColor,
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
          "Your professional profile",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell travelers about yourself',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _nameController,
          label: 'Full Legal Name',
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Short Bio',
          icon: CupertinoIcons.text_quote,
          maxLines: 3,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _buildServiceTypeStep(
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
          "What do you offer?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your primary service',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 30),
        ..._services.map(
          (service) => _buildServiceOption(
            service,
            isDark,
            textColor,
            subtitleColor,
            cardColor,
            accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceOption(
    Map<String, dynamic> service,
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color accentColor,
  ) {
    final isSelected = _selectedService == service['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedService = service['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
            Text(service['icon'], style: const TextStyle(fontSize: 32)),
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
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['desc'],
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: accentColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdVerificationStep(
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
          "Verify your identity",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This keeps travelers safe and builds trust',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 40),

        // ID Upload Card
        _buildVerificationCard(
          title: 'Government ID',
          subtitle: 'Upload front of your national ID or passport',
          icon: CupertinoIcons.creditcard_fill,
          isComplete: _idUploaded,
          onTap: () => setState(() => _idUploaded = true),
          isDark: isDark,
          textColor: textColor,
          subtitleColor: subtitleColor,
          cardColor: cardColor,
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Selfie Upload Card
        _buildVerificationCard(
          title: 'Selfie Verification',
          subtitle: 'Take a photo matching your ID',
          icon: CupertinoIcons.camera_fill,
          isComplete: _selfieUploaded,
          onTap: () => setState(() => _selfieUploaded = true),
          isDark: isDark,
          textColor: textColor,
          subtitleColor: subtitleColor,
          cardColor: cardColor,
          accentColor: accentColor,
        ),

        const SizedBox(height: 30),

        // Security note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                color: subtitleColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is encrypted and only used for verification. We never share your information.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isComplete,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: isComplete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isComplete
                  ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                  : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isComplete
                    ? Colors.green
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08)),
            width: isComplete ? 2 : 1,
          ),
          boxShadow:
              isComplete
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isComplete
                        ? Colors.green.withOpacity(isDark ? 0.3 : 0.15)
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05)),
              ),
              child: Icon(
                isComplete ? CupertinoIcons.checkmark_alt : icon,
                color: isComplete ? Colors.green : subtitleColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isComplete ? 'Uploaded ✓' : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isComplete ? Colors.green : subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!isComplete)
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: subtitleColor.withOpacity(0.5),
                size: 28,
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
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "You're all set! 🎉",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your profile before going live',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
        const SizedBox(height: 40),

        // Profile summary card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
          ),
          child: Column(
            children: [
              // Avatar placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.3),
                      accentColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 50,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nameController.text.isEmpty
                    ? 'Your Name'
                    : _nameController.text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: accentColor.withOpacity(isDark ? 0.2 : 0.1),
                ),
                child: Text(
                  _selectedService,
                  style: TextStyle(
                    fontSize: 14,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(
                    CupertinoIcons.checkmark_seal_fill,
                    'ID Verified',
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildBadge(
                    CupertinoIcons.shield_fill,
                    'Background Check',
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Note
        Text(
          'Your profile will be reviewed within 24 hours. You\'ll receive a notification once approved.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
        maxLines: maxLines,
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

  Widget _buildContinueButton(bool isDark, List<Color> accentGradient) {
    final bool canContinue =
        _currentStep != 2 || (_idUploaded && _selfieUploaded);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              canContinue
                  ? LinearGradient(colors: accentGradient)
                  : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  ),
          boxShadow:
              canContinue
                  ? [
                    BoxShadow(
                      color: accentGradient[0].withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: canContinue ? _nextStep : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _currentStep < 3 ? 'Continue' : 'Submit for Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: canContinue ? Colors.white : Colors.white70,
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
