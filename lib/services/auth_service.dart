import 'dart:convert';
import 'package:http/http.dart' as http;
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

class AuthService {
  static const String _base = 'http://localhost:8080';

  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    required String birthDate, // YYYY-MM-DD
  }) async {
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$_base/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'birth_date': birthDate,
        }),
      );
    } catch (_) {
      throw const ApiException(
        message: 'Check your internet connection.',
        statusCode: 0,
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 201) {
      return AuthResult(
        token: body['token'] as String,
        user: body['user'] as Map<String, dynamic>,
      );
    }

    final msg = (body['error'] as String?) ?? _defaultMessage(res.statusCode);
    throw ApiException(message: msg, statusCode: res.statusCode);
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$_base/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (_) {
      throw const ApiException(
        message: 'Check your internet connection.',
        statusCode: 0,
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return AuthResult(
        token: body['token'] as String,
        user: body['user'] as Map<String, dynamic>,
      );
    }

    final msg = (body['error'] as String?) ??
        (res.statusCode == 401
            ? 'Incorrect email or password.'
            : _defaultMessage(res.statusCode));
    throw ApiException(message: msg, statusCode: res.statusCode);
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 400: return 'Invalid input. Please check your details.';
      case 409: return 'An account with that email or username already exists.';
      case 422: return 'Please check your details and try again.';
      case 429: return 'Too many attempts. Please wait and try again.';
      default:  return 'Something went wrong. Please try again later.';
    }
  }
}

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'lokal_auth_token';

  static Future<void> save(String token) =>
      _storage.write(key: _key, value: token);

  static Future<String?> get() => _storage.read(key: _key);

  static Future<void> clear() => _storage.delete(key: _key);
}
