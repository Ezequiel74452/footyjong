import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/level_generator.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/models/models.dart';

/// Count how many of [count] generated levels fall into each difficulty.
/// Levels are generated sequentially starting at [startLevel].
Map<Difficulty, int> _sampleDifficulties(
  LevelGenerator gen,
  int count, {
  int startLevel = 1,
}) {
  final tallies = <Difficulty, int>{
    Difficulty.easy: 0,
    Difficulty.medium: 0,
    Difficulty.hard: 0,
  };
  for (int i = 0; i < count; i++) {
    final level = startLevel + i;
    final result = gen.generateLevel(level);
    tallies[result.layout.difficulty] =
        (tallies[result.layout.difficulty] ?? 0) + 1;
  }
  return tallies;
}

void main() {
  group('LevelGenerator', () {
    // -----------------------------------------------------------------------
    // Test 1: generateLevel returns a valid LevelResult with compatible
    //         layout + config
    // -----------------------------------------------------------------------
    test('1: generateLevel returns valid LevelResult with compatible config',
        () {
      final gen = LevelGenerator(seed: 42);
      final result = gen.generateLevel(1);

      expect(result, isA<LevelResult>());
      expect(result.layout, isA<LayoutDefinition>());
      expect(result.config, isA<TileConfig>());
      expect(result.layout.isCompatibleWith(result.config), isTrue,
          reason:
              'Layout ${result.layout.name} (${result.layout.totalPositions} pos) '
              'must be compatible with '
              '${result.config.numFootballers}x${result.config.copiesPerFootballer} '
              '(${result.config.totalTiles} tiles)');
    });

    // -----------------------------------------------------------------------
    // Test 2: No more than 2 consecutive easy levels
    // -----------------------------------------------------------------------
    test('2: No more than 2 consecutive easy levels', () {
      // With a fixed seed, the generator's internal streak logic kicks in.
      // Generate enough levels so streaks could happen.
      final gen = LevelGenerator(seed: 1);
      int easyStreak = 0;
      int maxEasySeen = 0;

      for (int i = 1; i <= 100; i++) {
        final result = gen.generateLevel(i);
        if (result.layout.difficulty == Difficulty.easy) {
          easyStreak++;
          if (easyStreak > maxEasySeen) maxEasySeen = easyStreak;
        } else {
          easyStreak = 0;
        }
      }

      expect(maxEasySeen, lessThanOrEqualTo(LevelGenerator.maxEasyStreak));
    });

    // -----------------------------------------------------------------------
    // Test 3: No more than 2 consecutive hard levels
    // -----------------------------------------------------------------------
    test('3: No more than 2 consecutive hard levels', () {
      final gen = LevelGenerator(seed: 2);
      int hardStreak = 0;
      int maxHardSeen = 0;

      for (int i = 1; i <= 100; i++) {
        final result = gen.generateLevel(i);
        if (result.layout.difficulty == Difficulty.hard) {
          hardStreak++;
          if (hardStreak > maxHardSeen) maxHardSeen = hardStreak;
        } else {
          hardStreak = 0;
        }
      }

      expect(maxHardSeen, lessThanOrEqualTo(LevelGenerator.maxHardStreak));
    });

    // -----------------------------------------------------------------------
    // Test 4: Over 100 levels, hard becomes more common
    // -----------------------------------------------------------------------
    test('4: Over 100 levels, hard becomes more common', () {
      // Early levels (1-50): hard weight is low (~20%).
      final earlyGen = LevelGenerator(seed: 10);
      final earlyCounts = _sampleDifficulties(earlyGen, 50, startLevel: 1);

      // Late levels (950-999): hard weight is high.
      // At level 950: hardWeight = 0.20 + 950 * 0.005 = 4.95 → very dominant.
      final lateGen = LevelGenerator(seed: 10);
      final lateCounts =
          _sampleDifficulties(lateGen, 50, startLevel: 950);

      // Hard should appear proportionally more at high levels.
      expect(
        lateCounts[Difficulty.hard]!,
        greaterThan(earlyCounts[Difficulty.hard]!),
        reason:
            'Hard count at high levels (${lateCounts[Difficulty.hard]}) '
            'should exceed hard count at low levels (${earlyCounts[Difficulty.hard]})',
      );
    });

    // -----------------------------------------------------------------------
    // Test 5: Deterministic with seed
    // -----------------------------------------------------------------------
    test('5: Deterministic with seed', () {
      final genA = LevelGenerator(seed: 42);
      final genB = LevelGenerator(seed: 42);

      for (int i = 1; i <= 20; i++) {
        final resultA = genA.generateLevel(i);
        final resultB = genB.generateLevel(i);

        expect(resultA.layout.name, resultB.layout.name);
        expect(resultA.config.totalTiles, resultB.config.totalTiles);
        expect(resultA.config.numFootballers, resultB.config.numFootballers);
        expect(resultA.config.copiesPerFootballer,
            resultB.config.copiesPerFootballer);
      }
    });

    // -----------------------------------------------------------------------
    // Test 6: All levels have compatible layout + config
    //         (positionCount == totalTiles)
    // -----------------------------------------------------------------------
    test('6: All generated levels have compatible layout + config', () {
      final gen = LevelGenerator(seed: 7);

      for (int i = 1; i <= 200; i++) {
        final result = gen.generateLevel(i);
        final reason = 'Level $i: ${result.layout.name} '
            '(${result.layout.totalPositions} pos) + '
            '${result.config.numFootballers}x${result.config.copiesPerFootballer} '
            '(${result.config.totalTiles} tiles)';
        expect(result.layout.isCompatibleWith(result.config), isTrue,
            reason: reason);
      }
    });
  });
}
