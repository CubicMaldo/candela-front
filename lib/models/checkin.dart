import 'dart:convert';
import 'enums.dart';


// ─── Feed embedded refs ──────────────────────────────────────────────────────
class FeedUser {
  final String userId;
  final String username;
  final BadgeLevel badgeLevel;
  final bool isFriend;

  const FeedUser({
    required this.userId,
    required this.username,
    required this.badgeLevel,
    required this.isFriend,
  });

  factory FeedUser.fromJson(Map<String, dynamic> j) => FeedUser(
    userId: (j['user_id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    isFriend: j['is_friend'] == true,
  );
}

class FeedPlace {
  final String placeId;
  final String name;
  final String category;
  final bool isFollowed;

  const FeedPlace({
    required this.placeId,
    required this.name,
    required this.category,
    required this.isFollowed,
  });

  factory FeedPlace.fromJson(Map<String, dynamic> j) => FeedPlace(
    placeId: (j['place_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    category: (j['category'] ?? '').toString(),
    isFollowed: j['is_followed'] == true,
  );
}


// ─── CheckInEvent (feed item) ────────────────────────────────────────────────
/// One page of the city feed. [nextCursor] is an opaque token from the API and
/// is null on the last page — never build one client-side from an event's
/// timestamp: the feed is ordered by priority layer first, so a timestamp does
/// not identify a position in it.
class FeedPage {
  final List<CheckInEvent> events;
  final String? nextCursor;

  const FeedPage({required this.events, this.nextCursor});

  bool get hasMore => nextCursor != null;
}

class CheckInEvent {
  final String checkinId;
  final FeedUser user;
  final FeedPlace place;
  final String? photoUrl;
  final bool photoIsPermanent;
  final DateTime checkedInAt;
  final int? priorityLayer;

  const CheckInEvent({
    required this.checkinId,
    required this.user,
    required this.place,
    this.photoUrl,
    required this.photoIsPermanent,
    required this.checkedInAt,
    this.priorityLayer,
  });

  factory CheckInEvent.fromJson(Map<String, dynamic> j) => CheckInEvent(
    checkinId: (j['checkin_id'] ?? j['event_id'] ?? '').toString(),
    user: FeedUser.fromJson(
      (j['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    place: FeedPlace.fromJson(
      (j['place'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    photoUrl: j['photo_url'] as String?,
    photoIsPermanent: j['photo_is_permanent'] == true,
    checkedInAt: parseDate(j['checked_in_at'] ?? j['timestamp']),
    priorityLayer: (j['priority_layer'] as num?)?.toInt(),
  );
}


// ─── MyCheckIn (own history — GET /api/me/check-ins) ─────────────────────────
class MyCheckIn {
  final String checkinId;
  final FeedPlace place;
  final String? photoUrl;
  final bool photoIsPermanent;
  final int pointsAwarded;
  final DateTime checkedInAt;

  const MyCheckIn({
    required this.checkinId,
    required this.place,
    this.photoUrl,
    required this.photoIsPermanent,
    required this.pointsAwarded,
    required this.checkedInAt,
  });

  factory MyCheckIn.fromJson(Map<String, dynamic> j) => MyCheckIn(
    checkinId: (j['checkin_id'] ?? '').toString(),
    place: FeedPlace.fromJson(
      (j['place'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    photoUrl: j['photo_url'] as String?,
    photoIsPermanent: j['photo_is_permanent'] == true,
    pointsAwarded: parseInt(j['points_awarded']),
    checkedInAt: parseDate(j['checked_in_at']),
  );
}


// ─── FeedCursor (Base64Url Layer|CheckedInAt|EventID) ────────────────────────
class FeedCursor {
  final int layer;
  final DateTime checkedInAt;
  final String eventId;

  const FeedCursor({
    required this.layer,
    required this.checkedInAt,
    required this.eventId,
  });

  String encode() {
    final raw = '$layer|${checkedInAt.toUtc().toIso8601String()}|$eventId';
    return base64Url.encode(utf8.encode(raw));
  }

  static FeedCursor? tryDecode(String token) {
    try {
      return decode(token);
    } catch (_) {
      return null;
    }
  }

  static FeedCursor decode(String token) {
    var normalized = token;
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    final raw = utf8.decode(base64Url.decode(normalized));
    final parts = raw.split('|');
    if (parts.length < 3) {
      throw const FormatException('Invalid FeedCursor string');
    }
    return FeedCursor(
      layer: int.parse(parts[0]),
      checkedInAt: DateTime.parse(parts[1]),
      eventId: parts.sublist(2).join('|'),
    );
  }

  factory FeedCursor.fromJson(Map<String, dynamic> j) => FeedCursor(
    layer: parseInt(j['layer']),
    checkedInAt: parseDate(j['checked_in_at'] ?? j['timestamp']),
    eventId: (j['event_id'] ?? j['checkin_id'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'layer': layer,
    'checked_in_at': checkedInAt.toUtc().toIso8601String(),
    'event_id': eventId,
  };
}

