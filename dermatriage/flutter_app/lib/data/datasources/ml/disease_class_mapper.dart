import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/disease_classes.dart';

/// A fully-resolved prediction: the raw top class plus the decision about how
/// the app should present it (diagnose vs. reject).
class TriagePrediction {
  /// Argmax index into the model's output (0-4).
  final int classIndex;

  /// Stable id of the top class (e.g. `fungal`, `healthy_skin`, `not_skin`).
  final String classId;

  /// Top-class probability after softmax, in 0–1.
  final double confidence;

  /// How the UI should treat this prediction.
  final TriageOutcome outcome;

  /// Disease metadata — non-null only when [outcome] is
  /// [TriageOutcome.diagnosis].
  final DiseaseClass? disease;

  /// Full softmax probability vector, index-aligned with [kModelClassIds].
  final List<double> probabilities;

  const TriagePrediction({
    required this.classIndex,
    required this.classId,
    required this.confidence,
    required this.outcome,
    required this.disease,
    required this.probabilities,
  });
}

/// Turns raw model logits into a [TriagePrediction], applying the rejection
/// rules: `not_skin` / `healthy_skin` never produce a diagnosis, and a top
/// confidence below [AppConstants.confidenceThreshold] is rejected as
/// low-confidence.
class DiseaseClassMapper {
  DiseaseClassMapper._();

  static TriagePrediction mapLogits(List<double> logits) {
    final List<double> probs = _softmax(logits);

    int argmax = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[argmax]) argmax = i;
    }
    final double confidence = probs[argmax];
    final String classId = argmax < kModelClassIds.length
        ? kModelClassIds[argmax]
        : 'unknown';

    // Decide the outcome. Rejection of not_skin / healthy_skin takes priority
    // over the confidence check, then the threshold gates everything else.
    final TriageOutcome outcome;
    DiseaseClass? disease;
    if (argmax == kNotSkinIndex) {
      outcome = TriageOutcome.notSkin;
    } else if (argmax == kHealthySkinIndex) {
      outcome = TriageOutcome.healthy;
    } else if (confidence < AppConstants.confidenceThreshold) {
      outcome = TriageOutcome.lowConfidence;
    } else {
      outcome = TriageOutcome.diagnosis;
      disease = getDiseaseByIndex(argmax);
    }

    return TriagePrediction(
      classIndex: argmax,
      classId: classId,
      confidence: confidence,
      outcome: outcome,
      disease: disease,
      probabilities: probs,
    );
  }

  /// Numerically-stable softmax.
  static List<double> _softmax(List<double> logits) {
    final double maxLogit = logits.reduce(math.max);
    final List<double> exps =
        logits.map((double l) => math.exp(l - maxLogit)).toList();
    final double sum = exps.reduce((double a, double b) => a + b);
    return exps.map((double e) => e / sum).toList();
  }
}
