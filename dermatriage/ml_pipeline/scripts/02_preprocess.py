#!/usr/bin/env python
"""Build and split the HAM10000-only manifest (7 classes).

While Fitzpatrick17k access is pending we train on HAM10000 alone, keeping its
native 7 diagnostic classes. This script:

    1. Reads HAM10000_metadata.csv from cfg["data"]["ham10000_path"].
    2. Resolves each image across HAM10000_images_part_1/ and _part_2/.
    3. Maps the ``dx`` code to a 7-class label index.
    4. Performs a lesion-level 80/10/10 split (group by lesion to avoid leakage
       between duplicate images of the same lesion).
    5. Saves data/processed/{train,val,test}/manifest.csv and reports stats.

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
    CLASS_TO_IDX_7,
    HAM10000_7CLASS_MAP,
)
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)

METADATA_FILE = "HAM10000_metadata.csv"
IMAGE_DIRS = ["HAM10000_images_part_1", "HAM10000_images_part_2"]
MANIFEST_COLUMNS = [
    "image_path",
    "label_idx",
    "fitzpatrick_type",
    "source",
    "is_synthetic",
]


def _find_image(ham_root, image_id):
    """Locate ``<image_id>.jpg`` across the two HAM10000 image folders."""
    for sub in IMAGE_DIRS:
        candidate = ham_root / sub / f"{image_id}.jpg"
        if candidate.exists():
            return candidate.resolve()
    # Fall back to a flat layout (all images directly under ham_root).
    flat = ham_root / f"{image_id}.jpg"
    if flat.exists():
        return flat.resolve()
    return None


def _lesion_id(row):
    """Lesion-level grouping key.

    HAM10000 metadata ships a ``lesion_id`` column (e.g. ``HAM_0000118``) that
    groups duplicate images of the same lesion — the correct key to split on.
    If absent, fall back to the image_id prefix before the last underscore.
    """
    if "lesion_id" in row and pd.notna(row["lesion_id"]):
        return str(row["lesion_id"])
    stem = str(row["image_id"])
    head, _, tail = stem.rpartition("_")
    return head if head else stem


def build_ham10000_dataframe(cfg):
    """Build the HAM10000 manifest DataFrame from its metadata CSV."""
    ham_root = Path(cfg["data"]["ham10000_path"])
    metadata_path = ham_root / METADATA_FILE
    if not metadata_path.exists():
        raise FileNotFoundError(
            f"HAM10000 metadata not found at {metadata_path}. "
            f"Run scripts/01_download_data.sh first."
        )

    meta = pd.read_csv(metadata_path)
    logger.info("Read %d rows from %s", len(meta), metadata_path)

    rows = []
    missing_images = 0
    unknown_dx = 0
    for _, row in meta.iterrows():
        dx = str(row["dx"]).strip().lower()
        if dx not in HAM10000_7CLASS_MAP:
            unknown_dx += 1
            continue
        class_name = HAM10000_7CLASS_MAP[dx]
        label_idx = CLASS_TO_IDX_7[class_name]

        image_path = _find_image(ham_root, str(row["image_id"]))
        if image_path is None:
            missing_images += 1
            continue

        rows.append(
            {
                "image_path": str(image_path),
                "label_idx": label_idx,
                "fitzpatrick_type": -1,  # HAM10000 has no Fitzpatrick labels
                "source": "ham10000",
                "is_synthetic": False,
                "group": _lesion_id(row),
            }
        )

    if missing_images:
        logger.warning("%d images referenced in metadata were not found on disk",
                       missing_images)
    if unknown_dx:
        logger.warning("%d rows had an unrecognised dx code and were skipped",
                       unknown_dx)

    return pd.DataFrame(rows)


def split_dataframe(df, splits, seed=42):
    """Lesion-level 80/10/10 split grouped by the ``group`` column."""
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
    train = trainval.iloc[train_idx].reset_index(drop=True)
    val = trainval.iloc[val_idx].reset_index(drop=True)

    return {"train": train, "val": val, "test": test}


def report_statistics(df, class_names):
    """Print total images, per-class counts/percentages and imbalance warnings."""
    total = len(df)
    logger.info("=" * 60)
    logger.info("Total HAM10000 images: %d", total)
    logger.info("Per-class distribution:")
    counts = df["label_idx"].value_counts().sort_index()
    for idx in range(len(class_names)):
        count = int(counts.get(idx, 0))
        pct = (count / total * 100) if total else 0.0
        flag = "  <-- under 5%" if total and pct < 5.0 else ""
        logger.info("  %2d %-22s %5d (%5.1f%%)%s",
                    idx, class_names[idx], count, pct, flag)

    underrepresented = [
        class_names[idx]
        for idx in range(len(class_names))
        if total and (int(counts.get(idx, 0)) / total * 100) < 5.0
    ]
    if underrepresented:
        logger.warning(
            "Class imbalance: %s under 5%% of the dataset. Consider class "
            "weighting or resampling.",
            ", ".join(underrepresented),
        )


def main():
    parser = argparse.ArgumentParser(
        description="Preprocess HAM10000 into 7-class manifests."
    )
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    class_names = cfg["data"]["class_names"]
    processed_root = Path(cfg["data"]["processed_path"])

    df = build_ham10000_dataframe(cfg)
    if df.empty:
        raise RuntimeError("No HAM10000 images were resolved; check the data path.")

    report_statistics(df, class_names)

    splits = split_dataframe(df, cfg["data"]["splits"])

    logger.info("=" * 60)
    for split_name, split_df in splits.items():
        out_dir = processed_root / split_name
        out_dir.mkdir(parents=True, exist_ok=True)
        out_df = split_df[MANIFEST_COLUMNS]
        out_df.to_csv(out_dir / "manifest.csv", index=False)
        logger.info("%-5s split: %d images (%d lesions)",
                    split_name, len(split_df), split_df["group"].nunique())

    logger.info("Preprocessing complete (HAM10000, 7 classes).")


if __name__ == "__main__":
    main()
