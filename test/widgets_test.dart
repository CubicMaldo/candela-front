import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candela_front/app/widgets.dart';
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
}
