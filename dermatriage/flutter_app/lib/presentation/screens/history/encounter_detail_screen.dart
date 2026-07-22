import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../../data/models/patient.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/result/disease_info_card.dart';
import '../../widgets/result/triage_badge.dart';

/// Read-only detail view for a saved encounter.
class EncounterDetailScreen extends StatelessWidget {
  final Encounter encounter;
  final Patient? patient;

  const EncounterDetailScreen({
    super.key,
    required this.encounter,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DiseaseClass? disease = getDiseaseById(encounter.predictedClass);
    final TriageLevel level =
        TriageLevelExtension.fromId(encounter.triageCategory);
    final int percent = (encounter.confidenceScore * 100).round();
    final String date =
        DateFormat('d MMM yyyy, HH:mm').format(encounter.encounterDate);
    final File? photo = encounter.photoPath.isNotEmpty
        ? File(encounter.photoPath)
        : null;
    final double photoHeight = MediaQuery.of(context).size.height * 0.4;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailTitle)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: photoHeight,
              child: photo != null && photo.existsSync()
                  ? Image.file(photo, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black12,
                      child: Center(child: Text(l10n.photoUnavailable)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    (patient?.name.isNotEmpty ?? false)
                        ? patient!.name
                        : l10n.unknownPatient,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (patient != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      <String>[
                        l10n.sexLabel(patient!.sex),
                        if (patient!.approximateAge != null)
                          l10n.approxAgeYears(patient!.approximateAge!),
                        if (patient!.location.isNotEmpty) patient!.location,
                      ].join(' · '),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(date,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  TriageBadge(level: level),
                  const SizedBox(height: 16),
                  Text(
                    '${disease?.displayName ?? encounter.predictedClass} '
                    '— ${l10n.confidencePercent(percent)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (disease != null) DiseaseInfoCard(disease: disease),
                  const SizedBox(height: 16),
                  if (encounter.chwNotes != null &&
                      encounter.chwNotes!.isNotEmpty) ...<Widget>[
                    Text(
                      l10n.chwNotes,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(encounter.chwNotes!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
