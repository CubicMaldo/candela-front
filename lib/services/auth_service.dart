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
  final Map<String, dynamic> user;
  const AuthResult({required this.token, required this.user});
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

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'candela_auth_token';

  static Future<void> save(String token) =>
      _storage.write(key: _key, value: token);

  static Future<String?> get() => _storage.read(key: _key);

  static Future<void> clear() => _storage.delete(key: _key);
}
