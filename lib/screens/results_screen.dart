import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';

/// Displays the final score and level reached after a game is won.
///
/// - "Play Again" calls [controller.resetGame] and navigates to `/game`.
/// - "Home" navigates to `/`.
class ResultsScreen extends StatelessWidget {
  final GameController controller;

  const ResultsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: ${controller.currentScore}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Level: ${controller.currentLevel}',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                controller.resetGame();
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
}
