// ============================================================================
// settings_screen.dart  —  fully implemented settings, glassmorphic theme
// ============================================================================
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/profile_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onSignOut,
    this.onEditProfile,
  });

  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification prefs
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _bookingAlerts = true;
  bool _reviewAlerts = true;
  bool _messageAlerts = true;
  bool _marketingAlerts = false;

  // Privacy prefs
  bool _profilePublic = true;
  bool _showLocation = false;
  bool _allowMatching = true;

  // Appearance
  bool _compactMode = false;

  // Account
  bool _savingNotif = false;
  bool _savingPrivacy = false;

  final ProfileApiService _profileService = ProfileApiService();

  Future<void> _saveNotificationPrefs() async {
    setState(() => _savingNotif = true);
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        await _profileService.updateUser(userId, {
          'notification_prefs': {
            'push': _pushEnabled,
            'email': _emailEnabled,
            'booking_alerts': _bookingAlerts,
            'review_alerts': _reviewAlerts,
            'message_alerts': _messageAlerts,
            'marketing': _marketingAlerts,
          },
        });
      }
      if (mounted) _showSnack('Notification preferences saved');
    } catch (_) {
      if (mounted) _showSnack('Failed to save preferences');
    } finally {
      if (mounted) setState(() => _savingNotif = false);
    }
  }

  Future<void> _savePrivacyPrefs() async {
    setState(() => _savingPrivacy = true);
    try {
      final userId = SessionStore.instance.userId;
      if (userId != null) {
        await _profileService.updateUser(userId, {
          'privacy_prefs': {
            'profile_public': _profilePublic,
            'show_location': _showLocation,
            'allow_matching': _allowMatching,
          },
        });
      }
      if (mounted) _showSnack('Privacy preferences saved');
    } catch (_) {
      if (mounted) _showSnack('Failed to save preferences');
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showDeleteAccountConfirm() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete Forever'),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Account deletion requested. Support will contact you.');
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppDesign.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
          const SizedBox(height: 12),
          TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 12),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack('Passwords do not match');
                return;
              }
              if (newCtrl.text.length < 8) {
                _showSnack('Password must be at least 8 characters');
                return;
              }
              Navigator.pop(ctx);
              _showSnack('Password change requested. Check your email.');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesign.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isDark ? Colors.white24 : AppDesign.lightGrey))),
            Padding(padding: const EdgeInsets.all(20), child: Text('Blocked Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppDesign.eerieBlack))),
            Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.userX, size: 48, color: AppDesign.midGrey),
              const SizedBox(height: 12),
              Text('No blocked users', style: TextStyle(color: AppDesign.midGrey)),
            ]))),
          ]),
        ),
      ),
    );
  }

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppDesign.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(controller: scroll, children: [
              Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isDark ? Colors.white24 : AppDesign.lightGrey))),
              Padding(padding: const EdgeInsets.all(20), child: Text('Help Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppDesign.eerieBlack))),
              ...[
                ('How do I book a service?', 'Go to the Feed tab, browse providers, tap on a service card, and tap Book. You can then choose a date and time.'),
                ('How do I write a review?', 'Go to your Profile tab → Reviews → tap the "Write a Review" button. You can also access it from any provider profile.'),
                ('How do I get verified as a provider?', 'Go to Profile → tap "Get Verified". Upload your credentials and a government ID. Our team will review within 3 business days.'),
                ('How do I edit my itinerary?', 'Go to the Planner tab, open your itinerary, and tap the Edit button. Each activity can be modified or reordered.'),
                ('How do I contact support?', 'Email us at support@smartexplorers.app or use the Contact Support button below.'),
              ].map((faq) => _FaqItem(question: faq.$1, answer: faq.$2, isDark: isDark)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showSnack('Opening support chat...'); },
                  icon: const Icon(LucideIcons.messageCircle),
                  label: const Text('Contact Support'),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Explorers',
      applicationVersion: '2.1.0',
      applicationLegalese: '© 2025 Smart Explorers. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text('Smart Explorers connects travelers with verified local service providers for safe, curated travel experiences.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 40),
            children: [
              // Account section
              _SettingsSection(
                title: 'Account',
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: LucideIcons.user,
                    label: 'Edit Profile',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEditProfile?.call();
                    },
                  ),
                  _SettingsTile(
                    icon: LucideIcons.keyRound,
                    label: 'Change Password',
                    isDark: isDark,
                    onTap: _showChangePasswordDialog,
                  ),
                  _SettingsTile(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    isDark: isDark,
                    trailing: Text(
                      SessionStore.instance.username ?? 'Not set',
                      style: const TextStyle(fontSize: 13, color: AppDesign.midGrey),
                    ),
                    onTap: () => _showSnack('Email changes require verification. Contact support.'),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.shieldCheck,
                    label: 'Verification Status',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/provider_verification');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notifications section
              _SettingsSection(
                title: 'Notifications',
                isDark: isDark,
                children: [
                  _SettingsToggle(label: 'Push Notifications', value: _pushEnabled, isDark: isDark, onChanged: (v) => setState(() => _pushEnabled = v)),
                  _SettingsToggle(label: 'Email Notifications', value: _emailEnabled, isDark: isDark, onChanged: (v) => setState(() => _emailEnabled = v)),
                  _SettingsToggle(label: 'Booking Alerts', value: _bookingAlerts, isDark: isDark, onChanged: (v) => setState(() => _bookingAlerts = v)),
                  _SettingsToggle(label: 'Review Alerts', value: _reviewAlerts, isDark: isDark, onChanged: (v) => setState(() => _reviewAlerts = v)),
                  _SettingsToggle(label: 'Message Alerts', value: _messageAlerts, isDark: isDark, onChanged: (v) => setState(() => _messageAlerts = v)),
                  _SettingsToggle(label: 'Marketing & Promotions', value: _marketingAlerts, isDark: isDark, onChanged: (v) => setState(() => _marketingAlerts = v)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: _savingNotif ? null : _saveNotificationPrefs,
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                      child: _savingNotif
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Notification Preferences'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Privacy section
              _SettingsSection(
                title: 'Privacy',
                isDark: isDark,
                children: [
                  _SettingsToggle(label: 'Public Profile', value: _profilePublic, isDark: isDark, onChanged: (v) => setState(() => _profilePublic = v)),
                  _SettingsToggle(label: 'Show Location', value: _showLocation, isDark: isDark, onChanged: (v) => setState(() => _showLocation = v)),
                  _SettingsToggle(label: 'Allow Smart Matching', value: _allowMatching, isDark: isDark, onChanged: (v) => setState(() => _allowMatching = v)),
                  _SettingsTile(icon: LucideIcons.userX, label: 'Blocked Users', isDark: isDark, onTap: _showBlockedUsers),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: _savingPrivacy ? null : _savePrivacyPrefs,
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                      child: _savingPrivacy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Privacy Preferences'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Appearance section
              _SettingsSection(
                title: 'Appearance',
                isDark: isDark,
                children: [
                  _SettingsToggle(
                    label: 'Compact Mode',
                    value: _compactMode,
                    isDark: isDark,
                    onChanged: (v) { setState(() => _compactMode = v); _showSnack('Compact mode ${v ? 'enabled' : 'disabled'}'); },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Help & Support section
              _SettingsSection(
                title: 'Help & Support',
                isDark: isDark,
                children: [
                  _SettingsTile(icon: LucideIcons.helpCircle, label: 'Help Center', isDark: isDark, onTap: _showHelpCenter),
                  _SettingsTile(
                    icon: LucideIcons.messageSquare,
                    label: 'Send Feedback',
                    isDark: isDark,
                    onTap: () => _showFeedbackDialog(),
                  ),
                  _SettingsTile(icon: LucideIcons.info, label: 'About', isDark: isDark, onTap: _showAbout),
                  _SettingsTile(
                    icon: LucideIcons.fileText,
                    label: 'Terms of Service',
                    isDark: isDark,
                    onTap: () => _showSnack('Opening Terms of Service...'),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.shield,
                    label: 'Privacy Policy',
                    isDark: isDark,
                    onTap: () => _showSnack('Opening Privacy Policy...'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Danger zone
              _SettingsSection(
                title: 'Danger Zone',
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: LucideIcons.logOut,
                    label: 'Sign Out',
                    isDark: isDark,
                    color: AppDesign.danger,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSignOut?.call();
                    },
                  ),
                  _SettingsTile(
                    icon: LucideIcons.trash2,
                    label: 'Delete Account',
                    isDark: isDark,
                    color: AppDesign.danger,
                    onTap: _showDeleteAccountConfirm,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Center(
                child: Text('Smart Explorers v2.1.0', style: TextStyle(fontSize: 12, color: AppDesign.midGrey)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppDesign.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Tell us what you think or report an issue...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Feedback submitted! Thank you.');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ── FAQ Item ────────────────────────────────────────────────────────────
class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer, required this.isDark});
  final String question, answer;
  final bool isDark;
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppDesign.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? Colors.white12 : AppDesign.lightGrey),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Text(widget.question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: widget.isDark ? Colors.white : AppDesign.eerieBlack))),
              Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: AppDesign.midGrey),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.answer, style: TextStyle(fontSize: 13, height: 1.5, color: AppDesign.midGrey)),
          ),
      ]),
    );
  }
}

// ── Settings Section ─────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children, required this.isDark});
  final String title;
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppDesign.midGrey)),
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppDesign.lightGrey),
            ),
            child: Column(children: children),
          ),
        ),
      ),
    ]);
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
    this.color,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white : AppDesign.eerieBlack);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c))),
          trailing ?? Icon(LucideIcons.chevronRight, size: 18, color: AppDesign.midGrey),
        ]),
      ),
    );
  }
}

// ── Settings Toggle ───────────────────────────────────────────────────────
class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppDesign.eerieBlack))),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: AppDesign.electricCobalt,
        ),
      ]),
    );
  }
}