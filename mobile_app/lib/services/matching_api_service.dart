import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service for communicating with the Smart Matching Engine backend.
///
/// Endpoints:
///   POST /api/matching/train        — Train clustering model
///   POST /api/matching/find-matches  — Find matches for a user
///   GET  /api/matching/model-status  — Check if model is trained
class MatchingApiService {
  final http.Client _client;

  MatchingApiService({http.Client? client})
      : _client = client ?? http.Client();

  /// Check whether the matching model is trained.
  Future<Map<String, dynamic>> getModelStatus() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/matching/model-status'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'trained': false};
  }

  /// Train (or retrain) the clustering model.
  Future<Map<String, dynamic>> trainModel({int nClusters = 5}) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/matching/train'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'n_clusters': nClusters}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Training failed: ${response.body}');
  }

  /// Find matches for a user identified by [email].
  ///
  /// Returns the full MatchResponse including `matches` list and `statistics`.
  Future<Map<String, dynamic>> findMatches({
    required String userEmail,
    int topK = 10,
    bool includeProviders = true,
    bool includeTravelers = true,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/matching/find-matches'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'user_email': userEmail,
        'top_k': topK,
        'include_providers': includeProviders,
        'include_travelers': includeTravelers,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Parse error detail from backend
    String errorMsg = 'Matching failed';
    try {
      final body = jsonDecode(response.body);
      errorMsg = body['detail'] ?? errorMsg;
    } catch (_) {}
    throw Exception(errorMsg);
  }

  void dispose() => _client.close();
}
