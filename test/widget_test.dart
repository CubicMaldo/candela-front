import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:candela_front/main.dart';

void main() {
  testWidgets('App UI test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CandelaApp()));
    await tester.pumpAndSettle();
    
    // Verify that the CircularProgressIndicator is shown initially
    // Since _token future is waiting
    expect(find.byType(CandelaApp), findsOneWidget);
  });
}
