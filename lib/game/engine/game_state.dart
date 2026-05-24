import 'dart:async';
import 'package:footyjong/game/models/models.dart';
import 'package:footyjong/game/engine/matching_engine.dart';
import 'package:footyjong/game/engine/shuffle_engine.dart';

enum GamePhase {
  initializing,
  playing,
  tileSelected,
  matching,
  deadlocked,
  won,
}

/// Events emitted by GameState for UI/effects to react to.
sealed class GameEvent {
  const GameEvent();
}

class TileSelected extends GameEvent {
  final TileData tile;
  final Position3D position;
  const TileSelected(this.tile, this.position);
}

class TileDeselected extends GameEvent {
  final TileData tile;
  const TileDeselected(this.tile);
}

class MatchSuccess extends GameEvent {
  final TileData tileA;
  final TileData tileB;
  final List<Position3D> removedPositions;
  const MatchSuccess(this.tileA, this.tileB, this.removedPositions);
}

class MatchFailed extends GameEvent {
  final TileData tileA;
  final TileData tileB;
  const MatchFailed(this.tileA, this.tileB);
}

class DeadlockDetected extends GameEvent {
  const DeadlockDetected();
}

class GameWon extends GameEvent {
  final int score;
  final int level;
  const GameWon(this.score, this.level);
}

class GameState {
  GamePhase _phase = GamePhase.initializing;
  TileData? _selectedTile;
  Position3D? _selectedPosition;
  int _score = 0;
  int _level = 1;

  // Board state: List of layers, each layer is a flat list of tiles (null = removed)
  List<List<TileData?>> _tilesByLayer = [];
  List<LayerDefinition> _layerDefs = [];
  LayoutDefinition _currentLayout;
  TileConfig _currentConfig;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  GamePhase get phase => _phase;
  TileData? get selectedTile => _selectedTile;
  int get score => _score;
  int get level => _level;

  GameState({
    required LayoutDefinition layout,
    required TileConfig config,
  })  : _currentLayout = layout,
        _currentConfig = config;

  /// Initialize the board with shuffled tiles.
  void initialize({int? seed}) {
    final tiles = ShuffleEngine.generateTiles(_currentConfig);
    _tilesByLayer = ShuffleEngine.assignToPositions(
      tiles,
      _currentLayout,
      seed: seed,
    );
    _layerDefs = List.from(_currentLayout.layers);
    _phase = GamePhase.playing;
  }

  /// Handle a tile tap at the given position.
  void onTileTapped(int layer, int gridX, int gridY) {
    if (_phase == GamePhase.matching || _phase == GamePhase.won) return;

    final tile = _tilesByLayer[layer][gridY * _layerDefs[layer].cols + gridX];
    if (tile == null) return;

    // Check if tile is free
    if (!MatchingEngine.isTileFree(
      layer: layer,
      gridX: gridX,
      gridY: gridY,
      tilesByLayer: _tilesByLayer,
      layerDefs: _layerDefs,
    )) return;

    if (_phase == GamePhase.playing) {
      // First selection
      _selectedTile = tile;
      _selectedPosition = Position3D(gridX: gridX, gridY: gridY, layer: layer);
      _phase = GamePhase.tileSelected;
      _eventController.add(TileSelected(tile, _selectedPosition!));
    } else if (_phase == GamePhase.tileSelected) {
      // Second selection
      if (tile.id == _selectedTile!.id) return; // same tile

      if (tile.isMatchableWith(_selectedTile!)) {
        // MATCH!
        _phase = GamePhase.matching;
        final posA = _selectedPosition!;
        final posB = Position3D(gridX: gridX, gridY: gridY, layer: layer);

        // Remove tiles
        final layerA = _tilesByLayer[posA.layer];
        layerA[posA.gridY * _layerDefs[posA.layer].cols + posA.gridX] = null;
        final layerB = _tilesByLayer[layer];
        layerB[gridY * _layerDefs[layer].cols + gridX] = null;

        _score += 100;
        _eventController.add(MatchSuccess(_selectedTile!, tile, [posA, posB]));

        _selectedTile = null;
        _selectedPosition = null;

        // Check win
        if (_checkWin()) {
          _phase = GamePhase.won;
          _eventController.add(GameWon(_score, _level));
          return;
        }

        // Check deadlock
        if (MatchingEngine.isDeadlocked(_tilesByLayer, _layerDefs)) {
          _phase = GamePhase.deadlocked;
          _eventController.add(DeadlockDetected());
          return;
        }

        _phase = GamePhase.playing;
      } else {
        // MISMATCH
        _eventController.add(MatchFailed(_selectedTile!, tile));
        _selectedTile = null;
        _selectedPosition = null;
        _phase = GamePhase.playing;
      }
    }
  }

  bool _checkWin() {
    for (final layer in _tilesByLayer) {
      for (final tile in layer) {
        if (tile != null) return false;
      }
    }
    return true;
  }

  /// Reshuffle remaining tiles after deadlock.
  void reshuffle({int? seed}) {
    // Collect all remaining tiles
    final remaining = <TileData>[];
    for (final layer in _tilesByLayer) {
      for (final tile in layer) {
        if (tile != null) remaining.add(tile);
      }
    }

    _tilesByLayer = ShuffleEngine.assignToPositions(
      remaining,
      _currentLayout,
      seed: seed,
    );

    if (MatchingEngine.isDeadlocked(_tilesByLayer, _layerDefs)) {
      // Still deadlocked — generate new layout (last resort)
      _phase = GamePhase.deadlocked;
    } else {
      _phase = GamePhase.playing;
    }
  }

  void dispose() {
    _eventController.close();
  }
}
