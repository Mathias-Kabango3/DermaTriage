import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/disease_classes.dart';
import '../../../core/constants/triage_levels.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/encounter.dart';
import '../../../data/models/triage_result.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/result/confidence_bar.dart';
import '../../widgets/result/inference_time_chip.dart';
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
        SnackBar(content: Text(AppLocalizations.of(context).noPatientSession)),
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
      // Only diagnosis results reach the save button, so triageLevel is set.
      triageCategory: result.triageLevel ?? TriageLevel.monitor.id,
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
      SnackBar(content: Text(AppLocalizations.of(context).encounterSaved)),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).triageResultTitle)),
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
              return result.isDiagnosis
                  ? _buildResult(context, provider, result)
                  : _buildRejection(context, provider, result);
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).analysing,
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError(TriageProvider provider) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 56, color: AppColors.urgent),
          const SizedBox(height: 16),
          Text(
            provider.error ?? l10n.somethingWrong,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            onPressed: () => provider.runTriage(),
          ),
        ],
      ),
    );
  }

  /// Shown when the model rejects the image (not skin / healthy skin) or is not
  /// confident enough. No diagnosis or triage is displayed — the CHW is guided
  /// to retake the photo or consult.
  Widget _buildRejection(
    BuildContext context,
    TriageProvider provider,
    TriageResult result,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final File? image = provider.capturedImage;
    final _RejectionContent content = _rejectionContent(result.outcome, l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          Icon(content.icon, size: 56, color: content.color),
          const SizedBox(height: 16),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (result.inferenceMs != null) ...<Widget>[
            const SizedBox(height: 20),
            Center(child: InferenceTimeChip(inferenceMs: result.inferenceMs!)),
          ],
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.retakePhoto),
            onPressed: () {
              provider.reset();
              context.pop(); // back to the camera screen
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.home_outlined),
            label: Text(l10n.backToHome),
            onPressed: () {
              provider.reset();
              context.go('/');
            },
          ),
        ],
      ),
    );
  }

  /// Maps a rejection outcome to its icon, colour and CHW-friendly copy.
  _RejectionContent _rejectionContent(
      TriageOutcome outcome, AppLocalizations l10n) {
    switch (outcome) {
      case TriageOutcome.notSkin:
        return _RejectionContent(
          icon: Icons.image_not_supported_outlined,
          color: AppColors.monitor,
          title: l10n.notSkinTitle,
          message: l10n.notSkinMsg,
        );
      case TriageOutcome.healthy:
        return _RejectionContent(
          icon: Icons.verified_outlined,
          color: AppColors.treatLocally,
          title: l10n.healthyTitle,
          message: l10n.healthyMsg,
        );
      case TriageOutcome.lowConfidence:
        return _RejectionContent(
          icon: Icons.help_outline,
          color: AppColors.urgent,
          title: l10n.lowConfTitle,
          message: l10n
              .lowConfMsg((AppConstants.confidenceThreshold * 100).round()),
        );
      case TriageOutcome.diagnosis:
        // Not a rejection — defensive default.
        return _RejectionContent(
          icon: Icons.help_outline,
          color: AppColors.monitor,
          title: l10n.retakeTitle,
          message: l10n.retakeMsg,
        );
    }
  }

  Widget _buildResult(
    BuildContext context,
    TriageProvider provider,
    TriageResult result,
  ) {
    // Reached only for diagnosis outcomes, where triageLevel is non-null.
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TriageLevel level = TriageLevelExtension.fromId(result.triageLevel!);
    final File? image = provider.capturedImage;
    final double photoHeight = MediaQuery.of(context).size.height * 0.5;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Captured photo.
          SizedBox(
            height: photoHeight,
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : Container(
                    color: Colors.black12,
                    child: Center(child: Text(l10n.noImage)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Result: triage badge + disease/confidence.
                TriageBadge(level: level),
                const SizedBox(height: 20),
                ConfidenceBar(
                  diseaseName: result.predictedClassDisplay,
                  confidence: result.confidence,
                  color: level.color,
                ),
                if (result.inferenceMs != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InferenceTimeChip(inferenceMs: result.inferenceMs!),
                  ),
                ],
                const SizedBox(height: 20),
                // CHW notes.
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.chwNotesOptional,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                // Save encounter.
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? l10n.saving : l10n.saveEncounter),
                  onPressed: _saving ? null : () => _saveEncounter(result),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, colour and copy for a single rejection outcome.
class _RejectionContent {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _RejectionContent({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}
