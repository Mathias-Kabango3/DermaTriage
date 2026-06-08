import 'dart:io';

import '../../core/constants/triage_levels.dart';
import '../../data/datasources/ml/disease_class_mapper.dart';
import '../../data/datasources/ml/image_processor.dart';
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
    final bytes = await imageFile.readAsBytes();
    final input = ImageProcessor.preprocess(bytes);
    final List<double> logits = _interpreter.predict(input);
    final Map<String, dynamic> mapped = DiseaseClassMapper.mapLogits(logits);

    final TriageLevel triageLevel = mapped['triageLevel'] as TriageLevel;

    return TriageResult(
      predictedClassIndex: mapped['classIndex'] as int,
      predictedClassId: mapped['classId'] as String,
      predictedClassDisplay: mapped['displayName'] as String,
      confidence: mapped['confidence'] as double,
      triageLevel: triageLevel.id,
      allLogits: logits,
      heatmapPath: null,
      timestamp: DateTime.now(),
    );
  }

  /// Release native resources.
  void dispose() {
    _interpreter.dispose();
  }
}
