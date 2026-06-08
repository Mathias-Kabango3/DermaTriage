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
    );
  }
}
