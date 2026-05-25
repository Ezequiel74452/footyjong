import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/services/game_settings.dart';
import 'package:footyjong/services/high_score_service.dart';

/// Landing screen with app title, Play button, Settings gear icon, and a
/// high-score leaderboard section.
///
/// Tap Play → calls [controller.startNewGame] and navigates to `/game`.
/// Tap Settings → navigates to `/settings`.
class HomeScreen extends StatefulWidget {
  final GameController controller;
  final GameSettings settings;
  final HighScoreService highScoreService;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.settings,
    required this.highScoreService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScoreEntry> _highScores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await widget.highScoreService.getHighScores(
      difficultyIndex: 0,
      limit: 5,
    );
    if (!mounted) return;
    setState(() {
      _highScores = scores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Title and main actions
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FootyJong',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        widget.controller.startNewGame();
                        context.go('/game');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to start game: $e'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    iconSize: 32,
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            // High scores section
            if (!_loading && _highScores.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Text(
                      'High Scores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._highScores.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.score} pts  ·  Level ${entry.level}  ·  '
                          '${_formatDuration(entry.elapsedSeconds)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
