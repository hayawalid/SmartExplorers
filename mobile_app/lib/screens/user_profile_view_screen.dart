import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/profile_api_service.dart';

/// View another user's profile — adapts layout for traveler vs provider.
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? accountType; // 'traveler' | 'service_provider'

  const UserProfileViewScreen({
    Key? key,
    required this.userId,
    this.displayName,
    this.accountType,
  }) : super(key: key);

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final ProfileApiService _profileService = ProfileApiService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  bool _isProvider = false;

  @override
  void initState() {
    super.initState();
    _isProvider = widget.accountType == 'service_provider';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (_isProvider) {
        final profile = await _profileService.getProviderProfile(widget.userId);
        final reviews = await _profileService.getProviderReviews(widget.userId);
        setState(() {
          _profile = profile;
          _reviews = reviews;
          _loading = false;
        });
      } else {
        final profile = await _profileService.getTravelerProfile(widget.userId);
        final reviews = await _profileService.getUserReviews(widget.userId);
        setState(() {
          _profile = profile;
          _reviews = reviews;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
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
        backgroundColor: bg,
        elevation: 0,
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
      ),
      body:
          _loading
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
                    const SizedBox(height: 20),
                    if (_isProvider)
                      _buildProviderInfo(isDark, text, sub, card),
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
    final name =
        _profile?['full_name'] ??
        _profile?['business_name'] ??
        widget.displayName ??
        'User';
    final bio = _profile?['bio'] ?? _profile?['description'] ?? '';
    final isVerified = _profile?['is_verified'] == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: (_isProvider
                    ? AppDesign.navProfile
                    : AppDesign.navExplore)
                .withValues(alpha: 0.12),
            child: Icon(
              _isProvider ? LucideIcons.briefcase : LucideIcons.user,
              size: 38,
              color: _isProvider ? AppDesign.navProfile : AppDesign.navExplore,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.badgeCheck,
                  size: 20,
                  color: AppDesign.success,
                ),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: sub, height: 1.4),
            ),
          ],
          if (_isProvider) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Rating', '${_profile?['rating'] ?? 'N/A'}', text, sub),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.white10 : AppDesign.lightGrey,
                ),
                _stat('Reviews', '${_reviews.length}', text, sub),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.white10 : AppDesign.lightGrey,
                ),
                _stat(
                  'Bookings',
                  '${_profile?['total_bookings'] ?? 0}',
                  text,
                  sub,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Trips', '${_profile?['trips_count'] ?? 0}', text, sub),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.white10 : AppDesign.lightGrey,
                ),
                _stat('Reviews', '${_reviews.length}', text, sub),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderInfo(bool isDark, Color text, Color sub, Color card) {
    final services = _profile?['service_types'] as List<dynamic>? ?? [];
    final languages = _profile?['languages'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          const SizedBox(height: 10),
          if (services.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  services
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.navConcierge.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppDesign.navConcierge,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            )
          else
            Text('Not specified', style: TextStyle(fontSize: 14, color: sub)),
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  languages
                      .map(
                        (l) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.navExplore.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppDesign.navExplore,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark, Color text, Color sub, Color card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews
            .take(10)
            .map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      isDark
                          ? []
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppDesign.navExplore.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            (r['author_name'] ?? r['reviewer_name'] ?? 'U')[0]
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppDesign.navExplore,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r['author_name'] ?? r['reviewer_name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: text,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              LucideIcons.star,
                              size: 14,
                              color:
                                  i < ((r['rating'] as num?)?.toInt() ?? 5)
                                      ? const Color(0xFFFFC107)
                                      : (isDark
                                          ? Colors.white24
                                          : AppDesign.lightGrey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r['text'] ?? r['content'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.white70 : AppDesign.eerieBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _stat(String label, String value, Color text, Color sub) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }
}
