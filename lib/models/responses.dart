import 'enums.dart';
import 'checkin.dart';


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
    base: parseInt(j['base']),
    multiplier: (j['multiplier'] as num?)?.toDouble() ?? 1.0,
    subtotalCheckin: parseInt(j['subtotal_checkin']),
    weeklyBonus: parseInt(j['weekly_bonus']),
    planBonus: parseInt(j['plan_bonus']),
    total: parseInt(j['total']),
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
    weeksCurrent: parseInt(j['weeks_current']),
    weekCheckins: parseInt(j['week_checkins']),
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
    photoExpiresAt: parseDateOrNull(j['photo_expires_at']),
    photoIsPermanent: j['photo_is_permanent'] == true,
    gpsValid: j['gps_valid'] == true,
    validationPassed: j['validation_passed'] == true,
    pointsAwarded: parseInt(j['points_awarded']),
    isFirstOfDay: j['is_first_of_day'] == true,
    checkedInAt: parseDate(j['checked_in_at']),
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
    pointsTotal: parseInt(j['points_total']),
    streakWeeksCurrent: parseInt(j['streak_weeks_current']),
    rank: parseInt(j['rank']),
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
    createdAt: parseDateOrNull(j['created_at']),
  );
}

