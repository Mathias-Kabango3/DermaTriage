"""Fairness / bias audit across Fitzpatrick skin types."""

import json
from pathlib import Path

import torch

from ..models.student import build_student
from ..utils.logger import get_logger
from .fitzpatrick_eval import evaluate_fitzpatrick_stratified

logger = get_logger(__name__)


def _disparity(accuracies, types):
    """Max accuracy disparity (max - min) restricted to ``types`` present."""
    present = [accuracies[t] for t in types if t in accuracies]
    if len(present) < 2:
        return 0.0
    return max(present) - min(present)


def run_bias_audit(model, loader, device, cfg):
    """Audit Fitzpatrick fairness and compare against a non-distilled baseline.

    The baseline is a plain ImageNet-pretrained MobileNetV3-Small (no
    distillation, no fine-tuning) evaluated on the same loader — it shows how
    much the distillation + GAN-augmentation pipeline improved equity.

    Args:
        model: The distilled student to audit.
        loader: Evaluation DataLoader (real images).
        device: Torch device.
        cfg: Full pipeline config dict.

    Returns:
        dict: The audit report (also written to JSON).
    """
    dark_types = cfg["data"]["fitzpatrick_dark_types"]

    # --- Model under test ---
    model_acc = evaluate_fitzpatrick_stratified(model, loader, device)
    model_disparity = _disparity(model_acc, dark_types)

    # --- Baseline: pretrained MobileNetV3, no distillation ---
    baseline = build_student(
        num_classes=cfg["data"]["num_classes"], pretrained=True
    ).to(device)
    baseline_acc = evaluate_fitzpatrick_stratified(baseline, loader, device)
    baseline_disparity = _disparity(baseline_acc, dark_types)

    report = {
        "fitzpatrick_dark_types": dark_types,
        "model": {
            "fitzpatrick_accuracies": model_acc,
            "max_disparity": model_disparity,
        },
        "baseline_pretrained_mobilenetv3": {
            "fitzpatrick_accuracies": baseline_acc,
            "max_disparity": baseline_disparity,
        },
        "disparity_reduction": baseline_disparity - model_disparity,
    }

    logger.info(
        "Bias audit | model disparity %.4f | baseline disparity %.4f | "
        "reduction %.4f",
        model_disparity, baseline_disparity, report["disparity_reduction"],
    )

    # --- Persist ---
    out_dir = Path(cfg["evaluation"]["metrics_output"])
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "bias_audit.json"
    with open(out_path, "w") as f:
        json.dump(report, f, indent=2)
    logger.info("Saved bias audit to %s", out_path)

    return report
