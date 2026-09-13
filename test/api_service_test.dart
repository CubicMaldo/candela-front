import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:candela_front/services/api_service.dart';
import 'package:candela_front/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory stand-in for flutter_secure_storage's platform channel so
  // TokenStorage works in a pure unit test.
  final secureStore = <String, String>{};
  const secureChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    secureStore.clear();
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
    ApiService.client = http.Client();
  });

  group('login (unauthenticated)', () {
    test('returns an AuthResult on 200', () async {
      ApiService.client = MockClient((req) async {
        expect(req.url.path, '/api/auth/login');
        return http.Response(
          jsonEncode({
            'token': 'tok123',
            'user': {'user_id': 'u1', 'username': 'lucho'},
          }),
          200,
        );
      });

      final result = await ApiService.login(
        email: 'a@b.com',
        password: 'secret',
      );
      expect(result.token, 'tok123');
      expect(result.user['username'], 'lucho');
    });

    test('throws ApiException (not session-expiry) on 401', () async {
      ApiService.client = MockClient((req) async {
        return http.Response(jsonEncode({'error': 'bad creds'}), 401);
      });

      expect(
        () => ApiService.login(email: 'a@b.com', password: 'nope'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'bad creds'),
        ),
      );
    });
  });

  group('getMyProfile (authenticated)', () {
    test('parses the User on 200', () async {
      await TokenStorage.save('tok123');
      ApiService.client = MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer tok123');
        return http.Response(
          jsonEncode({'user_id': 'u1', 'username': 'lucho'}),
          200,
        );
      });

      final user = await ApiService.getMyProfile();
      expect(user.userId, 'u1');
      expect(user.username, 'lucho');
    });

    test('on 401 clears the token and fires onSessionExpired', () async {
      await TokenStorage.save('tok123');
      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;
      ApiService.client = MockClient((req) async => http.Response('', 401));

      await expectLater(
        ApiService.getMyProfile(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(loggedOut, isTrue);
      expect(await TokenStorage.get(), isNull);
    });

    test(
      'on 404 (account gone) logs out via SessionExpiredException',
      () async {
        await TokenStorage.save('tok123');
        var loggedOut = false;
        ApiService.onSessionExpired = () => loggedOut = true;
        ApiService.client = MockClient((req) async => http.Response('', 404));

        await expectLater(
          ApiService.getMyProfile(),
          throwsA(isA<SessionExpiredException>()),
        );
        expect(loggedOut, isTrue);
        expect(await TokenStorage.get(), isNull);
      },
    );
  });

  group('session refresh', () {
    test('a 401 refreshes the access token and retries the request', () async {
      await TokenStorage.save('expired-tok', refreshToken: 'refresh-1');
      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;

      final seen = <String>[];
      ApiService.client = MockClient((req) async {
        seen.add('${req.method} ${req.url.path}');

        if (req.url.path == '/api/auth/refresh') {
          expect(jsonDecode(req.body)['refresh_token'], 'refresh-1');
          return http.Response(
            jsonEncode({
              'token': 'fresh-tok',
              'refresh_token': 'refresh-2',
              'expires_in': 3600,
              'user': {'user_id': 'u1', 'username': 'lucho'},
            }),
            200,
          );
        }
        // The protected endpoint only accepts the refreshed token.
        if (req.headers['Authorization'] == 'Bearer fresh-tok') {
          return http.Response(
            jsonEncode({'user_id': 'u1', 'username': 'lucho'}),
            200,
          );
        }
        return http.Response('', 401);
      });

      final user = await ApiService.getMyProfile();

      expect(user.username, 'lucho');
      expect(loggedOut, isFalse, reason: 'the session recovered silently');
      expect(seen, [
        'GET /api/me', // rejected
        'POST /api/auth/refresh', // recovered
        'GET /api/me', // retried
      ]);
      // The rotated pair replaced the old one.
      expect(await TokenStorage.get(), 'fresh-tok');
      expect(await TokenStorage.getRefresh(), 'refresh-2');
    });

    test('a rejected refresh token ends the session', () async {
      await TokenStorage.save('expired-tok', refreshToken: 'revoked');
      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;

      ApiService.client = MockClient((req) async {
        if (req.url.path == '/api/auth/refresh') {
          return http.Response(jsonEncode({'error': 'nope'}), 401);
        }
        return http.Response('', 401);
      });

      await expectLater(
        ApiService.getMyProfile(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(loggedOut, isTrue);
      expect(await TokenStorage.get(), isNull);
      expect(await TokenStorage.getRefresh(), isNull);
    });

    test('concurrent 401s share a single refresh', () async {
      await TokenStorage.save('expired-tok', refreshToken: 'refresh-1');

      var refreshCalls = 0;
      ApiService.client = MockClient((req) async {
        if (req.url.path == '/api/auth/refresh') {
          refreshCalls++;
          return http.Response(
            jsonEncode({
              'token': 'fresh-tok',
              'refresh_token': 'refresh-2',
              'expires_in': 3600,
              'user': {'user_id': 'u1', 'username': 'lucho'},
            }),
            200,
          );
        }
        if (req.headers['Authorization'] == 'Bearer fresh-tok') {
          return http.Response(jsonEncode({'events': []}), 200);
        }
        return http.Response('', 401);
      });

      await Future.wait([
        ApiService.getFeed(),
        ApiService.getFeed(),
        ApiService.getFeed(),
      ]);

      // Refresh tokens rotate on use: three refreshes would spend three
      // tokens and invalidate the last two.
      expect(refreshCalls, 1);
    });
  });

  group('feed pagination', () {
    test('uses the opaque cursor from the API, not a timestamp', () async {
      await TokenStorage.save('tok123');

      final requested = <String?>[];
      ApiService.client = MockClient((req) async {
        requested.add(req.url.queryParameters['cursor']);
        return http.Response(
          jsonEncode({
            'events': [
              {
                'checkin_id': 'c1',
                'timestamp': '2024-06-05T21:30:00Z',
                'priority_layer': 3,
                'user': {'user_id': 'u2', 'username': 'ana'},
                'place': {'place_id': 'p1', 'name': 'Bar'},
              },
            ],
            'next_cursor': 'opaque-token-2',
          }),
          200,
        );
      });

      final first = await ApiService.getFeed();
      expect(first.events, hasLength(1));
      expect(first.nextCursor, 'opaque-token-2');
      expect(first.hasMore, isTrue);

      await ApiService.getFeed(cursor: first.nextCursor);
      expect(requested, [null, 'opaque-token-2']);
    });

    test('a null next_cursor marks the end of the feed', () async {
      await TokenStorage.save('tok123');
      ApiService.client = MockClient(
        (req) async =>
            http.Response(jsonEncode({'events': [], 'next_cursor': null}), 200),
      );

      final page = await ApiService.getFeed();
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });
}
