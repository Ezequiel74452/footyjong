import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:footyjong/game/models/layout_definition.dart';
import 'package:footyjong/services/persistence_service.dart';

/// Reactive game settings backed by [PersistenceService].
///
/// Every setter persists the new value immediately and calls [notifyListeners]
/// so that UI widgets using [ListenableBuilder] react to changes.
///
/// Usage:
/// ```dart
/// final settings = GameSettings(persistence);
/// await settings.load();
/// settings.soundEnabled = false; // persists + notifies
/// ```
class GameSettings extends ChangeNotifier {
  final PersistenceService _persistence;

  bool _soundEnabled = true;
  Difficulty _difficultySetting = Difficulty.medium;
  List<String> _unlockedLayouts = [];

  GameSettings(this._persistence);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get soundEnabled => _soundEnabled;
  Difficulty get difficultySetting => _difficultySetting;
  List<String> get unlockedLayouts => List.unmodifiable(_unlockedLayouts);

  bool get allLayoutsUnlocked => _unlockedLayouts.contains('__all__');

  // ---------------------------------------------------------------------------
  // Setters (persist + notify)
  // ---------------------------------------------------------------------------

  set soundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    _persist().then((_) => notifyListeners());
  }

  set difficultySetting(Difficulty value) {
    if (_difficultySetting == value) return;
    _difficultySetting = value;
    _persist().then((_) => notifyListeners());
  }

  /// Replaces the unlocked layouts list.
  ///
  /// A special value `"__all__"` is interpreted as "all layouts unlocked"
  /// by the UI. Pass an empty list to reset.
  set unlockedLayouts(List<String> value) {
    _unlockedLayouts = List.of(value);
    _persist().then((_) => notifyListeners());
  }

  /// Unlocks all available layouts by writing `["__all__"]`.
  void unlockAllLayouts() {
    _unlockedLayouts = ['__all__'];
    _persist().then((_) => notifyListeners());
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Hydrates all settings from [PersistenceService].
  ///
  /// Call once before first use (e.g. in main.dart after [PersistenceService.init]).
  Future<void> load() async {
    _soundEnabled =
        await _persistence.getBool(PersistenceKeys.soundEnabled, defaultValue: true);
    final diffIndex =
        await _persistence.getInt(PersistenceKeys.difficulty, defaultValue: 1);
    _difficultySetting = Difficulty.values[
        diffIndex.clamp(0, Difficulty.values.length - 1)];
    final raw = await _persistence.getString(PersistenceKeys.unlockedLayouts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _unlockedLayouts = decoded.map((e) => e as String).toList();
      } catch (_) {
        _unlockedLayouts = [];
      }
    } else {
      _unlockedLayouts = [];
    }
    // No notifyListeners — caller should call after load if needed.
  }

  /// Persists all current settings immediately.
  Future<void> save() async {
    await _persist();
  }

  Future<void> _persist() async {
    await _persistence.setBool(PersistenceKeys.soundEnabled, _soundEnabled);
    await _persistence.setInt(
        PersistenceKeys.difficulty, _difficultySetting.index);
    await _persistence.setString(
        PersistenceKeys.unlockedLayouts, jsonEncode(_unlockedLayouts));
  }
}
