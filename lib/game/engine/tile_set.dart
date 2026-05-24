import 'package:footyjong/game/models/tile_data.dart';
import 'package:footyjong/game/models/tile_config.dart';

class TileSet {
  static List<TileData> generateTiles(TileConfig config) {
    final tiles = <TileData>[];
    int id = 0;
    for (int fi = 0; fi < config.numFootballers; fi++) {
      for (int ci = 0; ci < config.copiesPerFootballer; ci++) {
        tiles.add(TileData(
          id: id,
          footballerIndex: fi,
          copyIndex: ci,
        ));
        id++;
      }
    }
    return tiles;
  }
}
