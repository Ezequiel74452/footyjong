import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/screens/game_screen.dart';

void main() {
  testWidgets('GameScreen renders GameWidget and HUD', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen()),
    );
    // Pump to build the widget tree
    await tester.pump();

    // The HUD should display initial values
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Level: 1'), findsOneWidget);

    // Let entrance animation timers fire so there are no pending timers at teardown.
    // Max entrance delay = 72 tiles × 8ms stagger + 300ms duration ≈ 876ms.
    // Two full seconds covers all timers including the isAnimating release.
    await tester.pump(const Duration(seconds: 2));
  });
}
