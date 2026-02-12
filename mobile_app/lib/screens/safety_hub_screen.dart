import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_builder.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/safety_api_service.dart';
import '../services/session_store.dart';
import '../services/profile_api_service.dart';

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
  final SafetyApiService _safetyService = SafetyApiService();
  final ProfileApiService _profileService = ProfileApiService();

  List<_EmergencyContact> _contacts = [];
  List<_EmergencyContact> _personalContacts = [];
  bool _loadingContacts = true;
  String _locationLabel = '';
  String _currencySymbol = '';
  String _currencyCode = '';

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadEmergencyData();
  }

  @override
  void dispose() {
    _sosController.dispose();
    _safetyService.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyData() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) {
      setState(() => _loadingContacts = false);
      return;
    }

    try {
      // Get user profile to find their country of origin
      final username = SessionStore.instance.username ?? '';
      Map<String, dynamic>? user;
      if (username.isNotEmpty) {
        user = await _profileService.getUserByUsername(username);
      }

      String country = 'Egypt';
      String location = '';
      if (user != null) {
        // Try to get traveler profile for country
        try {
          final profile = await _profileService.getTravelerProfile(
            user['_id'] ?? userId,
          );
          country =
              profile?['country_of_origin'] ??
              profile?['nationality'] ??
              'Egypt';
          location = profile?['current_city'] ?? profile?['city'] ?? '';
        } catch (_) {}
      }

      // Derive currency from country
      final currencyInfo = _getCurrencyForCountry(country);

      // Fetch emergency numbers from backend (includes embassy based on country)
      List<_EmergencyContact> localContacts = [];
      try {
        final response = await _safetyService.getEmergencyNumbers(country);
        final numbers = response['emergency_numbers'] as List<dynamic>? ?? [];
        for (final n in numbers) {
          localContacts.add(
            _EmergencyContact(
              name: n['name'] ?? '',
              number: n['number'] ?? '',
              icon: _iconFromString(n['icon'] ?? 'shield'),
              color:
                  n['category'] == 'embassy'
                      ? const Color(0xFF00C566)
                      : _colorForEmergency(n['icon'] ?? 'shield'),
            ),
          );
        }
      } catch (_) {
        // Fallback to basic numbers if API fails
        localContacts = const [
          _EmergencyContact(
            name: 'Tourist Police',
            number: '126',
            icon: LucideIcons.shield,
            color: Color(0xFF4A90D9),
          ),
          _EmergencyContact(
            name: 'Ambulance',
            number: '123',
            icon: LucideIcons.heartPulse,
            color: Color(0xFFFF3B5C),
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
      }

      // Fetch personal emergency contacts from DB
      List<_EmergencyContact> personalContacts = [];
      try {
        final dbContacts = await _safetyService.getEmergencyContacts(userId);
        for (final c in dbContacts) {
          personalContacts.add(
            _EmergencyContact(
              name: c['name'] ?? 'Contact',
              number: c['phone_number'] ?? c['number'] ?? '',
              icon: LucideIcons.userCircle,
              color: const Color(0xFFE8604C),
              dbId: c['_id'],
            ),
          );
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _contacts = localContacts;
          _personalContacts = personalContacts;
          _locationLabel = location.isNotEmpty ? location : country;
          _currencySymbol = currencyInfo['symbol'] ?? '\$';
          _currencyCode = currencyInfo['code'] ?? 'USD';
          _loadingContacts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  IconData _iconFromString(String icon) {
    switch (icon) {
      case 'shield':
        return LucideIcons.shield;
      case 'heart_pulse':
        return LucideIcons.heartPulse;
      case 'flame':
        return LucideIcons.flame;
      case 'siren':
        return LucideIcons.siren;
      case 'landmark':
        return LucideIcons.landmark;
      case 'car':
        return LucideIcons.car;
      default:
        return LucideIcons.phone;
    }
  }

  Color _colorForEmergency(String icon) {
    switch (icon) {
      case 'shield':
        return const Color(0xFF4A90D9);
      case 'heart_pulse':
        return const Color(0xFFFF3B5C);
      case 'flame':
        return const Color(0xFFFFA726);
      case 'siren':
        return const Color(0xFF9B59B6);
      case 'car':
        return const Color(0xFF11998E);
      default:
        return const Color(0xFF4A90D9);
    }
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
                  const SmartExplorersLogo(
                    size: LogoSize.tiny,
                    showText: false,
                  ),
                  const SizedBox(width: 8),
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
            _sectionTitle('Local Emergency — $_locationLabel', text),
            const SizedBox(height: 8),
            if (_loadingContacts)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._contacts.map((c) => _contactTile(c, isDark, card, text, sub)),
            const SizedBox(height: 20),

            // ── Personal Contacts ────────────────────────────────────
            _sectionTitle('Personal Contacts', text),
            const SizedBox(height: 8),
            if (_personalContacts.isEmpty && !_loadingContacts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No personal contacts yet.',
                  style: TextStyle(fontSize: 13, color: sub),
                ),
              )
            else
              ..._personalContacts.map(
                (c) => _contactTile(c, isDark, card, text, sub),
              ),
            const SizedBox(height: 8),

            // Add contact button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => _showAddContactDialog(),
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
            if (_currencyCode.isNotEmpty)
              _tipCard(
                isDark,
                card,
                text,
                sub,
                LucideIcons.wallet,
                'Local currency: $_currencyCode ($_currencySymbol). Use trusted exchange offices or ATMs.',
              ),
          ],
        ),
      ),
    );
  }

  // ── Add Contact Dialog ──────────────────────────────────────────────
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Emergency Contact'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Mom',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 555 0101',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      numberController.text.isEmpty)
                    return;
                  Navigator.pop(ctx);
                  final userId = SessionStore.instance.userId;
                  if (userId == null) return;
                  try {
                    await _safetyService.addEmergencyContact(userId, {
                      'name': nameController.text,
                      'phone_number': numberController.text,
                    });
                    _loadEmergencyData();
                  } catch (_) {}
                },
                child: const Text('Add'),
              ),
            ],
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
          Text(
            _locationLabel.isNotEmpty ? _locationLabel : 'Loading...',
            style: TextStyle(fontSize: 12, color: sub),
          ),
          if (_currencyCode.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _currencyCode,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: sub,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns currency symbol and code based on country name.
  static Map<String, String> _getCurrencyForCountry(String country) {
    final c = country.toLowerCase();
    const map = {
      'egypt': {'symbol': 'E£', 'code': 'EGP'},
      'united states': {'symbol': '\$', 'code': 'USD'},
      'usa': {'symbol': '\$', 'code': 'USD'},
      'united kingdom': {'symbol': '£', 'code': 'GBP'},
      'uk': {'symbol': '£', 'code': 'GBP'},
      'japan': {'symbol': '¥', 'code': 'JPY'},
      'saudi arabia': {'symbol': '﷼', 'code': 'SAR'},
      'uae': {'symbol': 'د.إ', 'code': 'AED'},
      'united arab emirates': {'symbol': 'د.إ', 'code': 'AED'},
      'turkey': {'symbol': '₺', 'code': 'TRY'},
      'india': {'symbol': '₹', 'code': 'INR'},
      'germany': {'symbol': '€', 'code': 'EUR'},
      'france': {'symbol': '€', 'code': 'EUR'},
      'italy': {'symbol': '€', 'code': 'EUR'},
      'spain': {'symbol': '€', 'code': 'EUR'},
      'morocco': {'symbol': 'MAD', 'code': 'MAD'},
      'brazil': {'symbol': 'R\$', 'code': 'BRL'},
      'australia': {'symbol': 'A\$', 'code': 'AUD'},
      'canada': {'symbol': 'C\$', 'code': 'CAD'},
      'china': {'symbol': '¥', 'code': 'CNY'},
      'south korea': {'symbol': '₩', 'code': 'KRW'},
      'mexico': {'symbol': '\$', 'code': 'MXN'},
      'russia': {'symbol': '₽', 'code': 'RUB'},
      'south africa': {'symbol': 'R', 'code': 'ZAR'},
      'thailand': {'symbol': '฿', 'code': 'THB'},
      'malaysia': {'symbol': 'RM', 'code': 'MYR'},
      'indonesia': {'symbol': 'Rp', 'code': 'IDR'},
      'jordan': {'symbol': 'JD', 'code': 'JOD'},
      'lebanon': {'symbol': 'L£', 'code': 'LBP'},
      'tunisia': {'symbol': 'DT', 'code': 'TND'},
    };
    for (final entry in map.entries) {
      if (c.contains(entry.key)) return entry.value;
    }
    return {'symbol': '\$', 'code': 'USD'};
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
    this.dbId,
  });
  final String name, number;
  final IconData icon;
  final Color color;
  final String? dbId;
}
