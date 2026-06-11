# Dataset Status

## Currently Active

Merged training schema: **11 classes** (HAM10000's 7 cancer/lesion classes +
PASSION's 4 infectious/inflammatory classes).

| Dataset | Classes contributed | Images | Fitzpatrick Labels | Status |
|---------|--------------------|--------|--------------------|--------|
| HAM10000 | 7 (idx 0-6) | 10,015 | No | Active — training |
| PASSION | 4 (idx 7-10) | 4,901 | Yes (types 3-6; IV-VI are the dark-skin focus) | Active — access granted 2026-06-10 |

## Pending Access

| Dataset | Classes | Images | Fitzpatrick Labels | Status |
|---------|---------|--------|--------------------|--------|
| Fitzpatrick17k | 12 | 16,577 | Yes (I-VI) | Access requested — pending |
| eSkinHealth | 47 | 5,623 | Yes (IV-VI) | Access requested — no response |

## Migration Plan

When Fitzpatrick17k access is granted:

1. Run `02_preprocess.py` with `fitzpatrick17k_path` set
2. Merge manifests using `src/data/preprocessing.py` `merge_manifests()`
3. Reconcile the class schema (HAM/PASSION union vs Fitzpatrick17k 12-class)
   and update `config.yaml` `num_classes` / `class_names` accordingly
4. Retrain teacher from the HAM10000 + PASSION checkpoint (fine-tune, do not
   train from scratch)
5. Re-run distillation, export, evaluate
6. Expand GAN augmentation to all available Fitzpatrick IV-VI sources

## Impact on Project Objectives

- **RQ1:** Answerable with HAM10000 + PASSION (accuracy + latency target)
- **RQ2:** Now partially answerable — PASSION provides Fitzpatrick IV-VI labels.
  Full bias audit enabled. GAN augmentation pipeline now unblocked.
- **RQ3:** Fully answerable — Grad-CAM usability independent of dataset
- **RQ4:** Now answerable — PASSION supplies real Fitzpatrick IV-VI seed images
  for GAN synthesis (quality further improves if Fitzpatrick17k is added)

All pipeline code is dataset-agnostic. No architectural changes needed when
Fitzpatrick17k arrives.
