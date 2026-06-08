"""Knowledge distillation: loss, training loop and (later) TFLite export."""

from . import distill, loss
from .distill import distill_student, validate_real_only
from .loss import DistillationLoss

__all__ = [
    "distill",
    "loss",
    "distill_student",
    "validate_real_only",
    "DistillationLoss",
]
