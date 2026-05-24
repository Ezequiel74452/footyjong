import 'package:footyjong/game/models/models.dart';

/// 17 static factory constructors — one per board layout.
///
/// Each getter returns a [LayoutDefinition] with the correct number of layers,
/// position count matching one of the [TileConfig] totals (72, 100, or 144),
/// and an appropriate [Difficulty] rating.
class BoardLayout {
  BoardLayout._(); // prevent instantiation

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parse an ASCII grid into a [LayerDefinition].
  /// Use `.` for empty and `X` for occupied. All rows must be same length.
  static LayerDefinition _parse(List<String> ascii) {
    final rows = ascii.length;
    final cols = ascii[0].length;
    final occupied = <List<bool>>[];
    for (final line in ascii) {
      final row = <bool>[];
      for (var c = 0; c < line.length; c++) {
        row.add(line[c] != '.');
      }
      occupied.add(row);
    }
    return LayerDefinition(rows: rows, cols: cols, occupied: occupied);
  }

  /// Fully-filled [rows] × [cols] layer.
  static LayerDefinition _filled(int rows, int cols) {
    final occupied = List.generate(
      rows,
      (_) => List.generate(cols, (_) => true),
    );
    return LayerDefinition(rows: rows, cols: cols, occupied: occupied);
  }

  /// Ring / border with thickness [b] (default 1).
  static LayerDefinition _ring(int rows, int cols, {int b = 1}) {
    final g = List.generate(rows, (_) => List.generate(cols, (_) => false));
    for (var c = 0; c < cols; c++) {
      for (var i = 0; i < b && i < rows; i++) {
        g[i][c] = true;
        g[rows - 1 - i][c] = true;
      }
    }
    for (var r = b; r < rows - b; r++) {
      for (var i = 0; i < b && i < cols; i++) {
        g[r][i] = true;
        g[r][cols - 1 - i] = true;
      }
    }
    return LayerDefinition(rows: rows, cols: cols, occupied: g);
  }

  /// Cross / plus shape (arms meet at centre) on an N×N grid with arm width [w].
  static LayerDefinition _cross(int n, int w) {
    final g = List.generate(n, (_) => List.generate(n, (_) => false));
    final s = (n - w) ~/ 2;
    for (var r = s; r < s + w; r++) {
      for (var c = 0; c < n; c++) g[r][c] = true;
    }
    for (var c = s; c < s + w; c++) {
      for (var r = 0; r < n; r++) g[r][c] = true;
    }
    return LayerDefinition(rows: n, cols: n, occupied: g);
  }

  /// Four corner blocks of size [br] × [bc].
  static LayerDefinition _corners(int rows, int cols,
      {required int br, required int bc}) {
    final g = List.generate(rows, (_) => List.generate(cols, (_) => false));
    for (var r = 0; r < br && r < rows; r++) {
      for (var c = 0; c < bc && c < cols; c++) g[r][c] = true;
      for (var c = cols - bc; c < cols && c >= 0; c++) g[r][c] = true;
    }
    for (var r = rows - br; r < rows && r >= 0; r++) {
      for (var c = 0; c < bc && c < cols; c++) g[r][c] = true;
      for (var c = cols - bc; c < cols && c >= 0; c++) g[r][c] = true;
    }
    return LayerDefinition(rows: rows, cols: cols, occupied: g);
  }

