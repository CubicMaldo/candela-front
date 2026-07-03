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
}
