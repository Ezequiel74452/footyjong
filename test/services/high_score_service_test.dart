import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/services/high_score_service.dart';
import 'package:footyjong/services/persistence_service.dart';

/// In-memory fake for [PersistenceService] used in [HighScoreService] tests.
class FakePersistenceService {
  final _store = <String, String>{};

  Future<String?> getString(String key) async => _store[key];
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  // Only required by the real PersistenceKeys.highScore helper — unused.
  Future<void> remove(String key) async => _store.remove(key);
  Future<void> setMockInitialValues(Map<String, String> values) async {
    _store.addAll(values);
  }
}

/// Adapts [FakePersistenceService] to the real [PersistenceService] interface
/// so [HighScoreService] can use it without changing its constructor.
class FakePersistenceAdapter extends PersistenceService {
  final FakePersistenceService _fake;

  FakePersistenceAdapter(this._fake) : super.testing();

  @override
  Future<String?> getString(String key) => _fake.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _fake.setString(key, value);
}

PersistenceService _makeFake() => FakePersistenceAdapter(FakePersistenceService());

Future<void> _addTestScore(HighScoreService svc, int difficultyIndex,
    {int score = 100, int level = 1, int secs = 0}) async {
  await svc.saveHighScore(
    difficultyIndex: difficultyIndex,
    score: score,
    level: level,
    elapsedSeconds: secs,
  );
}

void main() {
  group('HighScoreService', () {
    group('save and load', () {
      test('saves and loads a single score', () async {
        final svc = HighScoreService(_makeFake());

        await svc.saveHighScore(
          difficultyIndex: 0,
          score: 500,
          level: 3,
          elapsedSeconds: 120,
        );

        final scores = await svc.getHighScores(difficultyIndex: 0);
        expect(scores.length, 1);
        expect(scores.first.score, 500);
        expect(scores.first.level, 3);
        expect(scores.first.elapsedSeconds, 120);
      });

      test('returns empty list when no scores exist', () async {
        final svc = HighScoreService(_makeFake());

        final scores = await svc.getHighScores(difficultyIndex: 1);
        expect(scores, isEmpty);
      });
    });

    group('sorting and limit', () {
      test('returns scores sorted descending', () async {
        final svc = HighScoreService(_makeFake());
        await _addTestScore(svc, 0, score: 100);
        await _addTestScore(svc, 0, score: 300);
        await _addTestScore(svc, 0, score: 200);

        final scores = await svc.getHighScores(difficultyIndex: 0);
        expect(scores.map((e) => e.score), [300, 200, 100]);
      });

      test('limits to defaultMaxEntries (10)', () async {
        final svc = HighScoreService(_makeFake());
        for (int i = 1; i <= 15; i++) {
          await _addTestScore(svc, 0, score: i);
        }

        final scores = await svc.getHighScores(difficultyIndex: 0);
        expect(scores.length, HighScoreService.defaultMaxEntries);
        expect(scores.first.score, 15);
        expect(scores.last.score, 6); // 15..6 = 10 entries
      });

      test('getHighScores respects custom limit', () async {
        final svc = HighScoreService(_makeFake());
        for (int i = 1; i <= 5; i++) {
          await _addTestScore(svc, 2, score: i * 100);
        }

        final scores =
            await svc.getHighScores(difficultyIndex: 2, limit: 3);
        expect(scores.length, 3);
        expect(scores.first.score, 500);
        expect(scores.last.score, 300);
      });
    });

    group('per-difficulty isolation', () {
      test('scores for different difficulties are independent', () async {
        final svc = HighScoreService(_makeFake());
        await _addTestScore(svc, 0, score: 900);
        await _addTestScore(svc, 1, score: 100);
        await _addTestScore(svc, 2, score: 500);

        final easy = await svc.getHighScores(difficultyIndex: 0);
        final medium = await svc.getHighScores(difficultyIndex: 1);
        final hard = await svc.getHighScores(difficultyIndex: 2);

        expect(easy.length, 1);
        expect(easy.first.score, 900);
        expect(medium.length, 1);
        expect(medium.first.score, 100);
        expect(hard.length, 1);
        expect(hard.first.score, 500);
      });
    });

    group('corrupted data resilience', () {
      test('corrupted JSON returns empty list', () async {
        final fake = FakePersistenceService();
        final adapter = FakePersistenceAdapter(fake);
        final svc = HighScoreService(adapter);

        // Write corrupted data directly to the fake store
        await fake.setString('highscore_0', 'not-json');

        final scores = await svc.getHighScores(difficultyIndex: 0);
        expect(scores, isEmpty);
      });
    });
  });
}
