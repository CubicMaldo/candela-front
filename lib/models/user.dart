import 'enums.dart';


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

  factory MyProfile.fromJson(Map<String, dynamic> j) => MyProfile(
    userId: (j['user_id'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
    birthDate: parseDateOrNull(j['birth_date']),
    age: parseInt(j['age']),
    isProtected: j['is_protected'] == true,
    privacyMode: PrivacyMode.from(j['privacy_mode']),
    accountStatus: (j['account_status'] ?? '').toString(),
    pointsTotal: parseInt(j['points_total']),
    pointsSeason: parseInt(j['points_season']),
    badgeLevel: BadgeLevel.from(j['badge_level']),
    streakWeeksCurrent: parseInt(j['streak_weeks_current']),
    streakWeeksMax: parseInt(j['streak_weeks_max']),
    streakWeekCheckins: parseInt(j['streak_week_checkins']),
    streakWeekStart: parseDateOrNull(j['streak_week_start']),
    streakLastCheckin: parseDateOrNull(j['streak_last_checkin']),
    rankingOptIn: j['ranking_opt_in'] == true,
    checkInCount: parseInt(j['check_in_count']),
    friendsCount: parseInt(j['friends_count']),
    completedPlansCount: parseInt(j['completed_plans_count']),
    createdAt: parseDate(j['created_at']),
    updatedAt: parseDate(j['updated_at']),
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
    streakWeeksCurrent: parseInt(j['streak_weeks_current']),
    streakWeeksMax: parseInt(j['streak_weeks_max']),
    checkInCount: parseInt(j['check_in_count']),
    createdAt: parseDate(j['created_at']),
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

