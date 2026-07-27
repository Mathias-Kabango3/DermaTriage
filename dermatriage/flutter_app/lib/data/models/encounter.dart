/// SQLite-backed data model for a triage encounter.
///
/// Mirrors the `encounters` table from the ERD. [encounterDate] is stored as an
/// ISO-8601 string.
class Encounter {
  final String encounterId; // UUID
  final String patientId; // FK -> patients.id
  final String photoPath;
  final String predictedClass;
  final double confidenceScore;
  final String triageCategory;
  final String? heatmapPath;
  final String? chwNotes;
  final DateTime encounterDate;

  /// Top confirmed-case retrieval match at save time (explainability layer).
  /// Null when retrieval didn't apply (not_skin/healthy_skin/low_confidence)
  /// or the reference bank was unavailable.
  final String? retrievalTop1Label;
  final double? retrievalTop1Similarity;
  final bool? retrievalAgreement;

  const Encounter({
    required this.encounterId,
    required this.patientId,
    required this.photoPath,
    required this.predictedClass,
    required this.confidenceScore,
    required this.triageCategory,
    this.heatmapPath,
    this.chwNotes,
    required this.encounterDate,
    this.retrievalTop1Label,
    this.retrievalTop1Similarity,
    this.retrievalAgreement,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'encounter_id': encounterId,
      'patient_id': patientId,
      'photo_path': photoPath,
      'predicted_class': predictedClass,
      'confidence_score': confidenceScore,
      'triage_category': triageCategory,
      'heatmap_path': heatmapPath,
      'chw_notes': chwNotes,
      'encounter_date': encounterDate.toIso8601String(),
      'retrieval_top1_label': retrievalTop1Label,
      'retrieval_top1_similarity': retrievalTop1Similarity,
      'retrieval_agreement': retrievalAgreement == null
          ? null
          : (retrievalAgreement! ? 1 : 0),
    };
  }

  factory Encounter.fromMap(Map<String, dynamic> map) {
    return Encounter(
      encounterId: map['encounter_id'] as String,
      patientId: map['patient_id'] as String,
      photoPath: map['photo_path'] as String,
      predictedClass: map['predicted_class'] as String,
      confidenceScore: (map['confidence_score'] as num).toDouble(),
      triageCategory: map['triage_category'] as String,
      heatmapPath: map['heatmap_path'] as String?,
      chwNotes: map['chw_notes'] as String?,
      encounterDate: DateTime.parse(map['encounter_date'] as String),
      retrievalTop1Label: map['retrieval_top1_label'] as String?,
      retrievalTop1Similarity:
          (map['retrieval_top1_similarity'] as num?)?.toDouble(),
      retrievalAgreement: (map['retrieval_agreement'] as int?) == null
          ? null
          : (map['retrieval_agreement'] as int) != 0,
    );
  }

  Encounter copyWith({
    String? encounterId,
    String? patientId,
    String? photoPath,
    String? predictedClass,
    double? confidenceScore,
    String? triageCategory,
    String? heatmapPath,
    String? chwNotes,
    DateTime? encounterDate,
    String? retrievalTop1Label,
    double? retrievalTop1Similarity,
    bool? retrievalAgreement,
  }) {
    return Encounter(
      encounterId: encounterId ?? this.encounterId,
      patientId: patientId ?? this.patientId,
      photoPath: photoPath ?? this.photoPath,
      predictedClass: predictedClass ?? this.predictedClass,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      triageCategory: triageCategory ?? this.triageCategory,
      heatmapPath: heatmapPath ?? this.heatmapPath,
      chwNotes: chwNotes ?? this.chwNotes,
      encounterDate: encounterDate ?? this.encounterDate,
      retrievalTop1Label: retrievalTop1Label ?? this.retrievalTop1Label,
      retrievalTop1Similarity:
          retrievalTop1Similarity ?? this.retrievalTop1Similarity,
      retrievalAgreement: retrievalAgreement ?? this.retrievalAgreement,
    );
  }
}
