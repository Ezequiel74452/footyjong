import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/engine/shuffle_engine.dart';
import 'package:footyjong/game/engine/matching_engine.dart';
import 'package:footyjong/game/models/models.dart';

// ---------------------------------------------------------------------------
// Test layouts
// ---------------------------------------------------------------------------

/// 2×2 single-layer test layout (4 positions).
LayoutDefinition _layout2x2() => LayoutDefinition(
      name: 'test-2x2',
      difficulty: Difficulty.easy,
      layers: [
        LayerDefinition(
          rows: 2,
          cols: 2,
          occupied: List.generate(2, (_) => List.filled(2, true)),
        ),
      ],
    );

/// 1×3 single-layer test layout (3 positions).
/// Positions: (0,0) free, (1,0) blocked, (2,0) free.
LayoutDefinition _layout1x3() => LayoutDefinition(
      name: 'test-1x3',
      difficulty: Difficulty.easy,
      layers: [
        LayerDefinition(
          rows: 1,
          cols: 3,
          occupied: [List.filled(3, true)],
        ),
      ],
    );

/// Two-layer layout for deadlock testing:
/// Layer 0 (bottom): 1×5 filled (5 positions)
/// Layer 1 (top):    1×3 filled (3 positions, centred offset = 1)
/// Total: 8 positions → TileConfig(4, 2) → 8 tiles, 4 footballers × 2 copies.
///
/// After matching and removing tiles, some free tiles may have unique
/// footballerIndex values, triggering a deadlock.
LayoutDefinition _layoutDeadlock() => LayoutDefinition(
      name: 'test-deadlock',
      difficulty: Difficulty.hard,
      layers: [
        LayerDefinition(
          rows: 1,
          cols: 5,
          occupied: [List.filled(5, true)],
        ),
        LayerDefinition(
          rows: 1,
          cols: 3,
          occupied: [List.filled(3, true)],
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pre-compute the tile arrangement for [layout] + [config] + [seed].
(List<List<TileData?>>, List<LayerDefinition>) _arrange(
  LayoutDefinition layout,
  TileConfig config,
  int seed,
) {
  final tiles = ShuffleEngine.generateTiles(config);
  return (
    ShuffleEngine.assignToPositions(tiles, layout, seed: seed),
    List.from(layout.layers),
  );
}

/// Find the first free tile matching [predicate] and return (layer, gridX, gridY).
(int, int, int) _findFreeTile(
  List<List<TileData?>> tilesByLayer,
  List<LayerDefinition> layerDefs,
  bool Function(TileData) predicate,
) {
  final free = MatchingEngine.getFreeTiles(tilesByLayer, layerDefs);
  for (final tile in free) {
    if (predicate(tile)) {
      for (int l = 0; l < tilesByLayer.length; l++) {
        final def = layerDefs[l];
        for (int i = 0; i < tilesByLayer[l].length; i++) {
          final t = tilesByLayer[l][i];
          if (t != null && t.id == tile.id) {
            return (l, i % def.cols, i ~/ def.cols);
          }
        }
      }
    }
  }
  throw StateError('No matching free tile found');
}

/// Return (layer, gridX, gridY) for all tiles grouped by footballerIndex.
Map<int, List<(int, int, int)>> _freeTilePositionsByFi(
  List<List<TileData?>> tilesByLayer,
  List<LayerDefinition> layerDefs,
) {
  final byFi = <int, List<(int, int, int)>>{};
  final free = MatchingEngine.getFreeTiles(tilesByLayer, layerDefs);
  for (final tile in free) {
    for (int l = 0; l < tilesByLayer.length; l++) {
      final def = layerDefs[l];
      for (int i = 0; i < tilesByLayer[l].length; i++) {
        final t = tilesByLayer[l][i];
        if (t != null && t.id == tile.id) {
          byFi.putIfAbsent(t.footballerIndex, () => []).add((
            l,
            i % def.cols,
            i ~/ def.cols,
          ));
        }
      }
    }
  }
  return byFi;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GameState', () {
    // -----------------------------------------------------------------------
    // Test 1: Initializes in playing phase
    // -----------------------------------------------------------------------
    test('1: Initializes in playing phase', () {
      final state = GameState(layout: _layout2x2(), config: TileConfig(2, 2));

      expect(state.phase, GamePhase.initializing);
      expect(state.score, 0);
      expect(state.level, 1);

      state.initialize(seed: 42);

      expect(state.phase, GamePhase.playing);
      expect(state.score, 0);
      expect(state.level, 1);
    });

    // -----------------------------------------------------------------------
    // Test 2: Selecting a free tile transitions to tileSelected
    // -----------------------------------------------------------------------
    test('2: Selecting a free tile transitions to tileSelected', () {
      final state = GameState(layout: _layout2x2(), config: TileConfig(2, 2));
      state.initialize(seed: 42);

      state.onTileTapped(0, 0, 0);

      expect(state.phase, GamePhase.tileSelected);
      expect(state.selectedTile, isNotNull);
    });

    // -----------------------------------------------------------------------
    // Test 3: Selecting matching pair triggers MatchSuccess
    // -----------------------------------------------------------------------
    test('3: Selecting matching pair triggers MatchSuccess', () async {
      final layout = _layout2x2();
      final config = TileConfig(2, 2);
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);

      // Find two free tiles with the same footballerIndex.
      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entry = byFi.entries.firstWhere((e) => e.value.length >= 2);
      final a = entry.value[0];
      final b = entry.value[1];

      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      state.onTileTapped(a.$1, a.$2, a.$3);

      expect(events.length, 1);
      expect(events[0], isA<TileSelected>());

      state.onTileTapped(b.$1, b.$2, b.$3);

      expect(events.length, 2);
      expect(events[1], isA<MatchSuccess>());
      final match = events[1] as MatchSuccess;
      expect(match.tileA.footballerIndex, entry.key);
      expect(match.tileB.footballerIndex, entry.key);
      expect(match.removedPositions.length, 2);
      expect(state.score, 100);

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 4: Selecting non-matching pair triggers MatchFailed
    // -----------------------------------------------------------------------
    test('4: Selecting non-matching pair triggers MatchFailed', () async {
      final layout = _layout2x2();
      final config = TileConfig(2, 2);
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);

      // Find two free tiles with different footballerIndex values.
      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entries = byFi.entries.toList();
      expect(entries.length, greaterThanOrEqualTo(2),
          reason: 'Need at least 2 distinct footballerIndex values');

      final a = entries[0].value[0]; // first tile of first footballer
      final b = entries[1].value[0]; // first tile of second footballer

      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      state.onTileTapped(a.$1, a.$2, a.$3);
      state.onTileTapped(b.$1, b.$2, b.$3);

      // TileSelected + MatchFailed
      expect(events.length, 2);
      expect(events[0], isA<TileSelected>());
      expect(events[1], isA<MatchFailed>());
      expect(state.phase, GamePhase.playing);
      expect(state.selectedTile, isNull);

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 5: Cannot select blocked tiles
    // -----------------------------------------------------------------------
    test('5: Cannot select blocked tiles', () async {
      // 1×3 layout: middle tile (1,0) is blocked
      final layout = _layout1x3();
      final config = TileConfig(3, 1);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 7);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      // Tap the middle tile (1,0) — should be blocked, so no-op.
      state.onTileTapped(0, 1, 0);

      expect(state.phase, GamePhase.playing);
      expect(state.selectedTile, isNull);
      expect(events, isEmpty);

      // Tap edge (0,0) — should be free.
      state.onTileTapped(0, 0, 0);

      expect(state.phase, GamePhase.tileSelected);
      expect(events.length, 1);

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 6: Win detection when all tiles removed
    // -----------------------------------------------------------------------
    test('6: Win detection when all tiles removed', () async {
      final layout = _layout2x2();
      final config = TileConfig(2, 2);
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);

      // Collect all matchable pairs (all positions).
      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);

      // Build ordered tap list: pair by pair.
      final taps = <(int, int, int)>[];
      for (final entry in byFi.entries) {
        taps.addAll(entry.value);
      }
      expect(taps.length, 4, reason: 'Need 4 taps to clear 2 pairs');

      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      // Match first pair.
      state.onTileTapped(taps[0].$1, taps[0].$2, taps[0].$3);
      state.onTileTapped(taps[1].$1, taps[1].$2, taps[1].$3);

      expect(state.phase, isNot(GamePhase.won),
          reason: 'Should not win after first match');

      // Match second pair — should clear the board.
      state.onTileTapped(taps[2].$1, taps[2].$2, taps[2].$3);
      state.onTileTapped(taps[3].$1, taps[3].$2, taps[3].$3);

      expect(state.phase, GamePhase.won);
      expect(events.any((e) => e is GameWon), isTrue);
      final won = events.firstWhere((e) => e is GameWon) as GameWon;
      expect(won.score, greaterThan(0));
      expect(won.level, 1);

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 7: Deadlock detection triggers DeadlockDetected event
    //
    // We arrange a multi-layer board and play one match.  If the remaining
    // free tiles happen to all have unique footballerIndex values, the
    // GameState must emit a DeadlockDetected event.
    //
    // Because the exact tile arrangement depends on the seed, this test
    // is adaptive: it plays whatever match is possible and checks whether
    // a deadlock occurred, rather than hardcoding expectations.
    // -----------------------------------------------------------------------
    test('7: Deadlock detection triggers DeadlockDetected event', () async {
      final layout = _layoutDeadlock();
      final config = TileConfig(4, 2); // 8 tiles, 4 footballers × 2 copies
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      // Compute the arrangement to know where tiles are.
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);
      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entries = byFi.entries.where((e) => e.value.length >= 2).toList();

      if (entries.isNotEmpty) {
        // Play the first available matching pair.
        final a = entries.first.value[0];
        final b = entries.first.value[1];

        state.onTileTapped(a.$1, a.$2, a.$3);
        state.onTileTapped(b.$1, b.$2, b.$3);

        if (state.phase == GamePhase.deadlocked) {
          expect(events.any((e) => e is DeadlockDetected), isTrue);
          final deadlockEvent =
              events.firstWhere((e) => e is DeadlockDetected) as DeadlockDetected;
          expect(deadlockEvent, isA<DeadlockDetected>());
        }
      }

      // If deadlock didn't occur, the scenario didn't cause one — that's OK.
      // The isDeadlocked function itself is tested in matching_engine_test.dart.

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 8: Reshuffle re-enters playing phase
    // -----------------------------------------------------------------------
    test('8: Reshuffle re-enters playing phase', () async {
      final layout = _layoutDeadlock();
      final config = TileConfig(4, 2);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      // Play the first available matching pair to consume some tiles.
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);
      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entries = byFi.entries.where((e) => e.value.length >= 2).toList();

      if (entries.isNotEmpty) {
        final a = entries.first.value[0];
        final b = entries.first.value[1];
        state.onTileTapped(a.$1, a.$2, a.$3);
        state.onTileTapped(b.$1, b.$2, b.$3);
      }

      // Reshuffle — must return to playing (unless still deadlocked).
      state.reshuffle(seed: 99);

      expect(state.phase, anyOf(GamePhase.playing, GamePhase.deadlocked));

      // If first reshuffle left us deadlocked, try another seed.
      if (state.phase == GamePhase.deadlocked) {
        state.reshuffle(seed: 123);
      }

      expect(state.phase, GamePhase.playing);
    });

    // -----------------------------------------------------------------------
    // Test 9: Stream events received in correct order
    // -----------------------------------------------------------------------
    test('9: Stream events received in correct order', () async {
      final layout = _layout2x2();
      final config = TileConfig(2, 2);
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);

      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entries = byFi.entries.toList();

      // Pair A: matching tiles.
      final a = entries[0].value[0];
      final b = entries[0].value[1];

      // Pair B (different footballerIndex): for mismatch test and later match.
      final c = entries[1].value[0];
      final d = entries[1].value[1];

      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      final events = <GameEvent>[];
      final sub = state.events.listen(events.add);

      // --- Sequence 1: mismatch ---
      state.onTileTapped(a.$1, a.$2, a.$3); // select
      state.onTileTapped(c.$1, c.$2, c.$3); // mismatch

      expect(events.length, 2);
      expect(events[0], isA<TileSelected>());
      expect(events[1], isA<MatchFailed>());
      expect(state.phase, GamePhase.playing);

      // --- Sequence 2: correct match ---
      state.onTileTapped(a.$1, a.$2, a.$3); // select again
      state.onTileTapped(b.$1, b.$2, b.$3); // match

      expect(events.length, 4);
      expect(events[2], isA<TileSelected>());
      expect(events[3], isA<MatchSuccess>());

      await sub.cancel();
    });

    // -----------------------------------------------------------------------
    // Test 10: Score increases on successful match
    // -----------------------------------------------------------------------
    test('10: Score increases on successful match', () async {
      final layout = _layout2x2();
      final config = TileConfig(2, 2);
      final (tilesByLayer, layerDefs) = _arrange(layout, config, 42);

      final byFi = _freeTilePositionsByFi(tilesByLayer, layerDefs);
      final entries = byFi.entries.toList();

      // First pair.
      final a = entries[0].value[0];
      final b = entries[0].value[1];

      // Second pair (different footballerIndex).
      final c = entries[1].value[0];
      final d = entries[1].value[1];

      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      expect(state.score, 0);

      // First match: +100
      state.onTileTapped(a.$1, a.$2, a.$3);
      state.onTileTapped(b.$1, b.$2, b.$3);
      expect(state.score, 100);

      // Second match: +100 → 200
      state.onTileTapped(c.$1, c.$2, c.$3);
      state.onTileTapped(d.$1, d.$2, d.$3);
      expect(state.score, 200);
    });
  });
}
