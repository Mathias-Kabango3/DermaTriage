import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';

/// Shows how long on-device inference took, with a pass / over-budget state
/// relative to [AppConstants.inferenceBudgetMs]. Lets the CHW (and reviewers)
/// see the <2 s requirement being met on every capture.
class InferenceTimeChip extends StatelessWidget {
  final int inferenceMs;

  const InferenceTimeChip({super.key, required this.inferenceMs});

  @override
  Widget build(BuildContext context) {
    final bool withinBudget = inferenceMs <= AppConstants.inferenceBudgetMs;
    final Color color =
        withinBudget ? AppColors.treatLocally : AppColors.monitor;
    final double seconds = inferenceMs / 1000.0;
    const double budgetSeconds = AppConstants.inferenceBudgetMs / 1000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            withinBudget ? Icons.bolt_rounded : Icons.timer_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            'Inference: ${seconds.toStringAsFixed(2)} s',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            withinBudget
                ? '· within ${budgetSeconds.toStringAsFixed(0)} s target'
                : '· over ${budgetSeconds.toStringAsFixed(0)} s target',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
