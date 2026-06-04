import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/api_config.dart';

/// Provider Verification Dashboard
/// Shows all 8 verification checks, scores, tips on how to improve,
/// and entry point for ID scan (with OCR name matching).
class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _report;
  String? _error;
  late final AnimationController _animController;

  static const List<_CheckMeta> _checks = [
    _CheckMeta(
      key: 'location_verification',
      label: 'Location',
      maxScore: 15,
      icon: LucideIcons.map_pin,
      tip: 'Make sure your business address exists on OpenStreetMap '
          'and your coordinates are accurate (within 500 m).',
    ),
    _CheckMeta(
      key: 'business_existence',
      label: 'Business',
      maxScore: 10,
      icon: LucideIcons.building_2,
      tip: 'Add your business to OpenStreetMap with phone, website '
          'and opening hours to earn full points.',
    ),
    _CheckMeta(
      key: 'social_media',
      label: 'Social Media',
      maxScore: 10,
      icon: LucideIcons.share_2,
      tip: 'Link a real Facebook page and Instagram account that '
          'matches your business name.',
    ),
    _CheckMeta(
      key: 'review_analysis',
      label: 'Reviews',
      maxScore: 15,
      icon: LucideIcons.star,
      tip: 'Encourage satisfied customers to leave reviews. '
          'Scam or bad-phone complaints reduce your score.',
    ),
    _CheckMeta(
      key: 'duplicate_check',
      label: 'Duplicates',
      maxScore: 10,
      icon: LucideIcons.copy,
      tip: 'Each phone number and email must be unique. '
          'Duplicate accounts are flagged as fraud.',
    ),
    _CheckMeta(
      key: 'phone_location',
      label: 'Phone Match',
      maxScore: 5,
      icon: LucideIcons.phone,
      tip: 'Your phone area code should match your listed city '
          '(e.g., Cairo numbers start with 02).',
    ),
    _CheckMeta(
      key: 'business_hours',
      label: 'Hours',
      maxScore: 5,
      icon: LucideIcons.clock,
      tip: 'Set realistic opening hours (9 AM–5 PM range). '
          'Very unusual or missing hours reduce your score.',
    ),
    _CheckMeta(
      key: 'license_validity',
      label: 'License',
      maxScore: 10,
      icon: LucideIcons.shield_check,
      tip: 'Provide a valid business license number (at least 5 characters). '
          'Missing license removes 10 points.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadVerification();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = SessionStore.instance.userId;
    if (userId == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      return;
    }

    try {
      final cachedRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/verification/providers/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (cachedRes.statusCode == 200) {
        final data = jsonDecode(cachedRes.body) as Map<String, dynamic>;
        // Unwrap envelope if present
        final inner = (data['details'] ?? data['verification'] ?? data) as Map<String, dynamic>;
        if (inner.isNotEmpty && inner['overall_score'] != null) {
          setState(() {
            _report = inner;
            _loading = false;
          });
          _animController.forward(from: 0);
          return;
        }
      }

      final freshRes = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/verification/providers/$userId/verify'),
        headers: {'Accept': 'application/json'},
      );

      if (freshRes.statusCode == 200) {
        final data = jsonDecode(freshRes.body) as Map<String, dynamic>;
        // The verify endpoint wraps the report: { "status": "success", "details": {...} }
        // or { "status": "success", "verification": {...} } — unwrap it.
        final inner = (data['details'] ?? data['verification'] ?? data) as Map<String, dynamic>;
        setState(() {
          _report = inner;
          _loading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _error = 'Could not load verification (${freshRes.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: _loading
                    ? _buildLoading(isDark)
                    : _error != null
                        ? _buildError(isDark)
                        : _buildContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppDesign.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.arrow_left,
                size: 18,
                color: isDark ? Colors.white : AppDesign.eerieBlack,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
                Text(
                  '8-source trust score',
                  style: TextStyle(fontSize: 12, color: AppDesign.midGrey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _loadVerification();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppDesign.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.refresh_cw,
                size: 18,
                color: isDark ? Colors.white : AppDesign.eerieBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isDark ? Colors.white : AppDesign.eerieBlack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Running verification checks…',
            style: TextStyle(fontSize: 14, color: AppDesign.midGrey),
          ),
        ],
      ),
    );
  }

  void _openBusinessInfoSheet(bool isDark) {
    // Create controllers inside the builder to avoid disposal issues
    bool saving = false;
    String? sheetError;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Create controllers INSIDE the builder, not outside
        final controllers = <String, TextEditingController>{
          'business_name': TextEditingController(),
          'address': TextEditingController(),
          'city': TextEditingController(),
          'latitude': TextEditingController(),
          'longitude': TextEditingController(),
          'phone': TextEditingController(),
          'facebook_url': TextEditingController(),
          'instagram_username': TextEditingController(),
          'business_license': TextEditingController(),
        };
        
        // Hours controllers and toggle states
        const dayKeys = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];
        for (final day in dayKeys) {
          controllers['hours_${day}_open'] = TextEditingController();
          controllers['hours_${day}_close'] = TextEditingController();
        }
        
        // Track which days are enabled
        final Map<String, bool> isDayEnabled = {};
        for (final day in dayKeys) {
          isDayEnabled[day] = false;
        }
        
        final profile = (_report?['provider_profile'] as Map<String, dynamic>?) ?? {};
        
        // Pre-fill data
        controllers['business_name']!.text = (profile['business_name'] as String?) ?? '';
        controllers['address']!.text = (profile['address'] as String?) ?? '';
        controllers['city']!.text = (profile['city'] as String?) ?? '';
        controllers['latitude']!.text = (profile['latitude'] != null) ? '${profile['latitude']}' : '';
        controllers['longitude']!.text = (profile['longitude'] != null) ? '${profile['longitude']}' : '';
        controllers['phone']!.text = (profile['phone_number'] as String?) ?? '';
        controllers['facebook_url']!.text = (profile['facebook_url'] as String?) ?? '';
        controllers['instagram_username']!.text = (profile['instagram_username'] as String?) ?? '';
        controllers['business_license']!.text = (profile['business_license_number'] as String?) ?? '';
        
        final savedHours = (profile['business_hours'] as Map<String, dynamic>?) ?? {};
        for (final day in dayKeys) {
          final times = (savedHours[day] as Map<String, dynamic>?) ?? {};
          final open = times['open'] as String? ?? '';
          final close = times['close'] as String? ?? '';
          controllers['hours_${day}_open']!.text = open;
          controllers['hours_${day}_close']!.text = close;
          isDayEnabled[day] = open.isNotEmpty && close.isNotEmpty;
        }
        
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              setSheetState(() {
                saving = true;
                sheetError = null;
              });
              
              final userId = SessionStore.instance.userId;
              if (userId == null) {
                setSheetState(() {
                  saving = false;
                  sheetError = 'Not logged in';
                });
                return;
              }
              
              final body = <String, dynamic>{};
              void addIfNotEmpty(String key, String value) {
                if (value.trim().isNotEmpty) body[key] = value.trim();
              }
              
              addIfNotEmpty('business_name', controllers['business_name']!.text);
              addIfNotEmpty('address', controllers['address']!.text);
              addIfNotEmpty('city', controllers['city']!.text);
              addIfNotEmpty('phone', controllers['phone']!.text);
              addIfNotEmpty('facebook_url', controllers['facebook_url']!.text);
              addIfNotEmpty('instagram_username', controllers['instagram_username']!.text);
              addIfNotEmpty('business_license', controllers['business_license']!.text);
              
              // Build business_hours map based on enabled days
              final hoursMap = <String, dynamic>{};
              for (final day in dayKeys) {
                if (isDayEnabled[day] == true) {
                  final open = controllers['hours_${day}_open']!.text.trim();
                  final close = controllers['hours_${day}_close']!.text.trim();
                  if (open.isNotEmpty && close.isNotEmpty) {
                    hoursMap[day] = {'open': open, 'close': close};
                  }
                }
              }
              if (hoursMap.isNotEmpty) {
                body['business_hours'] = hoursMap;
              }
              
              final latText = controllers['latitude']?.text.trim() ?? '';
              final lngText = controllers['longitude']?.text.trim() ?? '';
              if (latText.isNotEmpty) {
                body['latitude'] = double.tryParse(latText) ?? 0.0;
              }
              if (lngText.isNotEmpty) {
                body['longitude'] = double.tryParse(lngText) ?? 0.0;
              }
              
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/api/v1/verification/providers/$userId/submit-info'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(body),
                );
                
                if (res.statusCode == 200) {
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    if (mounted) _loadVerification();
                  }
                } else {
                  final err = jsonDecode(res.body);
                  if (ctx.mounted) {
                    setSheetState(() {
                      saving = false;
                      sheetError = (err is Map ? err['detail'] : null) ?? 'Save failed';
                    });
                  }
                }
              } catch (e) {
                if (ctx.mounted) {
                  setSheetState(() {
                    saving = false;
                    sheetError = 'Network error: $e';
                  });
                }
              }
            }
            
            Future<void> _selectTime(TextEditingController controller) async {
              final TimeOfDay? picked = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                setSheetState(() {
                  controller.text = formattedTime;
                });
              }
            }
            
            Widget field(String key, String label, {TextInputType keyboardType = TextInputType.text, String? hint}) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppDesign.eerieBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controllers[key]!,
                      keyboardType: keyboardType,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : AppDesign.eerieBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(fontSize: 13, color: AppDesign.midGrey),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : AppDesign.lightGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Container(
                decoration: BoxDecoration(
                  color: isDark ? AppDesign.eerieBlack : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : AppDesign.lightGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Business Info',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppDesign.eerieBlack,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Icon(LucideIcons.x, size: 20, color: AppDesign.midGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Fill in what you have. Each field improves your trust score.',
                        style: TextStyle(fontSize: 13, color: AppDesign.midGrey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                        children: [
                          field('business_name', 'Business Name', hint: 'e.g. Cairo Tours Co.'),
                          field('address', 'Street Address', hint: 'e.g. 12 Tahrir Square, Cairo'),
                          field('city', 'City', hint: 'e.g. Cairo'),
                          Row(
                            children: [
                              Expanded(
                                child: field('latitude', 'Latitude',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  hint: 'e.g. 30.0444'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: field('longitude', 'Longitude',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  hint: 'e.g. 31.2357'),
                              ),
                            ],
                          ),
                          field('phone', 'Phone Number', keyboardType: TextInputType.phone, hint: 'e.g. 0201234567'),
                          field('facebook_url', 'Facebook Page URL', keyboardType: TextInputType.url, hint: 'https://facebook.com/yourpage'),
                          field('instagram_username', 'Instagram Username', hint: '@yourbusiness'),
                          field('business_license', 'License Number', hint: 'e.g. LIC-2024-00123'),
                          const SizedBox(height: 6),
                          const Text(
                            'Business Hours (optional)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toggle each day ON to set working hours.',
                            style: TextStyle(fontSize: 12, color: AppDesign.midGrey),
                          ),
                          const SizedBox(height: 16),
                          ...dayKeys.map((day) {
                            final dayName = {
                              'sat': 'Saturday', 'sun': 'Sunday', 'mon': 'Monday',
                              'tue': 'Tuesday', 'wed': 'Wednesday', 'thu': 'Thursday', 'fri': 'Friday'
                            }[day]!;
                            final openCtrl = controllers['hours_${day}_open']!;
                            final closeCtrl = controllers['hours_${day}_close']!;
                            final isEnabled = isDayEnabled[day] ?? false;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          dayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: isEnabled,
                                        onChanged: (value) {
                                          setSheetState(() {
                                            isDayEnabled[day] = value;
                                            if (value && openCtrl.text.isEmpty && closeCtrl.text.isEmpty) {
                                              openCtrl.text = '09:00';
                                              closeCtrl.text = '17:00';
                                            }
                                          });
                                        },
                                        activeColor: AppDesign.success,
                                      ),
                                      if (isEnabled) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _selectTime(openCtrl),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.clock, size: 16, color: AppDesign.midGrey),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    openCtrl.text.isEmpty ? 'Start' : openCtrl.text,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: openCtrl.text.isEmpty ? AppDesign.midGrey : (isDark ? Colors.white : AppDesign.eerieBlack),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('—', style: TextStyle(color: AppDesign.midGrey)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _selectTime(closeCtrl),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withOpacity(0.08) : AppDesign.lightGrey,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.clock, size: 16, color: AppDesign.midGrey),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    closeCtrl.text.isEmpty ? 'End' : closeCtrl.text,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: closeCtrl.text.isEmpty ? AppDesign.midGrey : (isDark ? Colors.white : AppDesign.eerieBlack),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          if (sheetError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(sheetError!, style: TextStyle(fontSize: 13, color: AppDesign.danger)),
                            ),
                          GestureDetector(
                            onTap: saving ? null : save,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: saving ? AppDesign.midGrey : (isDark ? Colors.white : AppDesign.eerieBlack),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: saving
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? AppDesign.eerieBlack : Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Save & Recalculate Score',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppDesign.eerieBlack : Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circle_alert, size: 40, color: AppDesign.danger),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppDesign.midGrey),
            ),
            const SizedBox(height: 24),
            _PillButton(
              label: 'Try Again',
              isDark: isDark,
              onTap: _loadVerification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final report = _report!;
    final score = (report['overall_score'] as num?)?.toDouble() ?? 0.0;
    final level = report['verification_level'] as String? ?? 'basic';
    final sourceScores =
        (report['source_scores'] as Map<String, dynamic>?) ?? {};
    final warnings = (report['warnings'] as List?)?.cast<String>() ?? [];
    final recommendations =
        (report['recommendations'] as List?)?.cast<String>() ?? [];

    return RefreshIndicator(
      onRefresh: _loadVerification,
      color: isDark ? Colors.white : AppDesign.eerieBlack,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _buildScoreCard(isDark, score, level),
          const SizedBox(height: 20),
          _buildIdScanCard(isDark, report),
          const SizedBox(height: 20),
          Text(
            'Verification Checks',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppDesign.eerieBlack,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_checks.length, (i) {
            final meta = _checks[i];
            final src =
                (sourceScores[meta.key] as Map<String, dynamic>?) ?? {};
            final earned = (src['earned'] as num?)?.toInt() ?? 0;
            final passed = src['passed'] as bool? ?? false;
            return _buildCheckTile(
              isDark: isDark,
              meta: meta,
              earned: earned,
              passed: passed,
              index: i,
            );
          }),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildWarningsSection(isDark, warnings),
          ],
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRecommendationsSection(isDark, recommendations),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard(bool isDark, double score, String level) {
    final color = _scoreColor(score);
    final levelLabel = _levelLabel(level);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Opacity(
        opacity: _animController.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _animController.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppDesign.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : AppDesign.lightGrey,
                        color: color,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppDesign.eerieBlack,
                            ),
                          ),
                          Text('/100',
                              style: TextStyle(
                                  fontSize: 10, color: AppDesign.midGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          levelLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _levelDescription(level),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppDesign.midGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor:
                    isDark ? Colors.white12 : AppDesign.lightGrey,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0',
                    style:
                        TextStyle(fontSize: 10, color: AppDesign.midGrey)),
                Text(
                  score >= 80
                      ? 'Excellent — you rank highest in search'
                      : score >= 60
                          ? 'Good — keep improving to reach Trusted'
                          : score >= 40
                              ? 'Fair — complete missing checks below'
                              : 'Low — several checks need attention',
                  style:
                      TextStyle(fontSize: 11, color: AppDesign.midGrey),
                ),
                Text('100',
                    style:
                        TextStyle(fontSize: 10, color: AppDesign.midGrey)),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _openBusinessInfoSheet(isDark);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : AppDesign.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.pencil,
                        size: 15,
                        color:
                            isDark ? Colors.white70 : AppDesign.eerieBlack),
                    const SizedBox(width: 8),
                    Text(
                      'Update Business Info',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : AppDesign.eerieBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdScanCard(bool isDark, Map<String, dynamic> report) {
    final profile =
        report['provider_profile'] as Map<String, dynamic>? ?? {};
    final idStatus =
        profile['verification_status'] as String? ?? 'pending';
    final idVerified = idStatus == 'verified';
    final nameMatched = profile['id_name_match'] as bool? ?? false;
    final faceVerified = profile['face_verified'] as bool? ?? false;

    String statusMessage;
    if (idVerified && nameMatched && faceVerified) {
      statusMessage = 'ID verified with name match ✓';
    } else if (idVerified && !nameMatched) {
      statusMessage = 'ID verified but name does not match your account';
    } else if (idVerified) {
      statusMessage = 'ID verification complete';
    } else {
      statusMessage = 'ID scan will be completed during onboarding';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: idVerified
              ? AppDesign.success.withOpacity(0.4)
              : AppDesign.navSafety.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (idVerified ? AppDesign.success : AppDesign.navSafety)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              idVerified ? LucideIcons.shield_check : LucideIcons.id_card,
              size: 22,
              color: idVerified ? AppDesign.success : AppDesign.navSafety,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idVerified ? 'ID Verified' : 'Identity Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppDesign.eerieBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusMessage,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppDesign.midGrey,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile({
    required bool isDark,
    required _CheckMeta meta,
    required int earned,
    required bool passed,
    required int index,
  }) {
    final pct = meta.maxScore > 0 ? earned / meta.maxScore : 0.0;
    final color = passed
        ? AppDesign.success
        : earned > 0
            ? AppDesign.navExplore
            : AppDesign.danger;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = (index * 0.08).clamp(0.0, 0.7);
        final t =
            ((_animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppDesign.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, size: 18, color: color),
            ),
            title: Text(
              meta.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppDesign.eerieBlack,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor:
                            isDark ? Colors.white12 : AppDesign.lightGrey,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$earned/${meta.maxScore}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              passed ? LucideIcons.badge_check : LucideIcons.circle,
              size: 18,
              color: color,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : AppDesign.offWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.lightbulb,
                        size: 14, color: AppDesign.navExplore),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta.tip,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppDesign.midGrey,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningsSection(bool isDark, List<String> warnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warnings',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppDesign.danger),
        ),
        const SizedBox(height: 10),
        ...warnings.map(
          (w) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppDesign.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppDesign.danger.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.triangle_alert,
                    size: 16, color: AppDesign.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(w,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppDesign.danger,
                          height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
      bool isDark, List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Improve',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppDesign.eerieBlack,
          ),
        ),
        const SizedBox(height: 10),
        ...recommendations.asMap().entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppDesign.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppDesign.electricCobalt.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppDesign.electricCobalt,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppDesign.midGrey,
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

  Color _scoreColor(double score) {
    if (score >= 80) return AppDesign.success;
    if (score >= 60) return AppDesign.electricCobalt;
    if (score >= 40) return AppDesign.navExplore;
    return AppDesign.danger;
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'trusted':  return '✦ Trusted';
      case 'verified': return '✓ Verified';
      case 'standard': return '◈ Standard';
      default:         return '○ Basic';
    }
  }

  String _levelDescription(String level) {
    switch (level) {
      case 'trusted':
        return 'You appear at the top of traveler searches.';
      case 'verified':
        return 'Good standing. Reach Trusted by completing missing checks.';
      case 'standard':
        return 'Several checks incomplete. Improve to rank higher.';
      default:
        return 'Low trust score. Complete the checks below to rank in search.';
    }
  }
}

class _CheckMeta {
  final String key;
  final String label;
  final int maxScore;
  final IconData icon;
  final String tip;

  const _CheckMeta({
    required this.key,
    required this.label,
    required this.maxScore,
    required this.icon,
    required this.tip,
  });
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : AppDesign.eerieBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppDesign.eerieBlack : Colors.white,
          ),
        ),
      ),
    );
  }
}