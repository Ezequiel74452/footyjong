import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/screens/game_screen.dart';

void main() {
  testWidgets('GameScreen renders GameWidget and HUD with controller',
      (tester) async {
    final controller = GameController(seed: 42);
    addTearDown(() => controller.dispose());
    controller.startNewGame();

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/game',
          routes: [
            GoRoute(
              path: '/game',
              builder: (_, __) => GameScreen(controller: controller),
            ),
            GoRoute(
              path: '/results',
              builder: (_, __) => const Scaffold(body: Text('ResultsPage')),
            ),
          ],
        ),
      ),
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
