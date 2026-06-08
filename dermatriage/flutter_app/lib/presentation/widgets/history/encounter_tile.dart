import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';

/// List tile summarising a saved [Encounter].
class EncounterTile extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback onTap;

  const EncounterTile({
    super.key,
    required this.encounter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DiseaseClass? disease = getDiseaseById(encounter.predictedClass);
    final String displayName = disease?.displayName ?? encounter.predictedClass;
    final TriageLevel level =
        TriageLevelExtension.fromId(encounter.triageCategory);
    final int percent = (encounter.confidenceScore * 100).round();
    final String date =
        DateFormat('d MMM yyyy, HH:mm').format(encounter.encounterDate);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: level.colorLight,
          child: Icon(Icons.medical_services_outlined, color: level.color),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                _miniBadge(level),
                const SizedBox(width: 8),
                Text(
                  '$percent% confidence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

  Widget _miniBadge(TriageLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.displayLabel.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
