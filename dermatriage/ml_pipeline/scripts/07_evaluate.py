#!/usr/bin/env python
"""Evaluate the distilled student and compute the Deployment Viability Score.

Reports top-1 accuracy, per-class F1, a confusion matrix, Fitzpatrick-stratified
accuracy and the DVS. Plots and a JSON metrics report are written to
``cfg["evaluation"]["metrics_output"]``.

Run from the ml_pipeline/ directory:
    python scripts/07_evaluate.py --config config.yaml
"""

import argparse
import json
import sys
import tempfile
from pathlib import Path

import torch

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataloader import build_dataloaders  # noqa: E402
from src.distillation.quantise import benchmark_inference  # noqa: E402
from src.evaluation.dvs import DVSInput, compute_dvs  # noqa: E402
from src.evaluation.fitzpatrick_eval import (  # noqa: E402
    evaluate_fitzpatrick_stratified,
    plot_fitzpatrick_accuracy,
)
from src.evaluation.metrics import (  # noqa: E402
    compute_confusion_matrix,
    compute_per_class_f1,
    compute_top1_accuracy,
    plot_confusion_matrix,
)
from src.models.student import build_student  # noqa: E402
from src.utils.checkpoint import load_checkpoint  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402

logger = get_logger(__name__)


def _model_size_mb(cfg, student):
    """Prefer the exported TFLite size; fall back to the torch state size."""
    tflite_path = Path(cfg["quantisation"]["tflite_output_path"])
    if tflite_path.exists():
        return tflite_path.stat().st_size / (1024 * 1024)
    with tempfile.NamedTemporaryFile(suffix=".pt", delete=True) as tmp:
        torch.save(student.state_dict(), tmp.name)
        return Path(tmp.name).stat().st_size / (1024 * 1024)


def main():
    parser = argparse.ArgumentParser(description="Evaluate the DermaTriage student.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    num_classes = cfg["data"]["num_classes"]
    class_names = cfg["data"]["class_names"]

    out_dir = Path(cfg["evaluation"]["metrics_output"])
    out_dir.mkdir(parents=True, exist_ok=True)

    # --- Load best student ---
    student = build_student(num_classes=num_classes, pretrained=False).to(device)
    ckpt_dir = Path(cfg["distillation"].get("checkpoint_dir", "models/student"))
    epoch, ckpt_metrics = load_checkpoint(
        student, None, ckpt_dir / "student_best.pt", device
    )
    logger.info("Loaded student (epoch %s)", epoch)

    # --- Test loader ---
    _, _, test_loader = build_dataloaders(
        cfg, batch_size=cfg["distillation"]["batch_size"]
    )

    # --- Core metrics ---
    top1 = compute_top1_accuracy(student, test_loader, device)
    per_class_f1 = compute_per_class_f1(student, test_loader, num_classes, device)
    cm = compute_confusion_matrix(student, test_loader, num_classes, device)
    plot_confusion_matrix(cm, class_names, out_dir / "confusion_matrix.png")

    fitz_acc = evaluate_fitzpatrick_stratified(student, test_loader, device)
    plot_fitzpatrick_accuracy(fitz_acc, out_dir / "fitzpatrick_accuracy.png")

    # --- Deployment metrics ---
    latency_mean, latency_std = benchmark_inference(
        student, image_size=cfg["data"]["image_size"], device="cpu"
    )
    size_mb = _model_size_mb(cfg, student)

    dvs_input = DVSInput(
        top1_accuracy=top1,
        latency_ms=latency_mean,
        model_size_mb=size_mb,
        fitzpatrick_accuracies=fitz_acc,
    )
    dvs = compute_dvs(dvs_input, cfg["evaluation"]["dvs_weights"])

    # --- Report ---
    report = {
        "top1_accuracy": top1,
        "top1_target": cfg["evaluation"]["top1_target"],
        "per_class_f1": {class_names[i]: per_class_f1[i] for i in range(num_classes)},
        "fitzpatrick_accuracies": fitz_acc,
        "latency_ms": {"mean": latency_mean, "std": latency_std},
        "model_size_mb": size_mb,
        "dvs": dvs,
    }
    with open(out_dir / "evaluation.json", "w") as f:
        json.dump(report, f, indent=2)

    logger.info("=" * 60)
    logger.info(
        "Top-1 accuracy: %.4f (target %.2f) -> %s",
        top1, cfg["evaluation"]["top1_target"],
        "MET" if top1 >= cfg["evaluation"]["top1_target"] else "BELOW",
    )
    logger.info("Latency: %.2f ms | Size: %.2f MB", latency_mean, size_mb)
    logger.info("Deployment Viability Score (DVS): %.4f", dvs)
    logger.info("Report written to %s", out_dir / "evaluation.json")


if __name__ == "__main__":
    main()