  // ---------------------------------------------------------------------------
  // 1. Pyramid  (easy, 144 positions, 5 layers)
  //    64 + 36 + 16 + 16 + 12 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get pyramid {
    return LayoutDefinition(
      name: 'Pyramid',
      difficulty: Difficulty.easy,
      layers: [
        _corners(12, 12, br: 4, bc: 4), // 64
        _corners(10, 10, br: 3, bc: 3), // 36
        _corners(8, 8, br: 2, bc: 2), // 16
        _corners(6, 6, br: 2, bc: 2), // 16
        _ring(4, 4, b: 1), // 12
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Flat Diamond  (easy, 144 positions, 1 layer)
  //    filled 12×12 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get flatDiamond {
    return LayoutDefinition(
      name: 'Flat Diamond',
      difficulty: Difficulty.easy,
      layers: [_filled(12, 12)],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Cross  (easy, 100 positions, 1 layer)
  //    filled 10×10 = 100
  // ---------------------------------------------------------------------------
  static LayoutDefinition get cross {
    return LayoutDefinition(
      name: 'Cross',
      difficulty: Difficulty.easy,
      layers: [_filled(10, 10)],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Hexagon  (easy, 72 positions, 1 layer)
  //    6 + 8 + 10 + 12 + 12 + 10 + 8 + 6 = 72
  // ---------------------------------------------------------------------------
  static LayoutDefinition get hexagon {
    return LayoutDefinition(
      name: 'Hexagon',
      difficulty: Difficulty.easy,
      layers: [
        _parse([
          '...XXXXXX...', //  6
          '..XXXXXXXX..', //  8
          '.XXXXXXXXXX.', // 10
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          '.XXXXXXXXXX.', // 10
          '..XXXXXXXX..', //  8
          '...XXXXXX...', //  6
        ]),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Butterfly  (medium, 72 positions, 1 layer)
  //    filled 12×6 = 72
  // ---------------------------------------------------------------------------
  static LayoutDefinition get butterfly {
    return LayoutDefinition(
      name: 'Butterfly',
      difficulty: Difficulty.medium,
      layers: [_filled(12, 6)],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Windmill  (medium, 144 positions, 2 layers)
  //    108 + 36 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get windmill {
    return LayoutDefinition(
      name: 'Windmill',
      difficulty: Difficulty.medium,
      layers: [
        _cross(12, 6), // 108  — four windmill blades
        _filled(6, 6), // 36   — centre hub
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Castle  (medium, 144 positions, 2 layers)
  //    80 + 64 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get castle {
    return LayoutDefinition(
      name: 'Castle',
      difficulty: Difficulty.medium,
      layers: [
        _ring(12, 12, b: 2), // 80  — outer walls
        _filled(8, 8), // 64        — inner keep
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Diamond Ring  (medium, 144 positions, 2 layers)
  //    80 + 64 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get diamondRing {
    return LayoutDefinition(
      name: 'Diamond Ring',
      difficulty: Difficulty.medium,
      layers: [
        _ring(12, 12, b: 2), // 80  — outer diamond ring
        _filled(8, 8), // 64        — inner diamond fill
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Hourglass  (medium, 144 positions, 3 layers)
  //    80 + 48 + 16 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get hourglass {
    return LayoutDefinition(
      name: 'Hourglass',
      difficulty: Difficulty.medium,
      layers: [
        _ring(12, 12, b: 2), // 80  — bottom bell
        _ring(8, 8, b: 2), // 48    — narrow waist
        _filled(4, 4), // 16        — top bell
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Twin Peaks  (medium, 144 positions, 2 layers)
  //     120 + 24 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get twinPeaks {
    return LayoutDefinition(
      name: 'Twin Peaks',
      difficulty: Difficulty.medium,
      layers: [
        // Layer 0 (12×12): two 5×12 rectangles separated by a 2-column gap
        _parse([
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
          'XXXXX..XXXXX',
        ]), // 120
        // Layer 1 (6×6): smaller peaks at centre — 4 corner blocks of 2×3 = 24
        _corners(6, 6, br: 2, bc: 3), // 24
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Spiral  (medium, 144 positions, 2 layers)
  //     108 + 36 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get spiral {
    return LayoutDefinition(
      name: 'Spiral',
      difficulty: Difficulty.medium,
      layers: [
        // Layer 0 (12×12): clipped-corner spiral — 108
        _parse([
          '...XXXXXX...', //  6
          '...XXXXXX...', //  6
          '...XXXXXX...', //  6
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          '...XXXXXX...', //  6
          '...XXXXXX...', //  6
          '...XXXXXX...', //  6
        ]),
        // Layer 1 (8×8): inner spiral rectangle
        _parse([
          '........',
          '.XXXXXX.',
          '.XXXXXX.',
          '.XXXXXX.',
          '.XXXXXX.',
          '.XXXXXX.',
          '.XXXXXX.',
          '........',
        ]), // 36
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 12. Bridge  (medium, 100 positions, 2 layers)
  //     50 + 50 = 100
  // ---------------------------------------------------------------------------
  static LayoutDefinition get bridge {
    return LayoutDefinition(
      name: 'Bridge',
      difficulty: Difficulty.medium,
      layers: [
        // Layer 0 (10×10): two 5×5 rectangles with gap
        _parse([
          'XXXXX.....',
          'XXXXX.....',
          'XXXXX.....',
          'XXXXX.....',
          'XXXXX.....',
          '.....XXXXX',
          '.....XXXXX',
          '.....XXXXX',
          '.....XXXXX',
          '.....XXXXX',
        ]), // 50
        // Layer 1 (10×10): horizontal bridge bar connecting the two halves
        _parse([
          '..........',
          '..........',
          '..........',
          '..........',
          'XXXXXXXXXX',
          'XXXXXXXXXX',
          'XXXXXXXXXX',
          'XXXXXXXXXX',
          'XXXXXXXXXX',
          '..........',
        ]), // 50
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 13. Star  (hard, 144 positions, 4 layers)
  //     80 + 36 + 24 + 4 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get star {
    return LayoutDefinition(
      name: 'Star',
      difficulty: Difficulty.hard,
      layers: [
        // Layer 0 (12×12): thick cross / star = 80
        _cross(12, 4),
        // Layer 1 (10×10): medium cross = 36
        _cross(10, 2),
        // Layer 2 (6×6): centred ring = 24
        _parse([
          '.XXXX.',
          '.XXXX.',
          '.XXXX.',
          '.XXXX.',
          '.XXXX.',
          '.XXXX.',
        ]), // 24
        // Layer 3 (2×2): tiny centre = 4
        _filled(2, 2),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 14. Dragon  (hard, 144 positions, 2 layers)
  //     80 + 64 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get dragon {
    return LayoutDefinition(
      name: 'Dragon',
      difficulty: Difficulty.hard,
      layers: [
        // Layer 0 (12×12): thick winding body (outer ring)
        _ring(12, 12, b: 2), // 80
        // Layer 1 (8×8): inner body segment
        _filled(8, 8), // 64
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 15. Cobra  (hard, 144 positions, 3 layers)
  //     72 + 56 + 16 = 144
  // ---------------------------------------------------------------------------
  static LayoutDefinition get cobra {
    return LayoutDefinition(
      name: 'Cobra',
      difficulty: Difficulty.hard,
      layers: [
        // Layer 0 (12×12): thick snake — tail, body, head = 72
        _parse([
          'XXXX........', //  4
          'XXXX........', //  4
          'XXXX........', //  4
          'XXXX........', //  4
          'XXXX........', //  4
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          'XXXXXXXXXXXX', // 12
          '........XXXX', //  4
          '........XXXX', //  4
          '........XXXX', //  4
          '........XXXX', //  4
        ]),
        // Layer 1 (8×7): inner snake body = 56
        _filled(8, 7),
        // Layer 2 (4×4): tiny head = 16
        _filled(4, 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 16. Volcano  (hard, 72 positions, 4 layers)
  //     28 + 20 + 12 + 12 = 72
  // ---------------------------------------------------------------------------
  static LayoutDefinition get volcano {
    return LayoutDefinition(
      name: 'Volcano',
      difficulty: Difficulty.hard,
      layers: [
        // Layer 0 (8×8): wide base ring = 28
        _parse([
          'XXXXXXXX',
          'X......X',
          'X......X',
          'X......X',
          'X......X',
          'X......X',
          'X......X',
          'XXXXXXXX',
        ]),
        // Layer 1 (6×6): rim = 20
        _ring(6, 6, b: 1),
        // Layer 2 (4×4): inner crater ring = 12
        _parse([
          'XXXX',
          'X..X',
          'X..X',
          'XXXX',
        ]),
        // Layer 3 (2×6): very top = 12
        _filled(2, 6),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 17. Labyrinth  (hard, 100 positions, 2 layers)
  //     56 + 44 = 100
  // ---------------------------------------------------------------------------
  static LayoutDefinition get labyrinth {
    return LayoutDefinition(
      name: 'Labyrinth',
      difficulty: Difficulty.hard,
      layers: [
        // Layer 0 (10×10): maze-like alternating pattern = 56
        _parse([
          'XXXXXXXXXX',
          'X........X',
          'X.XXX.XXX.',
          'X.XX..X.X.',
          'X.X.XXXX.X',
          'X.XX..XXX.',
          'X.XXX.XXX.',
          'X......XX.',
          'XXXXXXXX.X',
          '..........',
        ]),
        // Layer 1 (10×5): smaller maze bridge = 44
        _parse([
          'XXXXXXXXXX',
          'XXXXXXXXXX',
          'XXX....XXX',
          'XXXX..XXXX',
          'XXXXXXXXXX',
        ]),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Registry
  // ---------------------------------------------------------------------------
  static List<LayoutDefinition> get all => [
        pyramid,
        flatDiamond,
        cross,
        hexagon,
        butterfly,
        windmill,
        castle,
        diamondRing,
        hourglass,
        twinPeaks,
        spiral,
        bridge,
        star,
        dragon,
        cobra,
        volcano,
        labyrinth,
      ];
}
