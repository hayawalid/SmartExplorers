import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service Provider API Service
/// Handles all service-related API calls including CRUD, discovery, and matching
class ServicesApiService {
  final http.Client _client;

  ServicesApiService({http.Client? client}) : _client = client ?? http.Client();

  // ==================== PROVIDER ENDPOINTS ====================

  /// Create a new service for the provider
  Future<Map<String, dynamic>> createService({
    required String providerId,
    required String serviceType,
    required String serviceName,
    String? description,
    List<String> tags = const [],
    List<String> clusterKeywords = const [],
    double? priceMin,
    double? priceMax,
    Map<String, dynamic>? availability,
  }) async {
    final body = {
      'provider_id': providerId,
      'service_type': serviceType,
      'service_name': serviceName,
      'description': description,
      'tags': tags,
      'cluster_keywords': clusterKeywords,
      'price_min': priceMin,
      'price_max': priceMax,
      'availability': availability,
    };

    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/services/provider/create'
        '?provider_id=$providerId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create service: ${response.body}');
  }

  /// Update an existing service
  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    required String providerId,
    Map<String, dynamic>? updates,
  }) async {
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/services/provider/$serviceId'
        '?provider_id=$providerId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(updates ?? {}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update service: ${response.body}');
  }

  /// Delete a service
  Future<void> deleteService({
    required String serviceId,
    required String providerId,
  }) async {
    final response = await _client.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/services/provider/$serviceId'
        '?provider_id=$providerId',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }

  /// Get all services for a provider
  Future<List<Map<String, dynamic>>> getProviderServices({
    required String providerId,
    bool activeOnly = true,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/services/provider/list'
        '?provider_id=$providerId&active_only=$activeOnly',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final services = data['services'] as List<dynamic>;
      return services.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch provider services: ${response.body}');
  }

  // ==================== USER DISCOVERY ENDPOINTS ====================

  /// Discover services with smart filtering
  Future<List<Map<String, dynamic>>> discoverServices({
    required String userId,
    int? clusterId,
    String? serviceType,
    List<String>? tags,
    double? latitude,
    double? longitude,
    double radiusKm = 50,
    double minRating = 0,
    int limit = 20,
    int skip = 0,
  }) async {
    final params = <String, String>{
      'user_id': userId,
      'radius_km': radiusKm.toString(),
      'min_rating': minRating.toString(),
      'limit': limit.toString(),
      'skip': skip.toString(),
    };

    if (clusterId != null) params['cluster_id'] = clusterId.toString();
    if (serviceType != null) params['service_type'] = serviceType;
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/services/discover',
    ).replace(queryParameters: params);

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final services = data['services'] as List<dynamic>;
      return services.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to discover services: ${response.body}');
  }

  /// Get nearby services based on location
  Future<List<Map<String, dynamic>>> getNearbyServices({
    required double latitude,
    required double longitude,
    String? serviceType,
    double radiusKm = 50,
    int limit = 20,
  }) async {
    final params = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'limit': limit.toString(),
    };

    if (serviceType != null) {
      params['service_type'] = serviceType;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/services/nearby',
    ).replace(queryParameters: params);

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final services = data['services'] as List<dynamic>;
      return services.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch nearby services: ${response.body}');
  }

  /// Get service details with provider profile
  Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/services/$serviceId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch service details: ${response.body}');
  }

  /// Get services by cluster
  Future<List<Map<String, dynamic>>> getServicesByCluster({
    required int clusterId,
    String? serviceType,
    List<String>? tags,
    int limit = 20,
  }) async {
    final params = {'limit': limit.toString()};

    if (serviceType != null) {
      params['service_type'] = serviceType;
    }
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/services/cluster/$clusterId',
    ).replace(queryParameters: params);

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final services = data['services'] as List<dynamic>;
      return services.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch cluster services: ${response.body}');
  }

  void dispose() {
    _client.close();
  }

  // ==================== BOOKING ENDPOINTS ====================

  /// Create a booking request
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String serviceId,
    required String providerId,
    String? bookingDate,
    String? bookingTime,
    String? specialRequests,
  }) async {
    final body = {
      'user_id': userId,
      'service_id': serviceId,
      'provider_id': providerId,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'special_requests': specialRequests,
      'status': 'pending',
    };

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/marketplace/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create booking: ${response.body}');
  }

  /// Get bookings for a user or provider
  Future<List<Map<String, dynamic>>> getBookings({
    String? userId,
    String? providerId,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId;
    if (providerId != null) params['provider_id'] = providerId;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/marketplace/bookings',
    ).replace(queryParameters: params);

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch bookings: ${response.body}');
  }
}
