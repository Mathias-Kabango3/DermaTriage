"""Dataset loader sanity checks on the real PASSION dataset.

Two properties matter for a trustworthy result:

1. **Patient overlap must be exactly zero.** PASSION ships several images per
   patient. If one patient's images land in both train and test, the model can
   memorise the patient rather than the condition, and the reported accuracy is
   inflated. `split_dataframe` groups by `subject_id` to prevent this; this test
   proves the guarantee holds on the actual data.
2. **Label distribution must be known and non-degenerate**, per split, so class
   imbalance is reported honestly rather than discovered after training.
"""

import importlib.util
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.harmonise_labels import CLASS_TO_IDX_11  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from tests._report import check, header, info, section, table  # noqa: E402

IDX_TO_CLASS = {v: k for k, v in CLASS_TO_IDX_11.items()}
DARK_TYPES = [4, 5, 6]


def _load_preprocess_module():
    """Import scripts/02_preprocess.py (its name is not a valid identifier)."""
    path = ROOT / "scripts" / "02_preprocess.py"
    spec = importlib.util.spec_from_file_location("preprocess_script", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules["preprocess_script"] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="module")
def passion_data():
    """Build the PASSION dataframe and its 80/10/10 patient-level splits."""
    preprocess = _load_preprocess_module()
    cfg = load_config(ROOT / "config.yaml")
    # Config paths are relative to ml_pipeline/; make them absolute.
    cfg["data"]["passion_path"] = str(ROOT / cfg["data"]["passion_path"])

    df = preprocess.build_passion_dataframe(cfg)
    if df.empty:
        pytest.skip("PASSION dataset not available on disk")
    splits = preprocess.split_dataframe(df, cfg["data"]["splits"])
    return df, splits, cfg


def test_patient_overlap_is_zero(passion_data):
    """No patient may appear in more than one split (leakage guard)."""
    df, splits, _ = passion_data
    header("DATASET 1/3 - patient-level leakage check (overlap must be 0)")

    groups = {name: set(sdf["group"]) for name, sdf in splits.items()}

    section("Patients (subject_id) per split")
    rows = [
        [name, len(sdf), len(groups[name])]
        for name, sdf in splits.items()
    ]
    rows.append(["TOTAL", len(df), df["group"].nunique()])
    table(rows, ["split", "images", "patients"])

    section("Pairwise patient overlap")
    results = []
    for a, b in [("train", "val"), ("train", "test"), ("val", "test")]:
        shared = groups[a] & groups[b]
        results.append(
            check(f"{a} ∩ {b}", len(shared), "0 patients", len(shared) == 0)
        )

    section("Global integrity")
    total_patients = sum(len(g) for g in groups.values())
    results.append(
        check("patients conserved", total_patients, df["group"].nunique(),
              total_patients == df["group"].nunique())
    )
    results.append(
        check("images conserved", sum(len(s) for s in splits.values()), len(df),
              sum(len(s) for s in splits.values()) == len(df))
    )

    assert all(results)


def test_split_ratios(passion_data):
    """Splits must land near the configured 80/10/10 (group splits are approximate)."""
    df, splits, cfg = passion_data
    header("DATASET 2/3 - split proportions (target 80/10/10)")

    target = cfg["data"]["splits"]
    section("Actual vs target")
    rows = []
    results = []
    for name in ["train", "val", "test"]:
        actual = len(splits[name]) / len(df)
        want = target[name]
        ok = abs(actual - want) <= 0.05  # grouping by patient prevents exactness
        rows.append([name, len(splits[name]), f"{actual:.1%}", f"{want:.0%}",
                     "PASS" if ok else "FAIL"])
        results.append(ok)
    table(rows, ["split", "images", "actual", "target", "status"])

    info("", "")
    info("note", "exact ratios are impossible: whole patients move together")

    assert all(results)


def test_label_and_fitzpatrick_distribution(passion_data):
    """Every split must contain every class, with the distribution reported."""
    df, splits, _ = passion_data
    header("DATASET 3/3 - label & Fitzpatrick distribution")

    present = sorted(df["label_idx"].unique())

    section("Class distribution per split (PASSION -> 11-class schema)")
    rows = []
    for idx in present:
        rows.append([
            idx,
            IDX_TO_CLASS.get(idx, f"class{idx}"),
            int((df["label_idx"] == idx).sum()),
            int((splits["train"]["label_idx"] == idx).sum()),
            int((splits["val"]["label_idx"] == idx).sum()),
            int((splits["test"]["label_idx"] == idx).sum()),
        ])
    table(rows, ["idx", "class", "total", "train", "val", "test"])

    section("Fitzpatrick skin-type distribution")
    ft_rows = []
    for ft in sorted(df["fitzpatrick_type"].unique()):
        tag = "dark skin (IV-VI)" if ft in DARK_TYPES else ""
        ft_rows.append([f"type {ft}", int((df["fitzpatrick_type"] == ft).sum()), tag])
    table(ft_rows, ["fitzpatrick", "images", "note"])

    dark = int(df["fitzpatrick_type"].isin(DARK_TYPES).sum())
    info("", "")
    info("dark-skin images (IV-VI)", f"{dark} / {len(df)} ({dark / len(df):.1%})")

    section("Checks")
    results = [
        check("classes found", len(present), "> 1 (non-degenerate)", len(present) > 1),
        check("no unmapped labels", all(i in IDX_TO_CLASS for i in present),
              "True", all(i in IDX_TO_CLASS for i in present)),
    ]
    for name in ["train", "val", "test"]:
        got = set(splits[name]["label_idx"].unique())
        results.append(
            check(f"{name}: all classes present", f"{len(got)}/{len(present)}",
                  "every class", got == set(present))
        )
    results.append(
        check("dark-skin images present", dark, "> 0", dark > 0)
    )

    assert all(results)
