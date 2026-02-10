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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf093fb), Color(0xFFf5576c), Color(0xFF0F4C75)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
            'Step ${_currentStep + 1} of 4',
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
        children: List.generate(4, (index) {
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
        return _buildServiceTypeStep();
      case 2:
        return _buildIdVerificationStep();
      case 3:
        return _buildReviewStep();
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
          "Your professional profile",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell travelers about yourself',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 40),
        _buildGlassTextField(
          controller: _nameController,
          label: 'Full Legal Name',
          icon: CupertinoIcons.person_fill,
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: CupertinoIcons.phone_fill,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
          controller: _bioController,
          label: 'Short Bio',
          icon: CupertinoIcons.text_quote,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildServiceTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "What do you offer?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your primary service',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 30),
        ..._services.map((service) => _buildServiceOption(service)),
      ],
    );
  }

  Widget _buildServiceOption(Map<String, dynamic> service) {
    final isSelected = _selectedService == service['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedService = service['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
            Text(service['icon'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['desc'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Verify your identity",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This keeps travelers safe and builds trust',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 40),

        // ID Upload Card
        _buildVerificationCard(
          title: 'Government ID',
          subtitle: 'Upload front of your national ID or passport',
          icon: CupertinoIcons.creditcard_fill,
          isComplete: _idUploaded,
          onTap: () => setState(() => _idUploaded = true),
        ),

        const SizedBox(height: 20),

        // Selfie Upload Card
        _buildVerificationCard(
          title: 'Selfie Verification',
          subtitle: 'Take a photo matching your ID',
          icon: CupertinoIcons.camera_fill,
          isComplete: _selfieUploaded,
          onTap: () => setState(() => _selfieUploaded = true),
        ),

        const SizedBox(height: 30),

        // Security note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is encrypted and only used for verification. We never share your information.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'SF Pro Text',
                  ),
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
  }) {
    return GestureDetector(
      onTap: isComplete ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isComplete
                      ? Colors.green.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isComplete ? Colors.green : Colors.white.withOpacity(0.3),
                width: 2,
              ),
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
                            ? Colors.green.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(
                    isComplete ? CupertinoIcons.checkmark_alt : icon,
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
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete ? 'Uploaded ✓' : subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isComplete)
                  Icon(
                    CupertinoIcons.arrow_right_circle_fill,
                    color: Colors.white.withOpacity(0.5),
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "You're all set! 🎉",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your profile before going live',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 40),

        // Profile summary card
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Your Name'
                        : _nameController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SF Pro Display',
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
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Text(
                      _selectedService,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'SF Pro Text',
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
                      ),
                      const SizedBox(width: 12),
                      _buildBadge(
                        CupertinoIcons.shield_fill,
                        'Background Check',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Note
        Text(
          'Your profile will be reviewed within 24 hours. You\'ll receive a notification once approved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
            maxLines: maxLines,
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
    final bool canContinue =
        _currentStep != 2 || (_idUploaded && _selfieUploaded);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors:
                canContinue
                    ? [Colors.white, const Color(0xFFE0E0E0)]
                    : [
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.3),
                    ],
          ),
          boxShadow:
              canContinue
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: canContinue ? _nextStep : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _currentStep < 3 ? 'Continue' : 'Submit for Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: canContinue ? const Color(0xFFf5576c) : Colors.grey,
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
