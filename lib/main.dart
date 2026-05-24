import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/screens/game_screen.dart';
import 'package:footyjong/screens/home_screen.dart';
import 'package:footyjong/screens/results_screen.dart';
import 'package:footyjong/screens/settings_screen.dart';

void main() {
  runApp(FootyJongApp());
}

/// Root application owning a single [GameController] and a [GoRouter] that
/// survives screen transitions.
class FootyJongApp extends StatefulWidget {
  const FootyJongApp({super.key});

  @override
  State<FootyJongApp> createState() => _FootyJongAppState();
}

class _FootyJongAppState extends State<FootyJongApp> {
  late final GameController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        // Guard: /game requires an active game
        if (state.matchedLocation == '/game' && !_controller.gameActive) {
          return '/';
        }
        // Guard: /results requires a concluded game
        if (state.matchedLocation == '/results' && _controller.gameActive) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => HomeScreen(controller: _controller),
        ),
        GoRoute(
          path: '/game',
          builder: (_, __) => GameScreen(controller: _controller),
        ),
        GoRoute(
          path: '/results',
          builder: (_, __) => ResultsScreen(controller: _controller),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FootyJong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routerConfig: _router,
    );
  }
}
