import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/legal_text.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../screens/legal/legal_screen.dart';

/// First-launch consent dialog explaining the research-prototype nature of the
/// app. Acceptance is persisted in [SharedPreferences] so it shows only once.
class ConsentDialog extends StatelessWidget {
  const ConsentDialog({super.key});

  static const String _prefsKey = 'consent_accepted_v1';

  /// Whether the CHW has already accepted the consent.
  static Future<bool> hasAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Show the (non-dismissible) consent dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentDialog(),
    );
  }

  Future<void> _accept(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Opens a legal document directly on the root navigator, bypassing
  /// go_router. This dialog can show before sign-in, so it avoids depending
  /// on the app's auth-gated route redirect logic.
  void _openLegal(BuildContext context, {required bool privacy}) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(
          title: privacy ? l10n.privacyPolicyTitle : l10n.termsTitle,
          bodyEn: privacy ? LegalText.privacyPolicyEn : LegalText.termsOfUseEn,
          rwSummary: privacy
              ? LegalText.privacyPolicyRwSummary
              : LegalText.termsOfUseRwSummary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false, // must explicitly accept
      child: AlertDialog(
        title: Text(l10n.consentTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.consentPrototype,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(AppConstants.ethicsDisclaimer),
              const SizedBox(height: 16),
              Text(
                l10n.consentDataLocation,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text('${l10n.consentLegalIntro} ',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _openLegal(context, privacy: true),
                    child: Text(
                      l10n.privacyPolicyTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(' ${l10n.consentLegalAnd} ',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _openLegal(context, privacy: false),
                    child: Text(
                      l10n.termsTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text('.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => _accept(context),
            child: Text(l10n.consentAgree),
          ),
        ],
      ),
    );
  }
}
