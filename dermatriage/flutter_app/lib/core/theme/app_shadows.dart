import 'package:flutter/material.dart';

/// Shared elevation, radius and spacing tokens.
///
/// The visual language is "soft elevation": surfaces lift off the background
/// with a wide, low-opacity shadow rather than being outlined with a hard
/// border. Using tokens instead of ad-hoc values keeps every card, sheet and
/// button reading as one system.
class AppShadows {
  AppShadows._();

  /// Resting elevation for cards and list tiles.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D000000), // 5% black — the soft, wide ambient layer
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x08000000), // 3% black — tight contact shadow
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Raised elevation for the primary call to action.
  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Coloured glow beneath a brand-filled surface, so the primary action reads
  /// as the most elevated thing on the screen.
  static List<BoxShadow> brand(Color color) => <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Shadow cast upward by the bottom navigation bar.
  static const List<BoxShadow> bottomBar = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, -2),
    ),
  ];
}

/// Corner radius tokens.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

/// Spacing scale (4pt grid).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
