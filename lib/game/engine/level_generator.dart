import 'dart:math';
import 'package:footyjong/game/models/models.dart';
import 'package:footyjong/game/engine/board_layout.dart';

class LevelResult {
  final LayoutDefinition layout;
  final TileConfig config;
  const LevelResult(this.layout, this.config);
}

class LevelGenerator {
  final Random _random;
  int _easyStreak = 0;
  int _mediumStreak = 0;
  int _hardStreak = 0;

  static const int maxEasyStreak = 2;
  static const int maxHardStreak = 2;
  static const double hardWeightIncreasePerLevel = 0.005;

  LevelGenerator({int? seed})
      : _random = seed != null ? Random(seed) : Random();

  LevelResult generateLevel(int levelNumber) {
    final difficulty = _pickDifficulty(levelNumber);
    final compatibleLayouts = _getCompatibleLayouts(difficulty);
    final layout = compatibleLayouts[_random.nextInt(compatibleLayouts.length)];

    // Pick a compatible config
    final configs = TileConfig.availableConfigs
        .where((c) => layout.isCompatibleWith(c))
        .toList();
    final config = configs[_random.nextInt(configs.length)];

    return LevelResult(layout, config);
  }

  Difficulty _pickDifficulty(int levelNumber) {
    // Base weights
    double easyWeight = 0.40;
    double mediumWeight = 0.40;
    double hardWeight = 0.20 + (levelNumber * hardWeightIncreasePerLevel);

    // Apply streak penalties
    if (_easyStreak >= maxEasyStreak) easyWeight = 0;
    if (_hardStreak >= maxHardStreak) hardWeight = 0;

    // Normalize and pick
    final total = easyWeight + mediumWeight + hardWeight;
    final roll = _random.nextDouble() * total;

    if (roll < easyWeight) {
      _easyStreak++;
      _mediumStreak = 0;
      _hardStreak = 0;
      return Difficulty.easy;
    } else if (roll < easyWeight + mediumWeight) {
      _easyStreak = 0;
      _mediumStreak++;
      _hardStreak = 0;
      return Difficulty.medium;
    } else {
      _easyStreak = 0;
      _mediumStreak = 0;
      _hardStreak++;
      return Difficulty.hard;
    }
  }

  List<LayoutDefinition> _getCompatibleLayouts(Difficulty difficulty) {
    return BoardLayout.allLayouts
        .where((l) => l.difficulty == difficulty)
        .toList();
  }
}
