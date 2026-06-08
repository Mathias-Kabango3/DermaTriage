"""Dynamic quantisation and latency benchmarking for the student model."""

import time

import torch
import torch.nn as nn

from ..utils.logger import get_logger

logger = get_logger(__name__)


def apply_dynamic_quantisation(model):
    """Apply int8 dynamic quantisation to the model's Linear layers.

    Dynamic quantisation quantises weights to int8 ahead of time and activations
    on the fly — a good fit for the student's classifier head on CPU.

    Args:
        model: A trained (fp32) model in eval mode.

    Returns:
        The dynamically quantised model.
    """
    model.eval()
    quantised = torch.quantization.quantize_dynamic(
        model, {nn.Linear}, dtype=torch.qint8
    )
    logger.info("Applied int8 dynamic quantisation to Linear layers.")
    return quantised


@torch.no_grad()
def benchmark_inference(model, image_size=224, n_runs=100, device="cpu"):
    """Measure forward-pass latency over ``n_runs`` random inputs.

    Args:
        model: Model to benchmark.
        image_size: Square input resolution.
        n_runs: Number of timed forward passes.
        device: Torch device string or object.

    Returns:
        tuple: ``(mean_ms, std_ms)`` latency in milliseconds.
    """
    device = torch.device(device)
    model.eval().to(device)
    dummy = torch.randn(1, 3, image_size, image_size, device=device)

    is_cuda = device.type == "cuda"

    # Warm-up (kernel autotuning / lazy init) — not timed.
    for _ in range(10):
        model(dummy)
    if is_cuda:
        torch.cuda.synchronize()

    timings = []
    for _ in range(n_runs):
        start = time.perf_counter()
        model(dummy)
        if is_cuda:
            torch.cuda.synchronize()
        timings.append((time.perf_counter() - start) * 1000.0)  # ms

    timings = torch.tensor(timings)
    mean_ms = float(timings.mean())
    std_ms = float(timings.std())
    logger.info(
        "Latency over %d runs: %.2f +/- %.2f ms (%s)",
        n_runs, mean_ms, std_ms, device,
    )
    return mean_ms, std_ms
