import 'package:flutter/material.dart';

class GameConstants {
  GameConstants._(); // prevent instantiation

  // Tile dimensions
  static const double tileSize = 48.0;
  static const double tileStep = 50.0;
  static const double tileGap = 2.0;
  static const double tileCornerRadius = 6.0;

  // Layer stagger for 3D perspective
  static const double staggerX = 25.0;
  static const double staggerY = 17.5;

  // Viewport
  static const double viewportWidth = 800.0;
  static const double viewportHeight = 600.0;
  static const Color viewportBackground = Color(0xFF1a1a2e);
  static const Color boardBackground = Color(0xFF16213e);

  // Animation durations (seconds)
  static const double entranceDuration = 0.3;
  static const double entranceStagger = 0.008;
  static const double entranceDrop = 200.0;
  static const double selectScaleUp = 1.08;
  static const double selectDuration = 0.1;
  static const double matchScalePeak = 1.15;
  static const double matchDuration = 0.4;
  static const double failDuration = 0.24;
  static const double failShakeOffset = 4.0;
  static const double victoryDuration = 0.2;
  static const double victoryStagger = 0.015;
  static const double victoryScalePeak = 1.2;

  // Tile visual
  static const double selectedBorderWidth = 3.0;
  static const Color selectedBorderColor = Colors.white;
  static const Color tileTextColor = Colors.white;
  static const double tileTextSize = 18.0;
  static const double backDarkenFactor = 0.4;

  // 36 placeholder colors — football jersey inspired
  // Groups: reds, blues, greens, yellows/oranges, purples, neutrals
  static const List<Color> footballerColors = [
    // Reds (0-5)
    Color(0xFFE53935),
    Color(0xFFEF5350),
    Color(0xFFFF5252),
    Color(0xFFD32F2F),
    Color(0xFFC62828),
    Color(0xFFFF8A80),
    // Blues (6-11)
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
    Color(0xFF42A5F5),
    Color(0xFF0D47A1),
    Color(0xFF1976D2),
    Color(0xFF64B5F6),
    // Greens (12-17)
    Color(0xFF2E7D32),
    Color(0xFF43A047),
    Color(0xFF66BB6A),
    Color(0xFF1B5E20),
    Color(0xFF388E3C),
    Color(0xFF81C784),
    // Yellows/Oranges (18-23)
    Color(0xFFF57F17),
    Color(0xFFFFB300),
    Color(0xFFFFCA28),
    Color(0xFFE65100),
    Color(0xFFFF6F00),
    Color(0xFFFFD54F),
    // Purples (24-29)
    Color(0xFF6A1B9A),
    Color(0xFF8E24AA),
    Color(0xFFAB47BC),
    Color(0xFF4A148C),
    Color(0xFF7B1FA2),
    Color(0xFFCE93D8),
    // Neutrals (30-35)
    Color(0xFF424242),
    Color(0xFF616161),
    Color(0xFF757575),
    Color(0xFF9E9E9E),
    Color(0xFFBDBDBD),
    Color(0xFF212121),
  ];
}
