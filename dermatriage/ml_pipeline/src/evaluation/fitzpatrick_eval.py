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

    Uses the per-sample ``fitzpatrick`` field from each batch. Samples with
    ``fitzpatrick == -1`` (no skin-type label, e.g. HAM10000) are skipped.

    Returns:
        dict: ``{fitzpatrick_type: accuracy}`` sorted by type, or an empty dict
        if no labelled samples are present.
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
            if ft == -1:
                continue  # no Fitzpatrick label for this sample
            total[ft] = total.get(ft, 0) + 1
            correct[ft] = correct.get(ft, 0) + int(is_correct)

    if not total:
        logger.warning(
            "No Fitzpatrick labels in this dataset. Fitzpatrick-stratified "
            "evaluation skipped. Will be enabled when Fitzpatrick17k is added."
        )
        return {}

    accuracies = {ft: correct[ft] / total[ft] for ft in sorted(total)}
    logger.info("Fitzpatrick-stratified accuracy: %s",
                {k: round(v, 4) for k, v in accuracies.items()})
    return accuracies


@torch.no_grad()
def evaluate_by_source(model, loader, device):
    """Accuracy broken down by dataset source (e.g. ham10000 vs passion).

    Surfaces whether the model performs differently across datasets, which can
    reveal distribution shift between the cancer-focused HAM10000 images and the
    tropical/dark-skin PASSION images.

    Returns:
        dict: ``{source: accuracy}`` sorted by source name.
    """
    model.eval()
    correct = {}
    total = {}

    for batch in loader:
        images = batch["image"].to(device, non_blocking=True)
        labels = batch["label"].to(device, non_blocking=True)
        sources = batch.get("source", ["unknown"] * labels.size(0))

        preds = model(images).argmax(dim=1)
        hit = (preds == labels).cpu()
        for src, is_correct in zip(list(sources), hit.tolist()):
            total[src] = total.get(src, 0) + 1
            correct[src] = correct.get(src, 0) + int(is_correct)

    accuracies = {s: correct[s] / total[s] for s in sorted(total)}
    logger.info("Accuracy by source: %s",
                {k: round(v, 4) for k, v in accuracies.items()})
    return accuracies


def plot_fitzpatrick_accuracy(accuracies, output_path, dark_types=(4, 5, 6)):
    """Bar chart of accuracy across all Fitzpatrick types present.

    Dark skin types (``dark_types``, default IV-VI) are drawn in a distinct
    colour to highlight the equity-critical groups.
    """
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if not accuracies:
        logger.warning("No Fitzpatrick accuracies to plot; skipping chart.")
        return

    types = sorted(accuracies)
    values = [accuracies[t] for t in types]
    labels = [f"Type {t}" for t in types]
    colors = ["#C44E52" if t in dark_types else "#4C72B0" for t in types]

    fig, ax = plt.subplots(figsize=(7, 4))
    bars = ax.bar(labels, values, color=colors)
    ax.set_ylim(0, 1)
    ax.set_ylabel("Accuracy")
    ax.set_title("Accuracy by Fitzpatrick Skin Type")
    for bar, val in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2, val + 0.01,
            f"{val:.3f}", ha="center", va="bottom", fontsize=9,
        )
    # Legend explaining the dark-skin highlight.
    from matplotlib.patches import Patch
    ax.legend(
        handles=[
            Patch(color="#4C72B0", label="Type I-III"),
            Patch(color="#C44E52", label=f"Type {'/'.join(map(str, dark_types))} (dark)"),
        ],
        loc="lower right", fontsize=8,
    )
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)
    logger.info("Saved Fitzpatrick accuracy chart to %s", output_path)
