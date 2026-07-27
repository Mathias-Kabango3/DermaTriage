import 'package:flutter/material.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/reference_case.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/retrieval/retrieval_service.dart';

/// "Similar confirmed cases" summary shown under a diagnosis result: how many
/// of the top-3 confirmed cases match the predicted label, their average
/// similarity, and whether they agree with the classifier.
///
/// DEMO-ONLY thumbnails: the row of reference photos below the summary text
/// is a temporary addition for the capstone defense so the panel can see the
/// retrieval concept visually. PASSION dataset photos cannot be redistributed
/// publicly — see the doc comment on [ReferenceCase.assetPath] for the exact
/// removal steps before any release build. The text summary itself has no
/// such restriction and can stay permanently.
///
/// Only ever built for [TriageOutcome.diagnosis] — the caller must not
/// construct this for `not_skin` (no section at all) or `healthy_skin`
/// (show [noReferenceMessage] directly instead), since the bank has no
/// coverage for either class.
class SimilarCasesSection extends StatelessWidget {
  final RetrievalResult? retrieval;
  final bool loading;
  final String predictedClassId;

  const SimilarCasesSection({
    super.key,
    required this.retrieval,
    required this.loading,
    required this.predictedClassId,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (loading) {
      return _card(
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.similarCasesLoading,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final RetrievalResult? result = retrieval;
    if (result == null || result.isEmpty) {
      return _card(child: _neutralMessage(l10n));
    }

    final String? majorityLabel = result.majorityLabel;
    final bool agrees = majorityLabel == predictedClassId;
    final int matchCount = result.matches
        .where((m) => m.reference.label == majorityLabel)
        .length;
    final int avgPercent = (result.matches
                .map((m) => m.similarity)
                .reduce((a, b) => a + b) /
            result.matches.length *
            100)
        .round();
    final String displayLabel =
        getDiseaseById(majorityLabel!)?.displayName ?? majorityLabel;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.similarCasesTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            '${l10n.similarCasesResembles(displayLabel)} '
            '(${l10n.matchSummary(matchCount, avgPercent)})',
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _thumbnailRow(context, result.matches),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: agrees ? AppColors.treatLocallyLight : AppColors.monitorLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  agrees ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  size: 18,
                  color: agrees ? AppColors.treatLocally : AppColors.monitor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    agrees
                        ? l10n.agreementSupport
                        : l10n.disagreementCaution(displayLabel),
                    style: TextStyle(
                      fontSize: 13,
                      color: agrees ? AppColors.treatLocally : AppColors.monitor,
                      fontWeight: agrees ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// DEMO-ONLY — see class doc comment. A row of tappable reference
  /// thumbnails; falls back to a placeholder icon (not a crash) if an image
  /// asset is missing, so removing the photo bundle later without touching
  /// this widget degrades gracefully rather than breaking the result screen.
  Widget _thumbnailRow(BuildContext context, List<ReferenceMatch> matches) {
    final int last = matches.length - 1;
    return Row(
      children: matches.asMap().entries.map((MapEntry<int, ReferenceMatch> e) {
        final ReferenceMatch m = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key == last ? 0 : 12),
            child: GestureDetector(
              onTap: () => _showFullImage(context, m),
              child: Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        m.reference.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.divider,
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 28, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${m.similarityPercent}%',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// DEMO-ONLY — see class doc comment.
  void _showFullImage(BuildContext context, ReferenceMatch m) {
    final String label =
        getDiseaseById(m.reference.label)?.displayName ?? m.reference.label;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.asset(
                  m.reference.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.image_not_supported_outlined)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('$label · ${m.similarityPercent}% similarity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _neutralMessage(AppLocalizations l10n) {
    return Row(
      children: <Widget>[
        const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(l10n.noReferenceCases,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
