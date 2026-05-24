import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Scaffold with title and placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      await tester.pump();

      // Verify title
      expect(find.text('Settings'), findsOneWidget);

      // Verify placeholder content
      expect(find.text('Settings page coming soon'), findsOneWidget);
    });
  });
}
