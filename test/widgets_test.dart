import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candela_front/app/checkin_screen.dart';
import 'package:candela_front/app/feed_screen.dart';
import 'package:candela_front/app/plans_screen.dart';
import 'package:candela_front/app/widgets.dart';
import 'package:candela_front/models.dart';
import 'package:candela_front/theme.dart';

void main() {
  testWidgets('CandelaLoader renders an amber spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandelaLoader.centered())),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.color, candelaAmber);
    expect(indicator.strokeWidth, 2.5);
  });

  testWidgets('CandelaLoader honours a custom size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CandelaLoader(size: 20))),
    );

    final sizedBox = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(sizedBox.width, 20);
    expect(sizedBox.height, 20);
  });

  group('Check-in TimerPill countdown', () {
    testWidgets('renders remaining seconds with timer icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimerPill(secondsRemaining: 90),
          ),
        ),
      );

      expect(find.text('90s restantes'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('renders urgent color state when <= 15 seconds remain', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimerPill(secondsRemaining: 10),
          ),
        ),
      );

      expect(find.text('10s restantes'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
      expect(icon.color, Colors.white);
    });
  });

  group('FeedPhoto expired placeholder', () {
    testWidgets('renders expired photo placeholder when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedPhoto(photoUrl: null),
          ),
        ),
      );

      expect(find.text('Foto expirada'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });
  });

  group('PlanStatusPill in Spanish', () {
    testWidgets('displays correct Spanish labels for all PlanStatus values', (tester) async {
      const expectations = {
        PlanStatus.pending: 'Pendiente',
        PlanStatus.accepted: 'Aceptado',
        PlanStatus.completed: 'Concretado',
        PlanStatus.failed: 'No concretado',
        PlanStatus.declined: 'Declinado',
      };

      for (final entry in expectations.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlanStatusPill(status: entry.key),
            ),
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      }
    });
  });
}
