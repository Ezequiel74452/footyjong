import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/screens/results_screen.dart';
import 'package:footyjong/game/game_controller.dart';

void main() {
  group('ResultsScreen', () {
    testWidgets('displays score and level from controller', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      controller.startNewGame();
      controller.onGameWon(350);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/results',
            routes: [
              GoRoute(
                path: '/results',
                builder: (_, __) => ResultsScreen(controller: controller),
              ),
              GoRoute(
                path: '/game',
                builder: (_, __) => const Scaffold(body: Text('GamePage')),
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

      // Verify score and level are displayed
      expect(find.text('Score: 350'), findsOneWidget);
      expect(find.text('Level: 1'), findsOneWidget);

      // Verify buttons exist
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Play Again navigates to /game', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      controller.startNewGame();
      controller.onGameWon(200);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/results',
            routes: [
              GoRoute(
                path: '/results',
                builder: (_, __) => ResultsScreen(controller: controller),
              ),
              GoRoute(
                path: '/game',
                builder: (_, __) => const Scaffold(body: Text('GamePage')),
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

      await tester.tap(find.text('Play Again'));
      await tester.pumpAndSettle();

      expect(find.text('GamePage'), findsOneWidget);
    });

    testWidgets('Home navigates to /', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      controller.startNewGame();
      controller.onGameWon(150);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/results',
            routes: [
              GoRoute(
                path: '/results',
                builder: (_, __) => ResultsScreen(controller: controller),
              ),
              GoRoute(
                path: '/game',
                builder: (_, __) => const Scaffold(body: Text('GamePage')),
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

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('HomePage'), findsOneWidget);
    });
  });
}
