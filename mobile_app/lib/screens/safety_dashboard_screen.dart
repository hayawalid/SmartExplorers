import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'dart:ui';
import '../widgets/smart_explorers_logo.dart';
import '../services/profile_api_service.dart';
import '../services/safety_api_service.dart';
import '../services/api_config.dart';
import '../services/session_store.dart';

/// Safety Dashboard with WCAG 2.1 AA accessibility compliance
/// Features: Emergency SOS with liveRegion, Semantics for screen readers
class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _pulseController;
  bool _isTracking = true;
  String? _userId;
  final ProfileApiService _profileService = ProfileApiService();
  final SafetyApiService _safetyService = SafetyApiService();
  List<Map<String, dynamic>> _contacts = [];
  String _emergencyNumber = '122';
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadSafetyData();
  }

  Future<void> _loadSafetyData() async {
    try {
      final username =
          SessionStore.instance.username ?? ApiConfig.demoTravelerUsername;
      final user = await _profileService.getUserByUsername(username);
      final userId = user['_id'] as String;
      final safetyProfile = await _safetyService.getSafetyProfile(userId);
      final contacts = await _safetyService.getEmergencyContacts(userId);

      // Get user profile country
      String country = 'Egypt';
      try {
        final profile = await _profileService.getTravelerProfile(userId);
        country =
            profile?['country_of_origin'] ?? profile?['nationality'] ?? 'Egypt';
      } catch (_) {}

      setState(() {
        _userId = userId;
        _isTracking = safetyProfile['live_tracking_enabled'] == true;
        _contacts = contacts;
        _userCountry = country;
        _emergencyNumber = _getEmergencyNumberForCountry(country);
      });
    } catch (_) {
      // Keep defaults on error
    }
  }

  static String _getEmergencyNumberForCountry(String country) {
    final c = country.toLowerCase();
    const numbers = {
      'egypt': '122',
      'united states': '911',
      'usa': '911',
      'united kingdom': '999',
      'uk': '999',
      'japan': '110',
      'saudi arabia': '999',
      'uae': '999',
      'turkey': '155',
      'india': '112',
      'germany': '112',
      'france': '17',
      'italy': '112',
      'spain': '112',
      'morocco': '19',
      'brazil': '190',
      'australia': '000',
      'canada': '911',
      'china': '110',
      'south korea': '112',
      'mexico': '911',
      'russia': '112',
      'south africa': '10111',
      'thailand': '191',
      'jordan': '911',
      'lebanon': '112',
      'tunisia': '197',
    };
    for (final entry in numbers.entries) {
      if (c.contains(entry.key)) return entry.value;
    }
    return '112';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _profileService.dispose();
    _safetyService.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(textColor, secondaryTextColor, isDark),

              const SizedBox(height: 30),

              // Status card
              _buildStatusCard(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),

              const SizedBox(height: 24),

              // Panic button
              _buildPanicButton(),

              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),

              const SizedBox(height: 24),

              // Emergency contacts
              _buildEmergencyContacts(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),

              const SizedBox(height: 24),

              // Safety tips
              _buildSafetyTips(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),

              // Bottom padding for nav bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildHeader(Color textColor, Color secondaryTextColor, bool isDark) {
    return Row(
      children: [
        const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your safety is our priority',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: textColor.withOpacity(0.1),
          ),
          child: Icon(CupertinoIcons.settings, color: secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(isDark ? 0.3 : 0.15),
            const Color(0xFF45a049).withOpacity(isDark ? 0.2 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xFF4CAF50,
                      ).withOpacity(0.3 + (_pulseController.value * 0.2)),
                    ),
                    child: const Icon(
                      CupertinoIcons.shield_fill,
                      color: Color(0xFF4CAF50),
                      size: 30,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Systems Active',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS tracking enabled • Location shared',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Tracking',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.9),
                  fontFamily: 'SF Pro Text',
                ),
              ),
              CupertinoSwitch(
                value: _isTracking,
                onChanged: (value) async {
                  setState(() => _isTracking = value);
                  if (_userId != null) {
                    await _safetyService.updateSafetyProfile(_userId!, {
                      'live_tracking_enabled': value,
                    });
                  }
                },
                activeColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    // WCAG 2.1 AA: Critical emergency button with full accessibility support
    return Semantics(
      button: true,
      liveRegion: true, // Announces changes to screen readers
      label: 'Emergency SOS Panic Button',
      hint:
          'Long press to send emergency alert to your contacts and authorities',
      child: GestureDetector(
        onLongPress: () {
          // Announce to screen reader
          SemanticsService.announce(
            'Emergency alert dialog opened',
            TextDirection.ltr,
          );
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Emergency Alert'),
                  content: const Text(
                    'Are you sure you want to send an emergency alert? This will notify your emergency contacts and local authorities.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                        SemanticsService.announce(
                          'Alert cancelled',
                          TextDirection.ltr,
                        );
                      },
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Send Alert'),
                      onPressed: () async {
                        Navigator.pop(context);
                        if (_userId != null) {
                          await _safetyService.createPanicEvent(_userId!, {
                            'status': 'sent',
                          });
                        }
                        SemanticsService.announce(
                          'Emergency alert sent successfully',
                          TextDirection.ltr,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency alert sent!'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
          );
        },
        child: Container(
          width: double.infinity,
          // WCAG: Minimum 44x44pt tap target (this is 80+ height)
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFf5576c), Color(0xFFf093fb)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFf5576c).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.white,
                size: 40,
                semanticLabel: 'Emergency warning icon',
              ),
              const SizedBox(height: 12),
              const Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Long press to activate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final actions = [
      {
        'icon': CupertinoIcons.phone_fill,
        'label': 'Call $_emergencyNumber',
        'color': Color(0xFF667eea),
      },
      {
        'icon': CupertinoIcons.location_fill,
        'label': 'Share Location',
        'color': Color(0xFF4facfe),
      },
      {
        'icon': CupertinoIcons.person_2_fill,
        'label': 'Contacts',
        'color': Color(0xFFD4AF37),
      },
    ];

    return Row(
      children:
          actions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                  boxShadow:
                      isDark
                          ? null
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Column(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.9),
                        fontFamily: 'SF Pro Text',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmergencyContacts(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 16),
        if (_contacts.isEmpty) ...[
          _buildContactCard(
            'Mom',
            '+20 100 123 4567',
            '👩',
            isDark,
            cardColor,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            'Embassy',
            '+20 2 2797 3300',
            '🏛️',
            isDark,
            cardColor,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 12),
        ] else ...[
          ..._contacts.map((contact) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildContactCard(
                contact['name']?.toString() ?? 'Contact',
                contact['phone']?.toString() ?? '',
                '📞',
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),
            );
          }).toList(),
        ],
        _buildAddContactButton(isDark, textColor, secondaryTextColor),
      ],
    );
  }

  Widget _buildContactCard(
    String name,
    String phone,
    String emoji,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFF2F2F7),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withOpacity(0.3),
            ),
            child: const Icon(
              CupertinoIcons.phone_fill,
              color: Color(0xFF4CAF50),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactButton(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return GestureDetector(
      onTap: _showAddContactDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D1D6),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.plus_circle_fill, color: secondaryTextColor),
            const SizedBox(width: 8),
            Text(
              'Add Emergency Contact',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    _contactNameController.clear();
    _contactPhoneController.clear();

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Add Emergency Contact'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _contactNameController,
                  placeholder: 'Name',
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _contactPhoneController,
                  placeholder: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Save'),
                onPressed: () async {
                  Navigator.pop(context);
                  if (_userId == null) return;
                  final name = _contactNameController.text.trim();
                  final phone = _contactPhoneController.text.trim();
                  if (name.isEmpty || phone.isEmpty) return;

                  final created = await _safetyService.createEmergencyContact(
                    _userId!,
                    {'name': name, 'phone': phone},
                  );

                  setState(() {
                    _contacts.add(created);
                  });
                },
              ),
            ],
          ),
    );
  }

  Widget _buildSafetyTips(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final tips = [
      'Always share your location with trusted contacts',
      'Keep your phone charged above 20%',
      'Store offline maps for emergencies',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.lightbulb_fill,
                  color: Color(0xFFD4AF37),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontFamily: 'SF Pro Text',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
