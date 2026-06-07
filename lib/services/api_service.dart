import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models.dart';
import 'auth_service.dart';
import 'demo_data.dart';

/// Authenticated client for all `/api/...` calls described in FRONTEND_GUIDE.md.
///
/// When the backend is unreachable (no server running in local dev) the client
/// transparently falls back to [DemoData] so the UI is fully explorable. Set
/// [ApiService.useDemoFallback] to `false` to surface real network errors.
class ApiService {
  static const String base = 'http://localhost:8080';
  static bool useDemoFallback = true;

  // ── Low-level helpers ──────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.get();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Never _raise(int status, Map<String, dynamic>? body) {
    final msg = (body?['error'] as String?) ?? switch (status) {
      401 => 'Your session expired. Please log in again.',
      403 => 'Action not allowed.',
      404 => 'Not found.',
      409 => 'That conflicts with something that already exists.',
      422 => 'That request was rejected.',
      429 => 'Too many attempts. Please wait and try again.',
      _ => 'Something went wrong. Please try again later.',
    };
    throw ApiException(message: msg, statusCode: status);
  }

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$base$path'), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    _raise(res.statusCode, _tryDecode(res.body));
  }

  static Future<dynamic> _post(String path, [Map<String, dynamic>? data]) async {
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: await _headers(),
      body: data == null ? null : jsonEncode(data),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    _raise(res.statusCode, _tryDecode(res.body));
  }

  static Future<void> _delete(String path) async {
    final res =
        await http.delete(Uri.parse('$base$path'), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    _raise(res.statusCode, _tryDecode(res.body));
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool _isNetwork(Object e) =>
      e is! ApiException; // network/parse errors aren't ApiException

  // ── Profile ────────────────────────────────────────────────────────────────
  static Future<MyProfile> me() async {
    try {
      final j = await _get('/api/me');
      return MyProfile.fromJson(j as Map<String, dynamic>);
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.profile;
      rethrow;
    }
  }

  static Future<List<CheckIn>> myCheckIns() async {
    try {
      final j = await _get('/api/me/check-ins');
      final list = (j?['check_ins'] as List? ?? []);
      return list.map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.checkIns;
      rethrow;
    }
  }

  // ── Feed ───────────────────────────────────────────────────────────────────
  static Future<List<FeedEvent>> feed() async {
    try {
      final j = await _get('/api/feed?limit=20');
      final list = (j?['events'] as List? ?? []);
      return list.map((e) => FeedEvent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.feed;
      rethrow;
    }
  }

  // ── Rankings ───────────────────────────────────────────────────────────────
  static Future<(List<RankingEntry>, int?)> globalRanking(String? meId) async {
    try {
      final j = await _get('/api/rankings/global');
      final list = (j?['rankings'] as List? ?? j?['entries'] as List? ?? []);
      final rank = (j?['user_rank'] as num?)?.toInt();
      return (
        list
            .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>, meId: meId))
            .toList(),
        rank,
      );
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return (DemoData.globalRanking, 7);
      rethrow;
    }
  }

  static Future<List<RankingEntry>> friendsRanking(String? meId) async {
    try {
      final j = await _get('/api/rankings/friends');
      final list = (j?['rankings'] as List? ?? j?['entries'] as List? ?? []);
      return list
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>, meId: meId))
          .toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.friendsRanking;
      rethrow;
    }
  }

  // ── Friends ────────────────────────────────────────────────────────────────
  static Future<List<UserRef>> friends() async {
    try {
      final j = await _get('/api/me/friends');
      final list = (j?['friends'] as List? ?? []);
      return list.map((e) => UserRef.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.friends;
      rethrow;
    }
  }

  static Future<List<FriendRequest>> incomingRequests() async {
    try {
      final j = await _get('/api/friend-requests/incoming');
      final list = (j?['requests'] as List? ?? []);
      return list
          .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.incoming;
      rethrow;
    }
  }

  static Future<void> acceptRequest(String userId) =>
      _post('/api/friend-requests/$userId/accept');

  static Future<void> rejectRequest(String userId) =>
      _post('/api/friend-requests/$userId/reject');

  static Future<void> sendFriendRequest(String userId) =>
      _post('/api/users/$userId/friend-request');

  static Future<void> removeFriend(String userId) =>
      _delete('/api/users/$userId/friend');

  // ── Challenges ─────────────────────────────────────────────────────────────
  static Future<List<Challenge>> activeChallenges() async {
    try {
      final j = await _get('/api/me/challenges?status=active');
      final list = (j?['challenges'] as List? ?? j as List? ?? []);
      return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.activeChallenges;
      rethrow;
    }
  }

  static Future<List<Challenge>> incomingChallenges() async {
    try {
      final j = await _get('/api/challenges/incoming');
      final list = (j?['challenges'] as List? ?? j as List? ?? []);
      return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.incomingChallenges;
      rethrow;
    }
  }

  static Future<void> acceptChallenge(String id) =>
      _post('/api/challenges/$id/accept');

  static Future<void> rejectChallenge(String id) =>
      _post('/api/challenges/$id/reject');

  static Future<void> createChallenge({
    required String targetUserId,
    required String placeId,
    required int deadlineHours,
  }) =>
      _post('/api/challenges', {
        'target_user_id': targetUserId,
        'place_id': placeId,
        'deadline_hours': deadlineHours,
      });

  // ── Places ─────────────────────────────────────────────────────────────────
  static Future<List<Place>> nearbyPlaces() async {
    try {
      final j = await _get('/api/places/nearby');
      final list = (j?['places'] as List? ?? j as List? ?? []);
      return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (useDemoFallback && _isNetwork(e)) return DemoData.places;
      rethrow;
    }
  }

  // ── Privacy ────────────────────────────────────────────────────────────────
  static Future<void> updatePrivacy(PrivacyMode mode) =>
      _post('/api/me/privacy', {'privacy_mode': mode.raw});
}
