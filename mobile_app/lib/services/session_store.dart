class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? userId;
  String? username;
  String? accountType; // traveler | service_provider

  bool get isLoggedIn => userId != null && username != null;

  void setSession({
    required String userId,
    required String username,
    required String accountType,
  }) {
    this.userId = userId;
    this.username = username;
    this.accountType = accountType;
  }

  void clear() {
    userId = null;
    username = null;
    accountType = null;
  }
}
