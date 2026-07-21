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
              return result.isDiagnosis
                  ? _buildResult(context, provider, result)
                  : _buildRejection(context, provider, result);
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

  /// Shown when the model rejects the image (not skin / healthy skin) or is not
  /// confident enough. No diagnosis or triage is displayed — the CHW is guided
  /// to retake the photo or consult.
  Widget _buildRejection(
    BuildContext context,
    TriageProvider provider,
    TriageResult result,
  ) {
    final File? image = provider.capturedImage;
    final _RejectionContent content = _rejectionContent(result.outcome);

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
            label: const Text('Retake Photo'),
            onPressed: () {
              provider.reset();
              context.pop(); // back to the camera screen
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
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
  _RejectionContent _rejectionContent(TriageOutcome outcome) {
    switch (outcome) {
      case TriageOutcome.notSkin:
        return const _RejectionContent(
          icon: Icons.image_not_supported_outlined,
          color: AppColors.monitor,
          title: 'This does not look like skin',
          message:
              'The image does not appear to show skin. Please take a clear, '
              'close-up photo of the affected skin area and try again.',
        );
      case TriageOutcome.healthy:
        return const _RejectionContent(
          icon: Icons.verified_outlined,
          color: AppColors.treatLocally,
          title: 'This skin appears healthy',
          message:
              'No skin condition was detected. If the patient still has a '
              'concern, retake the photo of the affected area or refer them '
              'to a clinician.',
        );
      case TriageOutcome.lowConfidence:
        return _RejectionContent(
          icon: Icons.help_outline,
          color: AppColors.urgent,
          title: 'Not confident enough',
          message:
              'The app is not sure about this image (below '
              '${(AppConstants.confidenceThreshold * 100).round()}% '
              'confidence). Please retake a clear, well-lit, close-up photo. '
              'If you are still concerned, refer the patient.',
        );
      case TriageOutcome.diagnosis:
        // Not a rejection — defensive default.
        return const _RejectionContent(
          icon: Icons.help_outline,
          color: AppColors.monitor,
          title: 'Please retake the photo',
          message: 'Please take a clear, close-up photo and try again.',
        );
    }
  }

  Widget _buildResult(
    BuildContext context,
    TriageProvider provider,
    TriageResult result,
  ) {
    // Reached only for diagnosis outcomes, where triageLevel is non-null.
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
                    child: const Center(child: Text('No image')),
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
                  decoration: const InputDecoration(
                    labelText: 'CHW notes (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                // Save encounter.
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Encounter'),
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
