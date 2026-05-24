import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/screens/game_screen.dart';
import 'package:footyjong/screens/home_screen.dart';
import 'package:footyjong/screens/results_screen.dart';
import 'package:footyjong/screens/settings_screen.dart';
import 'package:footyjong/services/game_settings.dart';
import 'package:footyjong/services/high_score_service.dart';
import 'package:footyjong/services/persistence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersistenceService.init();
  final settings = GameSettings(PersistenceService.instance);
  await settings.load();
  // ignore: unused_local_variable — HighScoreService is created here so
  // the singleton PersistenceService reference is retained and the service
  // is available for injection in later wiring.
  final highScoreService = HighScoreService(PersistenceService.instance);
  runApp(FootyJongApp(
    settings: settings,
    highScoreService: highScoreService,
  ));
}

/// Root application owning a single [GameController], [GameSettings], and a
/// [GoRouter] that survives screen transitions.
class FootyJongApp extends StatefulWidget {
  final GameSettings settings;
  final HighScoreService highScoreService;

  const FootyJongApp({
    super.key,
    required this.settings,
    required this.highScoreService,
  });

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
          builder: (_, __) => HomeScreen(
            controller: _controller,
            settings: widget.settings,
          ),
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
          builder: (_, __) => SettingsScreen(settings: widget.settings),
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
