import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

/// Service to communicate with the unified planner backend.
class PlannerApiService {
  PlannerApiService._();
  static final PlannerApiService instance = PlannerApiService._();

  final String _chatUrl = '${ApiConfig.baseUrl}/api/v1/planner/chat';
  final String _saveUrl = '${ApiConfig.baseUrl}/api/v1/planner/save';

  /// Headers with optional JWT auth
  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = SessionStore.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Send a message to the unified planner.
  /// Returns a map with keys: mode, message, conversation_id, suggestions, itinerary.
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic>? userContext,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (userContext != null) body['user_context'] = userContext;

    final response = await http
        .post(Uri.parse(_chatUrl), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Planner API error ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Retrieve the user's latest saved itinerary from the database.
  Future<Map<String, dynamic>?> getMyItinerary() async {
    final userId = SessionStore.instance.userId;
    if (userId == null || userId.isEmpty) return null;

    final url = '${ApiConfig.baseUrl}/api/v1/planner/my-itinerary/$userId';
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['found'] == true) {
        return data['itinerary'] as Map<String, dynamic>?;
      }
      return null;
    } else {
      throw Exception(
        'Get itinerary error ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Save the generated itinerary to the database.
  Future<Map<String, dynamic>> saveItinerary({
    required Map<String, dynamic> itinerary,
    String? conversationId,
  }) async {
    final body = <String, dynamic>{
      'itinerary': itinerary,
      'user_id': SessionStore.instance.userId,
      'conversation_id': conversationId,
    };

    final response = await http
        .post(Uri.parse(_saveUrl), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Save itinerary error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
