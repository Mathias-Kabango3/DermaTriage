"""Model checkpoint save/load helpers."""

from pathlib import Path

import torch


def save_checkpoint(model, optimizer, epoch, metrics, path):
    """Save model + optimizer state, epoch and metrics to ``path``.

    Parent directories are created if they do not exist.

    Args:
        model: torch.nn.Module whose state_dict is saved.
        optimizer: torch.optim.Optimizer whose state_dict is saved.
        epoch: Current epoch number.
        metrics: Dict of metrics to persist alongside the weights.
        path: Destination file path.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": optimizer.state_dict(),
            "epoch": epoch,
            "metrics": metrics,
        },
        path,
    )


def load_checkpoint(model, optimizer, path, device):
    """Load a checkpoint and restore model/optimizer state in place.

    Args:
        model: Module to load weights into.
        optimizer: Optimizer to restore state into. May be ``None`` to skip.
        path: Checkpoint file path.
        device: Device to map the loaded tensors onto.

    Returns:
        tuple: ``(epoch, metrics)`` from the checkpoint.
    """
    checkpoint = torch.load(path, map_location=device)
    model.load_state_dict(checkpoint["model_state_dict"])
    if optimizer is not None and checkpoint.get("optimizer_state_dict") is not None:
        optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
    return checkpoint["epoch"], checkpoint["metrics"]
