#!/usr/bin/env python
"""Build and split the merged HAM10000 + PASSION manifest (11-class union).

Schema (see src/data/harmonise_labels.py):
    indices 0-6  HAM10000 native classes (mel, nv, bcc, akiec, bkl, df, vasc)
    indices 7-10 PASSION classes (tinea_infection, scabies, eczema_dermatitis,
                 other_ntd)

Steps:
    1. Build the HAM10000 DataFrame from HAM10000_metadata.csv (fitzpatrick=-1).
    2. Build the PASSION DataFrame from label.csv (real Fitzpatrick labels).
    3. Merge and split 80/10/10 at the patient/lesion level (group by lesion for
       HAM10000, by subject for PASSION) to prevent leakage.
    4. Save data/processed/{train,val,test}/manifest.csv and report stats.

Either source may be absent on disk; whatever is present is processed.

Run from the ml_pipeline/ directory:
    python scripts/02_preprocess.py --config config.yaml
"""

import argparse
import sys
from pathlib import Path

import pandas as pd
from sklearn.model_selection import GroupShuffleSplit

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.harmonise_labels import (  # noqa: E402
    CLASS_TO_IDX_11,
    HAM10000_7CLASS_MAP,
    PASSION_MAP,
)
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)

GAN_TARGET_THRESHOLD = 50  # classes below this image count are flagged for GAN

MANIFEST_COLUMNS = [
    "image_path",
    "label_idx",
    "fitzpatrick_type",
    "source",
    "is_synthetic",
]

# HAM10000 layout.
HAM_METADATA_FILE = "HAM10000_metadata.csv"
HAM_IMAGE_DIRS = ["HAM10000_images_part_1", "HAM10000_images_part_2"]
# PASSION layout (confirmed by inspecting the dataset).
PASSION_METADATA_FILE = "label.csv"
PASSION_IMAGE_DIR = "images"


def _find_ham_image(ham_root, image_id):
    for sub in HAM_IMAGE_DIRS:
        candidate = ham_root / sub / f"{image_id}.jpg"
        if candidate.exists():
            return candidate.resolve()
    flat = ham_root / f"{image_id}.jpg"
    return flat.resolve() if flat.exists() else None


def build_ham10000_dataframe(cfg):
    """HAM10000 -> 11-class rows (fitzpatrick_type = -1, no skin-type labels)."""
    ham_root = Path(cfg["data"]["ham10000_path"]) if cfg["data"].get(
        "ham10000_path"
    ) else None
    if ham_root is None:
        return pd.DataFrame()
    metadata_path = ham_root / HAM_METADATA_FILE
    if not metadata_path.exists():
        logger.warning("HAM10000 metadata not found at %s — skipping HAM10000.",
                       metadata_path)
        return pd.DataFrame()

    meta = pd.read_csv(metadata_path)
    rows = []
    missing = 0
    for _, row in meta.iterrows():
        dx = str(row["dx"]).strip().lower()
        if dx not in HAM10000_7CLASS_MAP:
            continue
        label_idx = CLASS_TO_IDX_11[HAM10000_7CLASS_MAP[dx]]
        image_path = _find_ham_image(ham_root, str(row["image_id"]))
        if image_path is None:
            missing += 1
            continue
        # Lesion-level grouping (metadata ships a lesion_id column).
        lesion = (
            str(row["lesion_id"])
            if "lesion_id" in row and pd.notna(row["lesion_id"])
            else str(row["image_id"]).rpartition("_")[0] or str(row["image_id"])
        )
        rows.append(
            {
                "image_path": str(image_path),
                "label_idx": label_idx,
                "fitzpatrick_type": -1,
                "source": "ham10000",
                "is_synthetic": False,
                "group": f"ham10000:{lesion}",
            }
        )
    if missing:
        logger.warning("HAM10000: %d images missing on disk", missing)
    logger.info("HAM10000: %d images", len(rows))
    return pd.DataFrame(rows)


