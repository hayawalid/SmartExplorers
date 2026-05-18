import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/services_api_service.dart';
import '../services/session_store.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import 'create_service_screen.dart';

/// Provider Service Management Screen
/// Allows providers to create, edit, and manage their services
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

      final services = await _servicesService.getProviderServices(
        providerId: providerId,
        activeOnly: true,
      );

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

    if (result == true) {
      _loadServices();
    }
  }

  void _deleteService(Service service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text(
            'Are you sure you want to delete "${service.serviceName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performDeleteService(service);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppDesign.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteService(Service service) async {
    try {
      final providerId = SessionStore.instance.userId ?? 'provider_001';
      await _servicesService.deleteService(
        serviceId: service.id!,
        providerId: providerId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully')),
      );

      _loadServices();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppDesign.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceColor,
        elevation: 0,
        title: const Text(
          'My Services',
          style: TextStyle(
            color: AppDesign.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateService,
        backgroundColor: AppDesign.accentColor,
        child: const Icon(LucideIcons.plus, color: AppDesign.textColorLight),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppDesign.accentColor),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 64,
                      color: AppDesign.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadServices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.accentColor,
                        foregroundColor: AppDesign.textColorLight,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _services.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.briefcase,
                      size: 64,
                      color: AppDesign.textColorMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No services yet',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first service to start accepting bookings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppDesign.textColorMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _navigateToCreateService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.accentColor,
                        foregroundColor: AppDesign.textColorLight,
                      ),
                      child: const Text('Create Service'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return _buildServiceCard(service);
                },
              ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppDesign.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: const TextStyle(
                          color: AppDesign.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: AppDesign.textColorMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        service.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: service.isActive ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Rating', '${service.rating}/5'),
                _buildStat('Reviews', '${service.reviewsCount}'),
                _buildStat('Bookings', '${service.bookingsCount}'),
              ],
            ),

            const SizedBox(height: 12),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppDesign.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                service.priceRange,
                style: const TextStyle(
                  color: AppDesign.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to edit screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit feature coming soon')),
                    );
                  },
                  icon: const Icon(LucideIcons.edit2),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppDesign.accentColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteService(service),
                  icon: const Icon(LucideIcons.trash2),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppDesign.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppDesign.textColorMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppDesign.textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _servicesService.dispose();
    super.dispose();
  }
}
