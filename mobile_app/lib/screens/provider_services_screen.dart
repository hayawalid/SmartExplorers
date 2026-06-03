// ============================================================================
// provider_services_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/services_api_service.dart';
import '../services/session_store.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import 'create_service_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen>
    with AutomaticKeepAliveClientMixin {
  final ServicesApiService _servicesService = ServicesApiService();
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final providerId = SessionStore.instance.userId ?? 'provider_001';
      final services = await _servicesService.getProviderServices(providerId: providerId, activeOnly: true);
      setState(() {
        _services = services.map((json) => Service.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load services: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToCreateService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateServiceScreen()),
    );
    if (result == true) _loadServices();
  }

  void _deleteService(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text('Are you sure you want to delete "${service.serviceName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteService(service);
            },
            style: TextButton.styleFrom(foregroundColor: AppDesign.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteService(Service service) async {
    try {
      final providerId = SessionStore.instance.userId ?? 'provider_001';
      await _servicesService.deleteService(serviceId: service.id!, providerId: providerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully'), behavior: SnackBarBehavior.floating),
      );
      _loadServices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppDesign.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final cardColor = isDark ? AppDesign.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text('My Services'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateService,
        backgroundColor: AppDesign.electricCobalt,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 64, color: AppDesign.danger),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _loadServices, child: const Text('Try Again')),
                    ],
                  ),
                )
              : _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.briefcase, size: 64, color: AppDesign.midGrey),
                          const SizedBox(height: 16),
                          Text('No services yet',
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Create your first service to start accepting bookings',
                              style: TextStyle(color: AppDesign.midGrey, fontSize: 14)),
                          const SizedBox(height: 24),
                          ElevatedButton(onPressed: _navigateToCreateService, child: const Text('Create Service')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 100, // Extra padding for FAB + nav
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) => _buildServiceCard(_services[index], isDark, cardColor, textColor),
                    ),
    );
  }

  Widget _buildServiceCard(Service service, bool isDark, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppDesign.lightGrey),
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.serviceName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(service.serviceType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(fontSize: 12, color: AppDesign.midGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.isActive ? AppDesign.success.withOpacity(0.1) : AppDesign.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(service.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: service.isActive ? AppDesign.success : AppDesign.danger)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Rating', '${service.rating}/5', textColor),
                _buildStat('Reviews', '${service.reviewsCount}', textColor),
                _buildStat('Bookings', '${service.bookingsCount}', textColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppDesign.electricCobalt.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(service.priceRange,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppDesign.electricCobalt)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit feature coming soon'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteService(service),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppDesign.danger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppDesign.midGrey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  @override
  void dispose() {
    _servicesService.dispose();
    super.dispose();
  }
}