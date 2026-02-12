import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

/// Handles authentication (login & signup) against the backend.
class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  // ── LOGIN ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      SessionStore.instance.setSession(
        userId: user['_id'] as String,
        username: user['username'] as String,
        accountType: user['account_type'] as String,
        accessToken: data['access_token'] as String,
      );

      return data;
    }

    final body = jsonDecode(response.body);
    final detail =
        body is Map ? body['detail'] ?? 'Login failed' : 'Login failed';
    throw Exception(detail);
  }

  // ── SIGNUP ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String accountType,
    String? phoneNumber,
    String? countryOfOrigin,
    String? preferredLanguage,
    List<String>? travelInterests,
    List<String>? accessibilityNeeds,
    String? serviceType,
    String? bio,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
      'full_name': fullName,
      'account_type': accountType,
    };

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      payload['phone_number'] = phoneNumber;
    }
    if (countryOfOrigin != null && countryOfOrigin.isNotEmpty) {
      payload['country_of_origin'] = countryOfOrigin;
    }
    if (preferredLanguage != null && preferredLanguage.isNotEmpty) {
      payload['preferred_language'] = preferredLanguage;
    }
    if (travelInterests != null && travelInterests.isNotEmpty) {
      payload['travel_interests'] = travelInterests;
    }
    if (accessibilityNeeds != null && accessibilityNeeds.isNotEmpty) {
      payload['accessibility_needs'] = accessibilityNeeds;
    }
    if (serviceType != null && serviceType.isNotEmpty) {
      payload['service_type'] = serviceType;
    }
    if (bio != null && bio.isNotEmpty) {
      payload['bio'] = bio;
    }

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      SessionStore.instance.setSession(
        userId: user['_id'] as String,
        username: user['username'] as String,
        accountType: user['account_type'] as String,
        accessToken: data['access_token'] as String,
      );

      return data;
    }

    final body = jsonDecode(response.body);
    final detail =
        body is Map ? body['detail'] ?? 'Signup failed' : 'Signup failed';
    throw Exception(detail);
  }

  void dispose() => _client.close();
}
