import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:candela_front/models.dart';
import 'package:candela_front/services/api/api_client.dart';
import 'package:candela_front/services/api/auth_api.dart';
import 'package:candela_front/services/api/users_api.dart';
import 'package:candela_front/services/api/places_api.dart';
import 'package:candela_front/services/api/plans_api.dart';
import 'package:candela_front/services/api/feed_api.dart';
import 'package:candela_front/services/api/checkin_api.dart';
import 'package:candela_front/services/api/misc_api.dart';
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
    ApiClient.client = http.Client();
  });

  group('login (unauthenticated)', () {
    test('returns an AuthResult on 200', () async {
      ApiClient.client = MockClient((req) async {
        expect(req.url.path, '/api/auth/login');
        return http.Response(
          jsonEncode({
            'token': 'tok123',
            'user': {'user_id': 'u1', 'username': 'lucho'},
          }),
          200,
        );
      });

      final result = await AuthApi.login(
        email: 'a@b.com',
        password: 'secret',
      );
      expect(result.token, 'tok123');
      expect(result.user['username'], 'lucho');
    });

    test('throws ApiException (not session-expiry) on 401', () async {
      ApiClient.client = MockClient((req) async {
        return http.Response(jsonEncode({'error': 'bad creds'}), 401);
      });

      expect(
        () => AuthApi.login(email: 'a@b.com', password: 'nope'),
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
      ApiClient.client = MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer tok123');
        return http.Response(
          jsonEncode({'user_id': 'u1', 'username': 'lucho'}),
          200,
        );
      });

      final user = await UsersApi.getMyProfile();
      expect(user.userId, 'u1');
      expect(user.username, 'lucho');
    });

    test('on 401 clears the token and fires onSessionExpired', () async {
      await TokenStorage.save('tok123');
      var loggedOut = false;
      ApiService.onSessionExpired = () => loggedOut = true;
      ApiClient.client = MockClient((req) async => http.Response('', 401));

      await expectLater(
        UsersApi.getMyProfile(),
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
        ApiClient.client = MockClient((req) async => http.Response('', 404));

        await expectLater(
          UsersApi.getMyProfile(),
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
      ApiClient.client = MockClient((req) async {
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

      final user = await UsersApi.getMyProfile();

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

      ApiClient.client = MockClient((req) async {
        if (req.url.path == '/api/auth/refresh') {
          return http.Response(jsonEncode({'error': 'nope'}), 401);
        }
        return http.Response('', 401);
      });

      await expectLater(
        UsersApi.getMyProfile(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(loggedOut, isTrue);
      expect(await TokenStorage.get(), isNull);
      expect(await TokenStorage.getRefresh(), isNull);
    });

    test('concurrent 401s share a single refresh', () async {
      await TokenStorage.save('expired-tok', refreshToken: 'refresh-1');

      var refreshCalls = 0;
      ApiClient.client = MockClient((req) async {
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
        FeedApi.getFeed(),
        FeedApi.getFeed(),
        FeedApi.getFeed(),
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
      ApiClient.client = MockClient((req) async {
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

      final first = await FeedApi.getFeed();
      expect(first.events, hasLength(1));
      expect(first.nextCursor, 'opaque-token-2');
      expect(first.hasMore, isTrue);

      await FeedApi.getFeed(cursor: first.nextCursor);
      expect(requested, [null, 'opaque-token-2']);
    });

    test('a null next_cursor marks the end of the feed', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient(
        (req) async =>
            http.Response(jsonEncode({'events': [], 'next_cursor': null}), 200),
      );

      final page = await FeedApi.getFeed();
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('checkin 2-phase API calls', () {
    test('initiateCheckIn returns CheckInInitiation on 201', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient((req) async {
        expect(req.url.path, '/api/places/p1/checkin/initiate');
        final body = jsonDecode(req.body);
        expect(body['lat'], 19.4);
        expect(body['lon'], -99.1);
        return http.Response(
          jsonEncode({
            'checkin_nonce': 'nonce-xyz',
            'photo_key': 'photos/p1_chk.jpg',
            'upload_url': 'http://localhost:9000/bucket/key',
          }),
          201,
        );
      });

      final res = await CheckInApi.initiateCheckIn(
        placeId: 'p1',
        lat: 19.4,
        lon: -99.1,
      );
      expect(res.checkinNonce, 'nonce-xyz');
      expect(res.photoKey, 'photos/p1_chk.jpg');
      expect(res.uploadUrl, 'http://localhost:9000/bucket/key');
    });

    test('confirmCheckIn returns ConfirmCheckInResult on 200', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient((req) async {
        expect(req.url.path, '/api/places/p1/checkin/confirm');
        final body = jsonDecode(req.body);
        expect(body['checkin_nonce'], 'nonce-xyz');
        expect(body['photo_key'], 'photos/p1_chk.jpg');
        expect(body['photo_is_permanent'], true);
        return http.Response(
          jsonEncode({
            'checkin': {
              'checkin_id': 'c1',
              'user_id': 'u1',
              'place_id': 'p1',
              'photo_is_permanent': true,
              'gps_valid': true,
              'validation_passed': true,
              'points_awarded': 30,
              'is_first_of_day': true,
              'checked_in_at': '2026-09-16T21:00:00Z',
            },
            'points_breakdown': {
              'total': 30,
              'base': 20,
              'multiplier': 1.5,
              'weekly_bonus': 0,
              'plan_bonus': 0,
            },
            'streak': {
              'weeks_current': 2,
              'week_checkins': 1,
              'multiplier': 1.5,
            },
            'is_first_of_day': true,
          }),
          200,
        );
      });

      final res = await CheckInApi.confirmCheckIn(
        placeId: 'p1',
        checkinNonce: 'nonce-xyz',
        photoKey: 'photos/p1_chk.jpg',
        photoIsPermanent: true,
      );
      expect(res.checkin.checkinId, 'c1');
      expect(res.pointsBreakdown.total, 30);
      expect(res.streak.weeksCurrent, 2);
    });
  });

  group('Reports and Blocking', () {
    test('createReport posts to /api/reports and parses Report', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient((req) async {
        expect(req.url.path, '/api/reports');
        final body = jsonDecode(req.body);
        expect(body['target_type'], 'CHECKIN');
        expect(body['target_id'], 'chk-1');
        expect(body['reason'], 'INAPPROPRIATE_CONTENT');
        return http.Response(
          jsonEncode({
            'report_id': 'rep-1',
            'reporter_id': 'u1',
            'target_type': 'CHECKIN',
            'target_id': 'chk-1',
            'reason': 'INAPPROPRIATE_CONTENT',
            'notes': 'Spam',
            'status': 'PENDING',
            'created_at': '2026-09-16T22:00:00Z',
          }),
          201,
        );
      });

      final report = await MiscApi.createReport(
        const CreateReportRequest(
          targetType: 'CHECKIN',
          targetId: 'chk-1',
          reason: 'INAPPROPRIATE_CONTENT',
          comment: 'Spam',
        ),
      );
      expect(report.reportId, 'rep-1');
      expect(report.status, 'PENDING');
    });

    test('blockUser and unblockUser call respective endpoints', () async {
      await TokenStorage.save('tok123');
      final calls = <String>[];
      ApiClient.client = MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        return http.Response('', 204);
      });

      await UsersApi.blockUser('u-bad');
      await UsersApi.unblockUser('u-bad');

      expect(calls, [
        'POST /api/users/u-bad/block',
        'DELETE /api/users/u-bad/block',
      ]);
    });
  });

  group('HTTP error codes and custom handling', () {
    test('403 account suspended throws ApiException with Spanish message', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient(
        (req) async => http.Response(jsonEncode({}), 403),
      );

      expect(
        () => CheckInApi.getMyCheckIns(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having(
                (e) => e.message,
                'message',
                contains('Tu cuenta está suspendida'),
              ),
        ),
      );
    });

    test('404 user/resource not found throws ApiException with Spanish message', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient(
        (req) async => http.Response(jsonEncode({}), 404),
      );

      expect(
        () => UsersApi.getPublicProfile('nonexistent'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having(
                (e) => e.message,
                'message',
                contains('Usuario no encontrado'),
              ),
        ),
      );
    });

    test('409 conflict returns server error message', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient(
        (req) async => http.Response(
          jsonEncode({'error': 'Ya hiciste check-in en este lugar hoy'}),
          409,
        ),
      );

      expect(
        () => CheckInApi.initiateCheckIn(placeId: 'p1', lat: 10, lon: 10),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having(
                (e) => e.message,
                'message',
                'Ya hiciste check-in en este lugar hoy',
              ),
        ),
      );
    });

    test('422 validation error returns default Spanish message when empty', () async {
      await TokenStorage.save('tok123');
      ApiClient.client = MockClient(
        (req) async => http.Response(jsonEncode({}), 422),
      );

      expect(
        () => CheckInApi.initiateCheckIn(placeId: 'p1', lat: 10, lon: 10),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having(
                (e) => e.message,
                'message',
                contains('No fue posible completar la solicitud'),
              ),
        ),
      );
    });

    test('401 account no longer active clears tokens and throws ApiException', () async {
      await TokenStorage.save('tok123', refreshToken: 'ref123');
      var expired = false;
      ApiService.onSessionExpired = () => expired = true;

      ApiClient.client = MockClient(
        (req) async => http.Response(
          jsonEncode({'error': 'account no longer active'}),
          401,
        ),
      );

      expect(
        () => UsersApi.getMyProfile(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                'Tu cuenta ha sido eliminada.',
              ),
        ),
      );

      // Verify session expired callback and cleared tokens
      await pumpEventQueue();
      expect(expired, isTrue);
      expect(await TokenStorage.get(), isNull);
    });
  });

  group('sanitizeUploadUrl', () {
    test('rewrites localhost:9000 to 10.0.2.2:9000', () {
      const original = 'http://localhost:9000/candela-photos/photo.jpg?token=abc';
      final sanitized = ApiService.sanitizeUploadUrl(original);
      expect(
        sanitized,
        'http://10.0.2.2:9000/candela-photos/photo.jpg?token=abc',
      );
    });

    test('rewrites minio:9000 to 10.0.2.2:9000', () {
      const original = 'http://minio:9000/candela-photos/photo.jpg?token=xyz';
      final sanitized = ApiService.sanitizeUploadUrl(original);
      expect(
        sanitized,
        'http://10.0.2.2:9000/candela-photos/photo.jpg?token=xyz',
      );
    });

    test('leaves external or cloud URLs unchanged', () {
      const original = 'https://s3.amazonaws.com/bucket/photo.jpg';
      final sanitized = ApiService.sanitizeUploadUrl(original);
      expect(sanitized, original);
    });
  });
}
