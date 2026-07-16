"""Integration parity: the Flutter app's predictions vs the Python reference.

The Dart half of this test (`flutter_app/test/integration/model_parity_test.dart`)
runs the app's real inference pipeline — ImageProcessor.preprocess ->
SkinTriageInterpreter -> DiseaseClassMapper — and writes its results to
outputs/integration/flutter_predictions.json. This module replays the same
inputs through PyTorch / the Python TFLite runtime and compares.

Run the Dart half first::

    cd flutter_app && flutter test test/integration/model_parity_test.dart
    cd ml_pipeline && make test-parity

Two comparisons, because they answer different questions:

1. **Fixed tensors -> PyTorch.** The app's interpreter is fed a deterministic
   tensor (no image decoding) and compared against PyTorch running the paired
   checkpoint. Image resizing is excluded, so this must agree to float32 noise.
   This is the direct "Flutter output == PyTorch output" evidence.

2. **Real images -> Python TFLite.** The full app pipeline from JPEG bytes,
   using the model bundled in the app's assets. Dart resizes with
   `Interpolation.average` and Python with PIL's antialiased bilinear, so the
   tensors are genuinely not identical and the logits differ slightly. The
   *prediction* is what must not change.
"""

import json
import sys
from pathlib import Path

import numpy as np
import pytest
import torch
from PIL import Image
from torchvision.models import mobilenet_v3_small

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataset import IMAGENET_MEAN, IMAGENET_STD, SkinDataset  # noqa: E402
from tests._report import check, header, info, section, table  # noqa: E402

FLUTTER_JSON = ROOT / "outputs" / "integration" / "flutter_predictions.json"
PAIRED_PTH = ROOT / "outputs" / "tflite" / "MobileNet_distilled.pth"
DEPLOYED_TFLITE = ROOT / "outputs" / "tflite" / "dermatriage_diverse.tflite"
PASSION_IMAGES = ROOT / "data" / "raw" / "passion" / "images"

IMAGE_SIZE = 224
NUM_CLASSES = 5
TENSOR_LEN = 1 * IMAGE_SIZE * IMAGE_SIZE * 3

# Engine-level agreement: reordered float32 arithmetic only.
LOGIT_TOLERANCE = 1e-3
# Full-pipeline agreement: different resize kernels, so only the decision holds.
CONFIDENCE_TOLERANCE = 0.10
# Mirrors AppConstants.confidenceThreshold in the Flutter app: below this the
# app shows "retake photo" rather than a diagnosis.
CONFIDENCE_THRESHOLD = 0.50


def _fixed_tensor(seed):
    """Mirror of `_fixedTensor` in the Dart test (same LCG, same constants)."""
    t = np.empty(TENSOR_LEN, dtype=np.float32)
    state = seed
    for i in range(TENSOR_LEN):
        state = (state * 1664525 + 1013904223) & 0xFFFFFFFF
        u = state / 4294967296.0
        t[i] = -2.1179 + u * (2.6400 + 2.1179)
    return t


def _nhwc_to_nchw(flat):
    """Replicate the app's transpose: interleaved RGB -> planar channels-first."""
    return flat.reshape(IMAGE_SIZE, IMAGE_SIZE, 3).transpose(2, 0, 1)[None, ...]


def _softmax(v):
    e = np.exp(v - np.max(v))
    return e / e.sum()


def _interpreter(path):
    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError:  # pragma: no cover
        from tensorflow.lite import Interpreter
    interp = Interpreter(model_path=str(path))
    interp.allocate_tensors()
    return interp


def _tflite_predict(interp, x):
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    interp.set_tensor(inp["index"], x)
    interp.invoke()
    return interp.get_tensor(out["index"])[0]


@pytest.fixture(scope="module")
def flutter():
    if not FLUTTER_JSON.exists():
        pytest.skip(
            f"{FLUTTER_JSON} not found — run the Dart half first:\n"
            "  cd flutter_app && flutter test test/integration/model_parity_test.dart"
        )
    return json.loads(FLUTTER_JSON.read_text())


