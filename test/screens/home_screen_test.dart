import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footyjong/screens/home_screen.dart';
import 'package:footyjong/services/game_settings.dart';
import 'package:footyjong/services/high_score_service.dart';
import 'package:footyjong/services/persistence_service.dart';
import 'package:footyjong/game/game_controller.dart';

/// Helper: fully initialise PersistenceService.
Future<void> _initPersistence() async {
  SharedPreferences.setMockInitialValues({});
  PersistenceService.resetForTesting();
  await PersistenceService.init();
}

Future<GameSettings> _makeSettings() async {
  await _initPersistence();
  final s = GameSettings(PersistenceService.instance);
  await s.load();
  return s;
}

HighScoreService _makeScoreService() =>
    HighScoreService(PersistenceService.instance);

void main() {
  group('HomeScreen', () {
    testWidgets('displays title and navigation buttons', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final settings = await _makeSettings();
      final scoreService = _makeScoreService();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(
              controller: controller,
              settings: settings,
              highScoreService: scoreService,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (_, __) => const Scaffold(body: Text('GamePage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      expect(find.text('FootyJong'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Play button navigates to /game', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final settings = await _makeSettings();
      final scoreService = _makeScoreService();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(
              controller: controller,
              settings: settings,
              highScoreService: scoreService,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (_, __) => const Scaffold(body: Text('GamePage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(find.text('GamePage'), findsOneWidget);
    });

    testWidgets('Settings icon navigates to /settings', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final settings = await _makeSettings();
      final scoreService = _makeScoreService();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(
              controller: controller,
              settings: settings,
              highScoreService: scoreService,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (_, __) => const Scaffold(body: Text('GamePage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('SettingsPage'), findsOneWidget);
    });

    testWidgets('shows high scores when available', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final settings = await _makeSettings();
      final scoreService = _makeScoreService();

      // Pre-seed a high score
      await scoreService.saveHighScore(
        difficultyIndex: 0,
        score: 999,
        level: 3,
        elapsedSeconds: 120,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(
              controller: controller,
              settings: settings,
              highScoreService: scoreService,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (_, __) => const Scaffold(body: Text('GamePage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      // Pump twice so the async _loadScores settles
      await tester.pump();
      await tester.pump();

      // Should show the "High Scores" heading
      expect(find.text('High Scores'), findsOneWidget);
      // Should show the score entry
      expect(find.textContaining('999 pts'), findsOneWidget);
    });

    testWidgets('hides high scores section when empty', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final settings = await _makeSettings();
      final scoreService = _makeScoreService();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(
              controller: controller,
              settings: settings,
              highScoreService: scoreService,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (_, __) => const Scaffold(body: Text('GamePage')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('SettingsPage')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('High Scores'), findsNothing);
    });
  });
}
