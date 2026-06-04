import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/auth_api_service.dart';
import '../../widgets/smart_explorers_logo.dart';

/// Traveler signup – 2-step cinematic glass flow
/// Step 1: Name, Email, Password, Date of Birth, Gender
/// Step 2: Interests (pick ≥ 3)
class TravelerProfileSetupScreen extends StatefulWidget {
  const TravelerProfileSetupScreen({super.key});

  @override
  State<TravelerProfileSetupScreen> createState() =>
      _TravelerProfileSetupScreenState();
}

class _TravelerProfileSetupScreenState extends State<TravelerProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _dateOfBirth;
  String _selectedGender = '';
  final List<String> _selectedInterests = [];
  bool _isLoading = false;
  final AuthApiService _authService = AuthApiService();

  // Live validation error messages
  String _nameError = '';
  String _emailError = '';
  String _passwordError = '';

  // Debounce timer for email uniqueness check
  Timer? _emailDebounceTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Add live validation listeners
    _nameController.addListener(_validateNameLive);
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_validatePasswordLive);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateNameLive);
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_validatePasswordLive);
    _emailDebounceTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _authService.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _validateEmailLive();
    _debounceEmailUniquenessCheck();
  }

  // Live validation methods
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

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 2 &&
            _emailController.text.isNotEmpty &&
            _emailError.isEmpty &&
            _passwordController.text.length >= 8 &&
            _dateOfBirth != null &&
            _selectedGender.isNotEmpty;
      case 1:
        return _selectedInterests.length >= 3;
      default:
        return false;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  Future<void> _nextStep() async {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _fadeController.reset();
      _fadeController.forward();
      HapticFeedback.mediumImpact();
    } else {
      await _createAccount();
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

  Future<void> _createAccount() async {
    // Final validation before submission
    _validateNameLive();
    _validateEmailLive();
    _validatePasswordLive();
    
    if (_nameError.isNotEmpty || _emailError.isNotEmpty || _passwordError.isNotEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final username = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      await _authService.signup(
        email: email,
        username: username,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        accountType: 'traveler',
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T').first,
        gender: _selectedGender,
        travelInterests: _selectedInterests,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppDesign.onboardingAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1A1A1A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
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
                        child:
                            _currentStep == 0
                                ? _buildPersonalInfoStep()
                                : _buildInterestsStep(),
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

  Widget _buildHeader() {
    final titles = ['Personal Info', 'Interests'];
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
                'Step ${_currentStep + 1} of 2',
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
        children: List.generate(2, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4,
              margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
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

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Create Your\nAccount',
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
          "Let's personalize your journey",
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
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your name',
                    icon: LucideIcons.user,
                    errorText: _nameError,
                    onChanged: (_) => _validateNameLive(),
                  ),
                  const SizedBox(height: 16),
                  _glassFieldWithLiveError(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) => _onEmailChanged(),
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
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: _glassFieldDisplay(
                      label: 'Date of Birth',
                      value: _dateOfBirth != null
                          ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                          : '',
                      hint: 'Select your date of birth',
                      icon: LucideIcons.calendar,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _glassDropdown(
                    label: 'Gender',
                    hint: 'Select gender',
                    icon: LucideIcons.users,
                    value: _selectedGender.isEmpty ? null : _selectedGender,
                    items: _genderOptions,
                    onChanged: (val) => setState(() => _selectedGender = val ?? ''),
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

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'What Excites\nYou?',
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
          'Pick at least 3 interests',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _selectedInterests.length >= 3
                    ? AppDesign.onboardingAccent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Text(
                '${_selectedInterests.length} selected (need 3 minimum)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _selectedInterests.length >= 3
                      ? AppDesign.onboardingAccent
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest['name']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest['name']);
                  } else {
                    _selectedInterests.add(interest['name'] as String);
                  }
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: isSelected
                          ? AppDesign.onboardingAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: isSelected
                            ? AppDesign.onboardingAccent
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(interest['icon'] as String, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          interest['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppDesign.onboardingAccent : Colors.white,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomButton() {
    final bool canProceed = _canContinue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: Column(
        children: [
          if (_currentStep == 0 && (!canProceed))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Please fill all fields correctly to continue',
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
                disabledBackgroundColor: AppDesign.onboardingAccent.withValues(alpha: 0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
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
                          _currentStep == 1 ? 'Start Exploring' : 'Continue',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 1 ? LucideIcons.sparkles : LucideIcons.arrowRight,
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

  Widget _glassFieldWithLiveError({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
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
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
            ),
            suffixIcon: suffix != null
                ? Padding(padding: const EdgeInsets.only(right: 16), child: suffix)
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
              borderSide: const BorderSide(color: AppDesign.onboardingAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppDesign.danger),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  Widget _glassFieldDisplay({
    required String label,
    required String value,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.isEmpty ? Colors.white.withValues(alpha: 0.3) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronDown, size: 18, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _glassDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
              ),
              Text(
                hint,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
              ),
            ],
          ),
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(LucideIcons.chevronDown, color: Colors.white.withValues(alpha: 0.5), size: 18),
          ),
          dropdownColor: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Icon(icon, color: AppDesign.onboardingAccent, size: 20),
                  ),
                  Text(item, style: const TextStyle(color: Colors.white)),
                ],
              );
            }).toList();
          },
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}