def build_passion_dataframe(cfg):
    """PASSION -> 11-class rows with real Fitzpatrick labels, grouped by patient."""
    passion_root = Path(cfg["data"]["passion_path"]) if cfg["data"].get(
        "passion_path"
    ) else None
    if passion_root is None:
        return pd.DataFrame()
    metadata_path = passion_root / PASSION_METADATA_FILE
    image_dir = passion_root / PASSION_IMAGE_DIR
    if not metadata_path.exists():
        logger.warning("PASSION metadata not found at %s — skipping PASSION.",
                       metadata_path)
        return pd.DataFrame()

    meta = pd.read_csv(metadata_path).set_index("subject_id")
    rows = []
    unmatched = 0
    unknown_dx = 0
    for image_path in sorted(image_dir.glob("*.jpg")):
        subject = image_path.stem.rpartition("_")[0] or image_path.stem
        if subject not in meta.index:
            unmatched += 1
            continue
        record = meta.loc[subject]
        diagnosis = str(record["conditions_PASSION"]).strip().lower()
        if diagnosis not in PASSION_MAP:
            unknown_dx += 1
            continue
        label_idx = CLASS_TO_IDX_11[PASSION_MAP[diagnosis]]
        rows.append(
            {
                "image_path": str(image_path.resolve()),
                "label_idx": label_idx,
                "fitzpatrick_type": int(record["fitzpatrick"]),
                "source": "passion",
                "is_synthetic": False,
                "group": f"passion:{subject}",  # patient-level grouping
            }
        )
    if unmatched:
        logger.warning("PASSION: %d images had no metadata row", unmatched)
    if unknown_dx:
        logger.warning("PASSION: %d images had an unmapped diagnosis", unknown_dx)
    logger.info("PASSION: %d images", len(rows))
    return pd.DataFrame(rows)


def split_dataframe(df, splits, seed=42):
    """Group-aware 80/10/10 split (no group spans two splits)."""
    groups = df["group"].values
    gss_test = GroupShuffleSplit(
        n_splits=1, test_size=splits["test"], random_state=seed
    )
    trainval_idx, test_idx = next(gss_test.split(df, groups=groups))
    trainval = df.iloc[trainval_idx].reset_index(drop=True)
    test = df.iloc[test_idx].reset_index(drop=True)

    val_rel = splits["val"] / (splits["train"] + splits["val"])
    gss_val = GroupShuffleSplit(n_splits=1, test_size=val_rel, random_state=seed)
    train_idx, val_idx = next(
        gss_val.split(trainval, groups=trainval["group"].values)
    )
    return {
        "train": trainval.iloc[train_idx].reset_index(drop=True),
        "val": trainval.iloc[val_idx].reset_index(drop=True),
        "test": test,
    }


def report_statistics(df, splits, class_names, dark_types):
    """Print merged dataset statistics and GAN-candidate flags."""
    total = len(df)
    logger.info("=" * 64)
    logger.info("Merged dataset: %d images", total)

    logger.info("Images by source:")
    for source, count in df["source"].value_counts().items():
        logger.info("  %-10s %d", source, count)

    logger.info("Per-class counts (merged):")
    counts = df["label_idx"].value_counts()
    gan_candidates = []
    for idx in range(len(class_names)):
        c = int(counts.get(idx, 0))
        flag = ""
        if c < GAN_TARGET_THRESHOLD:
            flag = "  <-- underrepresented (GAN candidate)"
            gan_candidates.append(class_names[idx])
        logger.info("  %2d %-22s %5d%s", idx, class_names[idx], c, flag)

    logger.info("Fitzpatrick type distribution:")
    for ft, c in df["fitzpatrick_type"].value_counts().sort_index().items():
        tag = "  (dark skin)" if ft in dark_types else ""
        label = "unlabelled" if ft == -1 else f"type {ft}"
        logger.info("  %-12s %5d%s", label, int(c), tag)

    dark = df[df["fitzpatrick_type"].isin(dark_types)]
    logger.info("Dark-skin (IV-VI) images total: %d", len(dark))
    logger.info("Dark-skin (IV-VI) per split:")
    for name, sdf in splits.items():
        d = sdf[sdf["fitzpatrick_type"].isin(dark_types)]
        logger.info("  %-5s %d", name, len(d))

    if gan_candidates:
        logger.warning("GAN synthesis candidates (<%d images): %s",
                       GAN_TARGET_THRESHOLD, ", ".join(gan_candidates))


def main():
    parser = argparse.ArgumentParser(
        description="Preprocess HAM10000 + PASSION into 11-class manifests."
    )
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    class_names = cfg["data"]["class_names"]
    dark_types = cfg["data"]["fitzpatrick_dark_types"]
    processed_root = Path(cfg["data"]["processed_path"])

    frames = [build_ham10000_dataframe(cfg), build_passion_dataframe(cfg)]
    frames = [f for f in frames if not f.empty]
    if not frames:
        raise RuntimeError(
            "No data found for any source. Check ham10000_path / passion_path."
        )
    merged = pd.concat(frames, ignore_index=True)

    splits = split_dataframe(merged, cfg["data"]["splits"])
    report_statistics(merged, splits, class_names, dark_types)

    logger.info("=" * 64)
    for split_name, split_df in splits.items():
        out_dir = processed_root / split_name
        out_dir.mkdir(parents=True, exist_ok=True)
        split_df[MANIFEST_COLUMNS].to_csv(out_dir / "manifest.csv", index=False)
        logger.info("%-5s split: %d images (%d groups)",
                    split_name, len(split_df), split_df["group"].nunique())

    logger.info("Preprocessing complete (HAM10000 + PASSION, 11 classes).")


if __name__ == "__main__":
    main()
