import 'dart:convert';

import '../../core/constants/triage_levels.dart';

/// The outcome of running the on-device model on a single image.
///
/// [allLogits] is persisted as a JSON-encoded list of doubles.
class TriageResult {
  final int predictedClassIndex;
  final String predictedClassId;
  final String predictedClassDisplay;
  final double confidence; // 0–1
  final String triageLevel; // TriageLevel id, e.g. 'URGENT_REFERRAL'
  final List<double> allLogits;
  final String? heatmapPath;
  final DateTime timestamp;

  const TriageResult({
    required this.predictedClassIndex,
    required this.predictedClassId,
    required this.predictedClassDisplay,
    required this.confidence,
    required this.triageLevel,
    required this.allLogits,
    this.heatmapPath,
    required this.timestamp,
  });

  /// True when the predicted triage level requires urgent referral.
  bool get isUrgent => triageLevel == TriageLevel.urgentReferral.id;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'predicted_class_index': predictedClassIndex,
      'predicted_class_id': predictedClassId,
      'predicted_class_display': predictedClassDisplay,
      'confidence': confidence,
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
      triageLevel: map['triage_level'] as String,
      allLogits: (jsonDecode(map['all_logits'] as String) as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      heatmapPath: map['heatmap_path'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
