"""Classification metrics and confusion-matrix plotting."""

import matplotlib

matplotlib.use("Agg")  # headless backend for saving PNGs
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import seaborn as sns  # noqa: E402
import torch  # noqa: E402
from sklearn.metrics import confusion_matrix, f1_score  # noqa: E402

from ..utils.logger import get_logger  # noqa: E402

logger = get_logger(__name__)


@torch.no_grad()
def _collect_predictions(model, loader, device):
    """Run the model over a loader, returning (labels, preds) arrays."""
    model.eval()
    all_labels = []
    all_preds = []
    for batch in loader:
        images = batch["image"].to(device, non_blocking=True)
        labels = batch["label"]
        logits = model(images)
        preds = logits.argmax(dim=1).cpu()
        all_labels.append(labels)
        all_preds.append(preds)
    return (
        torch.cat(all_labels).numpy(),
        torch.cat(all_preds).numpy(),
    )


@torch.no_grad()
def compute_top1_accuracy(model, loader, device):
    """Top-1 accuracy over the loader."""
    labels, preds = _collect_predictions(model, loader, device)
    acc = float((labels == preds).mean()) if len(labels) else 0.0
    logger.info("Top-1 accuracy: %.4f", acc)
    return acc


@torch.no_grad()
def compute_per_class_f1(model, loader, num_classes, device):
    """Per-class F1 score as ``{class_idx: f1}``."""
    labels, preds = _collect_predictions(model, loader, device)
    f1 = f1_score(
        labels, preds, labels=list(range(num_classes)),
        average=None, zero_division=0,
    )
    return {idx: float(score) for idx, score in enumerate(f1)}


@torch.no_grad()
def compute_confusion_matrix(model, loader, num_classes, device):
    """Confusion matrix of shape (num_classes, num_classes)."""
    labels, preds = _collect_predictions(model, loader, device)
    return confusion_matrix(labels, preds, labels=list(range(num_classes)))


def plot_confusion_matrix(cm, class_names, output_path):
    """Save a seaborn heatmap of the confusion matrix to ``output_path``."""
    from pathlib import Path

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(max(8, len(class_names)), max(6, len(class_names))))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=class_names,
        yticklabels=class_names,
        ax=ax,
    )
    ax.set_xlabel("Predicted")
    ax.set_ylabel("True")
    ax.set_title("Confusion Matrix")
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)
    logger.info("Saved confusion matrix to %s", output_path)
