import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footyjong/game/models/layout_definition.dart';
import 'package:footyjong/services/game_settings.dart';
import 'package:footyjong/services/persistence_service.dart';
import 'package:footyjong/screens/settings_screen.dart';

/// Helper: fully initialise PersistenceService for tests that need settings.
Future<void> _initPersistence() async {
  SharedPreferences.setMockInitialValues({});
  PersistenceService.resetForTesting();
  await PersistenceService.init();
}

Widget _buildApp(GameSettings settings) {
  return MaterialApp(
    home: SettingsScreen(settings: settings),
  );
}

void main() {
  group('SettingsScreen', () {
    late GameSettings settings;

    setUp(() async {
      await _initPersistence();
      settings = GameSettings(PersistenceService.instance);
      await settings.load();
    });

    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows sound section with toggle', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);

      // Two switches exist: sound + all-layouts. The first should be sound.
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      final soundSwitch = switches.first;
      final switchWidget = tester.widget<Switch>(soundSwitch);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggling sound updates GameSettings', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      // Tap the first Switch (sound toggle)
      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(settings.soundEnabled, isFalse);
    });

    testWidgets('shows difficulty section with three radio options',
        (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('selecting difficulty updates GameSettings', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      // Find and tap the Hard radio tile
      await tester.tap(find.widgetWithText(RadioListTile<Difficulty>, 'Hard'));
      await tester.pump();

      expect(settings.difficultySetting, Difficulty.hard);
    });

    testWidgets('shows layouts section with layouts list', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      expect(find.text('Layouts'), findsOneWidget);
      expect(find.text('All Layouts Unlocked'), findsOneWidget);
    });

    testWidgets('all layouts unlocked toggle works', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      // Initially not unlocked
      expect(settings.allLayoutsUnlocked, isFalse);

      // Tap the "All Layouts Unlocked" switch — there are two switches now
      // (sound + all layouts). Find switches by their position.
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // Tap the second switch (All Layouts Unlocked)
      await tester.tap(switches.last);
      await tester.pump();

      expect(settings.allLayoutsUnlocked, isTrue);
    });

    testWidgets('layout tiles show unlock status', (tester) async {
      await tester.pumpWidget(_buildApp(settings));
      await tester.pump();

      // The first layout name should appear (e.g. "Pyramid")
      // With unlockedLayouts empty, layouts should show lock icons
      expect(find.byIcon(Icons.lock), findsWidgets);
    });
  });
}
