import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/screens/home_screen.dart';
import 'package:footyjong/game/game_controller.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays title and navigation buttons', (tester) async {
      final controller = GameController(seed: 42);
      addTearDown(() => controller.dispose());
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(controller: controller),
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
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(controller: controller),
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
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => HomeScreen(controller: controller),
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
  });
}
