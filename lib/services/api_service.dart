import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models.dart';
import 'auth_service.dart';

/// Thrown when a request fails because the stored session token is missing,
/// invalid, or rejected by the server with a 401. Callers should clear local
/// state and route to the login screen.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Session expired';
}

/// Typed client for all `/api/...` endpoints described in
/// CANDELA_API_CHANGELOG.md and CANDELA_MVP_1.0.md.
class ApiService {
  static const String baseUrl = apiBaseUrl;

  /// HTTP client used for every request. Overridable in tests with a mock
  /// (e.g. `http.testing.MockClient`).
  static http.Client client = http.Client();

  /// Set by the app shell so the API layer can trigger a logout/navigation
  /// without holding a `BuildContext` (e.g. on a 401 or a missing account).
  static void Function()? onSessionExpired;

  // ── Low-level helpers ──────────────────────────────────────────────────────
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
          AuthResult.fromJson(_asMap(jsonDecode(res.body))),
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

  static Future<dynamic> _handle(http.Response res, {bool auth = true}) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    // A 401 that survived the refresh-and-retry in _send means the session is
    // genuinely over. A 401 on an unauthenticated endpoint (e.g. login with
    // wrong credentials) is just a regular API error to surface.
    if (res.statusCode == 401 && auth) {
      await TokenStorage.clear();
      onSessionExpired?.call();
      throw const SessionExpiredException();
    }
    final body = _tryDecode(res.body);
    final msg =
        (body?['error'] as String?) ??
        (res.statusCode == 401
            ? 'Correo o contraseña incorrectos.'
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
  /// server rejects it. The access token lives an hour, so without this the
  /// user is thrown back to the login screen every hour — potentially in the
  /// middle of a check-in.
  static Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool auth = true,
  }) async {
    var res = await request(await _headers(auth: auth)).timeout(apiTimeout);

    if (res.statusCode == 401 && auth) {
      if (await _refreshSession()) {
        res = await request(await _headers(auth: auth)).timeout(apiTimeout);
      }
    }

    return _handle(res, auth: auth);
  }

  static Future<dynamic> _get(String path, {bool auth = true}) => _send(
    (headers) => client.get(Uri.parse('$baseUrl$path'), headers: headers),
    auth: auth,
  );

  static Future<dynamic> _post(
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

  static Future<dynamic> _patch(String path, [Map<String, dynamic>? data]) =>
      _send(
        (headers) => client.patch(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: data == null ? null : jsonEncode(data),
        ),
      );

  static Future<dynamic> _delete(String path) => _send(
    (headers) => client.delete(Uri.parse('$baseUrl$path'), headers: headers),
  );

  static Map<String, dynamic> _asMap(dynamic j) =>
      (j as Map).cast<String, dynamic>();

  // ── Auth ───────────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    required String birthDate,
  }) async {
    final j = await _post('/api/auth/register', {
      'email': email,
      'username': username,
      'password': password,
      'birth_date': birthDate,
    }, false);
    return AuthResult.fromJson(_asMap(j));
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final j = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    }, false);
    return AuthResult.fromJson(_asMap(j));
  }

  static Future<GoogleAuthOutcome> loginWithGoogle({
    required String idToken,
  }) async {
    final j = await _post('/api/auth/google', {'id_token': idToken}, false);
    final m = _asMap(j);
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
    final j = await _post('/api/auth/google/register', {
      'id_token': idToken,
      'username': username,
      'birth_date': birthDate,
    }, false);
    return AuthResult.fromJson(_asMap(j));
  }

  /// Ends the session on this device: revokes the refresh token server-side so
  /// it cannot be replayed, then clears local storage. Clearing happens even if
  /// the network call fails — a user who tapped "cerrar sesión" must not be
  /// left signed in.
  static Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefresh();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _post('/api/auth/logout', {'refresh_token': refreshToken}, false);
      }
    } catch (_) {
      // Best effort; the token expires on its own.
    } finally {
      await TokenStorage.clear();
    }
  }

  static Future<void> deleteAccount() async {
    await _delete('/api/me');
    await TokenStorage.clear();
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  static Future<User> getMyProfile() async {
    try {
      final j = await _get('/api/me');
      return User.fromJson(_asMap(j));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // The account behind the stored token no longer exists — log out.
        await TokenStorage.clear();
        onSessionExpired?.call();
        throw const SessionExpiredException();
      }
      rethrow;
    }
  }

  static Future<PublicProfile> getPublicProfile(String username) async {
    final j = await _get('/api/users/$username');
    return PublicProfile.fromJson(_asMap(j));
  }

  /// Username prefix search for the friends screen.
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    final j = await _get('/api/users?q=${Uri.encodeQueryComponent(query)}');
    final m = _asMap(j);
    return (m['users'] as List? ?? const [])
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updatePrivacy(PrivacyMode mode) =>
      _patch('/api/me/privacy', {'privacy_mode': mode.raw});

  static Future<bool> updateRankingOptIn(bool optIn) async {
    final j = await _patch('/api/me/ranking', {'ranking_opt_in': optIn});
    return _asMap(j)['ranking_opt_in'] == true;
  }

  // ── Check-in ───────────────────────────────────────────────────────────────
  static Future<CheckInInitiation> initiateCheckIn({
    required String placeId,
    required double lat,
    required double lon,
  }) async {
    final j = await _post('/api/places/$placeId/checkin/initiate', {
      'lat': lat,
      'lon': lon,
    });
    return CheckInInitiation.fromJson(_asMap(j));
  }

  static Future<ConfirmCheckInResult> confirmCheckIn({
    required String placeId,
    required String checkinNonce,
    required String photoKey,
    required DateTime capturedAt,
    bool photoIsPermanent = false,
  }) async {
    final j = await _post('/api/places/$placeId/checkin/confirm', {
      'checkin_nonce': checkinNonce,
      'photo_key': photoKey,
      // The API requires the capture timestamp and rejects photos older than
      // 60s — the "live photo" guarantee.
      'exif_timestamp': capturedAt.toUtc().toIso8601String(),
      'photo_is_permanent': photoIsPermanent,
    });
    return ConfirmCheckInResult.fromJson(_asMap(j));
  }

  static Future<bool> setPhotoPermanent(
    String checkinId,
    bool permanent,
  ) async {
    final j = await _patch('/api/checkins/$checkinId/permanent', {
      'permanent': permanent,
    });
    return _asMap(j)['photo_is_permanent'] == true;
  }

  static Future<List<MyCheckIn>> getMyCheckIns({
    int limit = 20,
    String? cursor,
  }) async {
    var path = '/api/me/check-ins?limit=$limit';
    if (cursor != null) path += '&before=$cursor';
    final j = await _get(path);
    final m = _asMap(j);
    return (m['check_ins'] as List? ?? const [])
        .map((e) => MyCheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Feed ───────────────────────────────────────────────────────────────────
  /// One page of the city feed, plus the cursor for the next one.
  ///
  /// The cursor is opaque and must come from [FeedPage.nextCursor] — the feed
  /// is ordered by priority layer before time, so a timestamp taken from the
  /// last event does not describe a position in it and paging on one returns
  /// events the reader has already seen.
  static Future<FeedPage> getFeed({String? cursor, int limit = 20}) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) {
      query.write('&cursor=${Uri.encodeQueryComponent(cursor)}');
    }
    final j = await _get('/api/feed$query');
    final m = _asMap(j);
    return FeedPage(
      events: (m['events'] as List? ?? const [])
          .map((e) => CheckInEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: m['next_cursor'] as String?,
    );
  }

  static Future<List<CheckInEvent>> getEventFeed(
    String placeId, {
    String? cursor,
    int limit = 20,
  }) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) {
      query.write('&before=${Uri.encodeQueryComponent(cursor)}');
    }
    final j = await _get('/api/places/$placeId/feed$query');
    final m = _asMap(j);
    return (m['events'] as List? ?? const [])
        .map((e) => CheckInEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Places ─────────────────────────────────────────────────────────────────
  static Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
  }) async {
    final j = await _get('/api/places/nearby?lat=$lat&lon=$lon');
    final list = j is List ? j : (_asMap(j)['data'] as List? ?? const []);
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Place> getPlaceDetail(String placeId) async {
    final j = await _get('/api/places/$placeId');
    return Place.fromJson(_asMap(j));
  }

  // ── Follow ─────────────────────────────────────────────────────────────────
  static Future<(bool, int)> followPlace(String placeId) async {
    final j = await _post('/api/places/$placeId/follow');
    final m = _asMap(j);
    return (m['following'] == true, _intOf(m['follower_count']));
  }

  static Future<(bool, int)> unfollowPlace(String placeId) async {
    final j = await _delete('/api/places/$placeId/follow');
    final m = _asMap(j);
    return (m['following'] == true, _intOf(m['follower_count']));
  }

  // ── Plans ──────────────────────────────────────────────────────────────────
  /// Proposes a plan. [targetUserId] is required only for
  /// [PlanVisibility.invite]; open (public/friends) plans leave it null.
  static Future<Plan> createPlan({
    String? targetUserId,
    required String placeId,
    required String message,
    required int deadlineHours,
    PlanVisibility visibility = PlanVisibility.invite,
  }) async {
    final j = await _post('/api/plans', {
      'target_user_id': ?targetUserId,
      'place_id': placeId,
      'message': message,
      'deadline_hours': deadlineHours,
      'visibility': visibility.raw,
    });
    return Plan.fromJson(_asMap(j));
  }

  /// Joins an open plan as a participant.
  static Future<Plan> joinPlan(String planId) async {
    final j = await _post('/api/plans/$planId/join');
    return Plan.fromJson(_asMap(j));
  }

  /// Open plans near (lat, lon) the user can join — for the map.
  static Future<List<OpenPlan>> discoverOpenPlans({
    required double lat,
    required double lon,
  }) async {
    final j = await _get('/api/plans/discover?lat=$lat&lon=$lon');
    final m = _asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => OpenPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plan>> getIncomingPlans() async {
    final j = await _get('/api/plans/incoming');
    final m = _asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plan>> getOutgoingPlans() async {
    final j = await _get('/api/plans/outgoing');
    final m = _asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Plan> getPlanById(String planId) async {
    final j = await _get('/api/plans/$planId');
    return Plan.fromJson(_asMap(j));
  }

  static Future<Plan> acceptPlan(String planId) async {
    final j = await _post('/api/plans/$planId/accept');
    return Plan.fromJson(_asMap(j));
  }

  // Both respond 204 No Content — nothing to parse.
  static Future<void> declinePlan(String planId) =>
      _post('/api/plans/$planId/decline');

  static Future<void> cancelPlan(String planId) =>
      _delete('/api/plans/$planId');

  // ── Friends ────────────────────────────────────────────────────────────────
  static Future<void> sendFriendRequest(String userId) =>
      _post('/api/users/$userId/friend-request');

  static Future<void> acceptFriendRequest(String userId) =>
      _post('/api/friend-requests/$userId/accept');

  static Future<void> rejectFriendRequest(String userId) =>
      _post('/api/friend-requests/$userId/reject');

  static Future<void> cancelFriendRequest(String userId) =>
      _delete('/api/friend-requests/$userId');

  static Future<void> removeFriend(String userId) =>
      _delete('/api/users/$userId/friend');

  static Future<List<FeedUser>> getFriends() async {
    final j = await _get('/api/me/friends');
    final m = _asMap(j);
    return (m['friends'] as List? ?? const [])
        .map((e) => FeedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FriendRequest>> getIncomingRequests() async {
    final j = await _get('/api/friend-requests/incoming');
    final m = _asMap(j);
    return (m['requests'] as List? ?? const [])
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FriendRequest>> getOutgoingRequests() async {
    final j = await _get('/api/friend-requests/outgoing');
    final m = _asMap(j);
    return (m['requests'] as List? ?? const [])
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Block ──────────────────────────────────────────────────────────────────
  static Future<void> blockUser(String userId) =>
      _post('/api/users/$userId/block');

  static Future<void> unblockUser(String userId) =>
      _delete('/api/users/$userId/block');

  // ── Rankings ───────────────────────────────────────────────────────────────
  static Future<RankingResponse> getGlobalRanking() async {
    final j = await _get('/api/rankings/global');
    return RankingResponse.fromJson(_asMap(j));
  }

  static Future<RankingResponse> getFriendsRanking() async {
    final j = await _get('/api/rankings/friends');
    return RankingResponse.fromJson(_asMap(j));
  }

  // ── Reports ────────────────────────────────────────────────────────────────
  static Future<Report> createReport(CreateReportRequest request) async {
    final j = await _post('/api/reports', request.toJson());
    return Report.fromJson(_asMap(j));
  }

  static int _intOf(Object? v) => (v as num?)?.toInt() ?? 0;
}
