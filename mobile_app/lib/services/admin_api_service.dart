import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service for communicating with the admin dashboard API.
class AdminApiService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/stats'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  Future<List<dynamic>> getProviderRequests({String? status}) async {
    var url =
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/provider-requests';
    if (status != null) url += '?status=$status';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> approveProvider(String providerId) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/provider-requests/$providerId/approve',
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> rejectProvider(String providerId) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/provider-requests/$providerId/reject',
      ),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getReports({String? status}) async {
    var url = '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/reports';
    if (status != null) url += '?status=$status';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> resolveReport(String reportId) async {
    final response = await _client.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/reports/$reportId/resolve',
      ),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getCategoryBreakdown() async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/category-breakdown',
      ),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getRecentUsers({int limit = 10}) async {
    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminEndpoint}/recent-users?limit=$limit',
      ),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  void dispose() => _client.close();
}
