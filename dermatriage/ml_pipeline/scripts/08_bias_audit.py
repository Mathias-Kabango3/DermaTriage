#!/usr/bin/env python
"""Run the Fitzpatrick fairness / bias audit on the distilled student.

Run from the ml_pipeline/ directory:
    python scripts/08_bias_audit.py --config config.yaml
"""

import argparse
import sys
from pathlib import Path

import torch

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataloader import build_dataloaders  # noqa: E402
from src.evaluation.bias_audit import run_bias_audit  # noqa: E402
from src.models.student import build_student  # noqa: E402
from src.utils.checkpoint import load_checkpoint  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402

logger = get_logger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Audit DermaTriage for bias.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # --- Load best student ---
    student = build_student(
        num_classes=cfg["data"]["num_classes"], pretrained=False
    ).to(device)
    ckpt_dir = Path(cfg["distillation"].get("checkpoint_dir", "models/student"))
    epoch, _ = load_checkpoint(
        student, None, ckpt_dir / "student_best.pt", device
    )
    logger.info("Loaded student (epoch %s)", epoch)

    # Audit on the held-out test split (real images).
    _, _, test_loader = build_dataloaders(
        cfg, batch_size=cfg["distillation"]["batch_size"]
    )

    report = run_bias_audit(student, test_loader, device, cfg)

    logger.info("=" * 60)
    logger.info("Bias audit complete.")
    logger.info("Model max disparity (IV-VI): %.4f",
                report["model"]["max_disparity"])
    logger.info("Baseline max disparity (IV-VI): %.4f",
                report["baseline_pretrained_mobilenetv3"]["max_disparity"])
    logger.info("Disparity reduction: %.4f", report["disparity_reduction"])


if __name__ == "__main__":
    main()
