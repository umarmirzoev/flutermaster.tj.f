class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phoneNumber,
    required this.role,
    this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phoneNumber;
  final String role;
  final DateTime? accessTokenExpiresAt;

  bool get isMaster => role.toLowerCase() == 'master';

  bool get isAdmin {
    final r = role.toLowerCase();
    return r == 'admin' || r == 'superadmin';
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: json['userId']?.toString() ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'Client',
      accessTokenExpiresAt: json['accessTokenExpiresAt'] != null
          ? DateTime.tryParse(json['accessTokenExpiresAt'].toString())
          : null,
    );
  }
}