def test_flutter_matches_pytorch_on_fixed_tensors(flutter):
    """Flutter's interpreter must reproduce PyTorch on identical input."""
    header("PARITY 1/2 - Flutter app vs PyTorch (identical input tensors)")

    if "fixedTensor" not in flutter:
        pytest.skip("Dart run exported no fixedTensor results")
    if not PAIRED_PTH.exists():
        pytest.skip(f"Missing {PAIRED_PTH}")

    model = mobilenet_v3_small(weights=None)
    model.classifier[3] = torch.nn.Linear(model.classifier[3].in_features, NUM_CLASSES)
    model.load_state_dict(torch.load(PAIRED_PTH, map_location="cpu"))
    model.eval()

    section("What is being compared")
    info("flutter side", "SkinTriageInterpreter (the app's own wrapper)")
    info("flutter model", flutter.get("pairedModel", "?"))
    info("python side", f"PyTorch {PAIRED_PTH.name}")
    info("input", "deterministic tensor, identical on both sides (no resizing)")

    section("Per-tensor logit comparison")
    rows = []
    worst = 0.0
    agree = 0
    for entry in flutter["fixedTensor"]:
        seed = entry["seed"]
        dart = np.array(entry["logits"], dtype=np.float32)
        x = _nhwc_to_nchw(_fixed_tensor(seed))
        with torch.no_grad():
            pt = model(torch.from_numpy(x)).numpy()[0]
        diff = float(np.abs(pt - dart).max())
        worst = max(worst, diff)
        same = int(pt.argmax()) == int(dart.argmax())
        agree += same
        rows.append([seed, f"{dart.max():+.4f}", f"{pt.max():+.4f}", f"{diff:.2e}",
                     "OK" if same else "DIFFER"])
    table(rows, ["seed", "flutter max logit", "pytorch max logit",
                 "max|diff|", "argmax"])

    section("Checks")
    results = [
        check("worst logit difference", f"{worst:.3e}", f"< {LOGIT_TOLERANCE}",
              worst < LOGIT_TOLERANCE),
        check("argmax agreement", f"{agree}/{len(rows)}", f"{len(rows)}/{len(rows)}",
              agree == len(rows)),
    ]

    section("Conclusion")
    info("verdict", "the Flutter app's TFLite output == PyTorch, to float32 noise")

    assert all(results)


def test_flutter_matches_python_on_real_images(flutter):
    """Every diagnosis the app actually shows must match the Python reference.

    Asserted on the app's *confident* predictions only, and that scope is a
    finding rather than a convenience: the Dart and training resize kernels are
    not the same (see the root-cause test below), which is enough to flip a
    borderline image. Sub-threshold images are reported but not asserted because
    the app never shows a diagnosis for them — it asks for a retake — so a flip
    there cannot reach a user.
    """
    header("PARITY 2/3 - Flutter app vs Python reference (real images, bundled model)")

    if "images" not in flutter:
        pytest.skip("Dart run exported no image results")
    if not DEPLOYED_TFLITE.exists():
        pytest.skip(f"Missing {DEPLOYED_TFLITE}")

    class_ids = flutter["classIds"]
    interp = _interpreter(DEPLOYED_TFLITE)
    transform = SkinDataset._build_transform(IMAGE_SIZE, split="test")

    section("What is being compared")
    info("model", f"{DEPLOYED_TFLITE.name} (bundled in the app's assets)")
    info("flutter preprocessing", "image pkg, Interpolation.average")
    info("python preprocessing", "PIL/torchvision, antialiased bilinear (training)")
    info("app confidence threshold", f"{CONFIDENCE_THRESHOLD:.2f} "
                                     "(below this the app shows 'retake', not a diagnosis)")

    section("Per-image comparison")
    rows = []
    confident_agree = 0
    confident_total = 0
    divergent = []
    worst_conf = 0.0
    for entry in flutter["images"]:
        name = entry["image"]
        path = PASSION_IMAGES / name
        if not path.exists():
            continue
        img = Image.open(path).convert("RGB")
        x = transform(img).unsqueeze(0).numpy().astype(np.float32)
        py_logits = _tflite_predict(interp, x)
        py_probs = _softmax(py_logits)
        py_idx = int(py_logits.argmax())

        dart_idx = entry["classIndex"]
        dart_conf = entry["confidence"]
        same = dart_idx == py_idx
        shown = dart_conf >= CONFIDENCE_THRESHOLD
        if shown:
            confident_total += 1
            confident_agree += same
            if same:
                worst_conf = max(worst_conf, abs(dart_conf - float(py_probs[py_idx])))
        if not same:
            divergent.append((name, entry["classId"], dart_conf,
                              class_ids[py_idx], float(py_probs[py_idx])))
        rows.append([
            name[:20], entry["classId"], f"{dart_conf:.4f}",
            class_ids[py_idx], f"{py_probs[py_idx]:.4f}",
            "diagnosis" if shown else "retake",
            "OK" if same else "DIFFER",
        ])
    table(rows, ["image", "flutter pred", "flutter conf", "python pred",
                 "python conf", "app shows", "agree"])

    section("Preprocessing tensor ranges (reported by the Dart app itself)")
    tr = [[e["image"][:20], f"{e['inputMin']:.4f}", f"{e['inputMax']:.4f}",
           f"{e['inputMean']:+.4f}"] for e in flutter["images"][:4]]
    table(tr, ["image", "min", "max", "mean"])
    info("expected bounds", "min >= -2.1179, max <= 2.6400 (ImageNet normalised)")

    in_range = all(
        e["inputMin"] >= -2.1179 - 1e-3 and e["inputMax"] <= 2.6400 + 1e-3
        for e in flutter["images"]
    )

    if divergent:
        section("Divergences (reported, not asserted)")
        for name, dc, dconf, pc, pconf in divergent:
            info(name, f"flutter {dc} {dconf:.4f}  vs  python {pc} {pconf:.4f}  "
                       f"-> app shows "
                       f"{'DIAGNOSIS' if dconf >= CONFIDENCE_THRESHOLD else 'retake'}")
        info("", "")
        info("cause", "resize kernel mismatch - see PARITY 3/3")

    section("Checks")
    results = [
        check("confident predictions agree", f"{confident_agree}/{confident_total}",
              f"{confident_total}/{confident_total}",
              confident_agree == confident_total),
        check("confident conf delta", f"{worst_conf:.4f}", f"< {CONFIDENCE_TOLERANCE}",
              worst_conf < CONFIDENCE_TOLERANCE),
        check("dart tensors in range", in_range, "True", in_range),
    ]

    section("Conclusion")
    info("verdict", "every diagnosis the app displays matches the Python reference")
    info("limitation", f"{len(divergent)}/{len(rows)} borderline image(s) diverge; all "
                       "sit below the")
    info("", "confidence threshold, so the app asks for a retake instead.")

    assert all(results)


