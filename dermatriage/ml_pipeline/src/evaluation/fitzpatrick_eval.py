"""Fitzpatrick-stratified accuracy evaluation and plotting."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import torch  # noqa: E402

from ..utils.logger import get_logger  # noqa: E402

logger = get_logger(__name__)


@torch.no_grad()
def evaluate_fitzpatrick_stratified(model, loader, device):
    """Accuracy broken down by Fitzpatrick skin type.

    Uses the per-sample ``fitzpatrick`` field from each batch.

    Returns:
        dict: ``{fitzpatrick_type: accuracy}`` sorted by type.
    """
    model.eval()
    correct = {}
    total = {}

    for batch in loader:
        images = batch["image"].to(device, non_blocking=True)
        labels = batch["label"].to(device, non_blocking=True)
        fitz = batch["fitzpatrick"]

        preds = model(images).argmax(dim=1)
        hit = (preds == labels).cpu()
        for ft, is_correct in zip(fitz.tolist(), hit.tolist()):
            total[ft] = total.get(ft, 0) + 1
            correct[ft] = correct.get(ft, 0) + int(is_correct)

    accuracies = {ft: correct[ft] / total[ft] for ft in sorted(total)}
    logger.info("Fitzpatrick-stratified accuracy: %s",
                {k: round(v, 4) for k, v in accuracies.items()})
    return accuracies


def plot_fitzpatrick_accuracy(accuracies, output_path):
    """Bar chart of accuracy across Fitzpatrick types, saved as PNG."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    types = sorted(accuracies)
    values = [accuracies[t] for t in types]
    labels = [f"Type {t}" for t in types]

    fig, ax = plt.subplots(figsize=(6, 4))
    bars = ax.bar(labels, values, color="#4C72B0")
    ax.set_ylim(0, 1)
    ax.set_ylabel("Accuracy")
    ax.set_title("Accuracy by Fitzpatrick Skin Type")
    for bar, val in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2, val + 0.01,
            f"{val:.3f}", ha="center", va="bottom", fontsize=9,
        )
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)
    logger.info("Saved Fitzpatrick accuracy chart to %s", output_path)
