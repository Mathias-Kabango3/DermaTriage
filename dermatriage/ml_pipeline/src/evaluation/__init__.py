"""Evaluation: metrics, DVS, Fitzpatrick equity and bias audit."""

from . import bias_audit, dvs, fitzpatrick_eval, metrics
from .bias_audit import run_bias_audit
from .dvs import DVSInput, compute_dvs, compute_equity_score
from .fitzpatrick_eval import (
    evaluate_fitzpatrick_stratified,
    plot_fitzpatrick_accuracy,
)
from .metrics import (
    compute_confusion_matrix,
    compute_per_class_f1,
    compute_top1_accuracy,
    plot_confusion_matrix,
)

__all__ = [
    "bias_audit",
    "dvs",
    "fitzpatrick_eval",
    "metrics",
    "run_bias_audit",
    "DVSInput",
    "compute_dvs",
    "compute_equity_score",
    "evaluate_fitzpatrick_stratified",
    "plot_fitzpatrick_accuracy",
    "compute_confusion_matrix",
    "compute_per_class_f1",
    "compute_top1_accuracy",
    "plot_confusion_matrix",
]
