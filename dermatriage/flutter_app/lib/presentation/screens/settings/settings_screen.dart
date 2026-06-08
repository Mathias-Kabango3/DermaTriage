import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../providers/history_provider.dart';
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently deletes all patients and encounters stored on '
          'this device. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.urgent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _resetData();
  }

  Future<void> _resetData() async {
    setState(() => _resetting = true);
    await DatabaseHelper.instance.resetDatabase();
    if (!mounted) return;

    // Refresh in-memory provider state.
    await context.read<HistoryProvider>().loadEncounters();
    await context.read<PatientProvider>().loadPatients();
    if (!mounted) return;

    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            trailing: const Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Model version'),
            trailing: Text(_modelVersion),
          ),
          const Divider(),
          const _SectionHeader('Disclaimer'),
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
          const _SectionHeader('Data'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.urgent,
              ),
              icon: const Icon(Icons.delete_forever),
              label: Text(_resetting ? 'Resetting...' : 'Reset All Data'),
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
