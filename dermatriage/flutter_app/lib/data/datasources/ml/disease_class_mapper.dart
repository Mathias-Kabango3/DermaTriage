import 'dart:math' as math;

import '../../../core/constants/disease_classes.dart';

/// Turns raw model logits into a human-meaningful prediction.
class DiseaseClassMapper {
  DiseaseClassMapper._();

  /// Apply softmax, pick the argmax class and resolve its metadata.
  ///
  /// Returns a map with keys:
  ///   classIndex (int), classId (String), displayName (String),
  ///   confidence (double 0–1), triageLevel (TriageLevel), allProbs (List<double>).
  static Map<String, dynamic> mapLogits(List<double> logits) {
    final List<double> probs = _softmax(logits);

    int argmax = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[argmax]) argmax = i;
    }

    final DiseaseClass disease = getDiseaseByIndex(argmax);

    return <String, dynamic>{
      'classIndex': disease.index,
      'classId': disease.id,
      'displayName': disease.displayName,
      'confidence': probs[argmax],
      'triageLevel': disease.triageLevel, // TriageLevel enum
      'allProbs': probs,
    };
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
