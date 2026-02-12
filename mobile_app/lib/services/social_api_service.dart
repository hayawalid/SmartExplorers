import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SocialApiService {
  final http.Client _client;

  SocialApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/posts'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create post: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getTravelSpaces() async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/travel-spaces',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getReviews({String? authorId}) async {
    try {
      final query = authorId != null ? '?author_id=$authorId' : '';
      final response = await _client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.socialEndpoint}/reviews$query',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  void dispose() {
    _client.close();
  }
}
