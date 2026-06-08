#!/usr/bin/env python
"""Distill the EfficientNet-B4 teacher into a MobileNetV3-Small student.

Run from the ml_pipeline/ directory:
    python scripts/05_distill_student.py --config config.yaml
"""

import argparse
import sys
from pathlib import Path

import torch

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.distillation.distill import distill_student  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger, init_wandb  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Distill the DermaTriage student.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    parser.add_argument(
        "--no-wandb", action="store_true", help="Disable Weights & Biases logging."
    )
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info("Distilling student on %s", device)

    run = None
    if not args.no_wandb:
        run = init_wandb(cfg, job_type="distill_student")

    try:
        summary = distill_student(cfg, device, run=run)
        if run is not None:
            run.summary.update(
                {
                    "best_val_accuracy": summary["best_val_accuracy"],
                    "best_epoch": summary["best_epoch"],
                }
            )
    finally:
        if run is not None:
            run.finish()

    logger.info(
        "Distillation done. Best student val accuracy %.4f at epoch %d (%s)",
        summary["best_val_accuracy"],
        summary["best_epoch"],
        summary["best_checkpoint"],
    )


if __name__ == "__main__":
    main()
