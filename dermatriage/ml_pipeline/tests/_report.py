"""Terminal-report helpers shared by the DermaTriage test suite.

The tests double as evidence for the project report, so each one prints a
readable summary of what it measured alongside the pass/fail assertion.
"""

import os
import sys

# Colour is disabled when the output is piped or NO_COLOR is set, so redirected
# runs stay readable in plain text.
_USE_COLOUR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def _c(code, text):
    return f"\033[{code}m{text}\033[0m" if _USE_COLOUR else text


def bold(text):
    return _c("1", text)


def green(text):
    return _c("32", text)


def red(text):
    return _c("31", text)


def cyan(text):
    return _c("36", text)


def dim(text):
    return _c("2", text)


WIDTH = 74


def header(title):
    """Print a titled banner for one test section."""
    print()
    print(cyan("=" * WIDTH))
    print(cyan(bold(f" {title}")))
    print(cyan("=" * WIDTH))


def section(title):
    """Print a sub-heading inside a test section."""
    print(bold(f"\n  {title}"))
    print(dim("  " + "-" * (WIDTH - 4)))


def check(label, value, expected, ok):
    """Print one aligned check row and return `ok` so callers can assert on it.

    Args:
        label: What is being checked.
        value: The measured value.
        expected: The expectation, shown for context.
        ok: Whether the check passed.
    """
    status = green("PASS") if ok else red("FAIL")
    print(f"  {label:<30} {str(value):<22} {dim(str(expected)):<24} {status}")
    return ok


def info(label, value):
    """Print a plain labelled value (no pass/fail semantics)."""
    print(f"  {label:<30} {value}")


def chart(series, height=12, width=None, ylabel=""):
    """Render labelled line series as an ASCII plot, for terminal screenshots.

    Args:
        series: Mapping of name -> list of y values (all same length).
        height: Plot height in character rows.
        width: Plot width; defaults to the number of points.
        ylabel: Axis label shown above the plot.
    """
    names = list(series)
    marks = ["*", "o", "+", "x"]
    n = max(len(v) for v in series.values())
    width = width or min(max(n, 20), 60)

    lo = min(min(v) for v in series.values())
    hi = max(max(v) for v in series.values())
    span = (hi - lo) or 1.0
    pad = span * 0.08
    lo, hi = lo - pad, hi + pad
    span = hi - lo

    # grid[row][col] -> marker
    grid = [[" "] * width for _ in range(height)]
    for si, name in enumerate(names):
        ys = series[name]
        for i, y in enumerate(ys):
            col = round(i * (width - 1) / max(len(ys) - 1, 1))
            row = height - 1 - round((y - lo) / span * (height - 1))
            row = min(max(row, 0), height - 1)
            grid[row][col] = marks[si % len(marks)]

    legend = "   ".join(f"{marks[i % len(marks)]} {n}" for i, n in enumerate(names))
    print(f"  {dim(ylabel)}")
    for r, row in enumerate(grid):
        y = hi - r * span / (height - 1)
        print(f"  {y:6.3f} |{''.join(row)}")
    print(f"  {'':6} +{'-' * width}")
    print(f"  {'':6}  epoch 1{' ' * max(width - 16, 1)}epoch {n}")
    print(f"  {dim('legend: ' + legend)}")


def table(rows, headers):
    """Print a simple aligned table."""
    widths = [
        max(len(str(headers[i])), max((len(str(r[i])) for r in rows), default=0))
        for i in range(len(headers))
    ]
    head = "  " + "  ".join(str(h).ljust(widths[i]) for i, h in enumerate(headers))
    print(bold(head))
    print(dim("  " + "  ".join("-" * w for w in widths)))
    for r in rows:
        print("  " + "  ".join(str(c).ljust(widths[i]) for i, c in enumerate(r)))
