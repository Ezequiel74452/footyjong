import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:footyjong/config/game_constants.dart';

/// Static factory for all game animation effects.
class GameEffects {
  GameEffects._();

  /// Board entrance: tile drops from above with bounce.
  static MoveEffect entranceEffect(double endY) {
    return MoveEffect.to(
      Vector2(0, endY),
      EffectController(
        duration: GameConstants.entranceDuration,
        curve: Curves.bounceOut,
      ),
    );
  }

  /// Selection: subtle scale-up.
  static ScaleEffect selectEffect() {
    return ScaleEffect.to(
      Vector2.all(GameConstants.selectScaleUp),
      EffectController(duration: GameConstants.selectDuration),
    );
  }

  /// Deselection: scale back to normal.
  static ScaleEffect deselectEffect() {
    return ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: GameConstants.selectDuration * 0.5),
    );
  }

  /// Match removal: scale up then down to 0 + fade out.
  static List<Effect> matchEffects() {
    final peakDuration = GameConstants.matchDuration * 0.4;
    final shrinkDuration = GameConstants.matchDuration * 0.6;
    return [
      ScaleEffect.to(
        Vector2.all(GameConstants.matchScalePeak),
        EffectController(duration: peakDuration),
      ),
      ScaleEffect.to(
        Vector2.all(0.0),
        EffectController(duration: shrinkDuration),
      ),
      OpacityEffect.to(
        0.0,
        EffectController(duration: GameConstants.matchDuration),
      ),
    ];
  }

  /// Match failed: horizontal shake.
  static SequenceEffect shakeEffect() {
    final offset = GameConstants.failShakeOffset;
    final dur = GameConstants.failDuration / 3;
    return SequenceEffect([
      MoveEffect.by(Vector2(-offset, 0), EffectController(duration: dur)),
      MoveEffect.by(Vector2(offset * 2, 0), EffectController(duration: dur)),
      MoveEffect.by(Vector2(-offset, 0), EffectController(duration: dur)),
    ]);
  }

  /// Victory: cascade removal for each tile.
  static List<Effect> victoryEffects() {
    final peakDur = GameConstants.victoryDuration * 0.3;
    final shrinkDur = GameConstants.victoryDuration * 0.7;
    return [
      ScaleEffect.to(
        Vector2.all(GameConstants.victoryScalePeak),
        EffectController(duration: peakDur),
      ),
      ScaleEffect.to(
        Vector2.all(0.0),
        EffectController(duration: shrinkDur),
      ),
      OpacityEffect.to(
        0.0,
        EffectController(duration: GameConstants.victoryDuration),
      ),
    ];
  }
}
