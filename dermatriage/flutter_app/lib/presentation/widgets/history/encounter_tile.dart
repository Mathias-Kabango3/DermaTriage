import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../../data/models/patient.dart';
import '../../../l10n/app_localizations.dart';

/// List tile summarising a saved [Encounter].
class EncounterTile extends StatelessWidget {
  final Encounter encounter;
  final Patient? patient;
  final VoidCallback onTap;

  const EncounterTile({
    super.key,
    required this.encounter,
    this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DiseaseClass? disease = getDiseaseById(encounter.predictedClass);
    final String displayName = disease?.displayName ?? encounter.predictedClass;
    final TriageLevel level =
        TriageLevelExtension.fromId(encounter.triageCategory);
    final int percent = (encounter.confidenceScore * 100).round();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String date =
        DateFormat('d MMM yyyy, HH:mm').format(encounter.encounterDate);
    final String? patientName = patient?.name;
    final String patientLabel =
        (patientName == null || patientName.isEmpty)
            ? l10n.unknownPatient
            : patientName;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: level.colorLight,
          child: Icon(Icons.medical_services_outlined, color: level.color),
        ),
        title: Text(
          patientLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Text(displayName, style: const TextStyle(fontSize: 13)),
            Text(date, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                _miniBadge(level, l10n),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.confidencePercent(percent),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _miniBadge(TriageLevel level, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.triageLabel(level.id).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
