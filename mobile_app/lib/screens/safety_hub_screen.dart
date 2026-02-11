import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_builder.dart';

/// Tab 5: Safety Hub
/// High-visibility layout with large SOS button
/// Emergency contacts list based on current itinerary location
class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({Key? key}) : super(key: key);

  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _sosController;
  bool _isTracking = true;

  // Demo emergency contacts for Egypt
  final List<_EmergencyContact> _contacts = const [
    _EmergencyContact(
      name: 'Tourist Police',
      number: '126',
      icon: LucideIcons.shield,
      color: Color(0xFF1A1A1A),
    ),
    _EmergencyContact(
      name: 'Ambulance',
      number: '123',
      icon: LucideIcons.heartPulse,
      color: Color(0xFFFF3B5C),
    ),
    _EmergencyContact(
      name: 'Embassy (US)',
      number: '+20 2 2797 3300',
      icon: LucideIcons.landmark,
      color: Color(0xFF00C566),
    ),
    _EmergencyContact(
      name: 'Fire Department',
      number: '180',
      icon: LucideIcons.flame,
      color: Color(0xFFFFA726),
    ),
    _EmergencyContact(
      name: 'Local Police',
      number: '122',
      icon: LucideIcons.siren,
      color: Color(0xFF9B59B6),
    ),
  ];

  // Personal emergency contacts
  final List<_EmergencyContact> _personalContacts = const [
    _EmergencyContact(
      name: 'Mom',
      number: '+1 555 0101',
      icon: LucideIcons.userCircle,
      color: Color(0xFFFF6B6B),
    ),
    _EmergencyContact(
      name: 'Travel Insurance',
      number: '+44 800 123 456',
      icon: LucideIcons.fileCheck,
      color: Color(0xFF1A1A1A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sosController.dispose();
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    color: AppDesign.electricCobalt,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Safety Hub',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: text),
                  ),
                  const Spacer(),
                  _locationPill(isDark, sub),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                'Your safety is our priority',
                style: TextStyle(fontSize: 14, color: sub),
              ),
            ),
            const SizedBox(height: 28),

            // ── SOS Button ───────────────────────────────────────────
            Center(child: _buildSOSButton(isDark)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Press & hold for emergency alert',
                style: TextStyle(fontSize: 12, color: sub),
              ),
            ),
            const SizedBox(height: 28),

            // ── Tracking Toggle ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: AppDesign.borderRadius,
                boxShadow: isDark ? [] : AppDesign.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (_isTracking
                              ? AppDesign.success
                              : AppDesign.midGrey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.navigation,
                      size: 20,
                      color:
                          _isTracking ? AppDesign.success : AppDesign.midGrey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Location Sharing',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isTracking
                              ? 'Sharing with emergency contacts'
                              : 'Disabled',
                          style: TextStyle(fontSize: 12, color: sub),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isTracking,
                    activeColor: AppDesign.electricCobalt,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _isTracking = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Local Emergency Contacts ─────────────────────────────
            _sectionTitle('Local Emergency — Cairo', text),
            const SizedBox(height: 8),
            ..._contacts.map((c) => _contactTile(c, isDark, card, text, sub)),
            const SizedBox(height: 20),

            // ── Personal Contacts ────────────────────────────────────
            _sectionTitle('Personal Contacts', text),
            const SizedBox(height: 8),
            ..._personalContacts.map(
              (c) => _contactTile(c, isDark, card, text, sub),
            ),
            const SizedBox(height: 8),

            // Add contact button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Add Emergency Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppDesign.electricCobalt,
                  side: const BorderSide(
                    color: AppDesign.electricCobalt,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDesign.borderRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Safety Tips ──────────────────────────────────────────
            _sectionTitle('Safety Tips', text),
            const SizedBox(height: 8),
            _tipCard(
              isDark,
              card,
              text,
              sub,
              LucideIcons.mapPin,
              'Share your itinerary with family before you travel.',
            ),
            _tipCard(
              isDark,
              card,
              text,
              sub,
              LucideIcons.wifi,
              'Download offline maps for areas with limited connectivity.',
            ),
            _tipCard(
              isDark,
              card,
              text,
              sub,
              LucideIcons.shieldCheck,
              'Only book verified SmartExplorers service providers.',
            ),
          ],
        ),
      ),
    );
  }

  // ── SOS Button ─────────────────────────────────────────────────────────
  Widget _buildSOSButton(bool isDark) {
    return PulseAnimatedBuilder(
      animation: _sosController,
      builder: (context, child) {
        final pulse = 1.0 + _sosController.value * 0.06;
        return Transform.scale(scale: pulse, child: child);
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Emergency alert sent to your contacts!'),
              backgroundColor: AppDesign.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppDesign.danger,
            boxShadow: [
              BoxShadow(
                color: AppDesign.danger.withOpacity(0.35),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertTriangle, size: 36, color: Colors.white),
              SizedBox(height: 6),
              Text(
                'SOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationPill(bool isDark, Color sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : AppDesign.lightGrey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mapPin, size: 13, color: sub),
          const SizedBox(width: 4),
          Text('Cairo', style: TextStyle(fontSize: 12, color: sub)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _contactTile(
    _EmergencyContact c,
    bool isDark,
    Color card,
    Color text,
    Color sub,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(c.icon, size: 22, color: c.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(c.number, style: TextStyle(fontSize: 13, color: sub)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppDesign.electricCobalt.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.phone,
                size: 18,
                color: AppDesign.electricCobalt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(
    bool isDark,
    Color card,
    Color text,
    Color sub,
    IconData icon,
    String tip,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppDesign.electricCobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppDesign.electricCobalt),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 13, height: 1.4, color: text),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContact {
  const _EmergencyContact({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });
  final String name, number;
  final IconData icon;
  final Color color;
}
