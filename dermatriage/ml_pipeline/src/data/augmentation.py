"""Merge real and synthetic manifests under a per-group synthetic cap."""

from pathlib import Path

import pandas as pd

from ..utils.logger import get_logger

logger = get_logger(__name__)

_GROUP_COLS = ["label_idx", "fitzpatrick_type"]
_MANIFEST_COLS = [
    "image_path",
    "label_idx",
    "fitzpatrick_type",
    "source",
    "is_synthetic",
]


def _max_synthetic(n_real, synthetic_ratio):
    """Largest synthetic count keeping synthetic/(real+synthetic) <= ratio.

    From ``s / (r + s) <= ratio``  =>  ``s <= ratio/(1-ratio) * r``.
    """
    if synthetic_ratio <= 0:
        return 0
    if synthetic_ratio >= 1:
        return None  # unbounded
    return int((synthetic_ratio / (1.0 - synthetic_ratio)) * n_real)


def merge_real_and_synthetic(
    real_manifest_path, synthetic_manifest_path, output_path, synthetic_ratio=0.30
):
    """Merge real + synthetic manifests, capping synthetic share per group.

    For every (label_idx, fitzpatrick_type) group, synthetic rows are sampled so
    they make up at most ``synthetic_ratio`` of that group's final total
    (default 30% synthetic : 70% real). The ``is_synthetic`` flag is set
    explicitly on both sides and the augmented manifest is written to
    ``output_path``.

    Args:
        real_manifest_path: CSV of real images.
        synthetic_manifest_path: CSV of synthetic images.
        output_path: Destination CSV.
        synthetic_ratio: Max synthetic fraction per group.

    Returns:
        pandas.DataFrame: The merged, capped manifest.
    """
    real = pd.read_csv(real_manifest_path)
    synthetic = pd.read_csv(synthetic_manifest_path)

    # Set flags explicitly rather than trusting the source files.
    real = real.copy()
    synthetic = synthetic.copy()
    real["is_synthetic"] = False
    synthetic["is_synthetic"] = True

    real_groups = {key: grp for key, grp in real.groupby(_GROUP_COLS)}
    synth_groups = {key: grp for key, grp in synthetic.groupby(_GROUP_COLS)}

    kept = [real]  # all real rows are kept as-is
    for key, synth_grp in synth_groups.items():
        n_real = len(real_groups.get(key, []))
        cap = _max_synthetic(n_real, synthetic_ratio)

        if cap is None:
            sampled = synth_grp
        elif cap <= 0:
            # No real images for this group -> cannot satisfy the cap.
            sampled = synth_grp.iloc[0:0]
        else:
            take = min(cap, len(synth_grp))
            sampled = synth_grp.sample(n=take, random_state=42)

        if len(sampled):
            kept.append(sampled)
        logger.info(
            "group %s: real=%d synthetic_available=%d synthetic_kept=%d",
            key, n_real, len(synth_grp), len(sampled),
        )

    merged = pd.concat(kept, ignore_index=True)
    merged = merged[_MANIFEST_COLS]

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    merged.to_csv(output_path, index=False)

    n_synth = int(merged["is_synthetic"].sum())
    logger.info(
        "Augmented manifest: %d total (%d real, %d synthetic) -> %s",
        len(merged), len(merged) - n_synth, n_synth, output_path,
    )
    return merged
