import 'package:flutter_test/flutter_test.dart';
import 'package:candela_front/models.dart';

void main() {
  group('Enum parsing', () {
    test('BadgeLevel.from matches the Spanish label', () {
      expect(BadgeLevel.from('Leyenda'), BadgeLevel.legend);
      expect(BadgeLevel.from('Parroquiano'), BadgeLevel.regular);
    });

    test('BadgeLevel.from falls back to newcomer on unknown/null', () {
      expect(BadgeLevel.from('???'), BadgeLevel.newcomer);
      expect(BadgeLevel.from(null), BadgeLevel.newcomer);
      expect(BadgeLevel.from(42), BadgeLevel.newcomer);
    });

    test('PrivacyMode.from is case-insensitive and defaults to friends', () {
      expect(PrivacyMode.from('public'), PrivacyMode.public);
      expect(PrivacyMode.from('PRIVATE'), PrivacyMode.private);
      expect(PrivacyMode.from(null), PrivacyMode.friends);
      expect(PrivacyMode.from('nope'), PrivacyMode.friends);
    });

    test('PlanStatus.from parses raw values and defaults to pending', () {
      expect(PlanStatus.from('CONCRETADO'), PlanStatus.completed);
      expect(PlanStatus.from('declinado'), PlanStatus.declined);
      expect(PlanStatus.from(null), PlanStatus.pending);
    });
  });

  group('User.fromJson', () {
    test('maps every field from a complete payload', () {
      final user = User.fromJson({
        'user_id': 'u1',
        'email': 'a@b.com',
        'username': 'lucho',
        'privacy_mode': 'PUBLIC',
        'account_status': 'ACTIVE',
        'points_total': 120,
        'points_season': 30,
        'badge_level': 'Callejero',
        'streak_weeks_current': 3,
        'streak_weeks_max': 5,
        'streak_week_checkins': 2,
        'ranking_opt_in': true,
        'check_in_count': 17,
        'friends_count': 8,
        'completed_plans_count': 4,
        'created_at': '2026-01-02T03:04:05Z',
        'updated_at': '2026-06-01T00:00:00Z',
      });

      expect(user.userId, 'u1');
      expect(user.username, 'lucho');
      expect(user.privacyMode, PrivacyMode.public);
      expect(user.pointsTotal, 120);
      expect(user.badgeLevel, BadgeLevel.streetwise);
      expect(user.rankingOptIn, isTrue);
      expect(user.checkInCount, 17);
      expect(user.createdAt, DateTime.parse('2026-01-02T03:04:05Z'));
    });

    test('is resilient to a sparse payload (defaults, no throw)', () {
      final user = User.fromJson(const {});

      expect(user.userId, '');
      expect(user.email, '');
      expect(user.privacyMode, PrivacyMode.friends);
      expect(user.badgeLevel, BadgeLevel.newcomer);
      expect(user.pointsTotal, 0);
      expect(user.rankingOptIn, isFalse);
      expect(user.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('coerces numeric strings/doubles via _parseInt', () {
      final user = User.fromJson({'points_total': 7.0, 'friends_count': 3});
      expect(user.pointsTotal, 7);
      expect(user.friendsCount, 3);
    });
  });

  group('RankingResponse.fromJson', () {
    // The API sends user_rank as a full entry object. Parsing it as a number
    // threw, and the throw was swallowed upstream, so the profile always said
    // "aún no tienes posición".
    test('reads user_rank when it is an entry object', () {
      final r = RankingResponse.fromJson({
        'rankings': [
          {
            'rank': 1,
            'user_id': 'u2',
            'username': 'carlos',
            'points_total': 860,
          },
        ],
        'total': 1,
        'user_rank': {
          'rank': 3,
          'user_id': 'u1',
          'username': 'ana',
          'badge_level': 'Parroquiano',
          'points_total': 1240,
        },
      });

      expect(r.entries, hasLength(1));
      expect(r.userRank, 3);
      expect(r.userEntry?.username, 'ana');
      expect(r.userEntry?.pointsTotal, 1240);
    });

    test('a null user_rank means no position, not an error', () {
      final r = RankingResponse.fromJson({
        'rankings': const [],
        'user_rank': null,
        'user_rank_reason': 'ranking_opt_in_disabled',
      });

      expect(r.userRank, isNull);
      expect(r.userEntry, isNull);
      expect(r.userRankReason, 'ranking_opt_in_disabled');
    });

    test(
      'an unexpected user_rank shape degrades to null instead of throwing',
      () {
        expect(
          () =>
              RankingResponse.fromJson({'rankings': const [], 'user_rank': 7}),
          returnsNormally,
        );
        expect(
          RankingResponse.fromJson({
            'rankings': const [],
            'user_rank': 7,
          }).userRank,
          isNull,
        );
      },
    );
  });
}
