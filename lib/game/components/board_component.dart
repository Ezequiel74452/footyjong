import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/components/tile_component.dart';
import 'package:footyjong/game/effects/game_effects.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/models/models.dart';

/// Orchestrates the visual board: creates [TileComponent]s from [GameState],
/// positions them with z-order sorting, and drives all tile animations.
class BoardComponent extends Component {
  final GameState gameState;

  /// Called when the board enters a deadlocked state (HUD/reshuffle signal).
  final VoidCallback? onDeadlock;

  bool _isAnimating = false;

  /// Whether the board is currently animating and should ignore taps.
  /// Synced to all child [TileComponent]s automatically.
  bool get isAnimating => _isAnimating;

  set isAnimating(bool value) {
    _isAnimating = value;
    for (final child in children) {
      if (child is TileComponent) {
        child.isAnimating = value;
      }
    }
  }

  /// Lookup: tile ID → TileComponent for animation dispatch.
  final Map<int, TileComponent> _tilesById = {};

  BoardComponent({
    required this.gameState,
    this.onDeadlock,
  });

  @override
  FutureOr<void> onLoad() {
    _buildBoard();
    _playEntranceAnimation();
  }

  /// Creates [TileComponent]s from the current [GameState.boardTiles],
  /// positions them using the centering formula, sorts by z-order (back→front).
  void _buildBoard() {
    final layers = gameState.tilesByLayer;
    final layerDefs = gameState.layerDefs;
    if (layers.isEmpty || layerDefs.isEmpty) return;

    // Max dimensions across all layers
    int maxCols = 0;
    int maxRows = 0;
    for (final def in layerDefs) {
      if (def.cols > maxCols) maxCols = def.cols;
      if (def.rows > maxRows) maxRows = def.rows;
    }

    final numLayers = layers.length;
    final boardPixelWidth =
        maxCols * GameConstants.tileStep + (numLayers - 1) * GameConstants.staggerX;
    final boardPixelHeight =
        maxRows * GameConstants.tileStep + (numLayers - 1) * GameConstants.staggerY;
    final offsetX = (GameConstants.viewportWidth - boardPixelWidth) / 2;
    final offsetY = (GameConstants.viewportHeight - boardPixelHeight) / 2;

    // Collect all tiles with their screen position and z-order
    final entries = <_TileEntry>[];
    for (int layer = 0; layer < layers.length; layer++) {
      final layerTiles = layers[layer];
      final layerDef = layerDefs[layer];
      final cols = layerDef.cols;
      for (int gy = 0; gy < layerDef.rows; gy++) {
        for (int gx = 0; gx < cols; gx++) {
          final tile = layerTiles[gy * cols + gx];
          if (tile == null) continue;

          final x = gx * GameConstants.tileStep +
              layer * GameConstants.staggerX +
              offsetX;
          final y = gy * GameConstants.tileStep +
              layer * GameConstants.staggerY +
              offsetY;

          entries.add(_TileEntry(
            tile: tile,
            position: Vector2(x, y),
            zOrder: Position3D(gridX: gx, gridY: gy, layer: layer).zOrder,
            layer: layer,
            gridX: gx,
            gridY: gy,
          ));
        }
      }
    }

    // Sort by z-order ascending (back to front for correct hit-test order)
    entries.sort((a, b) => a.zOrder.compareTo(b.zOrder));

    // Create TileComponents
    for (final entry in entries) {
      final colors = GameConstants.footballerColors;
      final tileComponent = TileComponent(
        footballerIndex: entry.tile.footballerIndex,
        gridX: entry.gridX,
        gridY: entry.gridY,
        layer: entry.layer,
        frontColor: colors[entry.tile.footballerIndex % colors.length],
        onTileTapped: gameState.onTileTapped,
        position: entry.position,
      );

      _tilesById[entry.tile.id] = tileComponent;
      add(tileComponent);
    }
  }

  /// Staggered entrance animation: each tile drops from above.
  void _playEntranceAnimation() {
    final tiles = children.whereType<TileComponent>().toList();
    if (tiles.isEmpty) return;

    isAnimating = true;
    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final endY = tile.position.y;
      tile.position.y = endY - GameConstants.entranceDrop;
      final delay = Duration(
        milliseconds: (i * GameConstants.entranceStagger * 1000).round(),
      );
      Future.delayed(delay, () {
        tile.add(GameEffects.entranceEffect());
      });
    }

    // Release lock after last tile finishes its animation
    final totalDuration =
        tiles.length * GameConstants.entranceStagger + GameConstants.entranceDuration;
    Future.delayed(
      Duration(milliseconds: (totalDuration * 1000).round()),
      () => isAnimating = false,
    );
  }

  // ─── Event handlers called by FootyJongGame ────────────────────────────

  /// Highlight a tile by its [tileId] (selection indicator).
  void highlightTile(int tileId) {
    _tilesById[tileId]?.setSelected(true);
  }

  /// Remove highlight from a tile by its [tileId].
  void unhighlightTile(int tileId) {
    _tilesById[tileId]?.setSelected(false);
  }

  /// Animate removal of two matched tiles, then release the animation lock.
  Future<void> animateMatchRemoval(int tileIdA, int tileIdB) async {
    isAnimating = true;

    _tilesById[tileIdA]?.playMatchAnimation();
    _tilesById[tileIdB]?.playMatchAnimation();

    await Future.delayed(
      Duration(milliseconds: (GameConstants.matchDuration * 1000).round()),
    );

    _tilesById.remove(tileIdA);
    _tilesById.remove(tileIdB);
    isAnimating = false;
  }

  /// Animate a failed match (shake both tiles).
  Future<void> animateShake(int tileIdA, int tileIdB) async {
    isAnimating = true;

    _tilesById[tileIdA]?.playShakeAnimation();
    _tilesById[tileIdB]?.playShakeAnimation();

    await Future.delayed(
      Duration(milliseconds: (GameConstants.failDuration * 1000).round()),
    );

    isAnimating = false;
  }

  /// Cascade victory removal across all remaining tiles.
  void animateVictory() {
    isAnimating = true;
    final remaining = children.whereType<TileComponent>().toList();
    for (int i = 0; i < remaining.length; i++) {
      remaining[i].playVictoryAnimation(index: i, total: remaining.length);
    }
  }

  /// Signal to HUD that the board is deadlocked.
  void showDeadlockUI() {
    onDeadlock?.call();
  }
}

/// Internal helper: pairs a [TileData] with its screen position and z-order.
class _TileEntry {
  final TileData tile;
  final Vector2 position;
  final int zOrder;
  final int layer;
  final int gridX;
  final int gridY;

  const _TileEntry({
    required this.tile,
    required this.position,
    required this.zOrder,
    required this.layer,
    required this.gridX,
    required this.gridY,
  });
}
