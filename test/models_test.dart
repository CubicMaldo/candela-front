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

  group('MyProfile / User serialization', () {
    test('roundtrips through fromJson and toJson', () {
      final json = {
        'user_id': 'u100',
        'email': 'maria@example.com',
        'username': 'maria',
        'birth_date': '2000-05-15',
        'age': 26,
        'is_protected': false,
        'privacy_mode': 'PUBLIC',
        'account_status': 'ACTIVE',
        'points_total': 350,
        'points_season': 120,
        'badge_level': 'Callejero',
        'streak_weeks_current': 4,
        'streak_weeks_max': 6,
        'streak_week_checkins': 3,
        'streak_week_start': '2026-09-14T00:00:00.000Z',
        'streak_last_checkin': '2026-09-16T18:30:00.000Z',
        'streak_freeze_active': false,
        'ranking_opt_in': true,
        'check_in_count': 22,
        'friends_count': 15,
        'completed_plans_count': 5,
        'created_at': '2026-01-01T12:00:00.000Z',
        'updated_at': '2026-09-16T12:00:00.000Z',
      };

      final profile = MyProfile.fromJson(json);
      expect(profile.userId, 'u100');
      expect(profile.age, 26);
      expect(profile.isProtected, isFalse);
      expect(profile.birthDate, DateTime.parse('2000-05-15'));
      expect(profile.streakWeekStart, isNotNull);
      expect(profile.streakLastCheckin, isNotNull);

      final out = profile.toJson();
      expect(out['user_id'], 'u100');
      expect(out['age'], 26);
      expect(out['is_protected'], false);
      expect(out['privacy_mode'], 'PUBLIC');
      expect(out['points_total'], 350);
      expect(out['badge_level'], 'Callejero');
    });

    test('copyWith updates specified fields only', () {
      final base = MyProfile.fromJson({
        'user_id': 'u1',
        'username': 'ana',
        'points_total': 100,
        'privacy_mode': 'FRIENDS_ONLY',
      });
      final updated = base.copyWith(
        pointsTotal: 200,
        privacyMode: PrivacyMode.private,
      );
      expect(updated.userId, 'u1');
      expect(updated.username, 'ana');
      expect(updated.pointsTotal, 200);
      expect(updated.privacyMode, PrivacyMode.private);
    });
  });

  group('PointsBreakdown serialization', () {
    test('roundtrips through fromJson and toJson', () {
      final json = {
        'total': 45,
        'base': 20,
        'multiplier': 1.5,
        'weekly_bonus': 10,
        'plan_bonus': 5,
      };
      final pb = PointsBreakdown.fromJson(json);
      expect(pb.total, 45);
      expect(pb.base, 20);
      expect(pb.multiplier, 1.5);
      expect(pb.weeklyBonus, 10);
      expect(pb.planBonus, 5);

      final out = pb.toJson();
      expect(out['total'], 45);
      expect(out['base'], 20);
      expect(out['multiplier'], 1.5);
      expect(out['weekly_bonus'], 10);
      expect(out['plan_bonus'], 5);
    });

    test('handles missing or zero bonus fields', () {
      final pb = PointsBreakdown.fromJson({
        'total': 20,
        'base': 20,
      });
      expect(pb.multiplier, 1.0);
      expect(pb.weeklyBonus, 0);
      expect(pb.planBonus, 0);
    });
  });

  group('DiscoverPlan / OpenPlan serialization', () {
    test('roundtrips through fromJson and toJson', () {
      final json = {
        'plan_id': 'plan-123',
        'visibility': 'PUBLIC',
        'message': 'Unas cervezas artesanales',
        'deadline_hours': 4,
        'deadline_at': '2026-09-16T23:00:00.000Z',
        'creator': {
          'user_id': 'u1',
          'username': 'carlos',
          'badge_level': 'Callejero',
        },
        'place': {
          'place_id': 'p1',
          'name': 'Cervecería Roma',
          'category': 'Bar',
          'lat': 19.419,
          'lon': -99.162,
        },
        'participant_count': 3,
      };

      final plan = DiscoverPlan.fromJson(json);
      expect(plan.planId, 'plan-123');
      expect(plan.visibility, PlanVisibility.public);
      expect(plan.message, 'Unas cervezas artesanales');
      expect(plan.creator.username, 'carlos');
      expect(plan.placeName, 'Cervecería Roma');
      expect(plan.participantCount, 3);

      final out = plan.toJson();
      expect(out['plan_id'], 'plan-123');
      expect(out['visibility'], 'PUBLIC');
      expect(out['message'], 'Unas cervezas artesanales');
      expect((out['creator'] as Map)['username'], 'carlos');
      expect((out['place'] as Map)['name'], 'Cervecería Roma');
    });
  });

  group('Social Plan serialization', () {
    test('roundtrips Plan with Spanish status', () {
      final json = {
        'plan_id': 'p-99',
        'status': 'PENDIENTE',
        'visibility': 'INVITE',
        'message': 'Tarde de café',
        'deadline_hours': 3,
        'created_at': '2026-09-16T18:00:00.000Z',
        'deadline_at': '2026-09-16T21:00:00.000Z',
        'creator': {
          'user_id': 'u1',
          'username': 'carlos',
          'badge_level': 'Callejero',
        },
        'place': {
          'place_id': 'pl-1',
          'name': 'Café Central',
          'category': 'Café',
        },
        'role': 'CREATOR',
        'participant_count': 1,
        'my_status': 'JOINED',
      };

      final plan = Plan.fromJson(json);
      expect(plan.planId, 'p-99');
      expect(plan.status, PlanStatus.pending);
      expect(plan.message, 'Tarde de café');
      expect(plan.creator.username, 'carlos');
      expect(plan.place.name, 'Café Central');

      final out = plan.toJson();
      expect(out['plan_id'], 'p-99');
      expect(out['status'], 'PENDIENTE');
      expect(out['message'], 'Tarde de café');
    });
  });

  group('CheckInResult and ConfirmCheckInResult', () {
    test('CheckInResult roundtrips', () {
      final json = {
        'checkin_id': 'chk-01',
        'user_id': 'u1',
        'place_id': 'p1',
        'photo_url': 'http://example.com/photo.jpg',
        'photo_expires_at': '2026-09-17T12:00:00.000Z',
        'photo_is_permanent': false,
        'gps_valid': true,
        'validation_passed': true,
        'points_awarded': 25,
        'is_first_of_day': true,
        'checked_in_at': '2026-09-16T20:00:00.000Z',
      };
      final res = CheckInResult.fromJson(json);
      expect(res.checkinId, 'chk-01');
      expect(res.userId, 'u1');
      expect(res.placeId, 'p1');
      expect(res.pointsAwarded, 25);
      expect(res.isFirstOfDay, isTrue);

      final out = res.toJson();
      expect(out['checkin_id'], 'chk-01');
      expect(out['points_awarded'], 25);
      expect(out['photo_url'], 'http://example.com/photo.jpg');
    });

    test('ConfirmCheckInResult handles PointsBreakdown and Streak', () {
      final json = {
        'checkin': {
          'checkin_id': 'chk-02',
          'user_id': 'u1',
          'place_id': 'p1',
          'photo_is_permanent': false,
          'gps_valid': true,
          'validation_passed': true,
          'points_awarded': 30,
          'is_first_of_day': true,
          'checked_in_at': '2026-09-16T20:00:00.000Z',
        },
        'points_breakdown': {
          'total': 30,
          'base': 20,
          'multiplier': 1.5,
          'weekly_bonus': 0,
          'plan_bonus': 0,
        },
        'streak': {
          'weeks_current': 3,
          'week_checkins': 1,
          'multiplier': 1.5,
        },
        'is_first_of_day': true,
        'photo_view_url': 'http://example.com/view.jpg',
      };
      final res = ConfirmCheckInResult.fromJson(json);
      expect(res.checkin.checkinId, 'chk-02');
      expect(res.pointsBreakdown.total, 30);
      expect(res.pointsBreakdown.multiplier, 1.5);
      expect(res.streak.weeksCurrent, 3);
      expect(res.photoViewUrl, 'http://example.com/view.jpg');

      final out = res.toJson();
      expect((out['checkin'] as Map)['checkin_id'], 'chk-02');
      expect((out['points_breakdown'] as Map)['total'], 30);
      expect(out['photo_view_url'], 'http://example.com/view.jpg');
    });
  });

  group('FeedCursor', () {
    test('encodes and decodes valid components', () {
      final now = DateTime.utc(2026, 9, 16, 21, 30);
      final cursor = FeedCursor(
        layer: 1,
        checkedInAt: now,
        eventId: 'evt-456',
      );

      final encoded = cursor.encode();
      expect(encoded, isNotEmpty);

      final decoded = FeedCursor.decode(encoded);
      expect(decoded.layer, 1);
      expect(decoded.checkedInAt, now);
      expect(decoded.eventId, 'evt-456');
    });

    test('tryDecode returns null on malformed cursor string', () {
      expect(FeedCursor.tryDecode('not-a-valid-cursor'), isNull);
      expect(FeedCursor.tryDecode(''), isNull);
      expect(FeedCursor.tryDecode('bm9wZQ=='), isNull); // "nope" without pipes
    });

    test('toJson and fromJson work cleanly', () {
      final now = DateTime.utc(2026, 9, 16, 22, 0);
      final cursor = FeedCursor(
        layer: 2,
        checkedInAt: now,
        eventId: 'evt-789',
      );
      final json = cursor.toJson();
      expect(json['layer'], 2);
      expect(json['event_id'], 'evt-789');

      final from = FeedCursor.fromJson(json);
      expect(from.layer, 2);
      expect(from.eventId, 'evt-789');
    });
  });

  group('Place serialization', () {
    test('roundtrips all fields including minorSuitability and distance', () {
      final json = {
        'place_id': 'p-bar-1',
        'name': 'El Candil',
        'category': 'Bar',
        'address': 'Calle 10 #20',
        'lat': 4.65,
        'lng': -74.05,
        'description': 'Lugar tradicional de encuentro',
        'minor_suitability': 'ADULTS_ONLY',
        'distance': 142.5,
        'is_active': true,
        'active_checkins_count': 8,
      };

      final place = Place.fromJson(json);
      expect(place.placeId, 'p-bar-1');
      expect(place.description, 'Lugar tradicional de encuentro');
      expect(place.minorSuitability, 'ADULTS_ONLY');
      expect(place.distance, 142.5);
      expect(place.isActive, isTrue);
      expect(place.activeCheckinsCount, 8);

      final out = place.toJson();
      expect(out['place_id'], 'p-bar-1');
      expect(out['description'], 'Lugar tradicional de encuentro');
      expect(out['minor_suitability'], 'ADULTS_ONLY');
      expect(out['distance'], 142.5);
    });
  });

  group('StreakStatus serialization', () {
    test('roundtrips correctly', () {
      final json = {
        'weeks_current': 5,
        'week_checkins': 2,
        'multiplier': 1.5,
      };
      final streak = StreakStatus.fromJson(json);
      expect(streak.weeksCurrent, 5);
      expect(streak.weekCheckins, 2);
      expect(streak.multiplier, 1.5);

      final out = streak.toJson();
      expect(out['weeks_current'], 5);
      expect(out['week_checkins'], 2);
      expect(out['multiplier'], 1.5);
    });
  });
}
