"""Build manifest CSVs from a raw dataset directory.

Convention: each immediate subdirectory of ``dataset_root`` is a *raw* class
label and contains the images for that label, e.g.::

    dataset_root/
        eczema/            <- raw label
            img001.jpg
        tinea corporis/
            img002.jpg

Raw labels are mapped onto the 12 harmonised classes via
:func:`harmonise_label`. Fitzpatrick skin type is not generally encoded in the
folder layout; it defaults to ``-1`` (unknown) and is expected to be joined in
from dataset metadata during the data-prep step.
"""

import csv
from collections import Counter
from pathlib import Path

from ..utils.logger import get_logger
from .harmonise_labels import harmonise_label

logger = get_logger(__name__)

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff"}

MANIFEST_COLUMNS = [
    "image_path",
    "label_idx",
    "fitzpatrick_type",
    "source",
    "is_synthetic",
]


def build_manifest(dataset_root, source, output_csv, cfg):
    """Walk a raw dataset directory and write a harmonised manifest CSV.

    Args:
        dataset_root: Root directory whose subfolders are raw class labels.
        source: Source key passed to ``harmonise_label`` ("fitzpatrick17k"
            or "ham10000").
        output_csv: Destination path for the manifest CSV.
        cfg: Full pipeline config dict (currently unused for the walk, kept
            for signature consistency and future options).

    Returns:
        int: Number of rows written.
    """
    dataset_root = Path(dataset_root)
    output_csv = Path(output_csv)
    output_csv.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    skipped = Counter()
    class_counts = Counter()
    fitzpatrick_counts = Counter()

    for label_dir in sorted(p for p in dataset_root.iterdir() if p.is_dir()):
        raw_label = label_dir.name
        try:
            _, label_idx, _ = harmonise_label(raw_label, source)
        except ValueError:
            skipped[raw_label] += 1
            logger.warning("Skipping unrecognised raw label %r", raw_label)
            continue

        for image_path in sorted(label_dir.rglob("*")):
            if image_path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            fitzpatrick_type = -1  # unknown; joined from metadata later
            rows.append(
                {
                    "image_path": str(image_path),
                    "label_idx": label_idx,
                    "fitzpatrick_type": fitzpatrick_type,
                    "source": source,
                    "is_synthetic": False,
                }
            )
            class_counts[label_idx] += 1
            fitzpatrick_counts[fitzpatrick_type] += 1

    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=MANIFEST_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    _log_distribution(source, len(rows), class_counts, fitzpatrick_counts, skipped)
    return len(rows)


def _log_distribution(source, total, class_counts, fitzpatrick_counts, skipped):
    """Log class and per-Fitzpatrick-type distribution for a manifest."""
    logger.info("Manifest for %s: %d images", source, total)

    logger.info("Class distribution (label_idx -> count):")
    for label_idx in sorted(class_counts):
        logger.info("  class %2d : %d", label_idx, class_counts[label_idx])

    logger.info("Fitzpatrick type distribution (type -> count):")
    for ftype in sorted(fitzpatrick_counts):
        logger.info("  type %2d : %d", ftype, fitzpatrick_counts[ftype])

    if skipped:
        logger.warning(
            "Skipped %d unrecognised raw labels: %s",
            sum(skipped.values()),
            dict(skipped),
        )
