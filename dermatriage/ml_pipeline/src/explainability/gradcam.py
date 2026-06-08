"""Grad-CAM explainability for the skin-disease classifier.

Wraps the ``pytorch-grad-cam`` library to produce class-activation heatmaps
overlaid on the input image, so clinicians can see which regions drove a
prediction.
"""

from pathlib import Path

import numpy as np
import torch
from PIL import Image
from pytorch_grad_cam import GradCAM
from pytorch_grad_cam.utils.image import show_cam_on_image
from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget

from ..data.dataset import IMAGENET_MEAN, IMAGENET_STD
from ..utils.logger import get_logger

logger = get_logger(__name__)


def _to_rgb_float(original_image_np):
    """Coerce an image array to float32 RGB in [0, 1] for overlay."""
    img = np.asarray(original_image_np)
    if img.dtype != np.float32 and img.dtype != np.float64:
        img = img.astype(np.float32)
    if img.max() > 1.0:  # assume 0-255 input
        img = img / 255.0
    return np.ascontiguousarray(img.astype(np.float32))


def generate_gradcam(model, input_tensor, target_class, target_layer, original_image_np):
    """Generate a Grad-CAM overlay for a single image.

    Args:
        model: The classifier.
        input_tensor: Preprocessed input, shape (1, C, H, W) or (C, H, W).
        target_class: Class index to explain.
        target_layer: Conv layer whose activations Grad-CAM uses.
        original_image_np: The original image as an HxWx3 array (uint8 or float).

    Returns:
        np.ndarray: uint8 RGB overlay (heatmap blended onto the image).
    """
    if input_tensor.dim() == 3:
        input_tensor = input_tensor.unsqueeze(0)

    rgb = _to_rgb_float(original_image_np)
    targets = [ClassifierOutputTarget(target_class)]

    with GradCAM(model=model, target_layers=[target_layer]) as cam:
        grayscale_cam = cam(input_tensor=input_tensor, targets=targets)[0]

    overlay = show_cam_on_image(rgb, grayscale_cam, use_rgb=True)
    return overlay  # uint8 RGB


def save_gradcam_overlay(overlay_np, output_path):
    """Save a Grad-CAM overlay array as a PNG."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(overlay_np).save(output_path)
    logger.info("Saved Grad-CAM overlay to %s", output_path)


def _denormalise(image_tensor):
    """Undo ImageNet normalisation -> HxWx3 float32 in [0, 1]."""
    mean = torch.tensor(IMAGENET_MEAN).view(3, 1, 1)
    std = torch.tensor(IMAGENET_STD).view(3, 1, 1)
    img = (image_tensor.cpu() * std + mean).clamp(0.0, 1.0)
    return img.permute(1, 2, 0).numpy().astype(np.float32)


def batch_generate_gradcam(
    model, loader, target_layer, output_dir, n_samples=20, device="cpu"
):
    """Generate and save Grad-CAM overlays for a sample of inputs.

    Prefers one sample per class (for class coverage), then fills the remaining
    slots with extra samples until ``n_samples`` overlays have been saved.

    Args:
        model: The classifier.
        loader: DataLoader yielding ``{image, label, ...}`` batches.
        target_layer: Conv layer for Grad-CAM.
        output_dir: Directory to write the overlay PNGs into.
        n_samples: Number of overlays to produce.
        device: Torch device.

    Returns:
        int: Number of overlays written.
    """
    model.eval().to(device)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Collect one sample per class first, plus a pool of extras.
    per_class = {}
    extras = []
    for batch in loader:
        images = batch["image"]
        labels = batch["label"]
        for img, label in zip(images, labels):
            c = int(label)
            if c not in per_class:
                per_class[c] = img
            elif len(extras) < n_samples:
                extras.append(img)
        if len(per_class) >= n_samples and len(extras) >= n_samples:
            break

    selected = list(per_class.values())[:n_samples]
    for img in extras:
        if len(selected) >= n_samples:
            break
        selected.append(img)

    saved = 0
    for img in selected:
        input_tensor = img.unsqueeze(0).to(device)
        with torch.no_grad():
            pred_class = int(model(input_tensor).argmax(dim=1).item())

        original = _denormalise(img)
        overlay = generate_gradcam(
            model, input_tensor, pred_class, target_layer, original
        )
        save_gradcam_overlay(
            overlay, output_dir / f"gradcam_{saved:02d}_class{pred_class}.png"
        )
        saved += 1

    logger.info("Generated %d Grad-CAM overlays in %s", saved, output_dir)
    return saved
