# Dataset Status

## Currently Active

| Dataset | Classes | Images | Fitzpatrick Labels | Status |
|---------|---------|--------|--------------------|--------|
| HAM10000 | 7 | 10,015 | No | Active — training now |

## Pending Access

| Dataset | Classes | Images | Fitzpatrick Labels | Status |
|---------|---------|--------|--------------------|--------|
| Fitzpatrick17k | 12 | 16,577 | Yes (I-VI) | Access requested — pending |
| PASSION | ~20 | 4,901 | Yes (IV-VI) | Access requested — no response |
| eSkinHealth | 47 | 5,623 | Yes (IV-VI) | Access requested — no response |

## Migration Plan

When Fitzpatrick17k access is granted:

1. Run `02_preprocess.py` with `fitzpatrick17k_path` set
2. Merge manifests using `src/data/preprocessing.py` `merge_manifests()`
3. Update `config.yaml` `num_classes` back to 12
4. Retrain teacher from HAM10000 checkpoint (fine-tune, do not train from scratch)
5. Re-run distillation, export, evaluate
6. Enable GAN augmentation pipeline for Fitzpatrick types IV-VI

## Impact on Project Objectives

- **RQ1:** Answerable with HAM10000 (accuracy + latency target)
- **RQ2:** Partially blocked — Fitzpatrick-stratified bias audit requires Fitzpatrick17k
- **RQ3:** Fully answerable — Grad-CAM usability independent of dataset
- **RQ4:** Partially blocked — GAN augmentation quality requires Fitzpatrick IV-VI real images as seed data

All pipeline code is dataset-agnostic. No architectural changes needed when Fitzpatrick17k arrives.
