# DermaTriage

**Offline, AI-assisted skin-disease triage for community health workers (CHWs).**

DermaTriage pairs a compact on-device classifier with an equity-first training
pipeline to help CHWs triage skin conditions where dermatologists are scarce and
connectivity is unreliable. A photo of a lesion is classified into one of 12
harmonised conditions and mapped to a clear triage action — **Urgent Referral**,
**Monitor**, or **Treat Locally** — entirely offline on a mid-range phone.

The project explicitly targets the well-documented under-performance of skin AI
on darker skin: a conditional WGAN-GP synthesises Fitzpatrick IV–VI training
images, and a custom **Deployment Viability Score (DVS)** weighs demographic
equity alongside accuracy, latency and model size.

> ⚠️ **Research prototype — not a medical device.** Predictions are decision
> support only and must never replace clinical judgement. Always refer when in
> doubt.

---

## Repository structure

```text
dermatriage/
├── ml_pipeline/                 # Python: data, training, evaluation
│   ├── config.yaml              # All hyperparameters
│   ├── Makefile                 # make data | gan | teacher | distill | export | evaluate | audit
│   ├── requirements.txt
│   ├── scripts/                 # Numbered pipeline entry points (01–08)
│   ├── notebooks/               # 01_EDA, 02_bias_audit
│   └── src/
│       ├── data/                # Manifests, harmonisation, datasets, augmentation
│       ├── models/              # EfficientNet-B4 teacher, MobileNetV3 student
│       ├── gan/                 # Conditional WGAN-GP + synthetic export
│       ├── distillation/        # KD loss, distill loop, quantise, TFLite export
│       ├── evaluation/          # Metrics, DVS, Fitzpatrick equity, bias audit
│       ├── explainability/      # Grad-CAM
│       └── utils/               # Config, seeding, logging, checkpoints
└── flutter_app/                 # Flutter: offline mobile app
    ├── lib/
    │   ├── core/                # Constants, theme, router
    │   ├── data/                # Models, SQLite DAOs, TFLite inference
    │   ├── domain/              # Entities
    │   ├── presentation/        # Screens, widgets, providers
    │   └── services/            # Inference orchestration
    └── assets/models/           # Drop skin_triage_model.tflite here
```

---

## Quickstart

### ML pipeline

```bash
cd ml_pipeline
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 1. Download + preprocess datasets (see dataset table for manual steps)
make data

# 2. Train the pipeline end to end
make gan        # synthesise Fitzpatrick IV–VI images (WGAN-GP)
make teacher    # train EfficientNet-B4 teacher
make distill    # distill into MobileNetV3-Small student
make export     # quantise + export int8 TFLite
make evaluate   # metrics + Deployment Viability Score
make audit      # Fitzpatrick fairness audit

# …or run everything:  make all
```

Outputs (checkpoints, TFLite model, metrics, plots) land under `models/` and
`outputs/`. Experiment tracking via Weights & Biases is on by default; pass
`--no-wandb` to any training script to disable it.

### Flutter app

```bash
cd flutter_app
flutter pub get
flutter run            # on a connected device or emulator
```

The app ships with placeholder assets; see
[Swapping in the real model](#swapping-in-the-real-tflite-model) to enable
real predictions.

---

## Architecture summary

| Stage | What | Why |
|-------|------|-----|
| **Teacher** | EfficientNet-B4, ImageNet-pretrained, fine-tuned on real + synthetic data | High-capacity model that learns the 12-class taxonomy |
| **GAN augmentation** | Conditional WGAN-GP conditioned on (skin type, disease) | Generate Fitzpatrick IV–VI lesions to correct dark-skin under-representation |
| **Student** | MobileNetV3-Small, knowledge-distilled from the teacher (soft KL + hard CE) | Small, fast model suitable for on-device inference |
| **Quantisation** | int8 dynamic-range / integer TFLite export | Fit the ≤10 MB / ≤2000 ms on-device budget |
| **DVS** | Weighted score: accuracy 0.40, latency 0.25, size 0.15, **equity 0.20** | Single deployment-readiness metric that bakes in fairness |

Equity is measured as `1 − (max − min accuracy across Fitzpatrick IV–VI)`, so a
model is rewarded for closing — not just maximising — accuracy gaps.

---

## Datasets

| Dataset | Role | Skin-tone coverage | Status |
|---------|------|--------------------|--------|
| **Fitzpatrick17k** | Primary training/eval; Fitzpatrick-labelled | I–VI | ✅ Available (Harvard Dataverse) |
| **HAM10000** | Additional dermoscopic training data | Skews lighter | ✅ Available (Kaggle) |
| **PASSION** | Dark-skin paediatric dermatology (Sub-Saharan Africa) | IV–VI | 🔶 Access requested |
| **eSkinHealth** | Dark-skin clinical dermatology incl. NTDs | IV–VI | 🔶 Access requested |

`make data` downloads HAM10000 via the Kaggle CLI and prints instructions for
the manual Fitzpatrick17k download. PASSION and eSkinHealth are pending data-use
agreements and are not required to run the pipeline; they will further strengthen
dark-skin coverage once granted.

---

## Swapping in the real TFLite model

The app references the model at `assets/models/skin_triage_model.tflite`
(`AppConstants.modelAssetPath`). To deploy a trained model:

1. Train and export from the pipeline:

   ```bash
   cd ml_pipeline && make export
   ```

   This writes the int8 TFLite model to the path in `config.yaml`
   (`quantisation.tflite_output_path`).

2. Copy it into the app and update the version marker:

   ```bash
   cp models/student_int8.tflite \
      ../flutter_app/assets/models/skin_triage_model.tflite
   echo "v1.0.0" > ../flutter_app/assets/models/model_version.txt
   ```

3. Rebuild the app (`flutter run` / `flutter build`). The bundled model is
   loaded on first launch; no code changes are required as long as the input is
   224×224×3 and the output is 12 logits.

Until a real model is dropped in, the inference path expects the asset to exist —
the placeholder build will surface a load error if the camera flow is run without
it.

---

## License

Released under the **MIT License**. See `LICENSE` for full text. Dataset usage is
governed by each dataset's own license / data-use agreement.

---

*DermaTriage — ALU Capstone 2026.*
