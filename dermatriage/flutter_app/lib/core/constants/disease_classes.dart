import 'triage_levels.dart';

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

/// The 11 merged classes (HAM10000 indices 0-6 + PASSION indices 7-10),
/// ordered to match the model's output logits exactly (CLASS_TO_IDX_11 in
/// ml_pipeline/src/data/harmonise_labels.py). Do NOT reorder.
const List<DiseaseClass> kDiseaseClasses = <DiseaseClass>[
  // --- HAM10000 classes (indices 0-6) ---
  DiseaseClass(
    index: 0,
    id: 'melanoma',
    displayName: 'Melanoma',
    triageLevel: TriageLevel.urgentReferral,
    icd10Code: 'C43.9',
    isNtd: false,
    description:
        'Malignant melanoma — an aggressive skin cancer. Suspicious '
        'pigmented lesions require urgent specialist referral.',
  ),
  DiseaseClass(
    index: 1,
    id: 'melanocytic_nevus',
    displayName: 'Melanocytic Nevus',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'D22.9',
    isNtd: false,
    description:
        'A common benign mole. Usually harmless; monitor for change in '
        'size, shape or colour and refer if suspicious.',
  ),
  DiseaseClass(
    index: 2,
    id: 'basal_cell_carcinoma',
    displayName: 'Basal Cell Carcinoma',
    triageLevel: TriageLevel.urgentReferral,
    icd10Code: 'C44.91',
    isNtd: false,
    description:
        'The most common skin cancer. Slow-growing but locally invasive; '
        'refer for confirmation and treatment.',
  ),
  DiseaseClass(
    index: 3,
    id: 'actinic_keratosis',
    displayName: 'Actinic Keratosis',
    triageLevel: TriageLevel.urgentReferral,
    icd10Code: 'L57.0',
    isNtd: false,
    description:
        'A pre-malignant lesion from sun damage that can progress to '
        'squamous cell carcinoma. Refer for assessment.',
  ),
  DiseaseClass(
    index: 4,
    id: 'benign_keratosis',
    displayName: 'Benign Keratosis',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L82.1',
    isNtd: false,
    description:
        'Benign keratosis-like lesion (e.g. seborrhoeic keratosis, '
        'solar lentigo). Harmless; monitor and reassure.',
  ),
  DiseaseClass(
    index: 5,
    id: 'dermatofibroma',
    displayName: 'Dermatofibroma',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'D23.9',
    isNtd: false,
    description:
        'A benign fibrous skin nodule. Harmless; monitor and refer only '
        'if symptomatic or changing.',
  ),
  DiseaseClass(
    index: 6,
    id: 'vascular_lesion',
    displayName: 'Vascular Lesion',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'D18.0',
    isNtd: false,
    description:
        'Benign vascular lesion (e.g. haemangioma, angioma). Usually '
        'harmless; monitor.',
  ),
  // --- PASSION classes (indices 7-10) ---
  DiseaseClass(
    index: 7,
    id: 'tinea_infection',
    displayName: 'Tinea (Fungal Infection)',
    triageLevel: TriageLevel.treatLocally,
    icd10Code: 'B35.9',
    isNtd: false,
    description:
        'Dermatophyte (ringworm) infection. Usually responds to topical '
        'or oral antifungals at the community level.',
  ),
  DiseaseClass(
    index: 8,
    id: 'scabies',
    displayName: 'Scabies',
    triageLevel: TriageLevel.treatLocally,
    icd10Code: 'B86',
    isNtd: true,
    description:
        'Mite infestation causing intense itching. A WHO neglected tropical '
        'disease; treat patient and contacts locally.',
  ),
  DiseaseClass(
    index: 9,
    id: 'eczema_dermatitis',
    displayName: 'Eczema / Dermatitis',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L30.9',
    isNtd: false,
    description:
        'Inflammatory, itchy skin condition. Manage symptoms and monitor; '
        'refer if severe or infected.',
  ),
  DiseaseClass(
    index: 10,
    id: 'other_ntd',
    displayName: 'Other / Neglected Tropical Disease',
    triageLevel: TriageLevel.urgentReferral,
    icd10Code: 'B88.9',
    isNtd: true,
    description:
        'Possible neglected tropical skin disease or an unrecognised '
        'condition. Refer for clinical assessment.',
  ),
];

/// Look up a [DiseaseClass] by its model output [index].
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
