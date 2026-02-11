/// API Configuration
/// Update the baseUrl with your actual backend server URL
class ApiConfig {
  // For iOS Simulator: Use http://localhost:8000
  // For Android Emulator: Use http://10.0.2.2:8000
  // For Physical Device: Use your computer's IP (e.g., http://192.168.1.100:8000)
  static const String baseUrl = 'http://localhost:8000';

  // ── OFFLINE / MOCK MODE ──────────────────────────────────────────────
  // Set to true to bypass all network calls and use hardcoded dummy data.
  // Flip back to false once the backend is running.
  static const bool offlineMode = true;

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

  // ── DUMMY USERS FOR OFFLINE LOGIN ────────────────────────────────────
  static const List<Map<String, String>> dummyUsers = [
    {
      '_id': 'mock_jana_001',
      'email': 'jana.ghoniem@gmail.com',
      'username': 'jana_explorer',
      'full_name': 'Jana Ghoniem',
      'account_type': 'traveler',
      'password': '12345678',
      'avatar_url': '/static/avatars/sarah.jpg',
    },
    {
      '_id': 'mock_sarah_001',
      'email': 'sarah.johnson@email.com',
      'username': 'sarah_explorer',
      'full_name': 'Sarah Johnson',
      'account_type': 'traveler',
      'password': 'Password123!',
      'avatar_url': '/static/avatars/sarah.jpg',
    },
    {
      '_id': 'mock_ahmed_001',
      'email': 'ahmed.hassan@email.com',
      'username': 'ahmed_adventurer',
      'full_name': 'Ahmed Hassan',
      'account_type': 'traveler',
      'password': 'Password123!',
      'avatar_url': '/static/avatars/ahmed.jpg',
    },
    {
      '_id': 'mock_mohamed_001',
      'email': 'mohamed.guide@egypttours.com',
      'username': 'mohamed_guide',
      'full_name': 'Mohamed Ibrahim',
      'account_type': 'service_provider',
      'password': 'Password123!',
      'avatar_url': '/static/avatars/mohamed.jpg',
    },
  ];

  /// Look up a dummy user by email. Returns null if not found.
  static Map<String, String>? findDummyUserByEmail(String email) {
    final lower = email.toLowerCase();
    for (final u in dummyUsers) {
      if (u['email']!.toLowerCase() == lower) return u;
    }
    return null;
  }

  /// Look up a dummy user by username. Returns null if not found.
  static Map<String, String>? findDummyUserByUsername(String username) {
    for (final u in dummyUsers) {
      if (u['username'] == username) return u;
    }
    return null;
  }
}
