import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../../data/models/triage_result.dart';
import '../../providers/history_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/common/disclaimer_banner.dart';
import '../../widgets/result/confidence_bar.dart';
import '../../widgets/result/disease_info_card.dart';
import '../../widgets/result/gradcam_overlay.dart';
import '../../widgets/result/triage_badge.dart';

/// Displays the triage outcome for the captured lesion image.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Kick off inference once the first frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final TriageProvider provider = context.read<TriageProvider>();
      if (provider.result == null &&
          provider.state != TriageState.processing) {
        provider.runTriage();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEncounter(TriageResult result) async {
    final PatientProvider patientProvider = context.read<PatientProvider>();
    final patient = patientProvider.currentPatient;
    final File? image = context.read<TriageProvider>().capturedImage;

    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient in session. Cannot save.')),
      );
      return;
    }

    setState(() => _saving = true);

    final encounter = Encounter(
      encounterId: const Uuid().v4(),
      patientId: patient.id,
      photoPath: image?.path ?? '',
      predictedClass: result.predictedClassId,
      confidenceScore: result.confidence,
      triageCategory: result.triageLevel,
      heatmapPath: result.heatmapPath,
      chwNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      encounterDate: DateTime.now(),
    );

    await context.read<HistoryProvider>().saveEncounter(encounter);
    if (!mounted) return;

    context.read<TriageProvider>().reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encounter saved.')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Triage Result')),
      body: Consumer<TriageProvider>(
        builder: (BuildContext context, TriageProvider provider, _) {
          switch (provider.state) {
            case TriageState.processing:
            case TriageState.idle:
              return _buildLoading();
            case TriageState.error:
              return _buildError(provider);
            case TriageState.done:
              final TriageResult? result = provider.result;
              if (result == null) return _buildLoading();
              return _buildResult(context, provider, result);
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analysing lesion...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError(TriageProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 56, color: AppColors.urgent),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => provider.runTriage(),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    TriageProvider provider,
    TriageResult result,
  ) {
    final TriageLevel level = TriageLevelExtension.fromId(result.triageLevel);
    final DiseaseClass disease = getDiseaseByIndex(result.predictedClassIndex);
    final File? image = provider.capturedImage;
    final double photoHeight = MediaQuery.of(context).size.height * 0.5;

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. Captured photo with Grad-CAM overlay.
                SizedBox(
                  height: photoHeight,
                  child: image != null
                      ? GradCAMOverlay(
                          image: Image.file(image, fit: BoxFit.cover),
                          heatmapPath: result.heatmapPath,
                        )
                      : Container(
                          color: Colors.black12,
                          child: const Center(child: Text('No image')),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // 2. Triage badge.
                      TriageBadge(level: level),
                      const SizedBox(height: 20),
                      // 3. Disease + confidence.
                      ConfidenceBar(
                        diseaseName: result.predictedClassDisplay,
                        confidence: result.confidence,
                        color: level.color,
                      ),
                      const SizedBox(height: 20),
                      // 4. Triage instruction.
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: level.colorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          level.instruction,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 5. Disease info card.
                      DiseaseInfoCard(disease: disease),
                      const SizedBox(height: 20),
                      // 6. CHW notes.
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'CHW notes (optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 7. Save encounter.
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(_saving ? 'Saving...' : 'Save Encounter'),
                        onPressed:
                            _saving ? null : () => _saveEncounter(result),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 8. Persistent disclaimer.
        const DisclaimerBanner(),
      ],
    );
  }
}
