import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class FaceVerificationService {
  FaceVerificationService._();
  static final FaceVerificationService instance = FaceVerificationService._();

  /// Sends id image bytes and selfie image bytes to the backend.
  /// Returns a map with keys: verified (bool), confidence (double), message (String)
  Future<Map<String, dynamic>> verifyFaces({
    required File idImageFile,
    required File selfieFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/verification/verify-faces');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'id_image',
        idImageFile.path,
        filename: 'id_image.jpg',
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'selfie_image',
        selfieFile.path,
        filename: 'selfie.jpg',
      ));

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Face verification error: $e');
    }
  }
}