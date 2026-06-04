// lib/services/notifications_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/api_config.dart';
import 'package:mobile_app/services/session_store.dart';

class NotificationsApiService {
  static const String _basePath = '/api/v1/notifications';

  Future<String?> _getAuthToken() async {
    return SessionStore.instance.accessToken;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int skip = 0,
    bool unreadFirst = true,
  }) async {
    final headers = await _headers();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}$_basePath?limit=$limit&skip=$skip&unread_first=$unreadFirst');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/$notificationId/read');
    final response = await http.patch(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark as read: ${response.statusCode}');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllRead() async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/mark-all-read');
    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all read: ${response.statusCode}');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/$notificationId');
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification: ${response.statusCode}');
    }
  }

  void dispose() {
    // Nothing to dispose currently
  }
}