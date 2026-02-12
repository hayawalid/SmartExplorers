import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/admin_api_service.dart';

/// Admin Dashboard – View insights, provider requests, user reports.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminApiService _adminService = AdminApiService();

  Map<String, dynamic> _stats = {};
  List<dynamic> _providerRequests = [];
  List<dynamic> _reports = [];
  bool _loadingStats = true;
  bool _loadingRequests = true;
  bool _loadingReports = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adminService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadStats();
    _loadProviderRequests();
    _loadReports();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted)
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadProviderRequests() async {
    try {
      final requests = await _adminService.getProviderRequests();
      if (mounted)
        setState(() {
          _providerRequests = requests;
          _loadingRequests = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _adminService.getReports();
      if (mounted)
        setState(() {
          _reports = reports;
          _loadingReports = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : AppDesign.pureWhite;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const SmartExplorersLogo(size: LogoSize.small),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.refreshCw, color: sub, size: 20),
                    onPressed: () {
                      setState(() {
                        _loadingStats = true;
                        _loadingRequests = true;
                        _loadingReports = true;
                      });
                      _loadData();
                    },
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: sub, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Admin Dashboard',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: text),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppDesign.electricCobalt,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: sub,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Insights'),
                  Tab(text: 'Providers'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(isDark, card, text, sub),
                  _buildProvidersTab(isDark, card, text, sub),
                  _buildReportsTab(isDark, card, text, sub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Insights Tab ──────────────────────────────────────────────────────
  Widget _buildInsightsTab(bool isDark, Color card, Color text, Color sub) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Stats grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _statCard(
              'Total Users',
              '${_stats['total_users'] ?? 0}',
              LucideIcons.users,
              const Color(0xFF4A90D9),
              isDark,
              card,
            ),
            _statCard(
              'Travelers',
              '${_stats['total_travelers'] ?? 0}',
              LucideIcons.compass,
              const Color(0xFF00C566),
              isDark,
              card,
            ),
            _statCard(
              'Providers',
              '${_stats['total_providers'] ?? 0}',
              LucideIcons.briefcase,
              const Color(0xFF9B59B6),
              isDark,
              card,
            ),
            _statCard(
              'Verified',
              '${_stats['verified_providers'] ?? 0}',
              LucideIcons.badgeCheck,
              const Color(0xFFD4AF37),
              isDark,
              card,
            ),
            _statCard(
              'Bookings',
              '${_stats['total_bookings'] ?? 0}',
              LucideIcons.calendarCheck,
              const Color(0xFFE8604C),
              isDark,
              card,
            ),
            _statCard(
              'Reviews',
              '${_stats['total_reviews'] ?? 0}',
              LucideIcons.star,
              const Color(0xFFFFA726),
              isDark,
              card,
            ),
            _statCard(
              'Posts',
              '${_stats['total_posts'] ?? 0}',
              LucideIcons.image,
              const Color(0xFF4FACFE),
              isDark,
              card,
            ),
            _statCard(
              'Itineraries',
              '${_stats['total_itineraries'] ?? 0}',
              LucideIcons.map,
              const Color(0xFF11998E),
              isDark,
              card,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Activity summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : AppDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 14),
              _activityRow(
                LucideIcons.userPlus,
                'New users today',
                '${_stats['new_users_today'] ?? 0}',
                const Color(0xFF00C566),
                text,
                sub,
              ),
              const SizedBox(height: 10),
              _activityRow(
                LucideIcons.trendingUp,
                'New users this week',
                '${_stats['new_users_week'] ?? 0}',
                const Color(0xFF4A90D9),
                text,
                sub,
              ),
              const SizedBox(height: 10),
              _activityRow(
                LucideIcons.alertTriangle,
                'Panic events',
                '${_stats['total_panic_events'] ?? 0}',
                AppDesign.danger,
                text,
                sub,
              ),
              const SizedBox(height: 10),
              _activityRow(
                LucideIcons.store,
                'Active listings',
                '${_stats['total_listings'] ?? 0}',
                const Color(0xFF9B59B6),
                text,
                sub,
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color card,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppDesign.midGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(
    IconData icon,
    String label,
    String value,
    Color color,
    Color text,
    Color sub,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: text)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Providers Tab ─────────────────────────────────────────────────────
  Widget _buildProvidersTab(bool isDark, Color card, Color text, Color sub) {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_providerRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: sub),
            const SizedBox(height: 12),
            Text(
              'No provider requests',
              style: TextStyle(color: sub, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _providerRequests.length,
      itemBuilder: (context, index) {
        final p = _providerRequests[index];
        final isVerified = p['verification_status'] == 'verified';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : AppDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF9B59B6).withOpacity(0.15),
                    child: Text(
                      (p['full_name'] ?? 'P').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9B59B6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['full_name'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                        Text(
                          p['service_type'] ?? 'Service Provider',
                          style: TextStyle(fontSize: 12, color: sub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isVerified
                              ? AppDesign.success.withOpacity(0.12)
                              : AppDesign.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVerified ? 'Verified' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isVerified ? AppDesign.success : AppDesign.warning,
                      ),
                    ),
                  ),
                ],
              ),
              if ((p['bio'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  p['bio'],
                  style: TextStyle(fontSize: 13, color: sub),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.mail, size: 13, color: sub),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      p['email'] ?? '',
                      style: TextStyle(fontSize: 12, color: sub),
                    ),
                  ),
                ],
              ),
              if (!isVerified) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final success = await _adminService.rejectProvider(
                            p['id'],
                          );
                          if (success && mounted) {
                            HapticFeedback.mediumImpact();
                            _loadProviderRequests();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDesign.danger,
                          side: const BorderSide(color: AppDesign.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await _adminService.approveProvider(
                            p['id'],
                          );
                          if (success && mounted) {
                            HapticFeedback.mediumImpact();
                            _loadProviderRequests();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Reports Tab ───────────────────────────────────────────────────────
  Widget _buildReportsTab(bool isDark, Color card, Color text, Color sub) {
    if (_loadingReports) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shieldCheck, size: 48, color: sub),
            const SizedBox(height: 12),
            Text(
              'No reports filed',
              style: TextStyle(color: sub, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text('All clear!', style: TextStyle(color: sub, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index];
        final isResolved = r['status'] == 'resolved';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : AppDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isResolved ? AppDesign.success : AppDesign.danger)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isResolved
                          ? LucideIcons.checkCircle
                          : LucideIcons.alertCircle,
                      size: 20,
                      color: isResolved ? AppDesign.success : AppDesign.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['reason'] ?? 'User Report',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                        Text(
                          'by ${r['reporter_name'] ?? 'Anonymous'}',
                          style: TextStyle(fontSize: 12, color: sub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isResolved
                              ? AppDesign.success
                              : AppDesign.warning)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isResolved ? 'Resolved' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isResolved ? AppDesign.success : AppDesign.warning,
                      ),
                    ),
                  ),
                ],
              ),
              if ((r['description'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  r['description'],
                  style: TextStyle(fontSize: 13, color: sub, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!isResolved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await _adminService.resolveReport(
                        r['id'],
                      );
                      if (success && mounted) {
                        HapticFeedback.mediumImpact();
                        _loadReports();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Mark Resolved'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
