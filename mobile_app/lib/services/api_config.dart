/// API Configuration
/// Update the baseUrl with your actual backend server URL
class ApiConfig {
  // For iOS Simulator: Use http://localhost:8000
  // For Android Emulator: Use http://10.0.2.2:8000
  // For Physical Device: Use your computer's IP (e.g., http://192.168.1.100:8000)
  static const String baseUrl = 'http://localhost:8000';

  // API endpoints
  static const String chatEndpoint = '/api/v1/chat/';
  static const String conversationEndpoint = '/api/v1/chat/conversation';
  static const String clearConversationEndpoint = '/api/v1/chat/conversation';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
