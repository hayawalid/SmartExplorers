import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:ui';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../services/session_store.dart';
import '../services/services_api_service.dart';

/// Service Detail Screen
/// Shows comprehensive details about a service with provider information
class ServiceDetailScreen extends StatefulWidget {
  final Service service;

  const ServiceDetailScreen({required this.service, super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isFavorited = false;
  bool _isBooking = false;
  final ServicesApiService _servicesService = ServicesApiService();

  Future<void> _handleBooking() async {
    final userId = SessionStore.instance.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book services')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      await _servicesService.createBooking(
        userId: userId,
        serviceId: widget.service.id ?? '',
        providerId: widget.service.providerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent! Provider will review shortly.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Optionally navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  void dispose() {
    _servicesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final provider = service.provider;

    return Scaffold(
      backgroundColor: AppDesign.surfaceColor,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppDesign.surfaceColor,
            elevation: 0,
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesign.accentColor.withOpacity(0.8),
                      AppDesign.accentColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getServiceIcon(service.serviceType),
                    size: 80,
                    color: AppDesign.textColorLight.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    _isFavorited ? LucideIcons.heart : LucideIcons.heart,
                    color: _isFavorited ? Colors.red : AppDesign.textColorLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isFavorited
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name and rating
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service.serviceType
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppDesign.textColorMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (service.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.star,
                                    size: 18,
                                    color: AppDesign.accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    service.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppDesign.accentColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${service.reviewsCount} reviews',
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

                  const SizedBox(height: 24),

                  // Description
                  if (service.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.description!,
                      style: const TextStyle(
                        color: AppDesign.textColorMuted,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tags
                  if (service.tags.isNotEmpty) ...[
                    const Text(
                      'Services',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          service.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppDesign.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pricing
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppDesign.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppDesign.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price Range',
                              style: TextStyle(
                                color: AppDesign.textColorMuted,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                        Text(
                          service.priceRange,
                          style: const TextStyle(
                            color: AppDesign.accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Availability
                  if (service.availability.days.isNotEmpty) ...[
                    const Text(
                      'Availability',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppDesign.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesign.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                size: 16,
                                color: AppDesign.textColorMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  service.availability.days.join(', '),
                                  style: const TextStyle(
                                    color: AppDesign.textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (service.availability.hoursStart != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.clock,
                                  size: 16,
                                  color: AppDesign.textColorMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${service.availability.hoursStart} - ${service.availability.hoursEnd}',
                                  style: const TextStyle(
                                    color: AppDesign.textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Provider Information
                  if (provider != null) ...[
                    const Text(
                      'About Provider',
                      style: TextStyle(
                        color: AppDesign.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppDesign.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesign.borderColor,
                          width: 1,
                        ),
                      ),
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
                                    Text(
                                      provider['name'] ?? 'Unknown Provider',
                                      style: const TextStyle(
                                        color: AppDesign.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (provider['verified'] == true)
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.check,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (provider['rating'] != null)
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.star,
                                          size: 14,
                                          color: AppDesign.accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (provider['rating'] as num)
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: AppDesign.accentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${provider['review_count']} reviews',
                                      style: const TextStyle(
                                        color: AppDesign.textColorMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (provider['bio'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              provider['bio'],
                              style: const TextStyle(
                                color: AppDesign.textColorMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (provider['languages'] != null &&
                              (provider['languages'] as List).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 4,
                              children:
                                  (provider['languages'] as List).map<Widget>((
                                    lang,
                                  ) {
                                    return Chip(
                                      label: Text(lang.toString()),
                                      backgroundColor: AppDesign.accentColor
                                          .withOpacity(0.1),
                                      labelStyle: const TextStyle(
                                        color: AppDesign.accentColor,
                                        fontSize: 11,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact info
                  if (service.providerEmail != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppDesign.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesign.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mail,
                            size: 16,
                            color: AppDesign.textColorMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              service.providerEmail!,
                              style: const TextStyle(
                                color: AppDesign.textColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Book button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _handleBooking,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppDesign.accentColor,
                         foregroundColor: AppDesign.textColorLight,
                         disabledBackgroundColor: AppDesign.accentColor.withOpacity(0.5),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       child: _isBooking
                           ? const SizedBox(
                               height: 20,
                               width: 20,
                               child: CircularProgressIndicator(
                                 strokeWidth: 2,
                                 valueColor: AlwaysStoppedAnimation<Color>(
                                   AppDesign.textColorLight,
                                 ),
                               ),
                             )
                           : const Text(
                               'Book Service',
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'tour_guide':
        return LucideIcons.map_pin;
      case 'driver':
        return LucideIcons.navigation;
      case 'photographer':
        return LucideIcons.camera;
      case 'interpreter':
        return LucideIcons.headphones;
      case 'local_expert':
        return LucideIcons.user;
      default:
        return LucideIcons.briefcase;
    }
  }
}
