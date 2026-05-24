import 'package:footyjong/game/models/layer_definition.dart';
import 'package:footyjong/game/models/tile_config.dart';

enum Difficulty { easy, medium, hard }

class LayoutDefinition {
  final String name;
  final List<LayerDefinition> layers;
  final Difficulty difficulty;

  int get totalPositions => layers.fold(0, (sum, l) => sum + l.positionCount);

  bool isCompatibleWith(TileConfig config) => totalPositions == config.totalTiles;

  const LayoutDefinition({
    required this.name,
    required this.layers,
    required this.difficulty,
  });
}
