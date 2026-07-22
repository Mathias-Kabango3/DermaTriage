import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../../data/models/patient.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/history/encounter_tile.dart';
import 'encounter_detail_screen.dart';

/// Lists all saved encounters, newest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadEncounters();
    });
  }

  void _openDetail(Encounter encounter, Patient? patient) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EncounterDetailScreen(encounter: encounter, patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).historyTitle)),
      body: Consumer<HistoryProvider>(
        builder: (BuildContext context, HistoryProvider provider, _) {
          final List<Encounter> encounters = provider.encounters;
          if (encounters.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            onRefresh: provider.loadEncounters,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: encounters.length,
              itemBuilder: (BuildContext context, int index) {
                final Encounter e = encounters[index];
                final Patient? patient = provider.patientFor(e.patientId);
                return EncounterTile(
                  encounter: e,
                  patient: patient,
                  onTap: () => _openDetail(e, patient),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.history),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.inbox_outlined,
              size: 72, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).historyEmpty,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
