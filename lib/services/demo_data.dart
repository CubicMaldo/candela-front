import '../models.dart';

/// Sample content shown when the backend is unreachable, so the full UI is
/// explorable in local dev without a running server. See [ApiService].
class DemoData {
  static final _now = DateTime.now();

  static const profile = MyProfile(
    id: 'me',
    username: 'luismaldo',
    email: 'luismaldonadocano10@gmail.com',
    pointsTotal: 1240,
    badge: BadgeLevel.local,
    privacy: PrivacyMode.friends,
    isProtected: false,
    checkInCount: 38,
    friendsCount: 12,
    completedChallengesCount: 5,
  );

  static const _alex = UserRef(id: 'u1', username: 'alex', badge: BadgeLevel.insider);
  static const _mira = UserRef(id: 'u2', username: 'mira', badge: BadgeLevel.explorer);
  static const _theo = UserRef(id: 'u3', username: 'theo', badge: BadgeLevel.legend);
  static const _june = UserRef(id: 'u4', username: 'june', badge: BadgeLevel.local);
  static const _kai = UserRef(id: 'u5', username: 'kai', badge: BadgeLevel.newcomer);
  static const _me = UserRef(id: 'me', username: 'luismaldo', badge: BadgeLevel.local);

  static List<FeedEvent> get feed => [
        FeedEvent(
          type: FeedType.checkin,
          createdAt: _now.subtract(const Duration(minutes: 8)),
          user: _alex,
          place: const Place(id: 'p1', name: 'Café Modern', category: 'Coffee'),
          photoUrl: null,
        ),
        FeedEvent(
          type: FeedType.challengeCompleted,
          createdAt: _now.subtract(const Duration(hours: 1, minutes: 12)),
          creator: _theo,
          target: _mira,
          place: const Place(id: 'p2', name: 'Riverside Park', category: 'Outdoors'),
        ),
        FeedEvent(
          type: FeedType.checkin,
          createdAt: _now.subtract(const Duration(hours: 3)),
          user: _june,
          place: const Place(id: 'p3', name: 'The Vinyl Bar', category: 'Nightlife'),
        ),
        FeedEvent(
          type: FeedType.checkin,
          createdAt: _now.subtract(const Duration(hours: 6, minutes: 40)),
          user: _mira,
          place: const Place(id: 'p4', name: 'Sunset Rooftop', category: 'Bar'),
        ),
        FeedEvent(
          type: FeedType.challengeCompleted,
          createdAt: _now.subtract(const Duration(hours: 9)),
          creator: _kai,
          target: _alex,
          place: const Place(id: 'p5', name: 'Old Town Gallery', category: 'Culture'),
        ),
      ];

  static List<RankingEntry> get globalRanking => [
        const RankingEntry(rank: 1, user: _theo, pointsTotal: 4820),
        const RankingEntry(rank: 2, user: _alex, pointsTotal: 3110),
        const RankingEntry(rank: 3, user: _june, pointsTotal: 2640),
        const RankingEntry(rank: 4, user: _mira, pointsTotal: 1980),
        const RankingEntry(rank: 5, user: _kai, pointsTotal: 1610),
        const RankingEntry(rank: 6, user: UserRef(id: 'u6', username: 'nadia', badge: BadgeLevel.explorer), pointsTotal: 1420),
        const RankingEntry(rank: 7, user: _me, pointsTotal: 1240, isMe: true),
        const RankingEntry(rank: 8, user: UserRef(id: 'u7', username: 'omar', badge: BadgeLevel.local), pointsTotal: 1105),
      ];

  static List<RankingEntry> get friendsRanking => [
        const RankingEntry(rank: 1, user: _alex, pointsTotal: 3110),
        const RankingEntry(rank: 2, user: _june, pointsTotal: 2640),
        const RankingEntry(rank: 3, user: _me, pointsTotal: 1240, isMe: true),
        const RankingEntry(rank: 4, user: _mira, pointsTotal: 1980),
        const RankingEntry(rank: 5, user: _kai, pointsTotal: 1610),
      ];

  static List<UserRef> get friends => const [_alex, _june, _kai, _mira, _theo];

  static List<FriendRequest> get incoming => [
        FriendRequest(
          user: const UserRef(id: 'u8', username: 'sofia', badge: BadgeLevel.explorer),
          createdAt: _now.subtract(const Duration(hours: 2)),
        ),
        FriendRequest(
          user: const UserRef(id: 'u9', username: 'dmitri', badge: BadgeLevel.newcomer),
          createdAt: _now.subtract(const Duration(days: 1)),
        ),
      ];

  static List<Challenge> get activeChallenges => [
        Challenge(
          id: 'c1',
          status: ChallengeStatus.accepted,
          role: 'target',
          creator: _alex,
          target: _me,
          place: const Place(id: 'p1', name: 'Café Modern', category: 'Coffee'),
          deadlineAt: _now.add(const Duration(hours: 19)),
        ),
        Challenge(
          id: 'c2',
          status: ChallengeStatus.accepted,
          role: 'creator',
          creator: _me,
          target: _june,
          place: const Place(id: 'p4', name: 'Sunset Rooftop', category: 'Bar'),
          deadlineAt: _now.add(const Duration(days: 1, hours: 4)),
        ),
      ];

  static List<Challenge> get incomingChallenges => [
        Challenge(
          id: 'c3',
          status: ChallengeStatus.pending,
          role: 'target',
          creator: _theo,
          target: _me,
          place: const Place(id: 'p2', name: 'Riverside Park', category: 'Outdoors'),
          deadlineAt: _now.add(const Duration(hours: 48)),
        ),
      ];

  static List<Place> get places => const [
        Place(id: 'p1', name: 'Café Modern', category: 'Coffee', distanceMeters: 120),
        Place(id: 'p4', name: 'Sunset Rooftop', category: 'Bar', distanceMeters: 340),
        Place(id: 'p3', name: 'The Vinyl Bar', category: 'Nightlife', distanceMeters: 510),
        Place(id: 'p2', name: 'Riverside Park', category: 'Outdoors', distanceMeters: 880),
        Place(id: 'p5', name: 'Old Town Gallery', category: 'Culture', distanceMeters: 1500),
      ];

  static List<CheckIn> get checkIns => [
        CheckIn(id: 'ci1', placeName: 'Café Modern', pointsAwarded: 20, createdAt: _now.subtract(const Duration(hours: 5))),
        CheckIn(id: 'ci2', placeName: 'Sunset Rooftop', pointsAwarded: 15, createdAt: _now.subtract(const Duration(days: 1))),
        CheckIn(id: 'ci3', placeName: 'Riverside Park', pointsAwarded: 20, createdAt: _now.subtract(const Duration(days: 2))),
        CheckIn(id: 'ci4', placeName: 'The Vinyl Bar', pointsAwarded: 10, createdAt: _now.subtract(const Duration(days: 3))),
        CheckIn(id: 'ci5', placeName: 'Old Town Gallery', pointsAwarded: 20, createdAt: _now.subtract(const Duration(days: 4))),
        CheckIn(id: 'ci6', placeName: 'Café Modern', pointsAwarded: 15, createdAt: _now.subtract(const Duration(days: 6))),
      ];
}
