import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/session_store.dart';
import '../services/profile_api_service.dart';
import '../services/api_config.dart';

/// Tab 3: Profile Screen - Account Management
/// Header card, stats row, settings list, dark mode toggle
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final ProfileApiService _profileService = ProfileApiService();

  String _name = 'Sarah Johnson';
  String _username = '@sarahtravels';
  String _bio = 'Solo traveler | History enthusiast';
  int _trips = 12;
  int _reviews = 24;
  int _photos = 89;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final username =
          SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      setState(() {
        _name = user['full_name'] ?? _name;
        _username = '@${user['username'] ?? 'sarahtravels'}';
        _bio = user['bio'] ?? _bio;
        _trips = user['trips_count'] ?? _trips;
        _reviews = user['reviews_count'] ?? _reviews;
        _photos = user['photos_count'] ?? _photos;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : AppDesign.pureWhite;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 100),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(LucideIcons.user, color: AppDesign.electricCobalt, size: 24),
                  const SizedBox(width: 10),
                  Text('Profile',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: text)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.settings, color: sub, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Avatar + info card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card,
                borderRadius: AppDesign.borderRadius,
                boxShadow: isDark ? [] : AppDesign.softShadow,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppDesign.electricCobalt.withOpacity(0.12),
                    child: const Icon(LucideIcons.user, size: 36, color: AppDesign.electricCobalt),
                  ),
                  const SizedBox(height: 14),
                  Text(_name,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 4),
                  Text(_username,
                      style: TextStyle(fontSize: 14, color: sub)),
                  const SizedBox(height: 6),
                  Text(_bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: sub, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('Trips', '$_trips', text, sub),
                      _divider(isDark),
                      _stat('Reviews', '$_reviews', text, sub),
                      _divider(isDark),
                      _stat('Photos', '$_photos', text, sub),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings list
            _sectionTitle('Account', text),
            _tile(isDark, card, text, sub, LucideIcons.userCog, 'Edit Profile'),
            _tile(isDark, card, text, sub, LucideIcons.shieldCheck, 'Verification'),
            _tile(isDark, card, text, sub, LucideIcons.lock, 'Privacy & Security'),

            const SizedBox(height: 16),
            _sectionTitle('Preferences', text),
            _tile(isDark, card, text, sub, LucideIcons.globe, 'Language'),
            _tile(isDark, card, text, sub, LucideIcons.bellRing, 'Notifications'),
            _tile(isDark, card, text, sub, LucideIcons.accessibility, 'Accessibility'),

            const SizedBox(height: 16),
            _sectionTitle('Support', text),
            _tile(isDark, card, text, sub, LucideIcons.helpCircle, 'Help Center'),
            _tile(isDark, card, text, sub, LucideIcons.messageSquare, 'Send Feedback'),
            _tile(isDark, card, text, sub, LucideIcons.logOut, 'Sign Out',
                isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color text, Color sub) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: sub)),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? Colors.white10 : AppDesign.lightGrey,
    );
  }

  Widget _sectionTitle(String title, Color text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppDesign.midGrey,
              letterSpacing: 0.6)),
    );
  }

  Widget _tile(bool isDark, Color card, Color text, Color sub,
      IconData icon, String label,
      {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppDesign.danger.withOpacity(0.1)
                : (isDark ? AppDesign.darkGrey : AppDesign.offWhite),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20,
              color: isDestructive ? AppDesign.danger : AppDesign.electricCobalt),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppDesign.danger : text)),
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: sub),
        onTap: () {},
      ),
    );
  }
}
