import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/footyjong_game.dart';
import 'package:footyjong/game/models/models.dart';

/// Full-screen game view with a Flame [GameWidget] rendering the board and a
/// Flutter HUD overlay showing score and level.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FootyJongGame _game;

  @override
  void initState() {
    super.initState();
    final layout = BoardLayout.butterfly;
    final config = const TileConfig(18, 4);
    final gameState = GameState(layout: layout, config: config);
    _game = FootyJongGame(gameState: gameState);
  }

  @override
  void dispose() {
    _game.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.viewportBackground,
      body: Stack(
        children: [
          GameWidget(game: _game),
          // HUD overlay
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _game.scoreNotifier,
                  builder: (context, score, _) {
                    return Text(
                      'Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _game.levelNotifier,
                  builder: (context, level, _) {
                    return Text(
                      'Level: $level',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
