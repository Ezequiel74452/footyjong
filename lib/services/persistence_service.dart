import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central key constants for all persisted values.
///
/// Grouped by domain: settings keys and high-score keys share a common prefix
/// so future migrations can enumerate relevant entries.
class PersistenceKeys {
  PersistenceKeys._();

  // Settings
  static const String soundEnabled = 'settings_sound_enabled';
  static const String difficulty = 'settings_difficulty';
  static const String unlockedLayouts = 'settings_unlocked_layouts';

  // High scores
  static String highScore({required int difficultyIndex}) =>
      'highscore_${difficultyIndex}';
}

/// Singleton wrapper around [SharedPreferences] providing typed getters,
/// setters, and safe initialisation.
///
/// Usage:
/// ```dart
/// final svc = await PersistenceService.init();
/// await svc.setBool('my_key', true);
/// final value = await svc.getBool('my_key', defaultValue: false);
/// ```
class PersistenceService {
  PersistenceService._();

  static PersistenceService? _instance;

  /// The global singleton instance. Throws if [init] has not completed
  /// successfully.
  static PersistenceService get instance {
    if (_instance == null) {
      throw StateError(
        'PersistenceService not initialised — call PersistenceService.init() '
        'before accessing instance.',
      );
    }
    return _instance!;
  }

  SharedPreferences? _prefs;

  /// Whether initialisation succeeded. While `false` all getters return
  /// their default values and setters are no-ops.
  bool get isReady => _prefs != null;

  /// Initialises the singleton instance.
  ///
  /// If SharedPreferences throws (e.g. platform not supported), the service
  /// enters a degraded mode — reads return defaults and writes are silently
  /// dropped. The app continues without crashing.
  static Future<PersistenceService> init() async {
    if (_instance != null) return _instance!;

    final svc = PersistenceService._();
    try {
      svc._prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Degraded mode — _prefs stays null.
    }

    _instance = svc;
    return svc;
  }

  // ---------------------------------------------------------------------------
  // Typed getters
  // ---------------------------------------------------------------------------

  Future<String?> getString(String key) async {
    if (!isReady) return null;
    return _prefs!.getString(key);
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    if (!isReady) return defaultValue;
    return _prefs!.getInt(key) ?? defaultValue;
  }

  Future<bool> getBool(String key, {bool defaultValue = true}) async {
    if (!isReady) return defaultValue;
    return _prefs!.getBool(key) ?? defaultValue;
  }

  Future<List<String>> getStringList(String key) async {
    if (!isReady) return [];
    return _prefs!.getStringList(key) ?? [];
  }

  // ---------------------------------------------------------------------------
  // Typed setters
  // ---------------------------------------------------------------------------

  Future<void> setString(String key, String value) async {
    if (!isReady) return;
    await _prefs!.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    if (!isReady) return;
    await _prefs!.setInt(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    if (!isReady) return;
    await _prefs!.setBool(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    if (!isReady) return;
    await _prefs!.setStringList(key, value);
  }

  /// Removes a single key from storage.
  Future<void> remove(String key) async {
    if (!isReady) return;
    await _prefs!.remove(key);
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the singleton for test isolation.
  /// Only intended for use in test setUp.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }
}
