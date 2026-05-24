import 'package:flutter/material.dart';

/// Placeholder settings screen — renders a Scaffold with title and placeholder
/// body. Back navigation via the AppBar leading button.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
          'Settings page coming soon',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
    );
  }
}
