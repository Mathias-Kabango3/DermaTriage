import 'triage_levels.dart';

/// What the app should do with a single model prediction.
///
/// Only [diagnosis] reveals a disease + triage level. The other three are
/// "rejection" outcomes: the model is confident the image is healthy skin or
/// not skin at all, or it is not confident enough to suggest anything.
enum TriageOutcome {
  /// A diagnosable skin condition was predicted with sufficient confidence.
  diagnosis,

  /// The model thinks the skin looks healthy — no condition to triage.
  healthy,

  /// The model thinks the image is not skin (e.g. a wall, floor, object).
  notSkin,

  /// The top prediction is below the confidence threshold — ask for a retake.
  lowConfidence,
}

/// The model's five output classes, in **logit-index order** (0-4).
///
/// This MUST match the training order exactly:
///   0 Fungal, 1 Scabies, 2 Eczema, 3 healthy_skin, 4 not_skin.
/// Do NOT reorder — the argmax index is looked up here to label the output.
const List<String> kModelClassIds = <String>[
  'fungal', // 0
  'scabies', // 1
  'eczema', // 2
  'healthy_skin', // 3
  'not_skin', // 4
];

/// Index of the `healthy_skin` class in [kModelClassIds].
const int kHealthySkinIndex = 3;

/// Index of the `not_skin` class in [kModelClassIds].
const int kNotSkinIndex = 4;

/// Metadata for one of the harmonised skin-disease classes.
class DiseaseClass {
  final int index;
  final String id;
  final String displayName;
  final TriageLevel triageLevel;
  final String icd10Code;
  final bool isNtd;
  final String description;

  const DiseaseClass({
    required this.index,
    required this.id,
    required this.displayName,
    required this.triageLevel,
    required this.icd10Code,
    required this.isNtd,
    required this.description,
  });
}

/// The three **diagnosable** classes, at model logit indices 0-2.
///
/// `healthy_skin` (3) and `not_skin` (4) are deliberately absent: they are
/// rejection outcomes (see [TriageOutcome]) with no disease metadata or triage
/// level. The list index matches the model logit index — do NOT reorder.
const List<DiseaseClass> kDiseaseClasses = <DiseaseClass>[
  DiseaseClass(
    index: 0,
    id: 'fungal',
    displayName: 'Fungal Infection',
    triageLevel: TriageLevel.treatLocally,
    icd10Code: 'B35.9',
    isNtd: false,
    description:
        'A fungal (dermatophyte / ringworm) skin infection. Usually '
        'responds to topical or oral antifungals at the community level.',
  ),
  DiseaseClass(
    index: 1,
    id: 'scabies',
    displayName: 'Scabies',
    triageLevel: TriageLevel.treatLocally,
    icd10Code: 'B86',
    isNtd: true,
    description:
        'Mite infestation causing intense itching. A WHO neglected tropical '
        'disease; treat the patient and close contacts locally.',
  ),
  DiseaseClass(
    index: 2,
    id: 'eczema',
    displayName: 'Eczema / Dermatitis',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L30.9',
    isNtd: false,
    description:
        'Inflammatory, itchy skin condition. Manage symptoms and monitor; '
        'refer if severe, spreading, or infected.',
  ),
];

/// Look up a diagnosable [DiseaseClass] by its model output [index] (0-2).
///
/// Only valid for the [TriageOutcome.diagnosis] classes; the rejection
/// indices (`healthy_skin`, `not_skin`) have no [DiseaseClass].
DiseaseClass getDiseaseByIndex(int index) {
  if (index < 0 || index >= kDiseaseClasses.length) {
    throw RangeError.index(index, kDiseaseClasses, 'index');
  }
  return kDiseaseClasses[index];
}

/// Look up a [DiseaseClass] by its string [id], or null if unknown.
DiseaseClass? getDiseaseById(String id) {
  for (final DiseaseClass d in kDiseaseClasses) {
    if (d.id == id) return d;
  }
  return null;
}
