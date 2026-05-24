import 'package:flutter/material.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/models/layout_definition.dart';
import 'package:footyjong/services/game_settings.dart';

/// Full settings screen with three sections:
///
/// 1. **Sound** — toggle sound on/off
/// 2. **Difficulty** — pick Easy, Medium, or Hard
/// 3. **Layouts** — toggle "all unlocked" or view individual layout statuses
///
/// Uses [ListenableBuilder] to react to [GameSettings] mutations without
/// requiring a StatefulWidget.
class SettingsScreen extends StatelessWidget {
  final GameSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSoundSection(),
            const Divider(height: 32),
            _buildDifficultySection(),
            const Divider(height: 32),
            _buildLayoutsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Sound',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Sound Effects'),
          subtitle: const Text('Enable or disable in-game sounds'),
          value: settings.soundEnabled,
          onChanged: (v) => settings.soundEnabled = v,
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        ...Difficulty.values.map((diff) {
          String subtitle;
          switch (diff) {
            case Difficulty.easy:
              subtitle = 'Relaxed play — simpler layouts';
              break;
            case Difficulty.medium:
              subtitle = 'Balanced challenge';
              break;
            case Difficulty.hard:
              subtitle = 'Complex layouts — for veterans';
              break;
          }
          return RadioListTile<Difficulty>(
            title: Text(_difficultyLabel(diff)),
            subtitle: Text(subtitle),
            value: diff,
            groupValue: settings.difficultySetting,
            onChanged: (v) {
              if (v != null) settings.difficultySetting = v;
            },
          );
        }),
      ],
    );
  }

  Widget _buildLayoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Layouts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('All Layouts Unlocked'),
          subtitle: const Text('Enable every board layout'),
          value: settings.allLayoutsUnlocked,
          onChanged: (v) {
            if (v) {
              settings.unlockAllLayouts();
            } else {
              settings.unlockedLayouts = [];
            }
          },
        ),
        const SizedBox(height: 8),
        ...BoardLayout.allLayouts.map((layout) {
          final unlocked = settings.allLayoutsUnlocked ||
              settings.unlockedLayouts.contains(layout.name);
          return ListTile(
            dense: true,
            leading: Icon(
              unlocked ? Icons.check_circle : Icons.lock,
              color: unlocked ? Colors.green : Colors.grey,
              size: 20,
            ),
            title: Text(layout.name),
            subtitle: Text(
              '${layout.totalPositions} tiles — ${_difficultyLabel(layout.difficulty)}',
              style: const TextStyle(fontSize: 12),
            ),
            enabled: unlocked,
          );
        }),
      ],
    );
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}
