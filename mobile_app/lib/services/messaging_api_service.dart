import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

class MessagingApiService {
  final http.Client _client;

  MessagingApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = SessionStore.instance.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get messages between current user and another user
  Future<List<Map<String, dynamic>>> getMessages(
    String otherUserId, {
    int limit = 50,
    String? before,
  }) async {
    final myId = SessionStore.instance.userId;
    if (myId == null) throw Exception('Not logged in');

    // First find or create conversation
    final convId = await _getConversationId(otherUserId);
    if (convId == null) return [];

    final headers = await _headers();
    final queryParams = {'limit': limit.toString()};
    if (before != null) queryParams['before'] = before;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/messages/conversations/$convId/messages',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>;
      return messages.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage(
    String recipientId,
    String text, {
    String? bookingId,
  }) async {
    final myId = SessionStore.instance.userId;
    if (myId == null) throw Exception('Not logged in');

    // Get or create conversation
    String convId = await _getOrCreateConversation(recipientId);

    final headers = await _headers();
    final body = {'content': text};

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations/$convId/messages'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to send message: ${response.statusCode}');
  }

  /// Get all conversations for current user
  Future<List<Map<String, dynamic>>> getConversations() async {
    final myId = SessionStore.instance.userId;
    if (myId == null) return [];

    final headers = await _headers();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    final headers = await _headers();
    await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations/$conversationId/archive'),
      headers: headers,
    );
  }

  // ---------- Private helpers ----------
  Future<String?> _getConversationId(String otherUserId) async {
    final convs = await getConversations();
    for (final conv in convs) {
      if (conv['other_user_id'] == otherUserId) {
        return conv['id'];
      }
    }
    return null;
  }

  Future<String> _getOrCreateConversation(String otherUserId) async {
    final existing = await _getConversationId(otherUserId);
    if (existing != null) return existing;

    final headers = await _headers();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/messages/conversations'),
      headers: headers,
      body: jsonEncode({'participant_id': otherUserId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id'];
    }
    throw Exception('Failed to create conversation');
  }

  void dispose() => _client.close();
}