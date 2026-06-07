"""Reproducibility helpers: seed every RNG used in the pipeline."""

import random

import numpy as np
import torch


def set_seed(seed=42):
    """Seed Python, NumPy and PyTorch RNGs for reproducible runs.

    Also forces cuDNN into deterministic mode at the cost of some speed.

    Args:
        seed: Integer seed applied to every RNG.
    """
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False
