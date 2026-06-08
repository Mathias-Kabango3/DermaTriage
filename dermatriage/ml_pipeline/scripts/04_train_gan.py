#!/usr/bin/env python
"""Train the conditional WGAN-GP for dark-skin image augmentation.

Run from the ml_pipeline/ directory:
    python scripts/04_train_gan.py --config config.yaml
"""

import argparse
import sys
from pathlib import Path

import torch

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.gan.train_gan import train_wgan_gp  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger, init_wandb  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Train the DermaTriage WGAN-GP.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    parser.add_argument(
        "--no-wandb", action="store_true", help="Disable Weights & Biases logging."
    )
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info("Training WGAN-GP on %s", device)

    run = None
    if not args.no_wandb:
        run = init_wandb(cfg, job_type="train_gan")

    try:
        summary = train_wgan_gp(cfg, device)
        if run is not None:
            run.summary.update(
                {
                    "best_fid": summary["best_fid"],
                    "best_epoch": summary["best_epoch"],
                }
            )
    finally:
        if run is not None:
            run.finish()

    logger.info(
        "WGAN-GP done. Best FID %.4f at epoch %d (%s)",
        summary["best_fid"],
        summary["best_epoch"],
        summary["best_checkpoint"],
    )


if __name__ == "__main__":
    main()
