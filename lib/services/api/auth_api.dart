import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class AuthApi {

  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    required String birthDate,
  }) async {
    final j = await ApiClient.post('/api/auth/register', {
      'email': email,
      'username': username,
      'password': password,
      'birth_date': birthDate,
    }, false);
    return AuthResult.fromJson(ApiClient.asMap(j));
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final j = await ApiClient.post('/api/auth/login', {
      'email': email,
      'password': password,
    }, false);
    return AuthResult.fromJson(ApiClient.asMap(j));
  }

  static Future<GoogleAuthOutcome> loginWithGoogle({
    required String idToken,
  }) async {
    final j = await ApiClient.post('/api/auth/google', {'id_token': idToken}, false);
    final m = ApiClient.asMap(j);
    if (m['needs_registration'] == true) {
      return GoogleAuthOutcome.needsRegistration((m['email'] ?? '').toString());
    }
    return GoogleAuthOutcome.authenticated(AuthResult.fromJson(m));
  }

  static Future<AuthResult> registerWithGoogle({
    required String idToken,
    required String username,
    required String birthDate, // YYYY-MM-DD
  }) async {
    final j = await ApiClient.post('/api/auth/google/register', {
      'id_token': idToken,
      'username': username,
      'birth_date': birthDate,
    }, false);
    return AuthResult.fromJson(ApiClient.asMap(j));
  }

  /// Ends the session on this device: revokes the refresh token server-side so
  /// it cannot be replayed, then clears local storage. Clearing happens even if
  /// the network call fails — a user who tapped "cerrar sesión" must not be
  /// left signed in.
  static Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefresh();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiClient.post('/api/auth/logout', {'refresh_token': refreshToken}, false);
      }
    } catch (_) {
      // Best effort; the token expires on its own.
    } finally {
      await TokenStorage.clear();
    }
  }

  static Future<void> deleteAccount() async {
    await ApiClient.delete('/api/me');
    await TokenStorage.clear();
  

  }
}
