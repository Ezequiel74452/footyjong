import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/config/game_constants.dart';

void main() {
  group('GameConstants', () {
    test('tile sizes are positive', () {
      expect(GameConstants.tileSize, greaterThan(0));
      expect(GameConstants.tileStep, greaterThan(0));
      expect(GameConstants.tileGap, greaterThanOrEqualTo(0));
    });

    test('viewport dimensions are positive', () {
      expect(GameConstants.viewportWidth, greaterThan(0));
      expect(GameConstants.viewportHeight, greaterThan(0));
    });

    test('animation durations are positive', () {
      expect(GameConstants.entranceDuration, greaterThan(0));
      expect(GameConstants.selectDuration, greaterThan(0));
      expect(GameConstants.matchDuration, greaterThan(0));
      expect(GameConstants.failDuration, greaterThan(0));
      expect(GameConstants.victoryDuration, greaterThan(0));
    });

    test('footballerColors has exactly 36 entries', () {
      expect(GameConstants.footballerColors.length, 36);
    });

    test('all footballerColors are non-transparent', () {
      for (final color in GameConstants.footballerColors) {
        expect(color.opacity, 1.0);
      }
    });

    test('stagger offsets are non-negative', () {
      expect(GameConstants.staggerX, greaterThanOrEqualTo(0));
      expect(GameConstants.staggerY, greaterThanOrEqualTo(0));
    });
  });
}
