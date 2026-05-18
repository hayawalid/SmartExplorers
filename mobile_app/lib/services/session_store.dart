class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? userId;
  String? username;
  String? accountType; // traveler | service_provider
  String? accessToken; // JWT token from backend
  String? avatarUrl;

  bool get isLoggedIn => userId != null && username != null;

  void setSession({
    required String userId,
    required String username,
    required String accountType,
    String? accessToken,
    String? avatarUrl,
  }) {
    this.userId = userId;
    this.username = username;
    this.accountType = accountType;
    this.accessToken = accessToken;
    this.avatarUrl = avatarUrl;
  }

  void clear() {
    userId = null;
    username = null;
    accountType = null;
    accessToken = null;
    avatarUrl = null;
  }
}
