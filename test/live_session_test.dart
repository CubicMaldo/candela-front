@Tags(['live'])
library;

/// Exercises the real [ApiService] session handling against a running API.
///
/// Unlike the rest of the suite this talks to a live server, so it is tagged
/// `live` and skipped unless one is reachable. Run it with:
///
///   flutter test --dart-define=API_BASE_URL=http://localhost:8080 \
///     test/live_session_test.dart
///
/// It is the only place the transparent-refresh path is covered end to end:
/// a mocked 401 proves the branch is wired, but only a real expired JWT proves
/// the server agrees the token is dead and that the stored refresh token can
/// revive the session.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:candela_front/config.dart';
import 'package:candela_front/services/api_service.dart';
import 'package:candela_front/services/auth_service.dart';

const _email = 'ana.garcia@example.com';
const _password = 'password123';

Future<bool> _serverIsUp() async {
  try {
    final res = await http
        .get(Uri.parse('$apiBaseUrl/health'))
        .timeout(const Duration(seconds: 3));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Seconds the access token lives, as the server itself reports it.
Future<int> _accessTokenTtl() async {
  final res = await http.post(
    Uri.parse('$apiBaseUrl/api/auth/login'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'email': _email, 'password': _password}),
  );
  return (jsonDecode(res.body)['expires_in'] as num).toInt();
}

void main() {
  // The binding is needed for the secure-storage platform channel, but it also
  // installs an HttpOverrides that answers every request with 400 and never
  // touches the network. Clearing it restores real sockets, which is the whole
  // point of this suite.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  // In-memory stand-in for flutter_secure_storage's platform channel.
  final secureStore = <String, String>{};
  const secureChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() async {
    if (!await _serverIsUp()) {
      throw StateError(
        'No API reachable at $apiBaseUrl. Start the stack and pass '
        '--dart-define=API_BASE_URL=http://localhost:8080',
      );
    }
  });

  setUp(() {
    secureStore.clear();
    ApiService.client = http.Client();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'write':
              secureStore[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return secureStore[args['key'] as String];
            case 'delete':
              secureStore.remove(args['key'] as String);
              return null;
            case 'readAll':
              return secureStore;
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'containsKey':
              return secureStore.containsKey(args['key'] as String);
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
    ApiService.onSessionExpired = null;
  });

  test('login stores both tokens', () async {
    final result = await ApiService.login(email: _email, password: _password);
    await TokenStorage.saveSession(result);

    expect(result.token, isNotEmpty);
    expect(result.refreshToken, isNotEmpty);
    expect(await TokenStorage.get(), result.token);
    expect(await TokenStorage.getRefresh(), result.refreshToken);

    final me = await ApiService.getMyProfile();
    expect(me.username, 'ana_garcia');
  });

  test(
    'an expired access token is refreshed transparently',
    () async {
      final ttl = await _accessTokenTtl();
      if (ttl > 120) {
        markTestSkipped(
          'access token lives ${ttl}s; waiting it out is impractical. '
          'Shorten accessTokenTTL to exercise this.',
        );
        return;
      }

      final result = await ApiService.login(email: _email, password: _password);
      await TokenStorage.saveSession(result);

      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;

      // Works right away.
      expect((await ApiService.getMyProfile()).username, 'ana_garcia');

      // Let the access token actually die on the server.
      await Future<void>.delayed(Duration(seconds: ttl + 5));

      // The server now rejects the stored access token outright...
      final rejected = await http.get(
        Uri.parse('$apiBaseUrl/api/me'),
        headers: {'Authorization': 'Bearer ${result.token}'},
      );
      expect(
        rejected.statusCode,
        401,
        reason:
            'the token must really be expired for this test to mean anything',
      );

      // ...yet the client recovers without the caller noticing.
      final profile = await ApiService.getMyProfile();
      expect(profile.username, 'ana_garcia');
      expect(loggedOut, isFalse, reason: 'the user must not be kicked out');

      // The pair was rotated and persisted.
      expect(await TokenStorage.get(), isNot(result.token));
      expect(await TokenStorage.getRefresh(), isNot(result.refreshToken));
      expect(await TokenStorage.get(), isNotNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'parallel calls after expiry spend only one refresh token',
    () async {
      final ttl = await _accessTokenTtl();
      if (ttl > 120) {
        markTestSkipped('access token lives ${ttl}s; impractical to wait out.');
        return;
      }

      final result = await ApiService.login(email: _email, password: _password);
      await TokenStorage.saveSession(result);

      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;

      await Future<void>.delayed(Duration(seconds: ttl + 5));

      // Three screens refreshing at once is the ordinary case on app resume.
      // Refresh tokens rotate on use, so without the shared in-flight future two
      // of these would spend already-consumed tokens and end the session.
      final results = await Future.wait([
        ApiService.getMyProfile(),
        ApiService.getFeed(),
        ApiService.getFriends(),
      ]);

      expect(results, hasLength(3));
      expect(loggedOut, isFalse, reason: 'concurrent refresh must not log out');
      expect(await TokenStorage.getRefresh(), isNot(result.refreshToken));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('a revoked refresh token ends the session cleanly', () async {
    final result = await ApiService.login(email: _email, password: _password);
    await TokenStorage.saveSession(result);

    // Server-side logout revokes the refresh token; the access token is left
    // in place so the next call still presents a credential the server refuses.
    await http.post(
      Uri.parse('$apiBaseUrl/api/auth/logout'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': result.refreshToken}),
    );
    await TokenStorage.save(
      'not-a-valid-jwt',
      refreshToken: result.refreshToken,
    );

    var loggedOut = false;
    ApiService.onSessionExpired = () => loggedOut = true;

    await expectLater(
      ApiService.getMyProfile(),
      throwsA(isA<SessionExpiredException>()),
    );
    expect(loggedOut, isTrue);
    expect(await TokenStorage.get(), isNull);
    expect(await TokenStorage.getRefresh(), isNull);
  });

  test(
    'logout revokes the token server-side',
    () async {
      final result = await ApiService.login(email: _email, password: _password);
      await TokenStorage.saveSession(result);

      await ApiService.logout();

      expect(await TokenStorage.get(), isNull);
      expect(await TokenStorage.getRefresh(), isNull);

      final replay = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': result.refreshToken}),
      );
      expect(
        replay.statusCode,
        401,
        reason: 'logout must revoke on the server, not just locally',
      );
    },
    skip: Platform.environment['CI'] == 'true',
  );
}
