import 'dart:async';
import 'dart:ui' show Canvas, Color, Offset, Paint, PaintingStyle, Radius, Rect, RRect;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' as material;
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/effects/game_effects.dart';

/// A visual tile on the Mahjong board. Renders as a colored rounded rectangle
/// with the footballer index as centered text. Responds to taps by calling
/// [onTileTapped].
class TileComponent extends PositionComponent with TapCallbacks {
  final int footballerIndex;
  final int gridX;
  final int gridY;
  final int layer;
  final Color frontColor;

  /// Callback invoked when this tile is tapped.
  /// Passes (layer, gridX, gridY) for GameState.onTileTapped().
  final void Function(int layer, int gridX, int gridY) onTileTapped;

  /// Whether the board is currently animating (prevents taps).
  bool isAnimating = false;

  bool _isSelected = false;
  bool _isMatched = false;

  bool get isSelected => _isSelected;

  TileComponent({
    required this.footballerIndex,
    required this.gridX,
    required this.gridY,
    required this.layer,
    required this.frontColor,
    required this.onTileTapped,
    super.position,
  }) : super(size: Vector2.all(GameConstants.tileSize));

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(GameConstants.tileCornerRadius),
    );

    if (_isMatched) {
      // Already animating out — don't re-render fully
      return;
    }

    // Draw tile back (shadow/base)
    final backPaint = Paint()
      ..color = Color.lerp(frontColor, material.Colors.transparent, GameConstants.backDarkenFactor)!;
    canvas.drawRRect(rrect, backPaint);

    // Draw tile front
    final frontPaint = Paint()..color = frontColor;
    // Slightly smaller than back for depth
    final frontRect = Rect.fromLTWH(2, 2, size.x - 4, size.y - 4);
    final frontRrect = RRect.fromRectAndRadius(
      frontRect,
      Radius.circular(GameConstants.tileCornerRadius - 1),
    );
    canvas.drawRRect(frontRrect, frontPaint);

    // Selected border
    if (_isSelected) {
      final borderPaint = Paint()
        ..color = GameConstants.selectedBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameConstants.selectedBorderWidth;
      // Draw slightly inside to avoid clipping
      final borderRect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);
      final borderRRect = RRect.fromRectAndRadius(
        borderRect,
        Radius.circular(GameConstants.tileCornerRadius),
      );
      canvas.drawRRect(borderRRect, borderPaint);
    }

    // Draw footballer index text
    final textPainter = material.TextPainter(
      text: material.TextSpan(
        text: '$footballerIndex',
        style: material.TextStyle(
          color: GameConstants.tileTextColor,
          fontSize: GameConstants.tileTextSize,
          fontWeight: material.FontWeight.bold,
        ),
      ),
      textDirection: material.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isAnimating || _isMatched) return;
    onTileTapped(layer, gridX, gridY);
  }

  void setSelected(bool selected) {
    _isSelected = selected;
    if (selected) {
      add(GameEffects.selectEffect());
    } else {
      add(GameEffects.deselectEffect());
    }
  }

  void playMatchAnimation() {
    _isMatched = true;

    final cleanup = SequenceEffect(
      [
        ScaleEffect.to(
          Vector2.all(GameConstants.matchScalePeak),
          EffectController(duration: GameConstants.matchDuration * 0.4),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: GameConstants.matchDuration * 0.6),
        ),
        OpacityEffect.to(
          0.0,
          EffectController(duration: GameConstants.matchDuration),
        ),
      ],
      onComplete: () {
        if (parent != null) removeFromParent();
      },
    );
    add(cleanup);
  }

  void playShakeAnimation() {
    final offset = GameConstants.failShakeOffset;
    final dur = GameConstants.failDuration / 3;
    add(SequenceEffect([
      MoveEffect.by(Vector2(-offset, 0), EffectController(duration: dur)),
      MoveEffect.by(Vector2(offset * 2, 0), EffectController(duration: dur)),
      MoveEffect.by(Vector2(-offset, 0), EffectController(duration: dur)),
    ]));
  }

  void playVictoryAnimation({required int index, required int total}) {
    _isMatched = true;
    final delay = index * GameConstants.victoryStagger;

    Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      final peakDur = GameConstants.victoryDuration * 0.3;
      final shrinkDur = GameConstants.victoryDuration * 0.7;
      add(SequenceEffect(
        [
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
        ],
        onComplete: () {
          if (parent != null) removeFromParent();
        },
      ));
    });
  }
}
