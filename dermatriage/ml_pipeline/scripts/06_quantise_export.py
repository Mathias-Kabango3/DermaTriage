#!/usr/bin/env python
"""Quantise the student and export it to int8 TFLite for mobile deployment.

Steps:
    1. Load the best distilled student checkpoint.
    2. Benchmark fp32 vs. dynamically-quantised latency on CPU.
    3. Export the fp32 student to ONNX (opset 13).
    4. Convert ONNX -> int8 TFLite via onnx2tf.
    5. Verify the TFLite model and report the final size in MB.

Run from the ml_pipeline/ directory:
    python scripts/06_quantise_export.py --config config.yaml
"""

import argparse
import shutil
import sys
from pathlib import Path

import torch

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.distillation.export_tflite import (  # noqa: E402
    export_to_onnx,
    onnx_to_tflite,
    verify_tflite,
)
from src.distillation.quantise import (  # noqa: E402
    apply_dynamic_quantisation,
    benchmark_inference,
)
from src.models.student import build_student  # noqa: E402
from src.utils.checkpoint import load_checkpoint  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger  # noqa: E402

logger = get_logger(__name__)


def _find_int8_tflite(tflite_dir):
    """Pick the integer-quantised TFLite file onnx2tf produced."""
    tflite_dir = Path(tflite_dir)
    # Prefer full-integer quant, then any integer quant, then any tflite.
    for pattern in ("*full_integer_quant.tflite",
                    "*integer_quant.tflite",
                    "*.tflite"):
        matches = sorted(tflite_dir.glob(pattern))
        if matches:
            return matches[0]
    return None


def main():
    parser = argparse.ArgumentParser(description="Quantise + export the student.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    args = parser.parse_args()

    cfg = load_config(args.config)
    quant_cfg = cfg["quantisation"]
    image_size = cfg["data"]["image_size"]
    device = torch.device("cpu")  # quantise/export on CPU

    # --- 1. Load best student ---
    student = build_student(
        num_classes=cfg["data"]["num_classes"], pretrained=False
    ).to(device)
    ckpt_dir = Path(cfg["distillation"].get("checkpoint_dir", "models/student"))
    ckpt_path = ckpt_dir / "student_best.pt"
    epoch, metrics = load_checkpoint(student, None, ckpt_path, device)
    logger.info(
        "Loaded student from %s (epoch %s, val_acc %s)",
        ckpt_path, epoch, metrics.get("val_accuracy"),
    )
    student.eval()

    # --- 2. Benchmark fp32 vs dynamic-quantised ---
    fp32_mean, fp32_std = benchmark_inference(student, image_size, device="cpu")
    quantised = apply_dynamic_quantisation(student)
    q_mean, q_std = benchmark_inference(quantised, image_size, device="cpu")
    logger.info(
        "Latency fp32 %.2f+/-%.2f ms | dynamic-int8 %.2f+/-%.2f ms",
        fp32_mean, fp32_std, q_mean, q_std,
    )

    # --- 3. Export fp32 student to ONNX ---
    tflite_output_path = Path(quant_cfg["tflite_output_path"])
    work_dir = tflite_output_path.parent
    onnx_path = work_dir / "student.onnx"
    export_to_onnx(student, onnx_path, image_size=image_size)

    # --- 4. Convert ONNX -> int8 TFLite ---
    tflite_dir = work_dir / "tflite"
    onnx_to_tflite(onnx_path, tflite_dir)

    int8_tflite = _find_int8_tflite(tflite_dir)
    if int8_tflite is None:
        raise FileNotFoundError(f"No .tflite produced in {tflite_dir}")
    # Publish to the configured output path.
    tflite_output_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(int8_tflite, tflite_output_path)

    # --- 5. Verify + report size ---
    out_shape, tflite_latency = verify_tflite(tflite_output_path, image_size)
    size_mb = tflite_output_path.stat().st_size / (1024 * 1024)

    logger.info("=" * 60)
    logger.info("Final TFLite model: %s", tflite_output_path)
    logger.info("Output shape: %s | TFLite latency: %.2f ms", out_shape, tflite_latency)
    logger.info("Model size: %.2f MB (target <= %s MB)",
                size_mb, quant_cfg["target_size_mb"])
    if size_mb <= quant_cfg["target_size_mb"]:
        logger.info("Size target MET.")
    else:
        logger.warning("Size target EXCEEDED.")


if __name__ == "__main__":
    main()
