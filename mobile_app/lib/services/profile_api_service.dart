import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ProfileApiService {
  final http.Client _client;

  ProfileApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    // ── Offline mock ──
    if (ApiConfig.offlineMode) {
      final mock = ApiConfig.findDummyUserByUsername(username);
      if (mock != null) return Map<String, dynamic>.from(mock);
      throw Exception('User not found (offline mode)');
    }

    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/by-username/$username',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch user: ${response.body}');
  }

  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    // ── Offline mock ──
    if (ApiConfig.offlineMode) {
      final mock = ApiConfig.findDummyUserByEmail(email);
      if (mock != null) return Map<String, dynamic>.from(mock);
      throw Exception('User not found (offline mode)');
    }

    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/by-email/$email',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch user: ${response.body}');
  }

  Future<Map<String, dynamic>?> getTravelerProfile(String userId) async {
    if (ApiConfig.offlineMode) return {'user_id': userId};
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/travelers/$userId',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProviderProfile(String userId) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/providers/$userId',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> upsertTravelerProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/travelers/$userId',
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
    throw Exception('Failed to save traveler profile: ${response.body}');
  }

  Future<Map<String, dynamic>> upsertProviderProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/providers/$userId',
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
    throw Exception('Failed to save provider profile: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getUserPhotos(String userId) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/photos?user_id=$userId',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/reviews?author_id=$userId',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getProviderReviews(
    String providerId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/reviews?provider_id=$providerId',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getProviderPortfolio(
    String providerId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/providers/$providerId/portfolio',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getProviderCredentials(
    String providerId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.profilesEndpoint}/providers/$providerId/credentials',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  void dispose() {
    _client.close();
  }
}
