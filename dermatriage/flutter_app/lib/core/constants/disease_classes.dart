import 'triage_levels.dart';

/// Metadata for one of the 12 harmonised skin-disease classes.
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

/// The 12 harmonised classes, ordered to match the model's output indices.
const List<DiseaseClass> kDiseaseClasses = <DiseaseClass>[
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
    index: 2,
    id: 'squamous_cell_carcinoma',
    displayName: 'Squamous Cell Carcinoma',
    triageLevel: TriageLevel.urgentReferral,
    icd10Code: 'C44.92',
    isNtd: false,
    description:
        'A common skin cancer that can metastasise if untreated. Refer '
        'for biopsy and management.',
  ),
  DiseaseClass(
    index: 3,
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
    index: 4,
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
    index: 5,
    id: 'psoriasis',
    displayName: 'Psoriasis',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L40.9',
    isNtd: false,
    description:
        'Chronic immune-mediated condition with scaly plaques. Monitor and '
        'refer for ongoing management.',
  ),
  DiseaseClass(
    index: 6,
    id: 'vitiligo',
    displayName: 'Vitiligo',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L80',
    isNtd: false,
    description:
        'Loss of skin pigment in patches. Benign but may need support and '
        'referral for management options.',
  ),
  DiseaseClass(
    index: 7,
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
    index: 8,
    id: 'keloid',
    displayName: 'Keloid',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L91.0',
    isNtd: false,
    description:
        'Overgrown scar tissue. Benign; monitor and refer for treatment '
        'options if symptomatic.',
  ),
  DiseaseClass(
    index: 9,
    id: 'acne_vulgaris',
    displayName: 'Acne Vulgaris',
    triageLevel: TriageLevel.treatLocally,
    icd10Code: 'L70.0',
    isNtd: false,
    description:
        'Common inflammatory condition of hair follicles. Manage locally '
        'with standard protocols.',
  ),
  DiseaseClass(
    index: 10,
    id: 'hyperpigmentation',
    displayName: 'Hyperpigmentation',
    triageLevel: TriageLevel.monitor,
    icd10Code: 'L81.4',
    isNtd: false,
    description:
        'Darkened patches of skin, often post-inflammatory. Benign; monitor '
        'and reassure.',
  ),
  DiseaseClass(
    index: 11,
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
