// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:bookin/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BookExchangeApp());

    // Verify that splash screen loads with title
    expect(find.text('BookIn'), findsOneWidget);

    // Advance time past the splash duration to finish timers and transition
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
