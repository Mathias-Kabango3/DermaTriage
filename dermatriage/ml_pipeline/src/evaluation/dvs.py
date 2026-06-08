"""Deployment Viability Score (DVS).

The DVS is a single 0-1 figure of merit combining accuracy, latency, model size
and demographic equity, so deployment trade-offs can be compared at a glance.
"""

from dataclasses import dataclass, field

# Reference targets for the latency / size sub-scores.
_LATENCY_TARGET_MS = 2000.0
_SIZE_TARGET_MB = 10.0


@dataclass
class DVSInput:
    """Measured quantities feeding the DVS."""

    top1_accuracy: float
    latency_ms: float
    model_size_mb: float
    fitzpatrick_accuracies: dict = field(default_factory=dict)


def compute_equity_score(fitzpatrick_accuracies):
    """Equity = 1 - (max_acc - min_acc) across Fitzpatrick groups.

    A score of 1.0 means perfectly equal accuracy across skin types; lower
    values indicate a larger disparity. Returns 1.0 when fewer than two groups
    are present (no disparity measurable).
    """
    accs = list(fitzpatrick_accuracies.values())
    if len(accs) < 2:
        return 1.0
    return 1.0 - (max(accs) - min(accs))


def compute_dvs(inp, weights):
    """Compute the weighted Deployment Viability Score.

        DVS = w_acc * accuracy
            + w_lat * min(1, 2000 / latency_ms)
            + w_size * min(1, 10 / model_size_mb)
            + w_equity * equity

    Args:
        inp: A :class:`DVSInput`.
        weights: Dict with keys ``accuracy``, ``latency``, ``model_size``,
            ``equity`` (e.g. ``cfg["evaluation"]["dvs_weights"]``).

    Returns:
        float: The DVS in [0, 1] (assuming weights sum to 1).
    """
    latency_score = min(1.0, _LATENCY_TARGET_MS / inp.latency_ms)
    size_score = min(1.0, _SIZE_TARGET_MB / inp.model_size_mb)
    equity = compute_equity_score(inp.fitzpatrick_accuracies)

    return (
        weights["accuracy"] * inp.top1_accuracy
        + weights["latency"] * latency_score
        + weights["model_size"] * size_score
        + weights["equity"] * equity
    )
