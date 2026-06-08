import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // must explicitly accept
      child: AlertDialog(
        title: const Text('Before you begin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '${AppConstants.appName} is a research prototype, not an '
                'approved medical device.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(AppConstants.ethicsDisclaimer),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => _accept(context),
            child: const Text('I understand and agree'),
          ),
        ],
      ),
    );
  }
}
