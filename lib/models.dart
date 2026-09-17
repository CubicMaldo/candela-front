import 'dart:convert';

// Data models for the Candela API (MVP 1.0). Field names mirror the JSON
// response keys documented in CANDELA_API_CHANGELOG.md sections 4-6.

// ─── Badge levels ─────────────────────────────────────────────────────────────
enum BadgeLevel {
  newcomer('Nuevo en la vuelta'),
  streetwise('Callejero'),
  regular('Parroquiano'),
  veteran('Teso'),
  legend('Leyenda');

  final String label;
  const BadgeLevel(this.label);

  static BadgeLevel from(Object? value) {
    if (value is String) {
      for (final b in BadgeLevel.values) {
        if (b.label == value) return b;
      }
    }
    return BadgeLevel.newcomer;
  }
}

enum PrivacyMode {
  public('PUBLIC'),
  friends('FRIENDS'),
  private('PRIVATE');

  final String raw;
  const PrivacyMode(this.raw);

  static PrivacyMode from(Object? value) {
    if (value is String) {
      for (final p in PrivacyMode.values) {
        if (p.raw == value.toUpperCase()) return p;
      }
    }
    return PrivacyMode.friends;
  }
}

enum PlanStatus {
  pending('PENDIENTE'),
  accepted('ACEPTADO'),
  completed('CONCRETADO'),
  failed('NO_CONCRETADO'),
  declined('DECLINADO');

  final String raw;
  const PlanStatus(this.raw);

  static PlanStatus from(Object? value) {
    if (value is String) {
      for (final s in PlanStatus.values) {
        if (s.raw == value.toUpperCase()) return s;
      }
    }
    return PlanStatus.pending;
  }
}

/// Who can see and join a plan.
///   public  — anyone can discover and join (no invitee).
///   friends — only the creator's friends can discover and join (no invitee).
///   invite  — a single friend is invited directly (the classic 1:1 flow).
enum PlanVisibility {
  public('PUBLIC'),
  friends('FRIENDS'),
  invite('INVITE');

  final String raw;
  const PlanVisibility(this.raw);

  static PlanVisibility from(Object? value) {
    if (value is String) {
      for (final v in PlanVisibility.values) {
        if (v.raw == value.toUpperCase()) return v;
      }
    }
    return PlanVisibility.invite;
  }
}

