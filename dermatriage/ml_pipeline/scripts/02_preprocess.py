#!/usr/bin/env python
"""Build, merge and split the harmonised dataset manifests.

Steps:
    1. Build per-source manifests (Fitzpatrick17k, HAM10000).
    2. Merge into a single DataFrame.
    3. Patient-level 80/10/10 split (grouped by image prefix to avoid leakage
       between an individual's images across splits).
    4. Save data/processed/{train,val,test}/manifest.csv.
    5. Print class + Fitzpatrick-type distributions per split.

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

from src.data.preprocessing import build_manifest  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)


def group_key(image_path):
    """Derive a patient/lesion group key from an image path.

    Both source datasets store multiple images per lesion/patient with a shared
    filename prefix and a trailing ``_<n>`` index. We strip that trailing index
    so all images of one lesion land in the same split.
    """
    stem = Path(image_path).stem
    head, _, tail = stem.rpartition("_")
    if head and tail.isdigit():
        return head
    return stem


def split_dataframe(df, splits, seed=42):
    """Patient-level 80/10/10 split grouped by ``group`` column.

    First peels off the test fraction, then splits the remainder into
    train/val while keeping every group entirely within one split.
    """
    groups = df["group"].values

    test_frac = splits["test"]
    gss_test = GroupShuffleSplit(n_splits=1, test_size=test_frac, random_state=seed)
    trainval_idx, test_idx = next(gss_test.split(df, groups=groups))
    trainval = df.iloc[trainval_idx].reset_index(drop=True)
    test = df.iloc[test_idx].reset_index(drop=True)

    # val fraction relative to the remaining train+val portion.
    val_rel = splits["val"] / (splits["train"] + splits["val"])
    gss_val = GroupShuffleSplit(n_splits=1, test_size=val_rel, random_state=seed)
    train_idx, val_idx = next(
        gss_val.split(trainval, groups=trainval["group"].values)
    )
    train = trainval.iloc[train_idx].reset_index(drop=True)
    val = trainval.iloc[val_idx].reset_index(drop=True)

    return {"train": train, "val": val, "test": test}


def log_split_distribution(split_name, df):
    """Print class and Fitzpatrick-type counts for a split."""
    logger.info("=== %s split: %d images ===", split_name, len(df))
    logger.info("Class distribution (label_idx -> count):")
    for label_idx, count in df["label_idx"].value_counts().sort_index().items():
        logger.info("  class %2d : %d", label_idx, count)
    logger.info("Fitzpatrick type distribution (type -> count):")
    for ftype, count in df["fitzpatrick_type"].value_counts().sort_index().items():
        logger.info("  type %2d : %d", ftype, count)


def main():
    parser = argparse.ArgumentParser(description="Preprocess DermaTriage data.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    data_cfg = cfg["data"]
    processed_root = Path(data_cfg["processed_path"])
    manifest_dir = processed_root / "_manifests"
    manifest_dir.mkdir(parents=True, exist_ok=True)

    # 1. Build per-source manifests.
    sources = {
        "fitzpatrick17k": data_cfg["fitzpatrick17k_path"],
        "ham10000": data_cfg["ham10000_path"],
    }
    frames = []
    for source, root in sources.items():
        out_csv = manifest_dir / f"{source}.csv"
        n = build_manifest(root, source, out_csv, cfg)
        logger.info("Built %s manifest: %d rows", source, n)
        frames.append(pd.read_csv(out_csv))

    # 2. Merge.
    merged = pd.concat(frames, ignore_index=True)
    logger.info("Merged manifest: %d total images", len(merged))

    # 3. Patient-level split (grouped by image prefix).
    merged["group"] = merged["image_path"].map(group_key)
    splits = split_dataframe(merged, data_cfg["splits"])

    # 4 & 5. Save and report.
    for split_name, split_df in splits.items():
        out_dir = processed_root / split_name
        out_dir.mkdir(parents=True, exist_ok=True)
        split_df = split_df.drop(columns=["group"])
        split_df.to_csv(out_dir / "manifest.csv", index=False)
        log_split_distribution(split_name, split_df)

    logger.info("Preprocessing complete.")


if __name__ == "__main__":
    main()
