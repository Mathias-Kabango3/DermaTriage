/// Domain entity for a triage encounter — pure business object.
class Encounter {
  final String encounterId;
  final String patientId;
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
}
