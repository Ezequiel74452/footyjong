import 'dart:async';
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
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('HomePage')),
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

  testWidgets('GameScreen shows timer text starting at 00:00',
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
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('HomePage')),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // Timer starts at 00:00
    expect(find.text('00:00'), findsOneWidget);

    // Advance the timer by 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    // Advance by 9 more seconds → 00:10
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('00:10'), findsOneWidget);

    // Let entrance animation timers fire for clean teardown
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('forfeit button triggers dialog, cancel dismisses',
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
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('HomePage')),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // Tap forfeit button
    await tester.tap(find.text('Forfeit'));
    await tester.pump();

    // Dialog should appear
    expect(find.text('Are you sure you want to forfeit?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Forfeit'), findsWidgets); // two: button + dialog

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    // Dialog should be gone
    expect(find.text('Are you sure you want to forfeit?'), findsNothing);

    // Let entrance animation timers fire for clean teardown
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('forfeit confirm navigates home', (tester) async {
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
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('HomePage')),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // Tap forfeit button in HUD
    await tester.tap(find.text('Forfeit').first);
    await tester.pump();

    // Tap Forfeit in dialog action (last in tree)
    await tester.tap(find.text('Forfeit').last);
    await tester.pump(); // dialog close
    await tester.pump(const Duration(milliseconds: 100)); // navigation

    // Should now be on home page
    expect(find.text('HomePage'), findsOneWidget);

    // Let entrance animation timers fire for clean teardown
    await tester.pump(const Duration(seconds: 2));
  });
}
