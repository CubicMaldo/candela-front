// Basic smoke test for the Candela app entry point.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:candela_front/main.dart';

void main() {
  testWidgets('App boots into the welcome flow', (WidgetTester tester) async {
    await tester.pumpWidget(const CandelaApp());

    // The root resolves the stored token asynchronously, then shows either the
    // welcome screen or the home shell. Let those frames settle.
    await tester.pump(const Duration(milliseconds: 100));

    // The app builds without throwing — the MaterialApp is present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
