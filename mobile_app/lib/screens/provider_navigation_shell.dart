// ============================================================================
// provider_navigation_shell.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/session_store.dart';
import '../services/services_api_service.dart';
import 'feed_screen.dart';
import 'safety_hub_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_services_screen.dart';

class ProviderNavigationShell extends StatefulWidget {
  const ProviderNavigationShell({super.key});

  @override
  State<ProviderNavigationShell> createState() => _ProviderNavigationShellState();
}

class _ProviderNavigationShellState extends State<ProviderNavigationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<ProviderNavItem> _navItems = [
    ProviderNavItem(
      icon: LucideIcons.users,
      label: 'Requests',
      activeColor: AppDesign.navExplore,
      semanticLabel: 'Match requests from travelers',
    ),
    ProviderNavItem(
      icon: LucideIcons.briefcase,
      label: 'Services',
      activeColor: AppDesign.navConcierge,
      semanticLabel: 'Your service offerings',
    ),
    ProviderNavItem(
      icon: LucideIcons.compass,
      label: 'Feed',
      activeColor: AppDesign.navItinerary,
      semanticLabel: 'Social feed and promotions',
    ),
    ProviderNavItem(
      icon: LucideIcons.shield,
      label: 'Safety',
      activeColor: AppDesign.navSafety,
      semanticLabel: 'Emergency SOS and safety',
    ),
    ProviderNavItem(
      icon: LucideIcons.user,
      label: 'Profile',
      activeColor: AppDesign.navProfile,
      semanticLabel: 'Your provider profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              const MatchRequestsScreen(),
              const ProviderServicesScreen(),
              FeedScreen(
                currentThemeMode: ThemeMode.system,
                onThemeModeSelected: (value) {},
              ),
              const SafetyHubScreen(),
              const ProviderProfileScreen(),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _FloatingNavBar(
              items: _navItems,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  final List<ProviderNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A20) : AppDesign.pureWhite;
    final inactive = isDark ? Colors.white38 : AppDesign.midGrey;

    return ClipRRect(
      borderRadius: AppDesign.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: bg.withOpacity(isDark ? 0.85 : 0.92),
            borderRadius: AppDesign.borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: isDark ? [] : AppDesign.mediumShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              final item = items[i];
              final tabColor = isActive ? item.activeColor : inactive;
              return Semantics(
                button: true,
                selected: isActive,
                label: item.semanticLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isActive
                            ? item.activeColor.withOpacity(0.12)
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 22, color: tabColor),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: tabColor,
                              letterSpacing: 0.1,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ProviderNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final String semanticLabel;

  const ProviderNavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.semanticLabel,
  });
}

