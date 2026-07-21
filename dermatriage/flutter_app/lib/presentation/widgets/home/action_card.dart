import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/colors.dart';

/// A tappable action card: leading icon, label and chevron on a lifted surface.
///
/// Two variants share one layout so the primary and secondary actions read as
/// the same component at different weights:
/// [ActionCard.primary] is brand-filled with a coloured glow;
/// [ActionCard.secondary] is a white surface with a tinted icon.
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const ActionCard._({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  /// The screen's main call to action.
  factory ActionCard.primary({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ActionCard._(icon: icon, label: label, onTap: onTap, filled: true);

  /// A supporting action, visually subordinate to the primary.
  factory ActionCard.secondary({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ActionCard._(icon: icon, label: label, onTap: onTap, filled: false);

  @override
  Widget build(BuildContext context) {
    final Color foreground = filled ? Colors.white : AppColors.textPrimary;
    final Color iconBg =
        filled ? Colors.white.withValues(alpha: 0.18) : AppColors.primary.withValues(alpha: 0.10);
    final Color iconFg = filled ? Colors.white : AppColors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: filled ? AppShadows.brand(AppColors.primary) : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: iconFg, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: filled
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
