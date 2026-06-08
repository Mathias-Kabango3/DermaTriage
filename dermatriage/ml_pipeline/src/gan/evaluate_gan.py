"""Evaluation and synthetic-image export for the conditional WGAN-GP.

Provides FID / Inception Score using torchvision's InceptionV3, plus helpers to
generate and export synthetic dark-skin images for under-represented
Fitzpatrick IV-VI + disease combinations.

Preprocessing conventions (important):
  * The generator emits images in [-1, 1] (Tanh output).
  * ``real_loader`` is assumed to yield ImageNet-normalised images, as produced
    by ``SkinDataset`` (mean/std normalisation). They are de-normalised back to
    [0, 1] before being fed to Inception.
Both real and fake images are then resized to 299x299 and normalised with the
ImageNet statistics that InceptionV3 expects.
"""

import csv
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import transforms
from torchvision.models import Inception_V3_Weights, inception_v3

try:
    from scipy import linalg
except ImportError:  # pragma: no cover
    linalg = None

from ..utils.logger import get_logger
from .generator import ConditionalGenerator  # noqa: F401  (type reference)
from .train_gan import build_condition_mapping

logger = get_logger(__name__)

# ImageNet stats used both to de-normalise real images and to normalise the
# Inception inputs.
_IMAGENET_MEAN = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1)
_IMAGENET_STD = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1)
_INCEPTION_SIZE = 299


# ----------------------------------------------------------------------------
# Inception backbone + preprocessing
# ----------------------------------------------------------------------------
def _load_inception(device, feature_mode):
    """Load a pretrained InceptionV3.

    Args:
        feature_mode: If True, the classifier is replaced with Identity so the
            model returns 2048-d pooled features (for FID). Otherwise it returns
            1000-class logits (for Inception Score).
    """
    model = inception_v3(weights=Inception_V3_Weights.IMAGENET1K_V1, aux_logits=True)
    if feature_mode:
        model.fc = nn.Identity()
    model.eval().to(device)
    for p in model.parameters():
        p.requires_grad = False
    return model


def _to_inception_input(imgs_01, device):
    """Resize [0,1] images to 299x299 and apply ImageNet normalisation."""
    imgs = F.interpolate(
        imgs_01, size=_INCEPTION_SIZE, mode="bilinear", align_corners=False
    )
    mean = _IMAGENET_MEAN.to(device)
    std = _IMAGENET_STD.to(device)
    return (imgs - mean) / std


def _denorm_imagenet(imgs, device):
    """Undo ImageNet normalisation -> [0,1]."""
    mean = _IMAGENET_MEAN.to(device)
    std = _IMAGENET_STD.to(device)
    return (imgs * std + mean).clamp(0.0, 1.0)


def _denorm_tanh(imgs):
    """Map generator [-1,1] output -> [0,1]."""
    return ((imgs + 1.0) / 2.0).clamp(0.0, 1.0)


def _extract_images(batch):
    """Pull the image tensor out of a loader batch (dict / tuple / tensor)."""
    if isinstance(batch, dict):
        return batch["image"]
    if isinstance(batch, (list, tuple)):
        return batch[0]
    return batch


def _sample_condition(condition, n, device):
    """Sample ``n`` condition rows (with replacement) from ``condition``."""
    cond = condition.to(device)
    if cond.dim() == 1:
        cond = cond.unsqueeze(0)
    idx = torch.randint(0, cond.size(0), (n,), device=device)
    return cond[idx]


# ----------------------------------------------------------------------------
# FID
# ----------------------------------------------------------------------------
def _frechet_distance(mu_r, sigma_r, mu_f, sigma_f):
    diff = mu_r - mu_f
    if linalg is None:  # crude fallback without the covariance cross-term
        return float(diff.dot(diff) + np.trace(sigma_r + sigma_f))
    covmean, _ = linalg.sqrtm(sigma_r.dot(sigma_f), disp=False)
    if np.iscomplexobj(covmean):
        covmean = covmean.real
    return float(diff.dot(diff) + np.trace(sigma_r + sigma_f - 2.0 * covmean))


