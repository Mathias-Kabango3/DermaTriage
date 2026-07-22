import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/patient_provider.dart';

/// App information, full disclaimer and data-reset controls.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _modelVersion = 'Loading...';
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _loadModelVersion();
  }

  Future<void> _loadModelVersion() async {
    String version;
    try {
      version =
          (await rootBundle.loadString(AppConstants.modelVersionAssetPath))
              .trim();
    } catch (_) {
      version = 'unknown';
    }
    if (mounted) setState(() => _modelVersion = version);
  }

  Future<void> _confirmReset() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.resetTitle),
        content: Text(l10n.resetBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.urgent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteEverything),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _resetData();
  }

  Future<void> _resetData() async {
    setState(() => _resetting = true);
    // Capture providers before the async gaps.
    final history = context.read<HistoryProvider>();
    final patients = context.read<PatientProvider>();

    await DatabaseHelper.instance.resetDatabase();
    await history.loadEncounters();
    await patients.loadPatients();
    if (!mounted) return;

    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).dataReset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LocaleProvider localeProvider = context.watch<LocaleProvider>();
    final String langCode = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: <Widget>[
          // Language switcher — English / Kinyarwanda.
          _SectionHeader(l10n.sectionLanguage),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'en',
                  label: Text(l10n.languageEnglish),
                  icon: const Icon(Icons.language),
                ),
                ButtonSegment<String>(
                  value: 'rw',
                  label: Text(l10n.languageKinyarwanda),
                ),
              ],
              selected: <String>{langCode},
              onSelectionChanged: (Set<String> selection) =>
                  localeProvider.setLocale(Locale(selection.first)),
            ),
          ),
          const Divider(),
          _SectionHeader(l10n.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            trailing: const Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: Text(l10n.modelVersion),
            // The model id is long, so show it below the title (left-aligned,
            // wraps) rather than squeezed into the trailing slot.
            subtitle: Text(_modelVersion),
          ),
          const Divider(),
          _SectionHeader(l10n.sectionDisclaimer),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              AppConstants.ethicsDisclaimer,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(),
          _SectionHeader(l10n.legalSection),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicyTitle),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onTap: () => context.push('/legal/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsTitle),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onTap: () => context.push('/legal/terms'),
          ),
          const Divider(),
          _SectionHeader(l10n.sectionData),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.urgent,
              ),
              icon: const Icon(Icons.delete_forever),
              label: Text(_resetting ? l10n.resetting : l10n.resetAllData),
              onPressed: _resetting ? null : _confirmReset,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
