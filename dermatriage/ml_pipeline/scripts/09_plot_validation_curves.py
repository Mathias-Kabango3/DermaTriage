#!/usr/bin/env python
"""Replot validation curves from the real per-epoch logs in the notebooks.

Training ran on Kaggle and wrote no history file; the surviving record is the
stdout captured in the committed notebooks. This script parses it back and
writes report-quality figures to outputs/figures/.

Run from the ml_pipeline/ directory:
    python scripts/09_plot_validation_curves.py
"""

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tests._history import (  # noqa: E402
    overfitting_report,
    parse_accuracy_history,
    parse_loss_and_accuracy_history,
)

FIGURES = ROOT / "outputs" / "figures"
FINAL_MODEL = "EfficientNet-B0"


def plot_five_class():
    """Accuracy curves for the 5-class run (this run logged accuracy only)."""
    hist = parse_accuracy_history("experiment5.ipynb")
    if not hist:
        print("No 5-class history found; skipping.")
        return

    fig, axes = plt.subplots(1, len(hist), figsize=(6.5 * len(hist), 4.6))
    if len(hist) == 1:
        axes = [axes]

    for ax, (model, h) in zip(axes, hist.items()):
        rep = overfitting_report(h["train_acc"], h["val_acc"])
        ax.plot(h["epoch"], h["train_acc"], "-o", ms=3, label="Train Acc")
        ax.plot(h["epoch"], h["val_acc"], "-o", ms=3, label="Val Acc")
        ax.axvline(rep["best_epoch"], ls="--", lw=1, color="grey")
        ax.annotate(
            f"best val {rep['best_val']:.3f}\n(epoch {rep['best_epoch']})",
            xy=(rep["best_epoch"], rep["best_val"]),
            xytext=(6, -34), textcoords="offset points", fontsize=8,
            arrowprops=dict(arrowstyle="->", lw=0.8, color="grey"),
        )
        role = "final model" if model == FINAL_MODEL else "rejected"
        ax.set_title(f"5-class — {model} ({role})\n"
                     f"gap at best {rep['gap_at_best']:+.3f}, "
                     f"val drop from peak {rep['val_drop_from_peak']:.3f}")
        ax.set_xlabel("Epoch")
        ax.set_ylabel("Accuracy")
        ax.grid(alpha=0.3)
        ax.legend(loc="lower right")

    fig.tight_layout()
    out = FIGURES / "5class_validation_curves.png"
    fig.savefig(out, dpi=150)
    print(f"wrote {out}")


def plot_e2_contrast():
    """E2's loss+accuracy curves — the documented overfitting contrast case."""
    h = parse_loss_and_accuracy_history("experiment_2_extended.ipynb")
    if not h["epoch"]:
        print("No E2 history found; skipping.")
        return

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(13, 4.6))
    a1.plot(h["epoch"], h["train_loss"], "-o", ms=3, label="Train Loss")
    a1.plot(h["epoch"], h["val_loss"], "-o", ms=3, label="Val Loss")
    a1.set_title("E2 (4-class, PASSION only) — Loss\nval loss rises: overfitting")
    a1.set_xlabel("Epoch"); a1.set_ylabel("Loss")
    a1.grid(alpha=0.3); a1.legend()

    a2.plot(h["epoch"], h["train_acc"], "-o", ms=3, label="Train Acc")
    a2.plot(h["epoch"], h["val_acc"], "-o", ms=3, label="Val Acc")
    gap = h["train_acc"][-1] - h["val_acc"][-1]
    a2.set_title(f"E2 — Accuracy\nfinal train-val gap {gap:+.3f}")
    a2.set_xlabel("Epoch"); a2.set_ylabel("Accuracy")
    a2.grid(alpha=0.3); a2.legend()

    fig.tight_layout()
    out = FIGURES / "e2_overfitting_contrast.png"
    fig.savefig(out, dpi=150)
    print(f"wrote {out}")


def main():
    FIGURES.mkdir(parents=True, exist_ok=True)
    plot_five_class()
    plot_e2_contrast()


if __name__ == "__main__":
    main()
