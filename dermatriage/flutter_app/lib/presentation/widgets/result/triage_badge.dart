import 'package:flutter/material.dart';

import '../../../core/constants/triage_levels.dart';
import '../../../l10n/app_localizations.dart';

/// Prominent coloured badge communicating the triage outcome.
class TriageBadge extends StatelessWidget {
  final TriageLevel level;

  const TriageBadge({super.key, required this.level});

  IconData get _icon {
    switch (level) {
      case TriageLevel.urgentReferral:
        return Icons.warning_amber_rounded;
      case TriageLevel.monitor:
        return Icons.remove_red_eye_outlined;
      case TriageLevel.treatLocally:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: level.color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(_icon, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              AppLocalizations.of(context).triageLabel(level.id).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
