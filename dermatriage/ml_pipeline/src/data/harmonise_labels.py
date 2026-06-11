"""Harmonise raw dataset labels onto the 12 DermaTriage classes.

Both source datasets (Fitzpatrick17k and HAM10000) use their own label
vocabularies. This module maps those raw labels onto the project's 12
harmonised class ids, and exposes the integer index and triage level for
each class.

Triage levels:
    URGENT_REFERRAL  - malignant / serious; refer to specialist.
    MONITOR          - chronic or cosmetic; observe and follow up.
    TREAT_LOCALLY    - common, treatable at primary-care level.
"""

# ----------------------------------------------------------------------------
# Triage level constants
# ----------------------------------------------------------------------------
URGENT_REFERRAL = "URGENT_REFERRAL"
MONITOR = "MONITOR"
TREAT_LOCALLY = "TREAT_LOCALLY"

# ----------------------------------------------------------------------------
# The 12 harmonised classes, in canonical order (index 0-11).
# ----------------------------------------------------------------------------
HARMONISED_CLASSES = [
    "melanoma",
    "basal_cell_carcinoma",
    "squamous_cell_carcinoma",
    "tinea_infection",
    "eczema_dermatitis",
    "psoriasis",
    "vitiligo",
    "scabies",
    "keloid",
    "acne_vulgaris",
    "hyperpigmentation",
    "other_ntd",
]

CLASS_TO_IDX = {name: idx for idx, name in enumerate(HARMONISED_CLASSES)}

# ----------------------------------------------------------------------------
# Triage level per harmonised class.
# ----------------------------------------------------------------------------
TRIAGE_LEVEL = {
    "melanoma": URGENT_REFERRAL,
    "basal_cell_carcinoma": URGENT_REFERRAL,
    "squamous_cell_carcinoma": URGENT_REFERRAL,
    "other_ntd": URGENT_REFERRAL,
    "eczema_dermatitis": MONITOR,
    "psoriasis": MONITOR,
    "vitiligo": MONITOR,
    "keloid": MONITOR,
    "hyperpigmentation": MONITOR,
    "tinea_infection": TREAT_LOCALLY,
    "scabies": TREAT_LOCALLY,
    "acne_vulgaris": TREAT_LOCALLY,
}

# ----------------------------------------------------------------------------
# Fitzpatrick17k raw label -> harmonised class id.
# Keys are lower-cased; lookups are normalised the same way.
# ----------------------------------------------------------------------------
FITZPATRICK17K_MAP = {
    # melanoma
    "melanoma": "melanoma",
    "malignant melanoma": "melanoma",
    # basal cell carcinoma
    "basal cell carcinoma": "basal_cell_carcinoma",
    "basal cell carcinoma morpheaform": "basal_cell_carcinoma",
    # squamous cell carcinoma
    "squamous cell carcinoma": "squamous_cell_carcinoma",
    "actinic keratosis": "squamous_cell_carcinoma",
    # tinea / dermatophyte infections
    "tinea": "tinea_infection",
    "tinea corporis": "tinea_infection",
    "tinea pedis": "tinea_infection",
    "tinea versicolor": "tinea_infection",
    "dermatophytosis": "tinea_infection",
    # eczema / dermatitis
    "eczema": "eczema_dermatitis",
    "atopic dermatitis": "eczema_dermatitis",
    "dermatitis": "eczema_dermatitis",
    "allergic contact dermatitis": "eczema_dermatitis",
    "contact dermatitis": "eczema_dermatitis",
    "seborrheic dermatitis": "eczema_dermatitis",
    # psoriasis
    "psoriasis": "psoriasis",
    # vitiligo
    "vitiligo": "vitiligo",
    # scabies
    "scabies": "scabies",
    # keloid
    "keloid": "keloid",
    # acne
    "acne": "acne_vulgaris",
    "acne vulgaris": "acne_vulgaris",
    # hyperpigmentation
    "hyperpigmentation": "hyperpigmentation",
    "melasma": "hyperpigmentation",
    "post inflammatory hyperpigmentation": "hyperpigmentation",
    # catch-all / neglected tropical diseases
    "other": "other_ntd",
}

# ----------------------------------------------------------------------------
# HAM10000 short code -> harmonised class id.
#   mel   melanoma
#   bcc   basal cell carcinoma
#   scc   squamous cell carcinoma
#   akiec actinic keratosis / intraepithelial carcinoma (SCC spectrum)
#   bkl   benign keratosis-like lesions (pigmented) -> hyperpigmentation
#   df    dermatofibroma (benign fibrous nodule)    -> keloid
#   nv    melanocytic nevi (benign pigmented)       -> hyperpigmentation
#   vasc  vascular lesions (no dedicated class)     -> other_ntd
# ----------------------------------------------------------------------------
HAM10000_MAP = {
    "mel": "melanoma",
    "bcc": "basal_cell_carcinoma",
    "scc": "squamous_cell_carcinoma",
    "akiec": "squamous_cell_carcinoma",
    "bkl": "hyperpigmentation",
    "df": "keloid",
    "nv": "hyperpigmentation",
    "vasc": "other_ntd",
}

# ----------------------------------------------------------------------------
# HAM10000-only 7-class taxonomy.
#
# While Fitzpatrick17k access is pending we train on HAM10000 alone, keeping its
# native 7 diagnostic classes (no collapsing into the 12-class taxonomy). The
# 12-class maps above are left untouched so the full pipeline still works once
# Fitzpatrick17k arrives.
# ----------------------------------------------------------------------------
HAM10000_7CLASS_MAP = {
    "mel": "melanoma",
    "nv": "melanocytic_nevus",
    "bcc": "basal_cell_carcinoma",
    "akiec": "actinic_keratosis",
    "bkl": "benign_keratosis",
    "df": "dermatofibroma",
    "vasc": "vascular_lesion",
}

