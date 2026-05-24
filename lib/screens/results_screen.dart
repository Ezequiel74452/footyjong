import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/services/high_score_service.dart';

/// Displays the final score, level, and elapsed time after a game is won.
///
/// If a [HighScoreService] is provided, the score is persisted once on first
/// build via a post-frame callback.
///
/// - "Play Again" calls [controller.resetGame] and navigates to `/game`.
/// - "Home" navigates to `/`.
class ResultsScreen extends StatefulWidget {
  final GameController controller;
  final HighScoreService? highScoreService;

  const ResultsScreen({
    super.key,
    required this.controller,
    this.highScoreService,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveHighScore());
  }

  void _saveHighScore() {
    if (_saved) return;
    _saved = true;
    final elapsed = widget.controller.elapsed;
    if (widget.highScoreService != null && elapsed != null) {
      widget.highScoreService!.saveHighScore(
        difficultyIndex: 0,
        score: widget.controller.currentScore,
        level: widget.controller.currentLevel,
        elapsedSeconds: elapsed.inSeconds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: ${widget.controller.currentScore}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Level: ${widget.controller.currentLevel}',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatDuration(widget.controller.elapsed)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                widget.controller.resetGame();
                context.go('/game');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Play Again',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text(
                'Home',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a [Duration] as `MM:SS`.  Returns `--:--` for `null`.
  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final twoDigitMinutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final twoDigitSeconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
