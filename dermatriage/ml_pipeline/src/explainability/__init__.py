"""Explainability: Grad-CAM class-activation overlays."""

from . import gradcam
from .gradcam import (
    batch_generate_gradcam,
    generate_gradcam,
    save_gradcam_overlay,
)

__all__ = [
    "gradcam",
    "batch_generate_gradcam",
    "generate_gradcam",
    "save_gradcam_overlay",
]
