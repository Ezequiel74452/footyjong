import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/services/game_settings.dart';

/// Landing screen with app title, Play button, and Settings gear icon.
///
/// Tap Play → calls [controller.startNewGame] and navigates to `/game`.
/// Tap Settings → navigates to `/settings`.
class HomeScreen extends StatelessWidget {
  final GameController controller;
  final GameSettings settings;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  controller.startNewGame();
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
    );
  }
}
