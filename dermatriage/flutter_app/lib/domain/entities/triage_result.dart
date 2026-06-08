import '../../core/constants/triage_levels.dart';

/// Domain entity for a model triage result — pure business object.
class TriageResult {
  final int predictedClassIndex;
  final String predictedClassId;
  final String predictedClassDisplay;
  final double confidence; // 0–1
  final String triageLevel; // TriageLevel id
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
}