# The 7 HAM10000 classes, in canonical order (index 0-6).
HAM10000_7CLASSES = [
    "melanoma",
    "melanocytic_nevus",
    "basal_cell_carcinoma",
    "actinic_keratosis",
    "benign_keratosis",
    "dermatofibroma",
    "vascular_lesion",
]

CLASS_TO_IDX_7 = {name: idx for idx, name in enumerate(HAM10000_7CLASSES)}

TRIAGE_LEVEL_7 = {
    "melanoma": URGENT_REFERRAL,
    "melanocytic_nevus": MONITOR,
    "basal_cell_carcinoma": URGENT_REFERRAL,
    "actinic_keratosis": URGENT_REFERRAL,
    "benign_keratosis": MONITOR,
    "dermatofibroma": MONITOR,
    "vascular_lesion": MONITOR,
}

# ----------------------------------------------------------------------------
# PASSION dataset (Gottfrois et al., MICCAI 2024) — inspection of label.csv
#
# Inspected: dermatriage/PASSION_MICCAI_2024/label.csv
#   - Patient-level: 1653 rows (one per subject), 4901 images on disk.
#   - Images: flat dir images/{subject_id}_{n}.jpg (multiple per patient).
#   - Columns: subject_id, country, age, sex, fitzpatrick, body_loc, impetig,
#              conditions_PASSION
#
#   Diagnosis column = conditions_PASSION (4 classes):
#       Fungal   579
#       Scabies  471
#       Eczema   414
#       Others   189
#   Separate binary flag = impetig (0/1): 191 positive. Impetigo is a
#   co-occurring bacterial infection flag, NOT a primary diagnosis label, so it
#   is not mapped as its own class here.
#
#   Skin type column = fitzpatrick. NOTE: the dataset is documented as
#   "IV-VI only" but actually contains:
#       type 1:   1
#       type 3: 354
#       type 4: 486
#       type 5: 428
#       type 6: 384
#   We keep the real values; GAN/equity work focuses on types 4-6.
#
#   Countries: Madagascar 985, Guinea 384, Malawi 261, Tanzania 23.
#   Age range: 0-97 (paediatric-focused, some adults).
#
# All 4 PASSION conditions are infectious/inflammatory and do not overlap the
# HAM10000 cancer/lesion classes, so they are added as new classes (union
# schema) rather than collapsed.
# ----------------------------------------------------------------------------
PASSION_MAP = {
    # Superficial fungal / dermatophyte infection — clinically "tinea".
    "fungal": "tinea_infection",
    # Direct match.
    "scabies": "scabies",
    # Atopic / contact dermatitis presents as eczema.
    "eczema": "eczema_dermatitis",
    # Heterogeneous catch-all for unclassified conditions -> NTD/other bucket.
    "others": "other_ntd",
}

# ----------------------------------------------------------------------------
# Merged HAM10000 (7) + PASSION (4) union taxonomy — 11 classes.
# Indices 0-6 are identical to the HAM10000 7-class set; 7-10 are the PASSION
# infectious/inflammatory additions.
# ----------------------------------------------------------------------------
MERGED_11CLASSES = HAM10000_7CLASSES + [
    "tinea_infection",
    "scabies",
    "eczema_dermatitis",
    "other_ntd",
]

CLASS_TO_IDX_11 = {name: idx for idx, name in enumerate(MERGED_11CLASSES)}

TRIAGE_LEVEL_11 = {
    **TRIAGE_LEVEL_7,
    "tinea_infection": TREAT_LOCALLY,
    "scabies": TREAT_LOCALLY,
    "eczema_dermatitis": MONITOR,
    "other_ntd": URGENT_REFERRAL,
}

# Registry of source -> (label_map, class_to_idx, triage_level).
_SOURCE_REGISTRY = {
    "fitzpatrick17k": (FITZPATRICK17K_MAP, CLASS_TO_IDX, TRIAGE_LEVEL),
    "ham10000": (HAM10000_MAP, CLASS_TO_IDX, TRIAGE_LEVEL),
    "ham10000_7class": (HAM10000_7CLASS_MAP, CLASS_TO_IDX_7, TRIAGE_LEVEL_7),
    # Merged 11-class union: HAM10000 keeps its native 7 codes, mapped into the
    # 11-class index space (indices 0-6 unchanged).
    "ham10000_11class": (HAM10000_7CLASS_MAP, CLASS_TO_IDX_11, TRIAGE_LEVEL_11),
    "passion": (PASSION_MAP, CLASS_TO_IDX_11, TRIAGE_LEVEL_11),
}


def harmonise_label(raw_label, source):
    """Map a raw dataset label onto the appropriate taxonomy.

    Args:
        raw_label: The raw label string from the source dataset.
        source: One of ``"fitzpatrick17k"`` / ``"ham10000"`` (12-class),
            ``"ham10000_7class"`` (HAM10000-only 7-class), or the merged
            11-class union sources ``"ham10000_11class"`` and ``"passion"``.

    Returns:
        tuple: ``(harmonised_id, class_idx, triage_level)``.

    Raises:
        ValueError: If the source or the label is not recognised.
    """
    if source not in _SOURCE_REGISTRY:
        raise ValueError(
            f"Unrecognised source {source!r}; "
            f"expected one of {sorted(_SOURCE_REGISTRY)}."
        )

    label_map, idx_map, triage_map = _SOURCE_REGISTRY[source]
    key = raw_label.strip().lower()
    if key not in label_map:
        raise ValueError(
            f"Unrecognised {source} label {raw_label!r}."
        )

    harmonised_id = label_map[key]
    return harmonised_id, idx_map[harmonised_id], triage_map[harmonised_id]
