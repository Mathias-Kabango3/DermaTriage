"""Extract real per-epoch training history from saved notebook outputs.

Training ran on Kaggle GPUs and no history file was written; the only surviving
per-epoch record is the stdout captured in the committed notebooks. This module
parses that stdout back into structured history so the curves can be replotted
and audited rather than taken on trust.

Two log formats exist in this project:

* ``experiment5.ipynb`` (the 5-class run behind the deployed model)::

      [EfficientNet-B0] Ep 01 | tr_acc 0.722 | va_acc 0.826 OK

  Accuracy only — this run did not log loss.

* ``experiment_2*.ipynb`` / ``experiment_3*.ipynb`` (earlier experiments)::

      Epoch 01/50 | Train Loss: 1.0098 | Train Acc: 0.5573 | Val Loss: 1.1058 | Val Acc: 0.5251

  Loss and accuracy.
"""

import json
import re
from collections import defaultdict
from pathlib import Path

EXPERIMENTS = Path(__file__).resolve().parents[1] / "experiments"

_ACC_ONLY = re.compile(
    r"\[([^\]]+)\]\s*Ep\s*(\d+)\s*\|\s*tr_acc\s*([\d.]+)\s*\|\s*va_acc\s*([\d.]+)"
)
_LOSS_AND_ACC = re.compile(
    r"Epoch\s*(\d+)/(\d+)\s*\|\s*Train Loss:\s*([\d.]+)\s*\|\s*Train Acc:\s*([\d.]+)"
    r"\s*\|\s*Val Loss:\s*([\d.]+)\s*\|\s*Val Acc:\s*([\d.]+)"
)


def _stdout_lines(notebook):
    """Return every captured stdout/text line from a notebook, in order."""
    path = EXPERIMENTS / notebook
    if not path.exists():
        return []
    nb = json.loads(path.read_text())
    lines = []
    for cell in nb.get("cells", []):
        for out in cell.get("outputs", []):
            text = "".join(out.get("text", []) or [])
            if not text and "data" in out:
                text = "".join(out["data"].get("text/plain", []) or [])
            if text:
                lines.extend(text.splitlines())
    return lines


def parse_accuracy_history(notebook):
    """Parse ``[model] Ep NN | tr_acc X | va_acc Y`` logs.

    Returns:
        dict: model name -> {"epoch": [...], "train_acc": [...], "val_acc": [...]}
    """
    per = defaultdict(lambda: {"epoch": [], "train_acc": [], "val_acc": []})
    for line in _stdout_lines(notebook):
        m = _ACC_ONLY.search(line)
        if m:
            h = per[m.group(1)]
            h["epoch"].append(int(m.group(2)))
            h["train_acc"].append(float(m.group(3)))
            h["val_acc"].append(float(m.group(4)))
    return dict(per)


def parse_loss_and_accuracy_history(notebook):
    """Parse ``Epoch N/M | Train Loss ... Val Acc ...`` logs.

    Returns:
        dict with epoch / train_loss / train_acc / val_loss / val_acc lists.
    """
    h = {"epoch": [], "train_loss": [], "train_acc": [], "val_loss": [], "val_acc": []}
    for line in _stdout_lines(notebook):
        m = _LOSS_AND_ACC.search(line)
        if m:
            h["epoch"].append(int(m.group(1)))
            h["train_loss"].append(float(m.group(3)))
            h["train_acc"].append(float(m.group(4)))
            h["val_loss"].append(float(m.group(5)))
            h["val_acc"].append(float(m.group(6)))
    return h


def overfitting_report(train, val):
    """Summarise generalisation behaviour from train/val accuracy curves.

    The distinction that matters for a report is *harmful* overfitting (val
    accuracy peaks then declines) versus a stable train-val gap (the model
    memorises the training set but validation never degrades).

    Returns:
        dict of diagnostics.
    """
    best_i = max(range(len(val)), key=lambda i: val[i])
    peak = val[best_i]
    final = val[-1]
    return {
        "best_epoch": best_i + 1,
        "best_val": peak,
        "final_val": final,
        "val_drop_from_peak": peak - final,
        "gap_at_best": train[best_i] - peak,
        "final_gap": train[-1] - final,
        "val_improved": final > val[0],
        # Post-peak decline is the signature of harmful overfitting.
        "val_declining": (peak - final) > 0.02,
    }