def test_resize_kernel_is_the_only_divergence(flutter):
    """Prove the Dart pipeline is exact, and isolate the one real difference.

    Re-runs the Python reference with PIL's BOX (area-averaging) filter — the
    equivalent of Dart's `Interpolation.average`. If that reproduces the app's
    output on every image, then Dart's decode/normalise/transpose/mapping are
    all correct and the sole divergence from training is the resize kernel.
    """
    header("PARITY 3/3 - root cause: resize kernel (BOX vs antialiased bilinear)")

    if "images" not in flutter:
        pytest.skip("Dart run exported no image results")
    if not DEPLOYED_TFLITE.exists():
        pytest.skip(f"Missing {DEPLOYED_TFLITE}")

    class_ids = flutter["classIds"]
    interp = _interpreter(DEPLOYED_TFLITE)
    mean = np.array(IMAGENET_MEAN, np.float32)
    std = np.array(IMAGENET_STD, np.float32)

    def predict_with(img, resample):
        arr = np.asarray(img.resize((IMAGE_SIZE, IMAGE_SIZE), resample), np.float32)
        x = ((arr / 255.0 - mean) / std).transpose(2, 0, 1)[None, ...].astype(np.float32)
        logits = _tflite_predict(interp, x)
        probs = _softmax(logits)
        return int(logits.argmax()), float(probs.max())

    section("Python re-run with Dart's resize (PIL BOX) vs training's (BILINEAR)")
    rows = []
    box_match = 0
    for entry in flutter["images"]:
        path = PASSION_IMAGES / entry["image"]
        if not path.exists():
            continue
        img = Image.open(path).convert("RGB")
        bi, bc = predict_with(img, Image.BILINEAR)
        xi, xc = predict_with(img, Image.BOX)
        matches = (class_ids[xi] == entry["classId"]
                   and abs(xc - entry["confidence"]) < 0.02)
        box_match += matches
        rows.append([
            entry["image"][:20],
            f"{entry['classId']} {entry['confidence']:.4f}",
            f"{class_ids[xi]} {xc:.4f}",
            f"{class_ids[bi]} {bc:.4f}",
            "MATCH" if matches else "-",
        ])
    table(rows, ["image", "flutter (dart avg)", "python BOX (area)",
                 "python BILINEAR (training)", "box==dart"])

    section("Checks")
    results = [
        check("PIL BOX reproduces Flutter", f"{box_match}/{len(rows)}",
              f"{len(rows)}/{len(rows)}", box_match == len(rows)),
    ]

    section("Finding")
    info("proven", "Dart decode/normalise/NCHW-transpose/mapping are all correct:")
    info("", "area-averaging in Python reproduces the app exactly.")
    info("", "")
    info("but", "training resized with antialiased BILINEAR, the app uses area-")
    info("", "average. They are close but not identical, which is enough to")
    info("", "flip a low-confidence prediction.")
    info("", "")
    info("recommendation", "align the app's resize with training, or document")
    info("", "the kernel as part of the preprocessing contract.")

    assert all(results)
