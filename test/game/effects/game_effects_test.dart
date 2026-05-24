import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/effects/game_effects.dart';

void main() {
  group('GameEffects', () {
    test('entranceEffect returns a MoveEffect', () {
      final effect = GameEffects.entranceEffect();
      expect(effect, isNotNull);
    });

    test('selectEffect returns a ScaleEffect', () {
      final effect = GameEffects.selectEffect();
      expect(effect, isNotNull);
    });

    test('deselectEffect returns a ScaleEffect', () {
      final effect = GameEffects.deselectEffect();
      expect(effect, isNotNull);
    });

    test('matchEffects returns 3 effects', () {
      final effects = GameEffects.matchEffects();
      expect(effects.length, 3);
    });

    test('shakeEffect returns a SequenceEffect', () {
      final effect = GameEffects.shakeEffect();
      expect(effect, isNotNull);
    });

    test('victoryEffects returns 3 effects', () {
      final effects = GameEffects.victoryEffects();
      expect(effects.length, 3);
    });
  });
}
