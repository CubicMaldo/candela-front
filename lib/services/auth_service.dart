import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final String refreshToken;
  final Map<String, dynamic> user;
  const AuthResult({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    refreshToken: (json['refresh_token'] ?? '') as String,
    user: (json['user'] as Map).cast<String, dynamic>(),
  );
}

/// Result of POST /api/auth/google: either an authenticated session, or the
/// verified email of a Google account that still has no Candela user and must
/// complete registration (username + birth date).
class GoogleAuthOutcome {
  final AuthResult? auth;
  final String? pendingEmail;

  const GoogleAuthOutcome.authenticated(AuthResult this.auth)
    : pendingEmail = null;
  const GoogleAuthOutcome.needsRegistration(String this.pendingEmail)
    : auth = null;

  bool get needsRegistration => pendingEmail != null;
}

/// Holds the session pair. The access token expires after an hour; the refresh
/// token is what actually keeps the user signed in, and is exchanged for a new
/// pair transparently by [ApiService].
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'candela_auth_token';
  static const _refreshKey = 'candela_refresh_token';

  static Future<void> save(String token, {String? refreshToken}) async {
    await _storage.write(key: _key, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  static Future<void> saveSession(AuthResult result) =>
      save(result.token, refreshToken: result.refreshToken);

  static Future<String?> get() => _storage.read(key: _key);

  static Future<String?> getRefresh() => _storage.read(key: _refreshKey);

  static Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _refreshKey);
  }
}
