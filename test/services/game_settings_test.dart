import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footyjong/game/models/layout_definition.dart';
import 'package:footyjong/services/game_settings.dart';
import 'package:footyjong/services/persistence_service.dart';

/// Helper: fully initialise the test environment including SharedPreferences
/// mock so PersistenceService.init() can succeed.
Future<void> _initPersistence(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  PersistenceService.resetForTesting();
  await PersistenceService.init();
}

PersistenceService get _ps => PersistenceService.instance;

void main() {
  group('GameSettings', () {
    setUp(() async {
      await _initPersistence({});
    });

    group('default state after load with empty store', () {
      test('soundEnabled defaults to true', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.soundEnabled, isTrue);
      });

      test('difficultySetting defaults to medium', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.difficultySetting, Difficulty.medium);
      });

      test('unlockedLayouts defaults to empty', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.unlockedLayouts, isEmpty);
      });
    });

    group('load hydrates from persisted values', () {
      test('load restores soundEnabled false', () async {
        await _initPersistence({PersistenceKeys.soundEnabled: false});

        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.soundEnabled, isFalse);
      });

      test('load restores difficultySetting from index', () async {
        // Difficulty.hard.index == 2
        await _initPersistence({PersistenceKeys.difficulty: 2});

        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.difficultySetting, Difficulty.hard);
      });

      test('load restores unlockedLayouts from JSON list', () async {
        await _initPersistence({
          PersistenceKeys.unlockedLayouts:
              jsonEncode(['butterfly', 'diamond'])
        });

        final settings = GameSettings(_ps);
        await settings.load();

        expect(settings.unlockedLayouts, containsAll(['butterfly', 'diamond']));
      });
    });

    group('setters mutate, persist, and notify', () {
      test('setting soundEnabled notifies listeners', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.soundEnabled = false;

        // Allow async persist to complete
        await Future(() {});

        expect(notifyCount, greaterThanOrEqualTo(1));
        expect(settings.soundEnabled, isFalse);
      });

      test('soundEnabled persists across re-load', () async {
        var settings = GameSettings(_ps);
        await settings.load();
        settings.soundEnabled = false;
        await settings.save(); // ensure persistence is flushed

        // Re-load from the same PersistenceService (simulates restart)
        settings = GameSettings(_ps);
        await settings.load();

        expect(settings.soundEnabled, isFalse);
      });

      test('difficultySetting notifies listeners', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.difficultySetting = Difficulty.hard;

        await Future(() {});
        expect(notifyCount, greaterThanOrEqualTo(1));
        expect(settings.difficultySetting, Difficulty.hard);
      });

      test('difficulty persists across re-load', () async {
        var settings = GameSettings(_ps);
        await settings.load();
        settings.difficultySetting = Difficulty.easy;
        await settings.save();

        settings = GameSettings(_ps);
        await settings.load();

        expect(settings.difficultySetting, Difficulty.easy);
      });

      test('unlockedLayouts notifies listeners', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.unlockedLayouts = ['custom'];

        await Future(() {});
        expect(notifyCount, greaterThanOrEqualTo(1));
        expect(settings.unlockedLayouts, ['custom']);
      });
    });

    group('unlockAllLayouts', () {
      test('unlockAllLayouts sets __all__ and notifies', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.unlockAllLayouts();

        await Future(() {});
        expect(notifyCount, greaterThanOrEqualTo(1));
        expect(settings.allLayoutsUnlocked, isTrue);
        expect(settings.unlockedLayouts, ['__all__']);
      });
    });

    group('setting same value does NOT notify', () {
      test('setting same sound value does not notify', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.soundEnabled = true; // already true

        await Future(() {});
        expect(notifyCount, 0);
      });

      test('setting same difficulty does not notify', () async {
        final settings = GameSettings(_ps);
        await settings.load();

        int notifyCount = 0;
        settings.addListener(() => notifyCount++);

        settings.difficultySetting = Difficulty.medium; // already medium

        await Future(() {});
        expect(notifyCount, 0);
      });
    });
  });
}