// ============================================================================
// MatchRequestsScreen
// ============================================================================
class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServicesApiService _servicesService = ServicesApiService();

  List<MatchRequest> _pendingRequests = [];
  List<MatchRequest> _confirmedRequests = [];
  bool _isLoading = true;
  String? _error;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final providerId = SessionStore.instance.userId;
    if (providerId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Provider ID not found';
      });
      return;
    }

    try {
      final bookings = await _servicesService.getBookings(providerId: providerId);
      setState(() {
        _pendingRequests = bookings
            .where((b) => (b['status'] ?? 'pending') == 'pending')
            .map((booking) => MatchRequest(
                  id: booking['_id'] ?? '',
                  travelerName: booking['traveler_username'] ??
                      booking['user_id'] ??
                      'Unknown Traveler',
                  service: booking['service_name'] ?? booking['service_id'] ?? 'Service',
                  date: booking['booking_date'] ?? 'TBD',
                  time: booking['booking_time'] ?? 'TBD',
                  duration: 'TBD',
                  price: 'Price on request',
                  message: booking['special_requests'] ?? '',
                  rating: 4.5,
                  isNew: true,
                ))
            .toList();
        _confirmedRequests = bookings
            .where((b) => (b['status'] ?? 'pending') != 'pending')
            .map((booking) => MatchRequest(
                  id: booking['_id'] ?? '',
                  travelerName: booking['traveler_username'] ??
                      booking['user_id'] ??
                      'Unknown Traveler',
                  service: booking['service_name'] ?? booking['service_id'] ?? 'Service',
                  date: booking['booking_date'] ?? 'TBD',
                  time: booking['booking_time'] ?? 'TBD',
                  duration: 'TBD',
                  price: 'Price on request',
                  message: booking['special_requests'] ?? '',
                  rating: 4.5,
                  isNew: false,
                  isConfirmed: true,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load bookings: ${e.toString()}';
      });
    }
  }

  Future<void> _handleAcceptRequest(MatchRequest request) async {
    HapticFeedback.mediumImpact();
    setState(() => _processingId = request.id);
    try {
      await _servicesService.updateBookingStatus(
        bookingId: request.id,
        status: 'confirmed',
        providerResponse: 'accepted',
      );
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == request.id);
        _confirmedRequests.add(MatchRequest(
          id: request.id,
          travelerName: request.travelerName,
          service: request.service,
          date: request.date,
          time: request.time,
          duration: request.duration,
          price: request.price,
          message: request.message,
          rating: request.rating,
          isNew: false,
          isConfirmed: true,
        ));
        _processingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Request accepted successfully!'),
          backgroundColor: AppDesign.success,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _processingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: AppDesign.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDeclineRequest(MatchRequest request) async {
    HapticFeedback.mediumImpact();
    setState(() => _processingId = request.id);
    try {
      await _servicesService.updateBookingStatus(
        bookingId: request.id,
        status: 'declined',
        providerResponse: 'declined',
      );
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == request.id);
        _processingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined'),
          backgroundColor: AppDesign.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _processingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline request: $e'), backgroundColor: AppDesign.danger),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _servicesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final cardColor = isDark ? AppDesign.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final subtitleColor = isDark ? Colors.white70 : AppDesign.midGrey;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppDesign.navExplore, AppDesign.navConcierge],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.users, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Match Requests',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
                        Text(_isLoading ? 'Loading...' : '${_pendingRequests.length} new requests waiting',
                            style: TextStyle(fontSize: 14, color: subtitleColor)),
                      ],
                    ),
                  ),
                  if (!_isLoading)
                    IconButton(
                      icon: Icon(LucideIcons.refreshCw, color: textColor),
                      onPressed: _loadBookings,
                    ),
                ],
              ),
            ),
            if (_error != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppDesign.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppDesign.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: AppDesign.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_error!, style: TextStyle(color: AppDesign.danger, fontSize: 12)),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.refreshCw, color: AppDesign.danger),
                        onPressed: _loadBookings,
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Loading bookings...', style: TextStyle(color: subtitleColor)),
                    ],
                  ),
                ),
              )
            else ...[
              // Tab bar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cardColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.08), blurRadius: 8)],
                  ),
                  labelColor: textColor,
                  unselectedLabelColor: subtitleColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pending'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppDesign.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${_pendingRequests.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Confirmed'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppDesign.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${_confirmedRequests.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_pendingRequests, false, isDark, cardColor, textColor, subtitleColor),
                    _buildRequestsList(_confirmedRequests, true, isDark, cardColor, textColor, subtitleColor),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    List<MatchRequest> requests,
    bool isConfirmed,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(isConfirmed ? LucideIcons.calendarCheck : LucideIcons.users,
                  size: 48, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            Text(isConfirmed ? 'No confirmed bookings' : 'No pending requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            Text(isConfirmed ? 'Confirmed requests will appear here' : 'New match requests will appear here',
                style: TextStyle(fontSize: 14, color: subtitleColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: request.isNew
                    ? AppDesign.navExplore.withOpacity(0.5)
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
                width: request.isNew ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                if (request.isNew)
                  BoxShadow(color: AppDesign.navExplore.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                AppDesign.navExplore.withOpacity(0.5),
                                AppDesign.navConcierge.withOpacity(0.5),
                              ]),
                            ),
                            child: Center(
                              child: Text(request.travelerName[0],
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(request.travelerName,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                                    if (request.isNew) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppDesign.navExplore,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('NEW',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.star, size: 14, color: AppDesign.navProfile),
                                    const SizedBox(width: 4),
                                    Text('${request.rating}', style: TextStyle(fontSize: 13, color: subtitleColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(request.price,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppDesign.navSafety)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildDetailItem(LucideIcons.briefcase, request.service, textColor, subtitleColor),
                                const Spacer(),
                                _buildDetailItem(LucideIcons.clock, request.duration, textColor, subtitleColor),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildDetailItem(LucideIcons.calendar, request.date, textColor, subtitleColor),
                                const Spacer(),
                                _buildDetailItem(LucideIcons.clock, request.time, textColor, subtitleColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('"${request.message}"',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: subtitleColor, height: 1.4)),
                    ],
                  ),
                ),
                if (!isConfirmed)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _processingId == null ? () => _handleDeclineRequest(request) : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppDesign.danger,
                              side: const BorderSide(color: AppDesign.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _processingId == request.id
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _processingId == null ? () => _handleAcceptRequest(request) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesign.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _processingId == request.id
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : const Text('Accept Request'),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton.icon(
                      onPressed: () => HapticFeedback.lightImpact(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.navExplore,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.messageCircle, size: 18),
                      label: const Text('Message Traveler'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color textColor, Color subtitleColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: subtitleColor),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }
}

class MatchRequest {
  final String id;
  final String travelerName;
  final String service;
  final String date;
  final String time;
  final String duration;
  final String price;
  final String message;
  final double rating;
  final bool isNew;
  final bool isConfirmed;

  MatchRequest({
    required this.id,
    required this.travelerName,
    required this.service,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
    required this.message,
    required this.rating,
    this.isNew = false,
    this.isConfirmed = false,
  });
}