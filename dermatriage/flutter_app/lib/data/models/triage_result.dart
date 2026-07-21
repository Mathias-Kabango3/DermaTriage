import 'dart:convert';

import '../../core/constants/disease_classes.dart';
import '../../core/constants/triage_levels.dart';

/// The outcome of running the on-device model on a single image.
///
/// [allLogits] is persisted as a JSON-encoded list of doubles. [triageLevel]
/// is null for rejection outcomes (healthy skin, not skin, low confidence),
/// which carry no diagnosis.
class TriageResult {
  final int predictedClassIndex;
  final String predictedClassId;
  final String predictedClassDisplay;
  final double confidence; // 0–1
  final TriageOutcome outcome;
  final String? triageLevel; // TriageLevel id; null for rejection outcomes
  final List<double> allLogits;
  final String? heatmapPath;
  final DateTime timestamp;

  /// End-to-end on-device inference time in milliseconds (preprocess + model
  /// run). Transient — measured at runtime and shown to the CHW; not persisted.
  final int? inferenceMs;

  const TriageResult({
    required this.predictedClassIndex,
    required this.predictedClassId,
    required this.predictedClassDisplay,
    required this.confidence,
    required this.outcome,
    required this.triageLevel,
    required this.allLogits,
    this.heatmapPath,
    required this.timestamp,
    this.inferenceMs,
  });

  /// Whether this prediction is a real diagnosis (vs. a rejection outcome).
  bool get isDiagnosis => outcome == TriageOutcome.diagnosis;

  /// Return a copy with selected fields replaced (used to attach the heatmap
  /// once it finishes generating).
  TriageResult copyWith({String? heatmapPath}) {
    return TriageResult(
      predictedClassIndex: predictedClassIndex,
      predictedClassId: predictedClassId,
      predictedClassDisplay: predictedClassDisplay,
      confidence: confidence,
      outcome: outcome,
      triageLevel: triageLevel,
      allLogits: allLogits,
      heatmapPath: heatmapPath ?? this.heatmapPath,
      timestamp: timestamp,
      inferenceMs: inferenceMs,
    );
  }

  /// True when the predicted triage level requires urgent referral.
  bool get isUrgent => triageLevel == TriageLevel.urgentReferral.id;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'predicted_class_index': predictedClassIndex,
      'predicted_class_id': predictedClassId,
      'predicted_class_display': predictedClassDisplay,
      'confidence': confidence,
      'outcome': outcome.name,
      'triage_level': triageLevel,
      'all_logits': jsonEncode(allLogits),
      'heatmap_path': heatmapPath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TriageResult.fromMap(Map<String, dynamic> map) {
    return TriageResult(
      predictedClassIndex: map['predicted_class_index'] as int,
      predictedClassId: map['predicted_class_id'] as String,
      predictedClassDisplay: map['predicted_class_display'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      outcome: _outcomeFromName(map['outcome'] as String?),
      triageLevel: map['triage_level'] as String?,
      allLogits: (jsonDecode(map['all_logits'] as String) as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      heatmapPath: map['heatmap_path'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Resolve a stored outcome name, defaulting to [TriageOutcome.diagnosis]
  /// for older records written before the field existed.
  static TriageOutcome _outcomeFromName(String? name) {
    if (name == null) return TriageOutcome.diagnosis;
    return TriageOutcome.values.firstWhere(
      (TriageOutcome o) => o.name == name,
      orElse: () => TriageOutcome.diagnosis,
    );
  }
}
