import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../models.dart';
import '../auth_service.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();
  @override
  String toString() => 'Session expired';
}

class ApiClient {
  
  static const String baseUrl = apiBaseUrl;

  /// HTTP client used for every request. Overridable in tests with a mock
  /// (e.g. `http.testing.MockClient`).
  static http.Client client = http.Client();

  /// Set by the app shell so the API layer can trigger a logout/navigation
  /// without holding a `BuildContext` (e.g. on a 401 or a missing account).
  static void Function()? onSessionExpired;

  
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await TokenStorage.get();
      if (token == null || token.isEmpty) {
        onSessionExpired?.call();
        throw const SessionExpiredException();
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// In-flight refresh, shared by every request that hits a 401 at the same
  /// time. Without it, a screen firing three parallel calls would spend three
  /// refresh tokens; the server rotates on use, so the last two would fail and
  /// log the user out mid-session.
  static Future<bool>? _refreshInFlight;

  /// Exchanges the stored refresh token for a new session. Returns false when
  /// the refresh token is missing or rejected — the caller must then treat the
  /// session as over.
  static Future<bool> _refreshSession() {
    return _refreshInFlight ??= () async {
      try {
        final refreshToken = await TokenStorage.getRefresh();
        if (refreshToken == null || refreshToken.isEmpty) return false;

        final res = await client
            .post(
              Uri.parse('$baseUrl/api/auth/refresh'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}),
            )
            .timeout(apiTimeout);

        if (res.statusCode < 200 || res.statusCode >= 300) return false;

        await TokenStorage.saveSession(
          AuthResult.fromJson(asMap(jsonDecode(res.body))),
        );
        return true;
      } catch (_) {
        // A network failure is not proof the session is gone, but the request
        // that triggered this cannot proceed either. Reporting false ends this
        // attempt; the next one retries the refresh from scratch.
        return false;
      } finally {
        _refreshInFlight = null;
      }
    }();
  }

  /// Sanitizes MinIO presigned URLs for local testing / Android emulator
  /// (mapping localhost:9000 or minio:9000 to 10.0.2.2:9000 per FRONTEND_GUIDE.md §3 & §12).
  static String sanitizeUploadUrl(String url) {
    var sanitized = url;
    if (sanitized.contains('localhost:9000')) {
      sanitized = sanitized.replaceAll('localhost:9000', '10.0.2.2:9000');
    }
    if (sanitized.contains('minio:9000')) {
      sanitized = sanitized.replaceAll('minio:9000', '10.0.2.2:9000');
    }
    return sanitized;
  }

  static Future<dynamic> _handle(http.Response res, {bool auth = true}) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    final body = _tryDecode(res.body);
    final errorStr = body?['error'] as String? ?? '';

    // A 401 that survived the refresh-and-retry in _send means the session is
    // genuinely over. A 401 on an unauthenticated endpoint (e.g. login with
    // wrong credentials) is just a regular API error to surface.
    if (res.statusCode == 401 && auth) {
      await TokenStorage.clear();
      onSessionExpired?.call();
      if (errorStr.contains('account no longer active')) {
        throw const ApiException(
          message: 'Tu cuenta ha sido eliminada.',
          statusCode: 401,
        );
      }
      throw const SessionExpiredException();
    }

    final msg =
        (body?['error'] as String?) ??
        (res.statusCode == 401
            ? 'Correo o contraseña incorrectos.'
            : res.statusCode == 403
            ? 'Tu cuenta está suspendida. Escríbenos si crees que es un error.'
            : res.statusCode == 404
            ? 'Usuario no encontrado.'
            : res.statusCode == 422
            ? 'No fue posible completar la solicitud. Verifica los datos ingresados.'
            : 'Algo salió mal. Inténtalo de nuevo en un momento.');
    throw ApiException(message: msg, statusCode: res.statusCode);
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Runs an authenticated request, refreshing the access token once if the
  /// server rejects it.
  static Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool auth = true,
  }) async {
    var res = await request(await _headers(auth: auth)).timeout(apiTimeout);

    if (res.statusCode == 401 && auth) {
      final body = _tryDecode(res.body);
      final errorStr = body?['error'] as String? ?? '';
      // If the account was deleted, do not attempt to refresh with revoked tokens
      if (errorStr.contains('account no longer active')) {
        await TokenStorage.clear();
        onSessionExpired?.call();
        throw const ApiException(
          message: 'Tu cuenta ha sido eliminada.',
          statusCode: 401,
        );
      }

      if (await _refreshSession()) {
        res = await request(await _headers(auth: auth)).timeout(apiTimeout);
      }
    }

    return _handle(res, auth: auth);
  }

  static Future<dynamic> get(String path, {bool auth = true}) => _send(
    (headers) => client.get(Uri.parse('$baseUrl$path'), headers: headers),
    auth: auth,
  );

  static Future<dynamic> post(
    String path, [
    Map<String, dynamic>? data,
    bool auth = true,
  ]) => _send(
    (headers) => client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: data == null ? null : jsonEncode(data),
    ),
    auth: auth,
  );

  static Future<dynamic> patch(String path, [Map<String, dynamic>? data]) =>
      _send(
        (headers) => client.patch(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: data == null ? null : jsonEncode(data),
        ),
      );

  static Future<dynamic> delete(String path) => _send(
    (headers) => client.delete(Uri.parse('$baseUrl$path'), headers: headers),
  );

  static Map<String, dynamic> asMap(dynamic j) =>
      (j as Map).cast<String, dynamic>();

  
  static int intOf(Object? v) => (v as num?)?.toInt() ?? 0;
}