DateTime _parseDate(Object? v) =>
    DateTime.tryParse(v?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _parseDateOrNull(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

int _parseInt(Object? v) => (v as num?)?.toInt() ?? 0;

// ─── User (own profile — GET /api/me) ────────────────────────────────────────
class User {
// ─── MyProfile / User (own profile — GET /api/me) ───────────────────────────
class MyProfile {
  final String userId;
  final String email;
  final String username;
  final DateTime? birthDate;
  final int age;
  final bool isProtected;
  final PrivacyMode privacyMode;
  final String accountStatus;
  final int pointsTotal;
  final int pointsSeason;
  final BadgeLevel badgeLevel;
  final int streakWeeksCurrent;
  final int streakWeeksMax;
  final int streakWeekCheckins;
  final DateTime? streakWeekStart;
  final DateTime? streakLastCheckin;
  final bool rankingOptIn;
  final int checkInCount;
  final int friendsCount;
  final int completedPlansCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
  const MyProfile({
    required this.userId,
    required this.email,
    required this.username,
    this.birthDate,
    this.age = 0,
    this.isProtected = false,
    required this.privacyMode,
    required this.accountStatus,
    required this.pointsTotal,
    required this.pointsSeason,
    required this.badgeLevel,
    required this.streakWeeksCurrent,
    required this.streakWeeksMax,
    required this.streakWeekCheckins,
    this.streakWeekStart,
    this.streakLastCheckin,
    required this.rankingOptIn,
    required this.checkInCount,
    required this.friendsCount,
    required this.completedPlansCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
  factory MyProfile.fromJson(Map<String, dynamic> j) => MyProfile(
    userId: (j['user_id'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    birthDate: _parseDateOrNull(j['birth_date']),
    age: _parseInt(j['age']),
    isProtected: j['is_protected'] == true,
    privacyMode: PrivacyMode.from(j['privacy_mode']),
    accountStatus: (j['account_status'] ?? '').toString(),
    pointsTotal: _parseInt(j['points_total']),
    pointsSeason: _parseInt(j['points_season']),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    streakWeeksCurrent: _parseInt(j['streak_weeks_current']),
    streakWeeksMax: _parseInt(j['streak_weeks_max']),
    streakWeekCheckins: _parseInt(j['streak_week_checkins']),
    streakWeekStart: _parseDateOrNull(j['streak_week_start']),
    streakLastCheckin: _parseDateOrNull(j['streak_last_checkin']),
    rankingOptIn: j['ranking_opt_in'] == true,
    checkInCount: _parseInt(j['check_in_count']),
    friendsCount: _parseInt(j['friends_count']),
    completedPlansCount: _parseInt(j['completed_plans_count']),
    createdAt: _parseDate(j['created_at']),
    updatedAt: _parseDate(j['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'username': username,
    if (birthDate != null) 'birth_date': birthDate!.toUtc().toIso8601String(),
    'age': age,
    'is_protected': isProtected,
    'privacy_mode': privacyMode.raw,
    'account_status': accountStatus,
    'points_total': pointsTotal,
    'points_season': pointsSeason,
    'badge_level': badgeLevel.label,
    'streak_weeks_current': streakWeeksCurrent,
    'streak_weeks_max': streakWeeksMax,
    'streak_week_checkins': streakWeekCheckins,
    if (streakWeekStart != null)
      'streak_week_start': streakWeekStart!.toUtc().toIso8601String(),
    if (streakLastCheckin != null)
      'streak_last_checkin': streakLastCheckin!.toUtc().toIso8601String(),
    'ranking_opt_in': rankingOptIn,
    'check_in_count': checkInCount,
    'friends_count': friendsCount,
    'completed_plans_count': completedPlansCount,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  MyProfile copyWith({
    String? userId,
    String? email,
    String? username,
    DateTime? birthDate,
    int? age,
    bool? isProtected,
    PrivacyMode? privacyMode,
    String? accountStatus,
    int? pointsTotal,
    int? pointsSeason,
    BadgeLevel? badgeLevel,
    int? streakWeeksCurrent,
    int? streakWeeksMax,
    int? streakWeekCheckins,
    DateTime? streakWeekStart,
    DateTime? streakLastCheckin,
    bool? rankingOptIn,
    int? checkInCount,
    int? friendsCount,
    int? completedPlansCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MyProfile(
    userId: userId ?? this.userId,
    email: email ?? this.email,
    username: username ?? this.username,
    birthDate: birthDate ?? this.birthDate,
    age: age ?? this.age,
    isProtected: isProtected ?? this.isProtected,
    privacyMode: privacyMode ?? this.privacyMode,
    accountStatus: accountStatus ?? this.accountStatus,
    pointsTotal: pointsTotal ?? this.pointsTotal,
    pointsSeason: pointsSeason ?? this.pointsSeason,
    badgeLevel: badgeLevel ?? this.badgeLevel,
    streakWeeksCurrent: streakWeeksCurrent ?? this.streakWeeksCurrent,
    streakWeeksMax: streakWeeksMax ?? this.streakWeeksMax,
    streakWeekCheckins: streakWeekCheckins ?? this.streakWeekCheckins,
    streakWeekStart: streakWeekStart ?? this.streakWeekStart,
    streakLastCheckin: streakLastCheckin ?? this.streakLastCheckin,
    rankingOptIn: rankingOptIn ?? this.rankingOptIn,
    checkInCount: checkInCount ?? this.checkInCount,
    friendsCount: friendsCount ?? this.friendsCount,
    completedPlansCount: completedPlansCount ?? this.completedPlansCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

typedef User = MyProfile;

// ─── PublicProfile (GET /api/users/:username) ────────────────────────────────
class PublicProfile {
  final String userId;
  final String username;
  final BadgeLevel badgeLevel;
  final int? pointsTotal;
  final int streakWeeksCurrent;
  final int streakWeeksMax;
  final int checkInCount;
  final DateTime createdAt;

  const PublicProfile({
    required this.userId,
    required this.username,
    required this.badgeLevel,
    this.pointsTotal,
    required this.streakWeeksCurrent,
    required this.streakWeeksMax,
    required this.checkInCount,
    required this.createdAt,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
    userId: (j['user_id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    pointsTotal: (j['points_total'] as num?)?.toInt(),
    streakWeeksCurrent: _parseInt(j['streak_weeks_current']),
    streakWeeksMax: _parseInt(j['streak_weeks_max']),
    checkInCount: _parseInt(j['check_in_count']),
    createdAt: _parseDate(j['created_at']),
  );
}

// ─── Place ────────────────────────────────────────────────────────────────────
class Place {
  final String placeId;
  final String name;
  final String? description;
  final String category;
  final double lat;
  final double lon;
  final int geofenceMeters;
  final String? minorSuitability;
  final bool isVerified;
  final bool isActive;
  final bool isFollowed;
  final int activeCheckinsCount;
  final DateTime? lastCheckinAt;
  final int followerCount;
  final double? distance;

  const Place({
    required this.placeId,
    required this.name,
    this.description,
    required this.category,
    required this.lat,
    required this.lon,
    required this.geofenceMeters,
    this.minorSuitability,
    required this.isVerified,
    required this.isActive,
    required this.isFollowed,
    required this.activeCheckinsCount,
    this.lastCheckinAt,
    required this.followerCount,
    this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    placeId: (j['place_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: j['description'] as String?,
    category: (j['category'] ?? '').toString(),
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lon: (j['lon'] as num?)?.toDouble() ?? 0,
    geofenceMeters: _parseInt(j['geofence_meters']),
    minorSuitability: j['minor_suitability'] as String?,
    isVerified: j['is_verified'] == true,
    isActive: j['is_active'] == true,
    isFollowed: j['is_followed'] == true,
    activeCheckinsCount: _parseInt(j['active_checkins_count']),
    lastCheckinAt: _parseDateOrNull(j['last_checkin_at']),
    followerCount: _parseInt(j['follower_count']),
    distance: (j['distance'] as num?)?.toDouble(),
  );

  Place copyWith({bool? isFollowed, int? followerCount}) => Place(
    placeId: placeId,
    name: name,
    description: description,
    category: category,
    lat: lat,
    lon: lon,
    geofenceMeters: geofenceMeters,
    minorSuitability: minorSuitability,
    isVerified: isVerified,
    isActive: isActive,
    isFollowed: isFollowed ?? this.isFollowed,
    activeCheckinsCount: activeCheckinsCount,
    lastCheckinAt: lastCheckinAt,
    followerCount: followerCount ?? this.followerCount,
    distance: distance,
  );

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    if (description != null) 'description': description,
    'category': category,
    'lat': lat,
    'lon': lon,
    'geofence_meters': geofenceMeters,
    if (minorSuitability != null) 'minor_suitability': minorSuitability,
    'is_verified': isVerified,
    'is_active': isActive,
    'is_followed': isFollowed,
    'active_checkins_count': activeCheckinsCount,
    if (lastCheckinAt != null)
      'last_checkin_at': lastCheckinAt!.toUtc().toIso8601String(),
    'follower_count': followerCount,
    if (distance != null) 'distance': distance,
  };
}

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
    checkedInAt: _parseDate(j['checked_in_at'] ?? j['timestamp']),
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
    pointsAwarded: _parseInt(j['points_awarded']),
    checkedInAt: _parseDate(j['checked_in_at']),
  );
}

// ─── PointsBreakdown (confirm response) ──────────────────────────────────────
class PointsBreakdown {
  final int base;
  final double multiplier;
  final int subtotalCheckin;
  final int weeklyBonus;
  final int planBonus;
  final int total;

  const PointsBreakdown({
    required this.base,
    required this.multiplier,
    required this.subtotalCheckin,
    required this.weeklyBonus,
    required this.planBonus,
    required this.total,
  });

  factory PointsBreakdown.fromJson(Map<String, dynamic> j) => PointsBreakdown(
    base: _parseInt(j['base']),
    multiplier: (j['multiplier'] as num?)?.toDouble() ?? 1.0,
    subtotalCheckin: _parseInt(j['subtotal_checkin']),
    weeklyBonus: _parseInt(j['weekly_bonus']),
    planBonus: _parseInt(j['plan_bonus']),
    total: _parseInt(j['total']),
  );

  Map<String, dynamic> toJson() => {
    'base': base,
    'multiplier': multiplier,
    'subtotal_checkin': subtotalCheckin,
    'weekly_bonus': weeklyBonus,
    'plan_bonus': planBonus,
    'total': total,
  };
}

// ─── StreakStatus (confirm response) ─────────────────────────────────────────
class StreakStatus {
  final int weeksCurrent;
  final int weekCheckins;
  final double multiplier;

  const StreakStatus({
    required this.weeksCurrent,
    required this.weekCheckins,
    required this.multiplier,
  });

  factory StreakStatus.fromJson(Map<String, dynamic> j) => StreakStatus(
    weeksCurrent: _parseInt(j['weeks_current']),
    weekCheckins: _parseInt(j['week_checkins']),
    multiplier: (j['multiplier'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'weeks_current': weeksCurrent,
    'week_checkins': weekCheckins,
    'multiplier': multiplier,
  };
}

// ─── CheckInResult (the `checkin` object in confirm response) ────────────────
class CheckInResult {
  final String checkinId;
  final String userId;
  final String placeId;
  final String? photoUrl;
  final DateTime? photoExpiresAt;
  final bool photoIsPermanent;
  final bool gpsValid;
  final bool validationPassed;
  final int pointsAwarded;
  final bool isFirstOfDay;
  final DateTime checkedInAt;

  const CheckInResult({
    required this.checkinId,
    required this.userId,
    required this.placeId,
    this.photoUrl,
    this.photoExpiresAt,
    required this.photoIsPermanent,
    required this.gpsValid,
    required this.validationPassed,
    required this.pointsAwarded,
    required this.isFirstOfDay,
    required this.checkedInAt,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> j) => CheckInResult(
    checkinId: (j['checkin_id'] ?? '').toString(),
    userId: (j['user_id'] ?? '').toString(),
    placeId: (j['place_id'] ?? '').toString(),
    photoUrl: j['photo_url'] as String?,
    photoExpiresAt: _parseDateOrNull(j['photo_expires_at']),
    photoIsPermanent: j['photo_is_permanent'] == true,
    gpsValid: j['gps_valid'] == true,
    validationPassed: j['validation_passed'] == true,
    pointsAwarded: _parseInt(j['points_awarded']),
    isFirstOfDay: j['is_first_of_day'] == true,
    checkedInAt: _parseDate(j['checked_in_at']),
  );

  Map<String, dynamic> toJson() => {
    'checkin_id': checkinId,
    'user_id': userId,
    'place_id': placeId,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (photoExpiresAt != null)
      'photo_expires_at': photoExpiresAt!.toUtc().toIso8601String(),
    'photo_is_permanent': photoIsPermanent,
    'gps_valid': gpsValid,
    'validation_passed': validationPassed,
    'points_awarded': pointsAwarded,
    'is_first_of_day': isFirstOfDay,
    'checked_in_at': checkedInAt.toUtc().toIso8601String(),
  };
}

// ─── ConfirmCheckInResult (full POST confirm response) ───────────────────────
class ConfirmCheckInResult {
  final CheckInResult checkin;
  final PointsBreakdown pointsBreakdown;
  final StreakStatus streak;
  final bool isFirstOfDay;
  final String? photoViewUrl;

  const ConfirmCheckInResult({
    required this.checkin,
    required this.pointsBreakdown,
    required this.streak,
    required this.isFirstOfDay,
    this.photoViewUrl,
  });

  factory ConfirmCheckInResult.fromJson(Map<String, dynamic> j) =>
      ConfirmCheckInResult(
        checkin: CheckInResult.fromJson(
          (j['checkin'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        pointsBreakdown: PointsBreakdown.fromJson(
          (j['points_breakdown'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        streak: StreakStatus.fromJson(
          (j['streak'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        isFirstOfDay: j['is_first_of_day'] == true,
        photoViewUrl: j['photo_view_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'checkin': checkin.toJson(),
    'points_breakdown': pointsBreakdown.toJson(),
    'streak': streak.toJson(),
    'is_first_of_day': isFirstOfDay,
    if (photoViewUrl != null) 'photo_view_url': photoViewUrl,
  };
}

// ─── CheckInInitiation (POST .../checkin/initiate response) ──────────────────
class CheckInInitiation {
  final String checkinNonce;
  final String photoKey;
  final String uploadUrl;

  const CheckInInitiation({
    required this.checkinNonce,
    required this.photoKey,
    required this.uploadUrl,
  });

  factory CheckInInitiation.fromJson(Map<String, dynamic> j) =>
      CheckInInitiation(
        checkinNonce: (j['checkin_nonce'] ?? '').toString(),
        photoKey: (j['photo_key'] ?? '').toString(),
        uploadUrl: (j['upload_url'] ?? '').toString(),
      );
}

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
      deadlineHours: _parseInt(j['deadline_hours']),
      createdAt: _parseDate(j['created_at']),
      deadlineAt: _parseDate(j['deadline_at']),
      concretadoAt: _parseDateOrNull(j['concretado_at']),
      creator: PlanUser.fromJson(
        (j['creator'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      target: targetJson == null ? null : PlanUser.fromJson(targetJson),
      place: PlanPlace.fromJson(
        (j['place'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      role: (j['role'] ?? '').toString(),
      participantCount: _parseInt(j['participant_count']),
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

// ─── Open plan (map discovery — GET /api/plans/discover) ─────────────────────
// ─── DiscoverPlan / OpenPlan (map discovery — GET /api/plans/discover) ───────
/// An open plan the viewer can join, positioned on the map by its place
/// coordinates.
class OpenPlan {
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

  const OpenPlan({
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

  factory OpenPlan.fromJson(Map<String, dynamic> j) {
  factory DiscoverPlan.fromJson(Map<String, dynamic> j) {
    final place = (j['place'] as Map?)?.cast<String, dynamic>() ?? const {};
    return OpenPlan(
    return DiscoverPlan(
      planId: (j['plan_id'] ?? '').toString(),
      visibility: PlanVisibility.from(j['visibility']),
      message: (j['message'] ?? '').toString(),
      deadlineHours: _parseInt(j['deadline_hours']),
      deadlineAt: _parseDate(j['deadline_at']),
      creator: PlanUser.fromJson(
        (j['creator'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      placeId: (place['place_id'] ?? '').toString(),
      placeName: (place['name'] ?? '').toString(),
      placeCategory: (place['category'] ?? '').toString(),
      lat: (place['lat'] as num?)?.toDouble() ?? 0,
      lon: (place['lon'] as num?)?.toDouble() ?? 0,
      participantCount: _parseInt(j['participant_count']),
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
    layer: _parseInt(j['layer']),
    checkedInAt: _parseDate(j['checked_in_at'] ?? j['timestamp']),
    eventId: (j['event_id'] ?? j['checkin_id'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'layer': layer,
    'checked_in_at': checkedInAt.toUtc().toIso8601String(),
    'event_id': eventId,
  };
}

// ─── Rankings ────────────────────────────────────────────────────────────────
class RankingEntry {
  final String userId;
  final String username;
  final BadgeLevel badgeLevel;
  final int pointsTotal;
  final int streakWeeksCurrent;
  final int rank;

  const RankingEntry({
    required this.userId,
    required this.username,
    required this.badgeLevel,
    required this.pointsTotal,
    required this.streakWeeksCurrent,
    required this.rank,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j) => RankingEntry(
    userId: (j['user_id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    pointsTotal: _parseInt(j['points_total']),
    streakWeeksCurrent: _parseInt(j['streak_weeks_current']),
    rank: _parseInt(j['rank']),
  );
}

class RankingResponse {
  final List<RankingEntry> entries;

  /// The caller's own position, or null when they have none (not opted in, or
  /// no ranked friends). The API sends this as a full entry object, not a bare
  /// number — see [RankingResponse.fromJson].
  final RankingEntry? userEntry;
  final String? userRankReason;

  const RankingResponse({
    required this.entries,
    this.userEntry,
    this.userRankReason,
  });

  /// The caller's numeric position, or null if they have none.
  int? get userRank => userEntry?.rank;

  factory RankingResponse.fromJson(Map<String, dynamic> j) {
    // `user_rank` is an object ({rank, user_id, username, ...}). Reading it as
    // a number threw, and the throw was swallowed by the FutureBuilder above,
    // so every user was permanently told they had no ranking position.
    final raw = j['user_rank'];
    return RankingResponse(
      entries: ((j['entries'] ?? j['rankings']) as List? ?? const [])
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      userEntry: raw is Map<String, dynamic>
          ? RankingEntry.fromJson(raw)
          : null,
      userRankReason: j['user_rank_reason'] as String?,
    );
  }
}

// ─── Reports ─────────────────────────────────────────────────────────────────
class Report {
  final String reportId;
  final String status;

  const Report({required this.reportId, required this.status});

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    reportId: (j['report_id'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
  );
}

class CreateReportRequest {
  final String targetType;
  final String targetId;
  final String reason;
  final String? comment;

  const CreateReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'target_type': targetType,
    'target_id': targetId,
    'reason': reason,
    if (comment != null) 'comment': comment,
  };
}

// ─── Friend request ───────────────────────────────────────────────────────────
class FriendRequest {
  final FeedUser user;
  final DateTime? createdAt;

  const FriendRequest({required this.user, this.createdAt});

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
    user: FeedUser.fromJson(((j['user'] as Map?) ?? j).cast<String, dynamic>()),
    createdAt: _parseDateOrNull(j['created_at']),
  );
}

// ─── User search (GET /api/users?q=) ─────────────────────────────────────────
class UserSearchResult {
  final String userId;
  final String username;
  final BadgeLevel badgeLevel;
  final bool isFriend;

  const UserSearchResult({
    required this.userId,
    required this.username,
    required this.badgeLevel,
    required this.isFriend,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) => UserSearchResult(
    userId: (j['user_id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    isFriend: j['is_friend'] == true,
  );
}

// ─── Relative time helpers ────────────────────────────────────────────────────
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'justo ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays < 7) return 'hace ${d.inDays} d';
  return 'hace ${(d.inDays / 7).floor()} sem';
}

String countdownLabel(Duration d) {
  if (d.inSeconds <= 0) return 'expirado';
  if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h restantes';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m restantes';
  return '${d.inMinutes}m restantes';
}

/// Human distance label: "240 m" under a km, "4.4 km" above.
String distanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

// ─── Place category display labels ────────────────────────────────────────────
/// Spanish display label for an API place category code. The raw codes
/// ('CAFE', 'NIGHTCLUB'…) must never reach the UI.
String categoryLabel(String category) {
  return switch (category.toUpperCase()) {
    'CAFE' => 'Café',
    'RESTAURANT' => 'Restaurante',
    'BAR' => 'Bar',
    'NIGHTCLUB' => 'Rumba',
    'PARK' => 'Parque',
    'UNIVERSITY' => 'Universidad',
    _ => category,
  };
}