def _feature_statistics(features):
    mu = features.mean(axis=0)
    sigma = np.cov(features, rowvar=False)
    return mu, sigma


@torch.no_grad()
def compute_fid(real_loader, generator, condition, n_samples=10000, device="cpu"):
    """Compute Fréchet Inception Distance between real and generated images.

    Args:
        real_loader: Iterable of batches yielding ImageNet-normalised images.
        generator: Trained ConditionalGenerator.
        condition: Condition tensor (K, condition_dim) sampled per fake batch.
        n_samples: Cap on the number of real and fake samples each.
        device: Torch device.

    Returns:
        float: The FID (lower is better).
    """
    inception = _load_inception(device, feature_mode=True)
    generator.eval().to(device)

    # Real features.
    real_feats = []
    seen = 0
    for batch in real_loader:
        imgs = _extract_images(batch).to(device)
        imgs01 = _denorm_imagenet(imgs, device)
        feats = inception(_to_inception_input(imgs01, device))
        real_feats.append(feats.cpu().numpy())
        seen += imgs.size(0)
        if seen >= n_samples:
            break

    # Fake features (matched count, generated in batches of 64).
    fake_feats = []
    z_dim = generator.z_dim
    produced = 0
    target = min(seen, n_samples)
    while produced < target:
        bs = min(64, target - produced)
        cond = _sample_condition(condition, bs, device)
        z = torch.randn(bs, z_dim, device=device)
        fake = _denorm_tanh(generator(z, cond))
        feats = inception(_to_inception_input(fake, device))
        fake_feats.append(feats.cpu().numpy())
        produced += bs

    feat_real = np.concatenate(real_feats, axis=0)[:target]
    feat_fake = np.concatenate(fake_feats, axis=0)[:target]

    mu_r, sigma_r = _feature_statistics(feat_real)
    mu_f, sigma_f = _feature_statistics(feat_fake)
    fid = _frechet_distance(mu_r, sigma_r, mu_f, sigma_f)
    logger.info("FID over %d samples: %.4f", target, fid)
    return fid


