import 'dart:convert';
import 'package:footyjong/services/persistence_service.dart';

/// A single persisted score entry.
class ScoreEntry {
  final int score;
  final int level;
  final int elapsedSeconds;
  final DateTime? timestamp;

  const ScoreEntry({
    required this.score,
    required this.level,
    required this.elapsedSeconds,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'elapsedSeconds': elapsedSeconds,
        'timestamp':
            (timestamp ?? DateTime.now()).toIso8601String(),
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
        score: json['score'] as int,
        level: json['level'] as int,
        elapsedSeconds: json['elapsedSeconds'] as int,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );
}

/// Persists and retrieves high scores per difficulty using [PersistenceService].
///
/// Scores are stored as a JSON-encoded list under keys like `highscore_0` for
/// Easy, `highscore_1` for Medium, etc. The list is kept sorted descending by
/// score and truncated to [defaultMaxEntries].
class HighScoreService {
  final PersistenceService _persistence;

  /// Maximum number of score entries stored per difficulty.
  static const int defaultMaxEntries = 10;

  HighScoreService(this._persistence);

  /// Returns the storage key for a given difficulty index.
  String _key(int difficultyIndex) =>
      PersistenceKeys.highScore(difficultyIndex: difficultyIndex);

  /// Saves [entry] under [difficultyIndex] and persists back.
  ///
  /// The leaderboard is re-sorted and truncated to [defaultMaxEntries].
  Future<void> saveHighScore({
    required int difficultyIndex,
    required int score,
    required int level,
    required int elapsedSeconds,
  }) async {
    final entry = ScoreEntry(
      score: score,
      level: level,
      elapsedSeconds: elapsedSeconds,
    );
    final entries = await _loadEntries(difficultyIndex);
    entries.add(entry);
    entries.sort((a, b) => b.score.compareTo(a.score));
    if (entries.length > defaultMaxEntries) {
      entries.removeRange(defaultMaxEntries, entries.length);
    }
    await _saveEntries(difficultyIndex, entries);
  }

  /// Returns the top [limit] high scores for [difficultyIndex].
  ///
  /// Returns an empty list if no scores have been saved for this difficulty.
  Future<List<ScoreEntry>> getHighScores({
    required int difficultyIndex,
    int limit = defaultMaxEntries,
  }) async {
    final entries = await _loadEntries(difficultyIndex);
    entries.sort((a, b) => b.score.compareTo(a.score));
    if (entries.length > limit) {
      entries.removeRange(limit, entries.length);
    }
    return entries;
  }

  Future<List<ScoreEntry>> _loadEntries(int difficultyIndex) async {
    final raw = await _persistence.getString(_key(difficultyIndex));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveEntries(
      int difficultyIndex, List<ScoreEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _persistence.setString(_key(difficultyIndex), encoded);
  }
}
