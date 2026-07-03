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
  final String userId;
  final String email;
  final String username;
  final PrivacyMode privacyMode;
  final String accountStatus;
  final int pointsTotal;
  final int pointsSeason;
  final BadgeLevel badgeLevel;
  final int streakWeeksCurrent;
  final int streakWeeksMax;
  final int streakWeekCheckins;
  final bool rankingOptIn;
  final int checkInCount;
  final int friendsCount;
  final int completedPlansCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.userId,
    required this.email,
    required this.username,
    required this.privacyMode,
    required this.accountStatus,
    required this.pointsTotal,
    required this.pointsSeason,
    required this.badgeLevel,
    required this.streakWeeksCurrent,
    required this.streakWeeksMax,
    required this.streakWeekCheckins,
    required this.rankingOptIn,
    required this.checkInCount,
    required this.friendsCount,
    required this.completedPlansCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    userId: (j['user_id'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    privacyMode: PrivacyMode.from(j['privacy_mode']),
    accountStatus: (j['account_status'] ?? '').toString(),
    pointsTotal: _parseInt(j['points_total']),
    pointsSeason: _parseInt(j['points_season']),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    streakWeeksCurrent: _parseInt(j['streak_weeks_current']),
    streakWeeksMax: _parseInt(j['streak_weeks_max']),
    streakWeekCheckins: _parseInt(j['streak_week_checkins']),
    rankingOptIn: j['ranking_opt_in'] == true,
    checkInCount: _parseInt(j['check_in_count']),
    friendsCount: _parseInt(j['friends_count']),
    completedPlansCount: _parseInt(j['completed_plans_count']),
    createdAt: _parseDate(j['created_at']),
    updatedAt: _parseDate(j['updated_at']),
  );
}

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
  final String category;
  final double lat;
  final double lon;
  final int geofenceMeters;
  final bool isVerified;
  final bool isActive;
  final bool isFollowed;
  final int activeCheckinsCount;
  final DateTime? lastCheckinAt;
  final int followerCount;

  const Place({
    required this.placeId,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    required this.geofenceMeters,
    required this.isVerified,
    required this.isActive,
    required this.isFollowed,
    required this.activeCheckinsCount,
    this.lastCheckinAt,
    required this.followerCount,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    placeId: (j['place_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    category: (j['category'] ?? '').toString(),
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lon: (j['lon'] as num?)?.toDouble() ?? 0,
    geofenceMeters: _parseInt(j['geofence_meters']),
    isVerified: j['is_verified'] == true,
    isActive: j['is_active'] == true,
    isFollowed: j['is_followed'] == true,
    activeCheckinsCount: _parseInt(j['active_checkins_count']),
    lastCheckinAt: _parseDateOrNull(j['last_checkin_at']),
    followerCount: _parseInt(j['follower_count']),
  );

  Place copyWith({bool? isFollowed, int? followerCount}) => Place(
    placeId: placeId,
    name: name,
    category: category,
    lat: lat,
    lon: lon,
    geofenceMeters: geofenceMeters,
    isVerified: isVerified,
    isActive: isActive,
    isFollowed: isFollowed ?? this.isFollowed,
    activeCheckinsCount: activeCheckinsCount,
    lastCheckinAt: lastCheckinAt,
    followerCount: followerCount ?? this.followerCount,
  );
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
}

class Plan {
  final String planId;
  final PlanStatus status;
  final String message;
  final int deadlineHours;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final DateTime? concretadoAt;
  final PlanUser creator;
  final PlanUser target;
  final PlanPlace place;
  final String role;

  const Plan({
    required this.planId,
    required this.status,
    required this.message,
    required this.deadlineHours,
    required this.createdAt,
    required this.deadlineAt,
    this.concretadoAt,
    required this.creator,
    required this.target,
    required this.place,
    required this.role,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    planId: (j['plan_id'] ?? '').toString(),
    status: PlanStatus.from(j['status']),
    message: (j['message'] ?? '').toString(),
    deadlineHours: _parseInt(j['deadline_hours']),
    createdAt: _parseDate(j['created_at']),
    deadlineAt: _parseDate(j['deadline_at']),
    concretadoAt: _parseDateOrNull(j['concretado_at']),
    creator: PlanUser.fromJson(
      (j['creator'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    target: PlanUser.fromJson(
      (j['target'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    place: PlanPlace.fromJson(
      (j['place'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    role: (j['role'] ?? '').toString(),
  );

  Duration get timeLeft {
    final diff = deadlineAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
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
  final int? userRank;
  final String? userRankReason;

  const RankingResponse({
    required this.entries,
    this.userRank,
    this.userRankReason,
  });

  factory RankingResponse.fromJson(Map<String, dynamic> j) => RankingResponse(
    entries: ((j['entries'] ?? j['rankings']) as List? ?? const [])
        .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    userRank: (j['user_rank'] as num?)?.toInt(),
    userRankReason: j['user_rank_reason'] as String?,
  );
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
