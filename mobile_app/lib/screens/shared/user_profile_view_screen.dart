// ============================================================================
// user_profile_view_screen.dart
// View another user's profile. For providers: shows action sheet to
// Review or Book (send request). Glassmorphic, no gradients.
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/smart_explorers_logo.dart';
import 'package:mobile_app/services/profile_api_service.dart';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/screens/shared/write_review_screen.dart';

/// View another user's profile — adapts layout for traveler vs provider.
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? accountType; // 'traveler' | 'service_provider'

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.accountType,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final ProfileApiService _profileService = ProfileApiService();
  final ServicesApiService _servicesService = ServicesApiService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  bool _isProvider = false;
  bool _bookingInProgress = false;

  @override
  void initState() {
    super.initState();
    _isProvider = widget.accountType == 'service_provider';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (_isProvider) {
        final results = await Future.wait([
          _profileService.getProviderProfile(widget.userId),
          _profileService.getProviderReviews(widget.userId),
          _servicesService.getProviderServices(
            providerId: widget.userId,
          ),
        ]);
        if (!mounted) return;
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _reviews = (results[1] as List).cast<Map<String, dynamic>>();
          _services = (results[2] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        final results = await Future.wait([
          _profileService.getTravelerProfile(widget.userId),
          _profileService.getUserReviews(widget.userId),
        ]);
        if (!mounted) return;
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _reviews = (results[1] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _profileService.dispose();
    _servicesService.dispose();
    super.dispose();
  }

  /// Shows bottom sheet: Review or View & Book
  void _showProviderActionSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final providerName =
        _profile?['full_name'] ?? _profile?['business_name'] ?? widget.displayName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppDesign.cardDark.withOpacity(0.95)
                  : Colors.white.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppDesign.lightGrey,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDark ? Colors.white24 : AppDesign.lightGrey,
                    ),
                  ),
                ),
                _Avatar(label: providerName?.toString() ?? '?', size: 56),
                const SizedBox(height: 12),
                Text(
                  providerName?.toString() ?? 'Provider',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'What would you like to do?',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppDesign.midGrey,
                  ),
                ),
                const SizedBox(height: 24),
                // Write Review
                _ActionSheetButton(
                  icon: LucideIcons.star,
                  label: 'Write a Review',
                  subtitle: 'Share your experience with this provider',
                  color: const Color(0xFFFFC107),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openWriteReview(providerName?.toString());
                  },
                ),
                const SizedBox(height: 12),
                // View Profile & Book
                _ActionSheetButton(
                  icon: LucideIcons.calendarPlus,
                  label: 'View Services & Book',
                  subtitle: 'Browse services and send a booking request',
                  color: AppDesign.navConcierge,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openBookingSheet(providerName?.toString());
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openWriteReview(String? providerName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          providerId: widget.userId,
          providerName: providerName,
        ),
      ),
    );
    if (result == true) _loadProfile();
  }

  void _openBookingSheet(String? providerName) {
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No services available from this provider'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BookingSheet(
        providerId: widget.userId,
        providerName: providerName ?? 'Provider',
        services: _services,
        isDark: isDark,
        servicesService: _servicesService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppDesign.eerieBlack.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
            const SizedBox(width: 8),
            Text(
              widget.displayName ?? 'Profile',
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_isProvider && !_loading && _profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(LucideIcons.moreHorizontal, color: text),
                onPressed: _showProviderActionSheet,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.userX, size: 48, color: sub),
                      const SizedBox(height: 12),
                      Text(
                        'Profile not found',
                        style: TextStyle(color: sub, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    children: [
                      _buildProfileCard(isDark, text, sub, card),
                      if (_isProvider) ...[
                        const SizedBox(height: 16),
                        // CTA buttons
                        Row(
                          children: [
                            Expanded(
                              child: _GlassButton(
                                icon: LucideIcons.star,
                                label: 'Write Review',
                                color: const Color(0xFFFFC107),
                                isDark: isDark,
                                onTap: () => _openWriteReview(
                                  _profile?['full_name']?.toString() ??
                                      _profile?['business_name']?.toString() ??
                                      widget.displayName,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GlassButton(
                                icon: LucideIcons.calendarPlus,
                                label: 'Book Service',
                                color: AppDesign.navConcierge,
                                isDark: isDark,
                                onTap: () => _openBookingSheet(
                                  _profile?['full_name']?.toString() ??
                                      _profile?['business_name']?.toString() ??
                                      widget.displayName,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProviderInfo(isDark, text, sub, card),
                      ],
                      if (_reviews.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildReviewsSection(isDark, text, sub, card),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(bool isDark, Color text, Color sub, Color card) {
    final name = _profile?['full_name'] ??
        _profile?['business_name'] ??
        widget.displayName ??
        'User';
    final bio = _profile?['bio'] ?? _profile?['description'] ?? '';
    final isVerified = _profile?['is_verified'] == true;

    return ClipRRect(
      borderRadius: AppDesign.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: AppDesign.borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppDesign.lightGrey,
            ),
          ),
          child: Column(
            children: [
              _Avatar(label: name.toString(), size: 64),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.badgeCheck,
                      size: 20,
                      color: AppDesign.navSafety,
                    ),
                  ],
                ],
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bio.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: sub, height: 1.4),
                ),
              ],
              if (_isProvider) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Rating', '${_profile?['rating'] ?? 'N/A'}', text, sub),
                    Container(width: 1, height: 32, color: isDark ? Colors.white10 : AppDesign.lightGrey),
                    _stat('Reviews', '${_reviews.length}', text, sub),
                    Container(width: 1, height: 32, color: isDark ? Colors.white10 : AppDesign.lightGrey),
                    _stat('Bookings', '${_profile?['total_bookings'] ?? 0}', text, sub),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Trips', '${_profile?['trips_count'] ?? 0}', text, sub),
                    Container(width: 1, height: 32, color: isDark ? Colors.white10 : AppDesign.lightGrey),
                    _stat('Reviews', '${_reviews.length}', text, sub),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfo(bool isDark, Color text, Color sub, Color card) {
    final services = _profile?['service_types'] as List<dynamic>? ?? [];
    final languages = _profile?['languages'] as List<dynamic>? ?? [];

    return ClipRRect(
      borderRadius: AppDesign.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: AppDesign.borderRadius,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
              const SizedBox(height: 10),
              if (services.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppDesign.navConcierge.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppDesign.navConcierge.withOpacity(0.2)),
                          ),
                          child: Text(
                            s.toString(),
                            style: const TextStyle(fontSize: 13, color: AppDesign.navConcierge, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Text('Not specified', style: TextStyle(fontSize: 14, color: sub)),
              if (languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Languages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languages
                      .map(
                        (l) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppDesign.navExplore.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppDesign.navExplore.withOpacity(0.2)),
                          ),
                          child: Text(
                            l.toString(),
                            style: const TextStyle(fontSize: 13, color: AppDesign.navExplore, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark, Color text, Color sub, Color card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text)),
        const SizedBox(height: 12),
        ..._reviews.take(10).map(
          (r) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : AppDesign.lightGrey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppDesign.navExplore.withOpacity(0.12),
                          child: Text(
                            (r['author_name'] ?? r['reviewer_name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppDesign.navExplore),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r['author_name'] ?? r['reviewer_name'] ?? 'User',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              LucideIcons.star,
                              size: 14,
                              color: i < ((r['rating'] as num?)?.toInt() ?? 5)
                                  ? const Color(0xFFFFC107)
                                  : (isDark ? Colors.white24 : AppDesign.lightGrey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r['text'] ?? r['content'] ?? '',
                      style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : AppDesign.eerieBlack),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color text, Color sub) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }
}

// ── Booking Sheet ──────────────────────────────────────────────────────────
class _BookingSheet extends StatefulWidget {
  final String providerId;
  final String providerName;
  final List<Map<String, dynamic>> services;
  final bool isDark;
  final ServicesApiService servicesService;

  const _BookingSheet({
    required this.providerId,
    required this.providerName,
    required this.services,
    required this.isDark,
    required this.servicesService,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _selectedServiceIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;

    final selected = widget.services[_selectedServiceIndex];
    setState(() => _submitting = true);

    try {
      await widget.servicesService.createBooking(
        userId: userId,
        serviceId: selected['_id']?.toString() ?? '',
        providerId: widget.providerId,
        specialRequests: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Booking request sent! Provider will respond shortly.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppDesign.navSafety,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppDesign.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = AppDesign.midGrey;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppDesign.cardDark.withOpacity(0.97)
                : Colors.white.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : AppDesign.lightGrey,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDark ? Colors.white24 : AppDesign.lightGrey,
                    ),
                  ),
                ),
                Text(
                  'Book a Service',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text),
                ),
                const SizedBox(height: 4),
                Text(
                  'from ${widget.providerName}',
                  style: const TextStyle(fontSize: 14, color: AppDesign.midGrey),
                ),
                const SizedBox(height: 20),
                Text('Select service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                const SizedBox(height: 10),
                ...widget.services.asMap().entries.map((e) {
                  final i = e.key;
                  final svc = e.value;
                  final isSelected = i == _selectedServiceIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedServiceIndex = i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppDesign.navConcierge.withOpacity(0.1)
                                : (isDark ? Colors.white.withOpacity(0.04) : AppDesign.offWhite),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppDesign.navConcierge.withOpacity(0.4)
                                  : (isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppDesign.navConcierge.withOpacity(isSelected ? 0.2 : 0.1),
                                ),
                                child: Icon(
                                  LucideIcons.briefcase,
                                  size: 18,
                                  color: AppDesign.navConcierge,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      svc['service_name']?.toString() ?? 'Service',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: text,
                                      ),
                                    ),
                                    if ((svc['service_type'] ?? '').isNotEmpty)
                                      Text(
                                        svc['service_type'].toString().replaceAll('_', ' '),
                                        style: const TextStyle(fontSize: 12, color: AppDesign.midGrey),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(LucideIcons.checkCircle, color: AppDesign.navConcierge, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text('Additional notes (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      style: TextStyle(fontSize: 14, color: text),
                      decoration: InputDecoration(
                        hintText: 'Anything specific you need...',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.04) : AppDesign.offWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _sendRequest,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.send, size: 18),
                    label: Text(_submitting ? 'Sending...' : 'Send Booking Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.navConcierge,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
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
}

// ── Shared Widgets ─────────────────────────────────────────────────────────
class _ActionSheetButton extends StatelessWidget {
  const _ActionSheetButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : color.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppDesign.eerieBlack,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppDesign.midGrey),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, this.size = 52});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppDesign.navConcierge,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}