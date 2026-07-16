"""TFLite conversion numerical-equivalence checks.

Converting PyTorch -> TFLite must not change what the model predicts. These
tests re-run both engines on identical inputs and assert the logits agree to
within float32 arithmetic noise.

Two artifacts are covered:

* ``MobileNet_distilled.pth`` -> ``dermatriage_float32.tflite`` — the verified
  conversion pair; equivalence is asserted numerically.
* ``dermatriage_diverse.tflite`` — the model actually bundled in the Flutter app.
  Its source checkpoint was produced by the later Kaggle "diverse not_skin"
  retrain and is not in this repository, so only its input/output contract can
  be checked here (a full equivalence check requires that .pth).
"""

import sys
from pathlib import Path

import numpy as np
import pytest
import torch
from PIL import Image
from torchvision.models import mobilenet_v3_small

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataset import SkinDataset  # noqa: E402
from tests._report import check, header, info, section, table  # noqa: E402

TFLITE_DIR = ROOT / "outputs" / "tflite"
PAIRED_PTH = TFLITE_DIR / "MobileNet_distilled.pth"
PAIRED_TFLITE = TFLITE_DIR / "dermatriage_float32.tflite"
DEPLOYED_TFLITE = TFLITE_DIR / "dermatriage_diverse.tflite"
PASSION_IMAGES = ROOT / "data" / "raw" / "passion" / "images"

NUM_CLASSES = 5
IMAGE_SIZE = 224
# Class order is fixed by training and mirrored in the Flutter app
# (lib/core/constants/disease_classes.dart). Any drift here corrupts every label.
CLASS_IDS = ["fungal", "scabies", "eczema", "healthy_skin", "not_skin"]

# float32 conv/BN arithmetic reorders between engines; ~1e-5 is expected noise.
LOGIT_TOLERANCE = 1e-3


def _interpreter(path):
    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError:  # pragma: no cover - fallback for TF installs
        from tensorflow.lite import Interpreter
    interp = Interpreter(model_path=str(path))
    interp.allocate_tensors()
    return interp


def _tflite_predict(interp, x):
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    interp.set_tensor(inp["index"], x)
    interp.invoke()
    return interp.get_tensor(out["index"])[0]


def _softmax(v):
    e = np.exp(v - v.max())
    return e / e.sum()


@pytest.fixture(scope="module")
def torch_model():
    if not PAIRED_PTH.exists():
        pytest.skip(f"Missing checkpoint {PAIRED_PTH}")
    model = mobilenet_v3_small(weights=None)
    model.classifier[3] = torch.nn.Linear(
        model.classifier[3].in_features, NUM_CLASSES
    )
    model.load_state_dict(torch.load(PAIRED_PTH, map_location="cpu"))
    model.eval()
    return model


def test_deployed_model_io_contract():
    """The bundled model's IO must match what the Flutter app feeds it."""
    header("TFLITE 1/3 - deployed model input/output contract")

    if not DEPLOYED_TFLITE.exists():
        pytest.skip(f"Missing {DEPLOYED_TFLITE}")
    interp = _interpreter(DEPLOYED_TFLITE)
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]

    section("Artifact")
    info("model", DEPLOYED_TFLITE.name)
    info("size", f"{DEPLOYED_TFLITE.stat().st_size / 1e6:.2f} MB")

    section("Tensor contract")
    results = [
        check("input shape", list(inp["shape"]), f"[1, 3, {IMAGE_SIZE}, {IMAGE_SIZE}]",
              list(inp["shape"]) == [1, 3, IMAGE_SIZE, IMAGE_SIZE]),
        check("input dtype", inp["dtype"].__name__, "float32",
              inp["dtype"] == np.float32),
        check("output shape", list(out["shape"]), f"[1, {NUM_CLASSES}]",
              list(out["shape"]) == [1, NUM_CLASSES]),
        check("output dtype", out["dtype"].__name__, "float32",
              out["dtype"] == np.float32),
    ]

    section("Class index order (must match the Flutter app)")
    table([[i, c] for i, c in enumerate(CLASS_IDS)], ["idx", "class_id"])

    assert all(results)


