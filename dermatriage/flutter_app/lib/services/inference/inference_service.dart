import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/disease_classes.dart';
import '../../core/constants/triage_levels.dart';
import '../../data/datasources/ml/disease_class_mapper.dart';
import '../../data/datasources/ml/image_processor.dart';
import '../../data/datasources/ml/occlusion_saliency.dart';
import '../../data/datasources/ml/tflite_interpreter.dart';
import '../../data/models/triage_result.dart';

/// Orchestrates the end-to-end on-device triage pipeline:
/// read image -> preprocess -> run model -> map to a [TriageResult].
class InferenceService {
  final SkinTriageInterpreter _interpreter;

  InferenceService({SkinTriageInterpreter? interpreter})
      : _interpreter = interpreter ?? SkinTriageInterpreter();

  /// Load the model. Call once before [runTriage].
  Future<void> init() async {
    await _interpreter.load();
  }

  /// Run the full triage pipeline on a captured image file.
  Future<TriageResult> runTriage(File imageFile) async {
    // Ensure the model is loaded (idempotent). If it failed to load at startup
    // this re-attempts and throws the real reason, instead of a null-check
    // crash deeper in the pipeline.
    await _interpreter.load();

    final bytes = await imageFile.readAsBytes();
    final input = ImageProcessor.preprocess(bytes);
    final List<double> logits = _interpreter.predict(input);
    final TriagePrediction pred = DiseaseClassMapper.mapLogits(logits);

    _logInferenceDebug(input, logits, pred);

    return TriageResult(
      predictedClassIndex: pred.classIndex,
      predictedClassId: pred.classId,
      predictedClassDisplay:
          pred.disease?.displayName ?? _rejectionLabel(pred.outcome),
      confidence: pred.confidence,
      outcome: pred.outcome,
      // Rejection outcomes carry no triage level.
      triageLevel: pred.disease?.triageLevel.id,
      allLogits: logits,
      heatmapPath: null,
      timestamp: DateTime.now(),
    );
  }

  /// Debug dump for one inference: input tensor stats (to verify the normalised
  /// range, ~[-2.1, +2.6]), plus raw logits and softmax probabilities for all
  /// classes — to compare directly against the Python notebook.
  void _logInferenceDebug(
    Float32List input,
    List<double> logits,
    TriagePrediction pred,
  ) {
    double mn = double.infinity, mx = double.negativeInfinity, sum = 0.0;
    for (final double v in input) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      sum += v;
    }
    final double mean = sum / input.length;

    final StringBuffer b = StringBuffer()
      ..writeln('--- DermaTriage inference debug ---')
      ..writeln('input: len=${input.length} '
          'min=${mn.toStringAsFixed(4)} '
          'max=${mx.toStringAsFixed(4)} '
          'mean=${mean.toStringAsFixed(4)} '
          '(expected ~ -2.1..+2.6)')
      ..writeln('raw logits:');
    for (int i = 0; i < logits.length; i++) {
      final String label =
          i < kModelClassIds.length ? kModelClassIds[i] : 'class$i';
      final double prob =
          i < pred.probabilities.length ? pred.probabilities[i] : double.nan;
      b.writeln('  [$i] ${label.padRight(13)} '
          'logit=${logits[i].toStringAsFixed(4)}  '
          'softmax=${prob.toStringAsFixed(4)}');
    }
    b.writeln('argmax=${pred.classIndex} (${pred.classId}) '
        'conf=${pred.confidence.toStringAsFixed(4)} '
        'outcome=${pred.outcome.name}');

    developer.log(b.toString(), name: 'DermaTriageDebug');
  }

  /// Generate an occlusion-based saliency heatmap explaining [targetClassIndex]
  /// for [imageFile], fully on-device. Writes a PNG into the app's documents
  /// directory and returns its path, or null if no heatmap could be produced.
  Future<String?> generateSaliencyMap(
    File imageFile,
    int targetClassIndex,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final Float32List base = ImageProcessor.preprocess(bytes);

      final Uint8List? png = await OcclusionSaliency().generate(
        base: base,
        predict: _interpreter.predict,
        targetIndex: targetClassIndex,
      );
      if (png == null) return null;

      final Directory dir = await getApplicationDocumentsDirectory();
      final String path = p.join(
        dir.path,
        'heatmap_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await File(path).writeAsBytes(png);
      return path;
    } catch (_) {
      // Explainability is best-effort: a failure here must never block triage.
      return null;
    }
  }

  /// A short label for a non-diagnostic outcome (used for storage/debugging;
  /// the UI shows fuller guidance).
  String _rejectionLabel(TriageOutcome outcome) {
    switch (outcome) {
      case TriageOutcome.healthy:
        return 'Healthy skin';
      case TriageOutcome.notSkin:
        return 'Not a skin image';
      case TriageOutcome.lowConfidence:
        return 'Low confidence';
      case TriageOutcome.diagnosis:
        return 'Diagnosis';
    }
  }

  /// Release native resources.
  void dispose() {
    _interpreter.dispose();
  }
}
