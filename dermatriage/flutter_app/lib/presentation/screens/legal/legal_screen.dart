import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// Renders a legal document (Privacy Policy or Terms of Use): a short
/// Kinyarwanda summary up top, then the full authoritative English text.
///
/// One generic screen for both documents — they share the same layout, only
/// the title and body differ.
class LegalScreen extends StatelessWidget {
  final String title;
  final String bodyEn;
  final String rwSummary;

  const LegalScreen({
    super.key,
    required this.title,
    required this.bodyEn,
    required this.rwSummary,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.kinyarwandaSummaryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(rwSummary, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.fullTextLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(bodyEn.trim(), style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
