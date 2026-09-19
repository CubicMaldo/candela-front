import 'enums.dart';


// ─── Plans ────────────────────────────────────────────────────────────────────
class PlanUser {
  final String userId;
  final String username;
  final BadgeLevel badgeLevel;

  const PlanUser({
    required this.userId,
    required this.username,
    required this.badgeLevel,
  });

  factory PlanUser.fromJson(Map<String, dynamic> j) => PlanUser(
    userId: (j['user_id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    badgeLevel: BadgeLevel.from(j['badge_level']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'badge_level': badgeLevel.label,
  };
}

class PlanPlace {
  final String placeId;
  final String name;
  final String category;

  const PlanPlace({
    required this.placeId,
    required this.name,
    required this.category,
  });

  factory PlanPlace.fromJson(Map<String, dynamic> j) => PlanPlace(
    placeId: (j['place_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    category: (j['category'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    'category': category,
  };
}

class Plan {
  final String planId;
  final PlanStatus status;
  final PlanVisibility visibility;
  final String message;
  final int deadlineHours;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final DateTime? concretadoAt;
  final PlanUser creator;

  /// The invited friend — null for open (public/friends) plans, which have no
  /// single invitee.
  final PlanUser? target;
  final PlanPlace place;
  final String role;

  /// Number of people going (joined + completed participants), including the
  /// creator.
  final int participantCount;

  /// The viewer's own participation status ('INVITED'/'JOINED'/…), if any.
  final String myStatus;

  const Plan({
    required this.planId,
    required this.status,
    required this.visibility,
    required this.message,
    required this.deadlineHours,
    required this.createdAt,
    required this.deadlineAt,
    this.concretadoAt,
    required this.creator,
    this.target,
    required this.place,
    required this.role,
    required this.participantCount,
    required this.myStatus,
  });

  bool get isOpen => visibility != PlanVisibility.invite;

  factory Plan.fromJson(Map<String, dynamic> j) {
    final targetJson = (j['target'] as Map?)?.cast<String, dynamic>();
    return Plan(
      planId: (j['plan_id'] ?? '').toString(),
      status: PlanStatus.from(j['status']),
      visibility: PlanVisibility.from(j['visibility']),
      message: (j['message'] ?? '').toString(),
      deadlineHours: parseInt(j['deadline_hours']),
      createdAt: parseDate(j['created_at']),
      deadlineAt: parseDate(j['deadline_at']),
      concretadoAt: parseDateOrNull(j['concretado_at']),
      creator: PlanUser.fromJson(
        (j['creator'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      target: targetJson == null ? null : PlanUser.fromJson(targetJson),
      place: PlanPlace.fromJson(
        (j['place'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      role: (j['role'] ?? '').toString(),
      participantCount: parseInt(j['participant_count']),
      myStatus: (j['my_status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'status': status.raw,
    'visibility': visibility.raw,
    'message': message,
    'deadline_hours': deadlineHours,
    'created_at': createdAt.toUtc().toIso8601String(),
    'deadline_at': deadlineAt.toUtc().toIso8601String(),
    if (concretadoAt != null)
      'concretado_at': concretadoAt!.toUtc().toIso8601String(),
    'creator': creator.toJson(),
    if (target != null) 'target': target!.toJson(),
    'place': place.toJson(),
    'role': role,
    'participant_count': participantCount,
    'my_status': myStatus,
  };

  Duration get timeLeft {
    final diff = deadlineAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}


// ─── DiscoverPlan / OpenPlan (map discovery — GET /api/plans/discover) ───────
/// An open plan the viewer can join, positioned on the map by its place
/// coordinates.
class DiscoverPlan {
  final String planId;
  final PlanVisibility visibility;
  final String message;
  final int deadlineHours;
  final DateTime deadlineAt;
  final PlanUser creator;
  final String placeId;
  final String placeName;
  final String placeCategory;
  final double lat;
  final double lon;
  final int participantCount;

  /// True when the viewer created this plan. The discover endpoint never
  /// returns own plans; this is set client-side when merging outgoing plans
  /// into the map pins.
  final bool isMine;

  const DiscoverPlan({
    required this.planId,
    required this.visibility,
    required this.message,
    required this.deadlineHours,
    required this.deadlineAt,
    required this.creator,
    required this.placeId,
    required this.placeName,
    required this.placeCategory,
    required this.lat,
    required this.lon,
    required this.participantCount,
    this.isMine = false,
  });

  factory DiscoverPlan.fromJson(Map<String, dynamic> j) {
    final place = (j['place'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DiscoverPlan(
      planId: (j['plan_id'] ?? '').toString(),
      visibility: PlanVisibility.from(j['visibility']),
      message: (j['message'] ?? '').toString(),
      deadlineHours: parseInt(j['deadline_hours']),
      deadlineAt: parseDate(j['deadline_at']),
      creator: PlanUser.fromJson(
        (j['creator'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      placeId: (place['place_id'] ?? '').toString(),
      placeName: (place['name'] ?? '').toString(),
      placeCategory: (place['category'] ?? '').toString(),
      lat: (place['lat'] as num?)?.toDouble() ?? 0,
      lon: (place['lon'] as num?)?.toDouble() ?? 0,
      participantCount: parseInt(j['participant_count']),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'visibility': visibility.raw,
    'message': message,
    'deadline_hours': deadlineHours,
    'deadline_at': deadlineAt.toUtc().toIso8601String(),
    'creator': creator.toJson(),
    'place': {
      'place_id': placeId,
      'name': placeName,
      'category': placeCategory,
      'lat': lat,
      'lon': lon,
    },
    'participant_count': participantCount,
  };

  Duration get timeLeft {
    final diff = deadlineAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

typedef OpenPlan = DiscoverPlan;

