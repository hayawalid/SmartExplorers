import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import 'api_config.dart';

/// Service for communicating with the AI Chat API
class ChatApiService {
  final http.Client _client;

  ChatApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Send a message to the AI assistant
  Future<ChatResponse> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic>? userContext,
  }) async {
    if (ApiConfig.offlineMode) {
      return ChatResponse(
        message:
            'AI assistant is unavailable in offline mode. '
            'Start the backend server and set offlineMode = false in ApiConfig.',
        conversationId: conversationId ?? 'offline',
        timestamp: DateTime.now(),
      );
    }
    try {
      final request = ChatRequest(
        message: message,
        conversationId: conversationId,
        userContext: userContext,
      );

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw ChatApiException(
          'Failed to send message: ${errorData['detail'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Network error: ${e.toString()}');
    }
  }

  /// Get conversation history
  Future<ConversationHistory> getConversationHistory(
    String conversationId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.conversationEndpoint}/$conversationId',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ConversationHistory.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ChatApiException(
          'Conversation not found',
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw ChatApiException(
          'Failed to get history: ${errorData['detail'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Network error: ${e.toString()}');
    }
  }

  /// Clear conversation history
  Future<bool> clearConversation(String conversationId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.clearConversationEndpoint}/$conversationId',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw ChatApiException(
          'Conversation not found',
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw ChatApiException(
          'Failed to clear conversation: ${errorData['detail'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Network error: ${e.toString()}');
    }
  }

  /// Test API connectivity
  Future<bool> testConnection() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  ChatApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ChatApiException: $message (Status: $statusCode)';
}
