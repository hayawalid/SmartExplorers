import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MarketplaceApiService {
  final http.Client _client;

  MarketplaceApiService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getListings({String? category}) async {
    // if (ApiConfig.offlineMode) return []; // COMMENTED OUT
    final query = category != null ? '?category=$category' : '';
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.marketplaceEndpoint}/listings$query',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createListing(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.marketplaceEndpoint}/listings',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create listing: ${response.body}');
  }

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.marketplaceEndpoint}/bookings',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create booking: ${response.body}');
  }

  void dispose() {
    _client.close();
  }
}
