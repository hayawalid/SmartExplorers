import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/services/session_store.dart';
import '../../services/auth_api_service.dart';
import '../../services/face_verification_service.dart';
import '../shared/selfie_camera_screen.dart';

/// Provider signup – 4-step cinematic glass flow
/// Step 1: Basic info  Step 2: Service type  Step 3: Verification  Step 4: Review
class ProviderProfileSetupScreen extends StatefulWidget {
  const ProviderProfileSetupScreen({super.key});

  @override
  State<ProviderProfileSetupScreen> createState() =>
      _ProviderProfileSetupScreenState();
}

class _ProviderProfileSetupScreenState extends State<ProviderProfileSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedService = '';
  bool _isLoading = false;
  final AuthApiService _authService = AuthApiService();

  // Live validation error messages
  String _emailError = '';
  String _usernameError = '';
  String _passwordError = '';
  String _nameError = '';
  String _phoneError = '';

  // Debounce timer for email uniqueness check
  Timer? _emailDebounceTimer;

  // Verification state
  bool _idScanning = false;
  bool _idCaptured = false;
  bool _selfieCapturing = false;
  bool _selfieCaptured = false;
  double _scanProgress = 0.0;

  // Real image files
  File? _idImageFile;
  File? _selfieFile;
  bool _isVerifying = false;
  bool _verificationPassed = false;
  String? _verificationError;

  late AnimationController _fadeController;
  late AnimationController _scanController;
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

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

    // Add live validation listeners
    _emailController.addListener(_onEmailChanged);
    _usernameController.addListener(_validateUsernameLive);
    _passwordController.addListener(_validatePasswordLive);
    _nameController.addListener(_validateNameLive);
    _phoneController.addListener(_validatePhoneLive);
  }

  @override
  void dispose() {
    // Cancel debounce timer
    _emailDebounceTimer?.cancel();
    
    // Remove live validation listeners
    _emailController.removeListener(_onEmailChanged);
    _usernameController.removeListener(_validateUsernameLive);
    _passwordController.removeListener(_validatePasswordLive);
    _nameController.removeListener(_validateNameLive);
    _phoneController.removeListener(_validatePhoneLive);
    
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _fadeController.dispose();
    _scanController.dispose();
    _celebrationController.dispose();
    _authService.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _validateEmailLive();
    _debounceEmailUniquenessCheck();
  }

  // Live validation methods
  void _validateEmailLive() {
    setState(() {
      final value = _emailController.text;
      if (value.isEmpty) {
        _emailError = '';
      } else {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          _emailError = 'Enter a valid email (e.g., name@example.com)';
        } else if (!_emailError.contains('already registered')) {
          _emailError = '';
        }
      }
    });
  }

  Future<void> _debounceEmailUniquenessCheck() async {
    _emailDebounceTimer?.cancel();
    
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return;
    
    _emailDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await _authService.checkEmailExists(email);
      if (mounted) {
        setState(() {
          if (exists) {
            _emailError = 'This email is already registered. Please use a different email or login.';
          } else if (_emailError.contains('already registered')) {
            _emailError = '';
            _validateEmailLive();
          }
        });
      }
    });
  }

  void _validateUsernameLive() {
    setState(() {
      final value = _usernameController.text;
      if (value.isEmpty) {
        _usernameError = '';
      } else if (value.length < 3) {
        _usernameError = 'Username must be at least 3 characters (${value.length}/3)';
      } else {
        _usernameError = '';
      }
    });
  }

  void _validatePasswordLive() {
    setState(() {
      final value = _passwordController.text;
      if (value.isEmpty) {
        _passwordError = '';
      } else if (value.length < 8) {
        _passwordError = 'Password must be at least 8 characters (${value.length}/8)';
      } else {
        _passwordError = '';
      }
    });
  }

  void _validateNameLive() {
    setState(() {
      final value = _nameController.text;
      if (value.isEmpty) {
        _nameError = '';
      } else if (value.trim().length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else {
        _nameError = '';
      }
    });
  }

  void _validatePhoneLive() {
    setState(() {
      final value = _phoneController.text;
      if (value.isEmpty) {
        _phoneError = '';
      } else {
        final phoneDigits = value.replaceAll(RegExp(r'[^\d]'), '');
        if (phoneDigits.length < 10) {
          _phoneError = 'Enter a valid phone number (at least 10 digits)';
        } else {
          _phoneError = '';
        }
      }
    });
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _emailController.text.isNotEmpty &&
            _emailError.isEmpty &&
            _usernameController.text.isNotEmpty &&
            _usernameError.isEmpty &&
            _passwordController.text.length >= 8 &&
            _passwordError.isEmpty &&
            _nameController.text.isNotEmpty &&
            _nameError.isEmpty &&
            _phoneController.text.isNotEmpty &&
            _phoneError.isEmpty;
      case 1:
        return _selectedService.isNotEmpty;
      case 2:
        return _idCaptured && _selfieCaptured && _verificationPassed;
      case 3:
        return true;
      default:
        return false;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 3) return 'Must be at least 3 characters';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length < 2) return 'Must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final phoneDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _fadeController.reset();
      _fadeController.forward();
      HapticFeedback.mediumImpact();
    } else {
      await _saveProviderProfile();
    }
  }

  Future<void> _saveProviderProfile() async {
    // Final validation before submission
    _validateEmailLive();
    _validateUsernameLive();
    _validatePasswordLive();
    _validateNameLive();
    _validatePhoneLive();
    
    if (_emailError.isNotEmpty || _usernameError.isNotEmpty || _passwordError.isNotEmpty || 
        _nameError.isNotEmpty || _phoneError.isNotEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _authService.signup(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        accountType: 'service_provider',
        phoneNumber: _phoneController.text.trim(),
        serviceType: _selectedService.toLowerCase().replaceAll(' ', '_'),
        bio: _bioController.text.trim(),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushNamedAndRemoveUntil('/provider_home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Check if error is about duplicate email
        if (errorMessage.toLowerCase().contains('email') || 
            errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('already exists') ||
            errorMessage.toLowerCase().contains('registered')) {
          errorMessage = 'This email is already registered. Please use a different email or login.';
          setState(() => _emailError = errorMessage);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: $errorMessage'),
            backgroundColor: AppDesign.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _idScanning = true;
      _idImageFile = File(picked.path);
    });
    HapticFeedback.lightImpact();

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

    // Auto-trigger verification if selfie already captured
    if (_selfieCaptured && _selfieFile != null) {
      await _runFaceVerification();
    }
  }

  Future<void> _startSelfieCapture() async {
    setState(() => _selfieCapturing = true);
    HapticFeedback.lightImpact();

    final File? selfieFile = await Navigator.of(
      context,
    ).push<File>(MaterialPageRoute(builder: (_) => const SelfieCameraScreen()));

    if (!mounted) return;

    if (selfieFile == null) {
      setState(() => _selfieCapturing = false);
      return;
    }

    setState(() {
      _selfieCapturing = false;
      _selfieFile = selfieFile;
      _selfieCaptured = true;
    });
    HapticFeedback.heavyImpact();
    _celebrationController.forward(from: 0);

    // Auto-trigger verification if ID already captured
    if (_idCaptured && _idImageFile != null) {
      await _runFaceVerification();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/public/WhatsApp Image 2026-02-12 at 2.12.53 PM.jpeg',
              fit: BoxFit.cover,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildProgressBar(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        physics: const BouncingScrollPhysics(),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final titles = ['Profile', 'Service', 'Verify', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _previousStep,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                titles[_currentStep],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color:
                    isActive
                        ? AppDesign.onboardingAccent
                        : Colors.white.withValues(alpha: 0.2),
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
        return _buildVerificationStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Basic Info ─────────────────────────────────────────────────
  Future<void> _runFaceVerification() async {
    if (_idImageFile == null || _selfieFile == null) return;

    debugPrint('[FaceVerif] Starting verification...');
    debugPrint('[FaceVerif] ID file: ${_idImageFile!.path}');
    debugPrint('[FaceVerif] Selfie file: ${_selfieFile!.path}');

    setState(() {
      _verificationError = null;
      _verificationPassed = false;
    });

    try {
      debugPrint('[FaceVerif] Calling backend...');
      final result = await FaceVerificationService.instance.verifyFacesWithName(
        idImageFile: _idImageFile!,
        selfieFile: _selfieFile!,
        providerId: SessionStore.instance.userId ?? '',
        expectedName: _nameController.text.trim(),
      );

      debugPrint('[FaceVerif] Response: $result');

      final passes =
          result['passes_threshold'] == true || result['verified'] == true;

      debugPrint('[FaceVerif] Passes: $passes');

      setState(() {
        _verificationPassed = passes;
        _verificationError =
            passes
                ? null
                : 'Face verification failed. Confidence: '
                    '${((result['confidence'] as num? ?? 0) * 100).toStringAsFixed(0)}%. '
                    'Please retake your selfie or use a clearer ID photo.';
      });
    } catch (e) {
      debugPrint('[FaceVerif] ERROR: $e');
      setState(() {
        _verificationPassed = false;
        _verificationError = 'Verification error: ${e.toString()}';
      });
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          "Let's Get\nStarted",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 28),

        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                children: [
                  _glassFieldWithLiveError(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'your@email.com',
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) => _onEmailChanged(),
                  ),
                  const SizedBox(height: 16),
                  _glassFieldWithLiveError(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Choose a unique username',
                    icon: LucideIcons.atSign,
                    errorText: _usernameError,
                    onChanged: (_) => _validateUsernameLive(),
                  ),
                  const SizedBox(height: 16),
                  _glassFieldWithLiveError(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'At least 8 characters',
                    icon: LucideIcons.lock,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: (_) => _validatePasswordLive(),
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _glassFieldWithLiveError(
                    controller: _nameController,
                    label: 'Full Legal Name',
                    hint: 'As it appears on your ID',
                    icon: LucideIcons.user,
                    errorText: _nameError,
                    onChanged: (_) => _validateNameLive(),
                  ),
                  const SizedBox(height: 16),
                  _glassFieldWithLiveError(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+20 xxx xxx xxxx',
                    icon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: (_) => _validatePhoneLive(),
                  ),
                  const SizedBox(height: 16),
                  _glassField(
                    controller: _bioController,
                    label: 'Short Bio',
                    hint: 'Tell travelers why they should choose you...',
                    icon: LucideIcons.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 2: Service Type ───────────────────────────────────────────────

  Widget _buildServiceTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          "What's Your\nExpertise?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your primary service',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 28),

        ...List.generate(_services.length, (index) {
          final service = _services[index];
          final isSelected = _selectedService == service['name'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedService = service['name'] as String);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color:
                          isSelected
                              ? AppDesign.onboardingAccent.withValues(
                                alpha: 0.2,
                              )
                              : Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppDesign.onboardingAccent
                                : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppDesign.onboardingAccent.withValues(
                                      alpha: 0.2,
                                    )
                                    : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              service['icon'] as String,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['name'] as String,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? AppDesign.onboardingAccent
                                          : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service['desc'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
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
                                    ? AppDesign.onboardingAccent
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppDesign.onboardingAccent
                                      : Colors.white.withValues(alpha: 0.3),
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
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 3: Verification ───────────────────────────────────────────────

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Verify Your\nIdentity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help travelers trust you',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 28),

        // ID Scanner
        _buildIdScannerCard(),
        const SizedBox(height: 16),

        // Selfie Capture
        _buildSelfieCaptureCard(),
        const SizedBox(height: 24),

        // Security note
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppDesign.onboardingAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.shield,
                      color: AppDesign.onboardingAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your data is encrypted',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We never share your personal information',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIdScannerCard() {
    return GestureDetector(
      onTap: _idCaptured ? null : _startIdScan,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color:
                  _idCaptured
                      ? AppDesign.success.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color:
                    _idCaptured
                        ? AppDesign.success
                        : _idScanning
                        ? AppDesign.onboardingAccent
                        : Colors.white.withValues(alpha: 0.15),
                width: _idCaptured || _idScanning ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (!_idCaptured)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.creditCard,
                          size: 40,
                          color:
                              _idScanning
                                  ? AppDesign.onboardingAccent
                                  : Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _idScanning ? 'Scanning...' : 'Tap to scan ID',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                _idScanning
                                    ? AppDesign.onboardingAccent
                                    : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        if (_idScanning) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _scanProgress,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppDesign.onboardingAccent,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (_idCaptured)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppDesign.success.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            size: 36,
                            color: AppDesign.success,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ID Verified!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Government ID captured successfully',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Label badge
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
                              ? AppDesign.success.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _idCaptured
                              ? LucideIcons.checkCircle
                              : LucideIcons.creditCard,
                          size: 14,
                          color:
                              _idCaptured
                                  ? AppDesign.success
                                  : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Government ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _idCaptured
                                    ? AppDesign.success
                                    : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieCaptureCard() {
    return GestureDetector(
      onTap: _selfieCaptured ? null : _startSelfieCapture,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color:
                  _selfieCaptured
                      ? AppDesign.success.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color:
                    _selfieCaptured
                        ? AppDesign.success
                        : _selfieCapturing
                        ? AppDesign.onboardingAccent
                        : Colors.white.withValues(alpha: 0.15),
                width: _selfieCaptured || _selfieCapturing ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (!_selfieCaptured)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _selfieCapturing
                                      ? AppDesign.onboardingAccent
                                      : Colors.white.withValues(alpha: 0.2),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.user,
                            size: 40,
                            color:
                                _selfieCapturing
                                    ? AppDesign.onboardingAccent
                                    : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selfieCapturing
                              ? 'Hold still...'
                              : 'Tap to take selfie',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                _selfieCapturing
                                    ? AppDesign.onboardingAccent
                                    : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selfieCaptured)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppDesign.success.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            size: 32,
                            color: AppDesign.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Selfie Captured!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Face verification complete',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Label badge
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
                              ? AppDesign.success.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selfieCaptured
                              ? LucideIcons.checkCircle
                              : LucideIcons.camera,
                          size: 14,
                          color:
                              _selfieCaptured
                                  ? AppDesign.success
                                  : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Selfie Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _selfieCaptured
                                    ? AppDesign.success
                                    : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 4: Review ─────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Success header
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppDesign.success.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppDesign.success.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 40,
                  color: AppDesign.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "You're all set! 🎉",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your profile before going live',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Profile summary card
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppDesign.onboardingAccent.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          size: 28,
                          color: AppDesign.onboardingAccent,
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.onboardingAccent.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedService.isEmpty
                                    ? 'Service Type'
                                    : _selectedService,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppDesign.onboardingAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppDesign.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 20,
                          color: AppDesign.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      _buildStatItem(
                        '📞',
                        'Phone',
                        _phoneController.text.isEmpty ? 'Not set' : 'Verified',
                      ),
                      _buildStatItem(
                        '🪪',
                        'ID',
                        _idCaptured ? 'Verified' : 'Pending',
                      ),
                      _buildStatItem(
                        '🤳',
                        'Selfie',
                        _selfieCaptured ? 'Verified' : 'Pending',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_bioController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.fileText,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _bioController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    final isVerified = value == 'Verified';
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isVerified
                      ? AppDesign.success
                      : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Button ──────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    final bool canProceed = _canContinue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: Column(
        children: [
          if (_currentStep == 0 && !canProceed && (_emailError.isNotEmpty || _usernameError.isNotEmpty || _passwordError.isNotEmpty || _nameError.isNotEmpty || _phoneError.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Please fix the errors above to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: AppDesign.danger,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canProceed && !_isLoading ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.onboardingAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppDesign.onboardingAccent.withValues(
                  alpha: 0.3,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 3
                                  ? 'Start Accepting Requests'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == 3
                                  ? LucideIcons.rocket
                                  : LucideIcons.arrowRight,
                              size: 20,
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Glass field helpers ────────────────────────────────────────────────

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        errorStyle: const TextStyle(color: AppDesign.danger, fontSize: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
        ),
        suffixIcon:
            suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: suffix,
                  )
                : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppDesign.onboardingAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDesign.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _glassFieldWithLiveError({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    int maxLines = 1,
    required String errorText,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            errorStyle: const TextStyle(color: AppDesign.danger, fontSize: 12),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
            ),
            suffixIcon:
                suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: suffix,
                      )
                    : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppDesign.onboardingAccent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppDesign.danger),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppDesign.danger, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText,
                    style: TextStyle(color: AppDesign.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}