# ----------------------------------------------------------------------------
# Inception Score
# ----------------------------------------------------------------------------
@torch.no_grad()
def compute_inception_score(
    generator, condition, n_samples=5000, device="cpu", splits=10
):
    """Compute the Inception Score of generated images.

    IS = exp( E_x[ KL( p(y|x) || p(y) ) ] ), estimated over ``splits`` chunks.

    Returns:
        tuple: ``(is_mean, is_std)`` across the splits.
    """
    inception = _load_inception(device, feature_mode=False)
    generator.eval().to(device)
    z_dim = generator.z_dim

    preds = []
    produced = 0
    while produced < n_samples:
        bs = min(64, n_samples - produced)
        cond = _sample_condition(condition, bs, device)
        z = torch.randn(bs, z_dim, device=device)
        fake = _denorm_tanh(generator(z, cond))
        logits = inception(_to_inception_input(fake, device))
        preds.append(F.softmax(logits, dim=1).cpu().numpy())
        produced += bs

    preds = np.concatenate(preds, axis=0)[:n_samples]

    scores = []
    split_size = max(1, preds.shape[0] // splits)
    for k in range(splits):
        part = preds[k * split_size : (k + 1) * split_size]
        if part.shape[0] == 0:
            continue
        p_y = np.mean(part, axis=0, keepdims=True)
        kl = part * (np.log(part + 1e-10) - np.log(p_y + 1e-10))
        kl = np.sum(kl, axis=1)
        scores.append(np.exp(np.mean(kl)))

    is_mean, is_std = float(np.mean(scores)), float(np.std(scores))
    logger.info("Inception Score over %d samples: %.4f +/- %.4f",
                len(preds), is_mean, is_std)
    return is_mean, is_std


# ----------------------------------------------------------------------------
# Synthetic image generation / export
# ----------------------------------------------------------------------------
def _build_condition(fitz_type, disease_idx, fitz_classes, disease_classes):
    """Build a one-hot (fitz | disease) condition vector."""
    condition_dim = len(fitz_classes) + disease_classes
    cond = torch.zeros(condition_dim)
    cond[fitz_classes.index(fitz_type)] = 1.0
    cond[len(fitz_classes) + disease_idx] = 1.0
    return cond


@torch.no_grad()
def generate_synthetic_batch(
    generator, fitzpatrick_type, disease_class, n_images, device="cpu"
):
    """Generate ``n_images`` for one (skin type, disease) combination.

    Args:
        generator: Trained ConditionalGenerator.
        fitzpatrick_type: Fitzpatrick type (one of 4, 5, 6).
        disease_class: Disease one-hot index in [0, disease_classes).
        n_images: Number of images to generate.
        device: Torch device.

    Returns:
        list[PIL.Image.Image]: The generated images.
    """
    generator.eval().to(device)

    # Infer the condition split from the generator. fitz ordering is the
    # canonical [4, 5, 6] used throughout the project.
    fitz_classes = [4, 5, 6]
    disease_classes = generator.condition_dim - len(fitz_classes)

    cond = _build_condition(
        fitzpatrick_type, disease_class, fitz_classes, disease_classes
    ).to(device)
    cond = cond.unsqueeze(0).expand(n_images, -1)

    z = torch.randn(n_images, generator.z_dim, device=device)
    fake = _denorm_tanh(generator(z, cond))

    to_pil = transforms.ToPILImage()
    return [to_pil(fake[i].cpu()) for i in range(n_images)]


def export_synthetic_images(
    generator, cfg, output_dir, dermatologist_approved_only=False
):
    """Generate and save synthetic images for all dark-skin combinations.

    Iterates over every Fitzpatrick IV-VI + disease class combination present
    in the training subset, saves PNGs named
    ``synthetic_{fitz}_{class}_{idx}.png`` and writes a manifest CSV compatible
    with the project manifest schema.

    Args:
        generator: Trained ConditionalGenerator.
        cfg: Full pipeline config dict.
        output_dir: Directory to write images and ``manifest.csv`` into.
        dermatologist_approved_only: If True, only export combinations listed in
            ``cfg["gan"]["approved_combos"]`` (a list of ``[fitz, label_idx]``
            pairs). With no approval list configured, nothing is exported.

    Returns:
        int: Number of synthetic images written.
    """
    gan_cfg = cfg["gan"]
    device = next(generator.parameters()).device

    fitz_classes, disease_to_idx = build_condition_mapping(cfg)
    disease_classes = gan_cfg["disease_classes"]
    idx_to_label = {v: k for k, v in disease_to_idx.items()}
    n_per_combo = gan_cfg.get("synthetic_per_class", 200)

    approved = None
    if dermatologist_approved_only:
        approved = {tuple(c) for c in gan_cfg.get("approved_combos", [])}
        if not approved:
            logger.warning(
                "dermatologist_approved_only=True but no approved_combos "
                "configured; nothing will be exported."
            )

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    for fitz_type in fitz_classes:
        for disease_idx, label_idx in idx_to_label.items():
            if approved is not None and (fitz_type, label_idx) not in approved:
                continue

            images = generate_synthetic_batch(
                generator, fitz_type, disease_idx, n_per_combo, device
            )
            for i, img in enumerate(images):
                fname = f"synthetic_{fitz_type}_{label_idx}_{i}.png"
                fpath = output_dir / fname
                img.save(fpath)
                rows.append(
                    {
                        "image_path": str(fpath),
                        "label_idx": label_idx,
                        "fitzpatrick_type": fitz_type,
                        "source": "synthetic",
                        "is_synthetic": True,
                    }
                )

    manifest_path = output_dir / "manifest.csv"
    with open(manifest_path, "w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "image_path",
                "label_idx",
                "fitzpatrick_type",
                "source",
                "is_synthetic",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    logger.info("Exported %d synthetic images to %s", len(rows), output_dir)
    return len(rows)
