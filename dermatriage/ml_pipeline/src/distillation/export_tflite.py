"""Export the student model to ONNX and then to int8 TFLite.

Pipeline: PyTorch (fp32) -> ONNX (opset 13) -> onnx2tf -> integer-quantised
TFLite. The ONNX export uses the fp32 model; integer quantisation is performed
by onnx2tf so the resulting TFLite runs efficiently on mobile.
"""

import subprocess
from pathlib import Path

import torch

from ..utils.logger import get_logger

logger = get_logger(__name__)


def _size_mb(path):
    return Path(path).stat().st_size / (1024 * 1024)


def export_to_onnx(model, output_path, image_size=224):
    """Export a PyTorch model to ONNX (opset 13) with a dynamic batch axis.

    Args:
        model: fp32 model in eval mode.
        output_path: Destination ``.onnx`` path.
        image_size: Square input resolution.

    Returns:
        str: The ONNX output path.
    """
    model.eval()
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    dummy = torch.randn(1, 3, image_size, image_size)
    torch.onnx.export(
        model,
        dummy,
        str(output_path),
        export_params=True,
        opset_version=13,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={
            "input": {0: "batch"},
            "logits": {0: "batch"},
        },
    )
    logger.info(
        "Exported ONNX to %s (%.2f MB)", output_path, _size_mb(output_path)
    )
    return str(output_path)


def onnx_to_tflite(onnx_path, tflite_output_dir):
    """Convert an ONNX model to int8 TFLite via the onnx2tf CLI.

    Args:
        onnx_path: Path to the input ONNX model.
        tflite_output_dir: Directory onnx2tf writes the TFLite models into.

    Returns:
        str: The output directory path.
    """
    tflite_output_dir = Path(tflite_output_dir)
    tflite_output_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "onnx2tf",
        "-i", str(onnx_path),
        "-o", str(tflite_output_dir),
        "--output_integer_quantized_tflite",
    ]
    logger.info("Running: %s", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        logger.error("onnx2tf failed:\n%s", result.stderr)
        raise RuntimeError(f"onnx2tf failed with code {result.returncode}")

    logger.info("onnx2tf wrote TFLite models to %s", tflite_output_dir)
    return str(tflite_output_dir)


def verify_tflite(tflite_path, image_size=224):
    """Load a TFLite model, run one inference, and report shape + latency.

    Args:
        tflite_path: Path to the ``.tflite`` model.
        image_size: Square input resolution.

    Returns:
        tuple: ``(output_shape, latency_ms)``.
    """
    import time

    import numpy as np
    import tensorflow as tf

    interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Build a random input matching the model's expected dtype/shape.
    in_detail = input_details[0]
    shape = list(in_detail["shape"])
    # Replace any dynamic/placeholder dims with the known image size / batch 1.
    if len(shape) == 4:
        shape = [1, shape[1] if shape[1] > 0 else image_size,
                 shape[2] if shape[2] > 0 else image_size,
                 shape[3] if shape[3] > 0 else 3]
    dummy = np.random.random_sample(shape).astype(in_detail["dtype"])

    interpreter.set_tensor(in_detail["index"], dummy)
    start = time.perf_counter()
    interpreter.invoke()
    latency_ms = (time.perf_counter() - start) * 1000.0

    output = interpreter.get_tensor(output_details[0]["index"])
    logger.info(
        "TFLite verify: output shape %s, latency %.2f ms",
        tuple(output.shape), latency_ms,
    )
    return tuple(output.shape), latency_ms
