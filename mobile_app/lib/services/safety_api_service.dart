import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SafetyApiService {
  final http.Client _client;

  SafetyApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getSafetyProfile(String userId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.safetyEndpoint}/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'user_id': userId};
  }

  Future<Map<String, dynamic>> updateSafetyProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.safetyEndpoint}/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update safety profile: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.safetyEndpoint}/$userId/contacts',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createEmergencyContact(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.safetyEndpoint}/$userId/contacts',
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
    throw Exception('Failed to create emergency contact: ${response.body}');
  }

  Future<Map<String, dynamic>> createPanicEvent(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.safetyEndpoint}/$userId/panic-events',
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
    throw Exception('Failed to create panic event: ${response.body}');
  }

  void dispose() {
    _client.close();
  }
}
