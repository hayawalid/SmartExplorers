import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';

class ItineraryCalendarScreen extends StatefulWidget {
  /// Pass the full itinerary map from the planner to render dynamically.
  final Map<String, dynamic>? itinerary;

  const ItineraryCalendarScreen({Key? key, this.itinerary}) : super(key: key);

  @override
  State<ItineraryCalendarScreen> createState() =>
      _ItineraryCalendarScreenState();
}

class _ItineraryCalendarScreenState extends State<ItineraryCalendarScreen> {
  int _selectedDayIndex = 0;

  // Parsed from itinerary JSON
  late final List<_DayPlan> _days;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _parseItinerary();
  }

  void _parseItinerary() {
    final it = widget.itinerary;
    if (it == null) {
      _title = 'No itinerary';
      _days = [];
      return;
    }
    _title = it['title'] as String? ?? 'My Trip';

    final rawDays = it['daily_plans'] as List<dynamic>? ?? [];
    _days =
        rawDays.map((d) {
          final activities = (d['activities'] as List<dynamic>? ?? []);
          final events =
              activities.map((a) {
                return _CalendarEvent(
                  title: a['title'] as String? ?? 'Activity',
                  startTime: a['start_time'] as String? ?? '09:00',
                  endTime: a['end_time'] as String? ?? '10:00',
                  location: a['location_name'] as String? ?? '',
                  description: a['description'] as String? ?? '',
                  category: a['category'] as String? ?? 'sightseeing',
                  bestTimeReason: a['best_time_reason'] as String? ?? '',
                );
              }).toList();
          events.sort((a, b) => a.startTime.compareTo(b.startTime));

          return _DayPlan(
            day: d['day'] as int? ?? 1,
            date: d['date'] as String? ?? '',
            title: d['title'] as String? ?? 'Day ${d['day']}',
            events: events,
          );
        }).toList();
  }

  // ── Computed helpers ──────────────────────────────────────────────
  List<_CalendarEvent> get _currentEvents =>
      _days.isNotEmpty ? _days[_selectedDayIndex].events : [];

  int get _totalPlaces {
    int c = 0;
    for (final d in _days) c += d.events.length;
    return c;
  }

  int get _totalMeals {
    int c = 0;
    for (final d in _days) {
      for (final e in d.events) {
        if ([
          'breakfast',
          'lunch',
          'dinner',
          'food',
          'restaurant',
          'cafe',
        ].contains(e.category.toLowerCase()))
          c++;
      }
    }
    return c;
  }

  String get _routeString {
    final locs = <String>[];
    for (final d in _days) {
      for (final e in d.events) {
        final loc = e.location.split(',').first.trim();
        if (loc.isNotEmpty && !locs.contains(loc)) locs.add(loc);
      }
    }
    return locs.take(3).join('  →  ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;

    if (_days.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(textColor),
              const Expanded(
                child: Center(
                  child: Text(
                    'No itinerary to display.\nGo back and plan a trip!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(textColor),
            _buildRoute(isDark, textColor),
            _buildStatsPills(isDark),
            _buildDaySelector(isDark, textColor),
            Expanded(child: _buildTimeline(isDark, textColor)),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 16, right: 4),
        decoration: BoxDecoration(
          color: AppDesign.eerieBlack,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.chevronLeft, color: textColor, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoute(bool isDark, Color textColor) {
    final route = _routeString;
    if (route.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Text(
        route,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatsPills(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          _statPill(
            icon: LucideIcons.calendar,
            text: '${_days.length} ${_days.length == 1 ? 'Day' : 'Days'}',
            color: const Color(0xFFFFE5E5),
            textColor: const Color(0xFFFF6B6B),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _statPill(
            icon: LucideIcons.mapPin,
            text: '$_totalPlaces Places',
            color: const Color(0xFFE5E5FF),
            textColor: const Color(0xFF6B6BFF),
            isDark: isDark,
          ),
          if (_totalMeals > 0) ...[
            const SizedBox(width: 8),
            _statPill(
              icon: LucideIcons.utensils,
              text: '$_totalMeals Meals',
              color: const Color(0xFFE5F5FF),
              textColor: const Color(0xFF4A9FFF),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Day selector (horizontal scrollable chips) ──────────────────────
  Widget _buildDaySelector(bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkGrey : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final day = _days[i];
            final isSelected = i == _selectedDayIndex;

            String dateLabel = 'Day ${day.day}';
            String weekday = '';
            if (day.date.isNotEmpty) {
              try {
                final dt = DateTime.parse(day.date);
                const weekdays = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                weekday = weekdays[dt.weekday - 1];
                dateLabel = '${dt.day}/${dt.month}';
              } catch (_) {}
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected ? AppDesign.eerieBlack : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekday.isNotEmpty ? weekday : 'D${day.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected
                                ? Colors.white70
                                : (isDark ? Colors.white54 : AppDesign.midGrey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppDesign.eerieBlack),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 24-hour timeline ───────────────────────────────────────────────
  Widget _buildTimeline(bool isDark, Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: 24,
      itemBuilder: (context, index) {
        final hour = index;
        final timeStr =
            hour < 12
                ? '${hour.toString().padLeft(2, '0')} AM'
                : hour == 12
                ? '12 PM'
                : '${(hour - 12).toString().padLeft(2, '0')} PM';

        final event = _getEventAtHour(hour);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppDesign.midGrey,
                ),
              ),
            ),
            Expanded(
              child:
                  event != null
                      ? _buildEventCard(event, isDark, textColor)
                      : Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 0),
                      ),
            ),
          ],
        );
      },
    );
  }

  _CalendarEvent? _getEventAtHour(int hour) {
    for (final event in _currentEvents) {
      final startHour = int.tryParse(event.startTime.split(':')[0]) ?? -1;
      if (startHour == hour) return event;
    }
    return null;
  }

  // ── Event card ─────────────────────────────────────────────────────
  Widget _buildEventCard(_CalendarEvent event, bool isDark, Color textColor) {
    final startHour = int.tryParse(event.startTime.split(':')[0]) ?? 0;
    final endHour =
        int.tryParse(event.endTime.split(':')[0]) ?? (startHour + 1);
    final duration = (endHour - startHour).clamp(1, 6);
    final cardHeight = (duration * 60.0).clamp(160.0, double.infinity);

    final catColor = _categoryColor(event.category);

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.only(left: 12, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored accent bar
            Container(height: 4, width: double.infinity, color: catColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Title
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _categoryIcon(event.category),
                            size: 20,
                            color: catColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Time
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: isDark ? Colors.white54 : AppDesign.midGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${event.startTime} – ${event.endTime}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : AppDesign.midGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: isDark ? Colors.white54 : AppDesign.midGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : AppDesign.midGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (event.description.isNotEmpty)
                      Expanded(
                        child: Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : AppDesign.midGrey,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Best-time reason
                    if (event.bestTimeReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.lightbulb,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.bestTimeReason,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      isDark
                                          ? Colors.white38
                                          : AppDesign.midGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

  // ── Category helpers ───────────────────────────────────────────────
  Color _categoryColor(String category) {
    return AppDesign.eerieBlack;
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
      case 'food':
      case 'restaurant':
      case 'cafe':
        return LucideIcons.utensils;
      case 'transport':
      case 'metro':
      case 'transfer':
        return LucideIcons.train;
      case 'sightseeing':
      case 'historical':
      case 'cultural':
        return LucideIcons.landmark;
      case 'museum':
        return LucideIcons.building2;
      case 'shopping':
      case 'market':
        return LucideIcons.shoppingBag;
      case 'cruise':
      case 'boat':
        return LucideIcons.ship;
      case 'adventure':
      case 'diving':
      case 'snorkeling':
        return LucideIcons.waves;
      case 'relaxation':
      case 'spa':
      case 'beach':
        return LucideIcons.palmtree;
      default:
        return LucideIcons.mapPin;
    }
  }
}

// ── Data models ──────────────────────────────────────────────────────

class _DayPlan {
  final int day;
  final String date;
  final String title;
  final List<_CalendarEvent> events;

  const _DayPlan({
    required this.day,
    required this.date,
    required this.title,
    required this.events,
  });
}

class _CalendarEvent {
  final String title;
  final String startTime;
  final String endTime;
  final String location;
  final String description;
  final String category;
  final String bestTimeReason;

  const _CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.description,
    required this.category,
    required this.bestTimeReason,
  });
}
