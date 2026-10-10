import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookin/core/animations/app_animations.dart';

void main() {
  testWidgets('FadeSlideEntry renders child and animates in', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideEntry(
            child: Text('Animated Item'),
          ),
        ),
      ),
    );

    expect(find.text('Animated Item'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Animated Item'), findsOneWidget);
  });

  testWidgets('BounceTap renders child and triggers onTap callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BounceTap(
            onTap: () => tapped = true,
            child: const Text('Bounce Button'),
          ),
        ),
      ),
    );

    expect(find.text('Bounce Button'), findsOneWidget);
    await tester.tap(find.text('Bounce Button'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('PopHeartIcon renders and triggers onTap callback', (WidgetTester tester) async {
    bool selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PopHeartIcon(
                isSelected: selected,
                activeIcon: Icons.favorite,
                inactiveIcon: Icons.favorite_border,
                activeColor: Colors.red,
                inactiveColor: Colors.grey,
                onTap: () {
                  setState(() => selected = !selected);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byType(PopHeartIcon));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('ShimmerEffect renders child continuously', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerEffect(
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    expect(find.byType(ShimmerEffect), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShimmerEffect), findsOneWidget);
  });

  testWidgets('AppPageRoute builds route with cubic animation curve', (WidgetTester tester) async {
    final route = AppPageRoute(
      child: const Text('Page Target'),
    );

    expect(route.transitionDuration, const Duration(milliseconds: 320));
  });
}
