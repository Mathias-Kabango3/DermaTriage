import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../widgets/result/disease_info_card.dart';
import '../../widgets/result/triage_badge.dart';

/// Read-only detail view for a saved encounter.
class EncounterDetailScreen extends StatelessWidget {
  final Encounter encounter;

  const EncounterDetailScreen({super.key, required this.encounter});

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('Encounter Detail')),
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
                      child: const Center(child: Text('Photo unavailable')),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(date,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  TriageBadge(level: level),
                  const SizedBox(height: 16),
                  Text(
                    '${disease?.displayName ?? encounter.predictedClass} '
                    '— $percent% confidence',
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
                    const Text(
                      'CHW Notes',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
