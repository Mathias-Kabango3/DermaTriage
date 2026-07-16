"""Model-level unit tests for the image preprocessing transform.

Verifies that `SkinDataset`'s transform produces exactly the tensor the model
was trained on — correct shape, dtype and ImageNet-normalised value range — and
that the val/test path is deterministic while the train path augments.

A mismatch here silently corrupts every prediction, so these are the checks the
Flutter app's preprocessing must also satisfy (resize 224, /255, ImageNet
mean/std).
"""

import sys
from pathlib import Path

import pytest
import torch
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataset import (  # noqa: E402
    IMAGENET_MEAN,
    IMAGENET_STD,
    SkinDataset,
)
from tests._report import check, header, info, section, table  # noqa: E402

IMAGE_SIZE = 224
PASSION_IMAGES = ROOT / "data" / "raw" / "passion" / "images"

# With x in [0,1] and per-channel ImageNet mean/std, the reachable output range
# is [(0-mean)/std, (1-mean)/std] -> about [-2.1179, +2.6400].
EXPECTED_MIN = min((0.0 - m) / s for m, s in zip(IMAGENET_MEAN, IMAGENET_STD))
EXPECTED_MAX = max((1.0 - m) / s for m, s in zip(IMAGENET_MEAN, IMAGENET_STD))


@pytest.fixture(scope="module")
def sample_image():
    """A real PASSION clinical image, so the test exercises production data."""
    images = sorted(PASSION_IMAGES.glob("*.jpg"))
    if not images:
        pytest.skip(f"No PASSION images found at {PASSION_IMAGES}")
    return images[0]


def test_eval_transform_shape_dtype_and_range(sample_image):
    """val/test transform -> (3,224,224) float32 within ImageNet-normalised range."""
    header("PREPROCESSING 1/3 - output shape, dtype and value range")

    img = Image.open(sample_image).convert("RGB")
    transform = SkinDataset._build_transform(IMAGE_SIZE, split="val")
    tensor = transform(img)

    section("Input")
    info("source image", sample_image.name)
    info("original size (WxH)", f"{img.size[0]} x {img.size[1]}")
    info("original mode", img.mode)

    section("Output tensor checks")
    results = [
        check("shape", tuple(tensor.shape), f"(3, {IMAGE_SIZE}, {IMAGE_SIZE})",
              tuple(tensor.shape) == (3, IMAGE_SIZE, IMAGE_SIZE)),
        check("dtype", tensor.dtype, "torch.float32",
              tensor.dtype == torch.float32),
        check("channels", tensor.shape[0], "3 (RGB)", tensor.shape[0] == 3),
        check("min >= theoretical min", f"{tensor.min():.4f}",
              f">= {EXPECTED_MIN:.4f}", tensor.min().item() >= EXPECTED_MIN - 1e-4),
        check("max <= theoretical max", f"{tensor.max():.4f}",
              f"<= {EXPECTED_MAX:.4f}", tensor.max().item() <= EXPECTED_MAX + 1e-4),
        check("no NaN / Inf", bool(torch.isfinite(tensor).all()), "True",
              bool(torch.isfinite(tensor).all())),
    ]

    section("Per-channel statistics (ImageNet normalised)")
    rows = []
    for i, name in enumerate(["R", "G", "B"]):
        ch = tensor[i]
        rows.append([name, f"{IMAGENET_MEAN[i]:.3f}", f"{IMAGENET_STD[i]:.3f}",
                     f"{ch.min():.4f}", f"{ch.max():.4f}", f"{ch.mean():.4f}"])
    table(rows, ["ch", "norm mean", "norm std", "min", "max", "mean"])

    assert all(results)


def test_normalisation_is_mathematically_correct(sample_image):
    """Un-normalising the output must recover the raw [0,1] pixel values."""
    header("PREPROCESSING 2/3 - normalisation is mathematically correct")

    img = Image.open(sample_image).convert("RGB")
    transform = SkinDataset._build_transform(IMAGE_SIZE, split="val")
    tensor = transform(img)

    # Independently reproduce the expected tensor: resize -> [0,1] -> normalise.
    from torchvision import transforms as T

    raw01 = T.ToTensor()(T.Resize((IMAGE_SIZE, IMAGE_SIZE))(img))
    mean = torch.tensor(IMAGENET_MEAN).view(3, 1, 1)
    std = torch.tensor(IMAGENET_STD).view(3, 1, 1)
    expected = (raw01 - mean) / std

    # Invert the pipeline's own output and compare against the [0,1] source.
    recovered = tensor * std + mean
    max_norm_err = (tensor - expected).abs().max().item()
    max_recon_err = (recovered - raw01).abs().max().item()

    section("Checks")
    results = [
        check("matches manual normalise", f"{max_norm_err:.2e}", "< 1e-6",
              max_norm_err < 1e-6),
        check("un-normalise recovers [0,1]", f"{max_recon_err:.2e}", "< 1e-6",
              max_recon_err < 1e-6),
        check("recovered min in [0,1]", f"{recovered.min():.4f}", ">= 0",
              recovered.min().item() >= -1e-4),
        check("recovered max in [0,1]", f"{recovered.max():.4f}", "<= 1",
              recovered.max().item() <= 1 + 1e-4),
    ]
    info("", "")
    info("formula verified", "(pixel/255 - ImageNet mean) / ImageNet std")

    assert all(results)


def test_eval_deterministic_train_augments(sample_image):
    """val/test must be repeatable; train must vary (stochastic augmentation)."""
    header("PREPROCESSING 3/3 - eval determinism vs train augmentation")

    img = Image.open(sample_image).convert("RGB")

    eval_tf = SkinDataset._build_transform(IMAGE_SIZE, split="val")
    a, b = eval_tf(img), eval_tf(img)
    eval_identical = torch.equal(a, b)

    torch.manual_seed(0)
    train_tf = SkinDataset._build_transform(IMAGE_SIZE, split="train")
    t1, t2 = train_tf(img), train_tf(img)
    train_differs = not torch.equal(t1, t2)

    section("Checks")
    results = [
        check("val: two runs identical", eval_identical, "True (deterministic)",
              eval_identical),
        check("train: two runs differ", train_differs, "True (augmented)",
              train_differs),
        check("train output shape", tuple(t1.shape), f"(3, {IMAGE_SIZE}, {IMAGE_SIZE})",
              tuple(t1.shape) == (3, IMAGE_SIZE, IMAGE_SIZE)),
        check("train dtype", t1.dtype, "torch.float32", t1.dtype == torch.float32),
    ]

    section("Why this matters")
    info("val/test deterministic", "same image -> same prediction, every run")
    info("train augmented", "RandomResizedCrop + Flip + ColorJitter")

    assert all(results)
