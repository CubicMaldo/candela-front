// Data models for the Nomad API. All `fromJson` constructors tolerate missing
// or null fields — the backend returns different shapes depending on privacy
// and photo TTLs (see FRONTEND_GUIDE.md).

import 'theme.dart';
import 'package:flutter/material.dart';

// ─── Badge levels ─────────────────────────────────────────────────────────────
// The server exposes `badge_level` as a string. We map it to a colour + label so
// the whole app renders reputation consistently.
enum BadgeLevel {
  newcomer('NEWCOMER', 'Newcomer', Color(0xFF8A8F94)),
  explorer('EXPLORER', 'Explorer', Color(0xFF5C9CE8)),
  local('LOCAL', 'Local', kGreen),
  insider('INSIDER', 'Insider', Color(0xFFF2B705)),
  legend('LEGEND', 'Legend', kRed);

  final String raw;
  final String label;
  final Color color;
  const BadgeLevel(this.raw, this.label, this.color);

  static BadgeLevel from(Object? value) {
    if (value is String) {
      for (final b in BadgeLevel.values) {
        if (b.raw == value.toUpperCase()) return b;
      }
    }
    return BadgeLevel.newcomer;
  }
}

enum PrivacyMode {
  public('PUBLIC', 'Public', 'Anyone can see your profile and ranking'),
  friends('FRIENDS', 'Friends only', 'Strangers see only your name & badge'),
  private('PRIVATE', 'Private', 'Hidden from strangers entirely');

  final String raw;
  final String label;
  final String blurb;
  const PrivacyMode(this.raw, this.label, this.blurb);

  static PrivacyMode from(Object? value) {
    if (value is String) {
      for (final p in PrivacyMode.values) {
        if (p.raw == value.toUpperCase()) return p;
      }
    }
    return PrivacyMode.friends;
  }
}

// ─── My profile (GET /api/me) ─────────────────────────────────────────────────
class MyProfile {
  final String id;
  final String username;
  final String? email;
  final int pointsTotal;
  final BadgeLevel badge;
  final PrivacyMode privacy;
  final bool isProtected;
  final int checkInCount;
  final int friendsCount;
  final int completedChallengesCount;
  final String? avatarUrl;

  const MyProfile({
    required this.id,
    required this.username,
    this.email,
    required this.pointsTotal,
    required this.badge,
    required this.privacy,
    required this.isProtected,
    required this.checkInCount,
    required this.friendsCount,
    required this.completedChallengesCount,
    this.avatarUrl,
  });

  factory MyProfile.fromJson(Map<String, dynamic> j) => MyProfile(
        id: (j['id'] ?? j['sub'] ?? '').toString(),
        username: (j['username'] ?? 'explorer').toString(),
        email: j['email'] as String?,
        pointsTotal: (j['points_total'] as num?)?.toInt() ?? 0,
        badge: BadgeLevel.from(j['badge_level']),
        privacy: PrivacyMode.from(j['privacy_mode']),
        isProtected: j['is_protected'] == true,
        checkInCount: (j['check_in_count'] as num?)?.toInt() ?? 0,
        friendsCount: (j['friends_count'] as num?)?.toInt() ?? 0,
        completedChallengesCount:
            (j['completed_challenges_count'] as num?)?.toInt() ?? 0,
        avatarUrl: j['avatar_url'] as String?,
      );
}

// ─── A place ──────────────────────────────────────────────────────────────────
class Place {
  final String id;
  final String name;
  final String? category;
  final double? distanceMeters;
  final double? lat;
  final double? lon;