def test_tflite_matches_pytorch_on_random_inputs(torch_model):
    """PyTorch and TFLite must agree on random inputs across the valid range."""
    header("TFLITE 2/3 - numerical equivalence on random inputs")

    if not PAIRED_TFLITE.exists():
        pytest.skip(f"Missing {PAIRED_TFLITE}")
    interp = _interpreter(PAIRED_TFLITE)

    section("Conversion pair under test")
    info("pytorch source", PAIRED_PTH.name)
    info("tflite output", PAIRED_TFLITE.name)
    info("tolerance", f"max |logit diff| < {LOGIT_TOLERANCE}")

    section("Per-input comparison (inputs span the normalised range)")
    rows = []
    worst = 0.0
    argmax_agree = 0
    trials = 8
    for seed in range(trials):
        rng = np.random.default_rng(seed)
        x = rng.uniform(-2.1179, 2.64, (1, 3, IMAGE_SIZE, IMAGE_SIZE)).astype(np.float32)
        with torch.no_grad():
            pt = torch_model(torch.from_numpy(x)).numpy()[0]
        tf = _tflite_predict(interp, x)
        diff = float(np.abs(pt - tf).max())
        worst = max(worst, diff)
        same = int(pt.argmax()) == int(tf.argmax())
        argmax_agree += same
        rows.append([seed, CLASS_IDS[int(pt.argmax())], CLASS_IDS[int(tf.argmax())],
                     f"{diff:.2e}", "OK" if same else "DIFFER"])
    table(rows, ["seed", "torch argmax", "tflite argmax", "max|diff|", "agree"])

    section("Checks")
    results = [
        check("worst logit difference", f"{worst:.3e}", f"< {LOGIT_TOLERANCE}",
              worst < LOGIT_TOLERANCE),
        check("argmax agreement", f"{argmax_agree}/{trials}", f"{trials}/{trials}",
              argmax_agree == trials),
    ]
    assert all(results)


def test_tflite_matches_pytorch_on_real_images(torch_model):
    """Equivalence must hold on real clinical images, not just random noise."""
    header("TFLITE 3/3 - numerical equivalence on real PASSION images")

    if not PAIRED_TFLITE.exists():
        pytest.skip(f"Missing {PAIRED_TFLITE}")
    images = sorted(PASSION_IMAGES.glob("*.jpg"))[:6]
    if not images:
        pytest.skip(f"No PASSION images at {PASSION_IMAGES}")

    interp = _interpreter(PAIRED_TFLITE)
    transform = SkinDataset._build_transform(IMAGE_SIZE, split="test")

    section("Per-image comparison (full production preprocessing)")
    rows = []
    worst = 0.0
    worst_prob = 0.0
    agree = 0
    for path in images:
        img = Image.open(path).convert("RGB")
        x = transform(img).unsqueeze(0).numpy().astype(np.float32)
        with torch.no_grad():
            pt = torch_model(torch.from_numpy(x)).numpy()[0]
        tf = _tflite_predict(interp, x)
        diff = float(np.abs(pt - tf).max())
        prob_diff = float(np.abs(_softmax(pt) - _softmax(tf)).max())
        worst = max(worst, diff)
        worst_prob = max(worst_prob, prob_diff)
        same = int(pt.argmax()) == int(tf.argmax())
        agree += same
        rows.append([
            path.name[:22],
            CLASS_IDS[int(pt.argmax())],
            f"{_softmax(pt).max():.4f}",
            f"{_softmax(tf).max():.4f}",
            f"{diff:.2e}",
            "OK" if same else "DIFFER",
        ])
    table(rows, ["image", "prediction", "torch conf", "tflite conf",
                 "max|diff|", "agree"])

    section("Checks")
    results = [
        check("worst logit difference", f"{worst:.3e}", f"< {LOGIT_TOLERANCE}",
              worst < LOGIT_TOLERANCE),
        check("worst softmax difference", f"{worst_prob:.3e}", "< 1e-3",
              worst_prob < 1e-3),
        check("prediction agreement", f"{agree}/{len(images)}",
              f"{len(images)}/{len(images)}", agree == len(images)),
    ]

    section("Conclusion")
    info("verdict", "TFLite reproduces PyTorch within float32 noise")
    info("meaning", "conversion is safe to deploy; predictions are unchanged")

    assert all(results)
