import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/screens/results_screen.dart';
import 'package:footyjong/services/high_score_service.dart';
import 'package:footyjong/services/persistence_service.dart';

Future<void> _initPersistence() async {
  SharedPreferences.setMockInitialValues({});
  PersistenceService.resetForTesting();
  await PersistenceService.init();
}

void main() {
  group('Integration: game win persists high score', () {
    testWidgets('full game win flow saves high score via ResultsScreen',
        (tester) async {
      await _initPersistence();
      final highScoreService = HighScoreService(PersistenceService.instance);
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());

      controller.startNewGame();
      // Simulate winning the game with a score and elapsed time
      controller.onGameWon(350, elapsed: const Duration(seconds: 90));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/results',
            routes: [
              GoRoute(
                path: '/results',
                builder: (_, __) => ResultsScreen(
                  controller: controller,
                  highScoreService: highScoreService,
                ),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) =>
                    const Scaffold(body: Text('HomePage')),
              ),
              GoRoute(
                path: '/game',
                builder: (_, __) =>
                    const Scaffold(body: Text('GamePage')),
              ),
            ],
          ),
        ),
      );
      // First pump renders the widget, second pump processes the
      // post-frame callback that saves the high score
      await tester.pump();
      await tester.pump();

      // Verify the high score was persisted
      final scores = await highScoreService.getHighScores(
        difficultyIndex: 0,
      );
      expect(scores.length, 1);
      expect(scores.first.score, 350);
      expect(scores.first.level, 1);
      expect(scores.first.elapsedSeconds, 90);

      // Verify the ResultsScreen displays the data
      expect(find.text('Score: 350'), findsOneWidget);
      expect(find.text('Level: 1'), findsOneWidget);
      expect(find.text('Time: 01:30'), findsOneWidget);
    });
  });
}
