import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:ui';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/models/service_models.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/smart_explorers_logo.dart';
import 'package:mobile_app/screens/shared/service_detail_screen.dart';

/// Service Discovery Screen for Travelers
/// Browse and discover services from providers matching their preferences
class ServiceDiscoveryScreen extends StatefulWidget {
  const ServiceDiscoveryScreen({super.key});

  @override
  State<ServiceDiscoveryScreen> createState() => _ServiceDiscoveryScreenState();
}

class _ServiceDiscoveryScreenState extends State<ServiceDiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  final ServicesApiService _servicesService = ServicesApiService();

  List<Service> _services = [];
  List<Service> _filteredServices = [];
  bool _isLoading = false;
  String? _error;

  // Booking status tracking
  Map<String, String> _bookingStatuses = {}; // service_id -> status
  bool _loadingBookings = false;

  // Filter state
  String _selectedServiceType = 'All';
  List<String> _selectedTags = [];
  double _minRating = 0;
  bool _useLocationFilter = false;

  final List<String> _serviceTypes = [
    'All',
    'tour_guide',
    'driver',
    'photographer',
    'interpreter',
    'local_expert',
  ];

  final List<String> _availableTags = [
    'history',
    'photography',
    'adventure',
    'food',
    'culture',
    'museums',
    'shopping',
    'nightlife',
    'nature',
    'wellness',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadUserBookings();
  }

  Future<void> _loadUserBookings() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) return;

    setState(() => _loadingBookings = true);

    try {
      final bookings = await _servicesService.getBookings(userId: userId);

      final statuses = <String, String>{};
      for (final booking in bookings) {
        final serviceId = booking['service_id'] as String?;
        final status = booking['status'] as String?;
        if (serviceId != null && status != null) {
          statuses[serviceId] = status;
        }
      }

      setState(() {
        _bookingStatuses = statuses;
        _loadingBookings = false;
      });
    } catch (e) {
      setState(() => _loadingBookings = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = SessionStore.instance.userId ?? 'user_001';

      List<Service> services = await _servicesService
          .discoverServices(
            userId: userId,
            serviceType:
                _selectedServiceType == 'All' ? null : _selectedServiceType,
            tags: _selectedTags.isEmpty ? null : _selectedTags,
            minRating: _minRating,
            limit: 50,
          )
          .then((data) => data.map((json) => Service.fromJson(json)).toList());

      setState(() {
        _services = services;
        _filteredServices = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load services: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserBookings();
    }
  }

  void _filterServices() {
    _loadServices();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _filterServices();
  }

  void _navigateToServiceDetail(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: service),
      ),
    );
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
          'Discover Services',
          style: TextStyle(
            color: AppDesign.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.sliders_horizontal),
            onPressed: () => _showFilterModal(),
            color: AppDesign.textColor,
          ),
        ],
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
                      LucideIcons.x,
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
              : _filteredServices.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 64,
                      color: AppDesign.textColorMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No services found',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try adjusting your filters',
                      style: TextStyle(
                        color: AppDesign.textColorMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Active tags display
                      if (_selectedTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Wrap(
                            spacing: 8,
                            children:
                                _selectedTags.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    onDeleted: () => _toggleTag(tag),
                                    backgroundColor: AppDesign.accentColor,
                                    labelStyle: const TextStyle(
                                      color: AppDesign.textColorLight,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                      // Service cards
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return _buildServiceCard(service);
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildServiceCard(Service service) {
    final bookingStatus = _bookingStatuses[service.id] ?? 'none';
    final hasBooking = bookingStatus != 'none';

    return GestureDetector(
      onTap: () => _navigateToServiceDetail(service),
      child: Container(
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
              // Header with title and booking status
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
                          service.serviceType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppDesign.textColorMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Booking status badge
                  _buildBookingStatusBadge(bookingStatus),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (service.rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesign.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 14,
                            color: AppDesign.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppDesign.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Book button (visible only if no active booking)
                  if (!hasBooking)
                    GestureDetector(
                      onTap: () => _navigateToServiceDetail(service),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesign.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (service.description != null)
                Text(
                  service.description!,
                  style: const TextStyle(
                    color: AppDesign.textColorMuted,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Tags
              if (service.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children:
                      service.tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppDesign.accentColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                ),

              const SizedBox(height: 12),

              // Provider and price row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider',
                          style: const TextStyle(
                            color: AppDesign.textColorMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          service.providerName ?? 'Unknown',
                          style: const TextStyle(
                            color: AppDesign.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Price',
                        style: const TextStyle(
                          color: AppDesign.textColorMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        service.priceRange,
                        style: const TextStyle(
                          color: AppDesign.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Distance if available
              if (service.distanceKm != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.map_pin,
                        size: 12,
                        color: AppDesign.textColorMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.distanceKm!.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: AppDesign.textColorMuted,
                          fontSize: 11,
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

  Widget _buildBookingStatusBadge(String status) {
    Color badgeColor;
    String badgeText;
    IconData? icon;

    switch (status) {
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'Requested';
        icon = LucideIcons.clock;
        break;
      case 'confirmed':
        badgeColor = Colors.green;
        badgeText = 'Confirmed';
        icon = LucideIcons.check;
        break;
      case 'declined':
        badgeColor = Colors.red;
        badgeText = 'Declined';
        icon = LucideIcons.x;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppDesign.surfaceColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Services',
                    style: TextStyle(
                      color: AppDesign.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Type Filter
                  const Text(
                    'Service Type',
                    style: TextStyle(
                      color: AppDesign.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _serviceTypes.map((type) {
                          final isSelected = _selectedServiceType == type;
                          return FilterChip(
                            label: Text(type.replaceAll('_', ' ')),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedServiceType = type;
                              });
                            },
                            backgroundColor: AppDesign.cardColor,
                            selectedColor: AppDesign.accentColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? AppDesign.textColorLight
                                      : AppDesign.textColor,
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Tags Filter
                  const Text(
                    'Tags',
                    style: TextStyle(
                      color: AppDesign.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _toggleTag(tag);
                              });
                            },
                            backgroundColor: AppDesign.cardColor,
                            selectedColor: AppDesign.accentColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? AppDesign.textColorLight
                                      : AppDesign.textColor,
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Rating Filter
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(
                      color: AppDesign.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _minRating.toStringAsFixed(1),
                    activeColor: AppDesign.accentColor,
                    onChanged: (value) {
                      setModalState(() {
                        _minRating = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        _filterServices();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.accentColor,
                        foregroundColor: AppDesign.textColorLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _servicesService.dispose();
    super.dispose();
  }
}
