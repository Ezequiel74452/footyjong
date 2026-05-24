import 'package:flutter/material.dart';
import 'package:footyjong/screens/game_screen.dart';

void main() {
  runApp(const FootyJongApp());
}

class FootyJongApp extends StatelessWidget {
  const FootyJongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FootyJong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: GameScreen(),
    );
  }
}
