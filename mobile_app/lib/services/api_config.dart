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

  static const String usersEndpoint = '/api/v1/users';
  static const String profilesEndpoint = '/api/v1/profiles';
  static const String socialEndpoint = '/api/v1/social';
  static const String marketplaceEndpoint = '/api/v1/marketplace';
  static const String safetyEndpoint = '/api/v1/safety';
  static const String preferencesEndpoint = '/api/v1/preferences';

  // Demo users (until auth is added)
  static const String demoTravelerUsername = 'sarah_explorer';
  static const String demoProviderUsername = 'mohamed_guide';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