  const Place({
    required this.id,
    required this.name,
    this.category,
    this.distanceMeters,
    this.lat,
    this.lon,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Unknown place').toString(),
        category: j['category'] as String?,
        distanceMeters: (j['distance_meters'] as num?)?.toDouble(),
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );

  String? get distanceLabel {
    final d = distanceMeters;
    if (d == null) return null;
    if (d < 1000) return '${d.round()} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }
}

// ─── A lightweight user reference (feed, rankings, friends) ────────────────────
class UserRef {
  final String id;
  final String username;
  final BadgeLevel badge;
  final String? avatarUrl;

  const UserRef({
    required this.id,
    required this.username,
    required this.badge,
    this.avatarUrl,
  });

  factory UserRef.fromJson(Map<String, dynamic> j) => UserRef(
        id: (j['id'] ?? j['user_id'] ?? '').toString(),
        username: (j['username'] ?? 'user').toString(),
        badge: BadgeLevel.from(j['badge_level']),
        avatarUrl: j['avatar_url'] as String?,
      );
}

// ─── Feed event (GET /api/feed) ───────────────────────────────────────────────
enum FeedType { checkin, challengeCompleted, unknown }

class FeedEvent {
  final FeedType type;
  final DateTime createdAt;
  final UserRef? user; // checkin actor
  final UserRef? creator; // challenge creator
  final UserRef? target; // challenge target
  final Place? place;
  final String? photoUrl;

  const FeedEvent({
    required this.type,
    required this.createdAt,
    this.user,
    this.creator,
    this.target,
    this.place,
    this.photoUrl,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> j) {
    final t = (j['type'] as String?) ?? '';
    return FeedEvent(
      type: switch (t) {
        'checkin' => FeedType.checkin,
        'challenge_completed' => FeedType.challengeCompleted,
        _ => FeedType.unknown,
      },
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: j['user'] is Map ? UserRef.fromJson(j['user']) : null,
      creator: j['creator'] is Map ? UserRef.fromJson(j['creator']) : null,
      target: j['target'] is Map ? UserRef.fromJson(j['target']) : null,
      place: j['place'] is Map ? Place.fromJson(j['place']) : null,
      photoUrl: j['photo_url'] as String?,
    );
  }
}

// ─── Ranking entry ────────────────────────────────────────────────────────────
class RankingEntry {
  final int rank;
  final UserRef user;
  final int pointsTotal;
  final bool isMe;

  const RankingEntry({
    required this.rank,
    required this.user,
    required this.pointsTotal,
    this.isMe = false,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j, {String? meId}) {
    final user = UserRef.fromJson(j);
    return RankingEntry(
      rank: (j['rank'] as num?)?.toInt() ?? 0,
      user: user,
      pointsTotal: (j['points_total'] as num?)?.toInt() ?? 0,
      isMe: meId != null && user.id == meId,
    );
  }
}

// ─── Friend request ───────────────────────────────────────────────────────────
class FriendRequest {
  final UserRef user;
  final DateTime? createdAt;

  const FriendRequest({required this.user, this.createdAt});

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        user: UserRef.fromJson(j['user'] is Map ? j['user'] : j),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

// ─── Challenge ────────────────────────────────────────────────────────────────
enum ChallengeStatus { pending, accepted, completed, failed, unknown }

class Challenge {
  final String id;
  final ChallengeStatus status;
  final String role; // "creator" | "target"
  final UserRef? creator;
  final UserRef? target;
  final Place? place;
  final DateTime? deadlineAt;
  final int? pointsCreator;
  final int? pointsTarget;

  const Challenge({
    required this.id,
    required this.status,
    required this.role,
    this.creator,
    this.target,
    this.place,
    this.deadlineAt,
    this.pointsCreator,
    this.pointsTarget,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: (j['id'] ?? '').toString(),
        status: switch ((j['status'] as String?)?.toUpperCase()) {
          'PENDING' => ChallengeStatus.pending,
          'ACCEPTED' => ChallengeStatus.accepted,
          'COMPLETED' => ChallengeStatus.completed,
          'FAILED' => ChallengeStatus.failed,
          _ => ChallengeStatus.unknown,
        },
        role: (j['role'] ?? 'target').toString(),
        creator: j['creator'] is Map ? UserRef.fromJson(j['creator']) : null,
        target: j['target'] is Map ? UserRef.fromJson(j['target']) : null,
        place: j['place'] is Map ? Place.fromJson(j['place']) : null,
        deadlineAt: DateTime.tryParse(j['deadline_at']?.toString() ?? ''),
        pointsCreator: (j['points_creator'] as num?)?.toInt(),
        pointsTarget: (j['points_target'] as num?)?.toInt(),
      );

  Duration? get timeLeft {
    final d = deadlineAt;
    if (d == null) return null;
    final diff = d.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

// ─── Check-in history item (GET /api/me/check-ins) ────────────────────────────
class CheckIn {
  final String id;
  final String placeName;
  final String? photoUrl;
  final int pointsAwarded;
  final DateTime createdAt;

  const CheckIn({
    required this.id,
    required this.placeName,
    this.photoUrl,
    required this.pointsAwarded,
    required this.createdAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: (j['id'] ?? '').toString(),
        placeName: (j['place']?['name'] ?? j['place_name'] ?? 'A place').toString(),
        photoUrl: j['photo_url'] as String?,
        pointsAwarded: (j['points_awarded'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

// ─── Relative time helper ─────────────────────────────────────────────────────
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${(d.inDays / 7).floor()}w ago';
}

String countdownLabel(Duration d) {
  if (d.inSeconds <= 0) return 'expired';
  if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h left';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m left';
  return '${d.inMinutes}m left';
}
