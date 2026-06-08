import 'package:flutter/material.dart';

/// Centralised colour palette for DermaTriage.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00695C); // deep teal
  static const Color primaryDark = Color(0xFF003D33);
  static const Color primaryLight = Color(0xFF439889);
  static const Color accent = Color(0xFFFF8F00);

  // Triage levels
  static const Color urgent = Color(0xFFD32F2F); // red
  static const Color urgentLight = Color(0xFFFFCDD2);
  static const Color monitor = Color(0xFFF57C00); // orange
  static const Color monitorLight = Color(0xFFFFE0B2);
  static const Color treatLocally = Color(0xFF388E3C); // green
  static const Color treatLocallyLight = Color(0xFFC8E6C9);

  // Surfaces & text
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  /// Representative skin-tone colours for Fitzpatrick types I–VI.
  static const List<Color> fitzpatrickColors = <Color>[
    Color(0xFFF6D5C2), // I
    Color(0xFFEFC09A), // II
    Color(0xFFE2A875), // III
    Color(0xFFC68642), // IV
    Color(0xFF8D5524), // V
    Color(0xFF4B2E1E), // VI
  ];
}
