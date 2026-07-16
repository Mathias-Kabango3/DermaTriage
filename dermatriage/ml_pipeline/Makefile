# ============================================================================
# DermaTriage — ML pipeline Makefile
# Each target invokes the matching numbered script in scripts/, passing the
# shared config. Run `make all` for the full pipeline or any stage on its own.
# ============================================================================

PYTHON  ?= python
CONFIG  ?= config.yaml
SCRIPTS := scripts
# Tests run against the local venv if present, so `make test` works out of the box.
PYTEST  ?= $(if $(wildcard .venv/bin/pytest),.venv/bin/pytest,pytest)
PYTHON_VENV ?= $(if $(wildcard .venv/bin/python),.venv/bin/python,$(PYTHON))

.PHONY: data teacher gan distill export evaluate audit all clean test \
        test-preprocess test-dataset test-tflite test-validation curves \
        test-parity test-integration

## data: download datasets, harmonise labels and split into train/val/test
data:
	bash $(SCRIPTS)/01_download_data.sh
	$(PYTHON) $(SCRIPTS)/02_preprocess.py --config $(CONFIG)

## gan: train WGAN-GP and generate synthetic dark-skin images
gan:
	$(PYTHON) $(SCRIPTS)/04_train_gan.py --config $(CONFIG)

## teacher: train the EfficientNet-B4 teacher model
teacher:
	$(PYTHON) $(SCRIPTS)/03_train_teacher.py --config $(CONFIG)

## distill: distill teacher into the MobileNetV3-Small student
distill:
	$(PYTHON) $(SCRIPTS)/05_distill_student.py --config $(CONFIG)

## export: quantise and export the student to TFLite
export:
	$(PYTHON) $(SCRIPTS)/06_quantise_export.py --config $(CONFIG)

## evaluate: evaluate models and compute the Deployment Viability Score
evaluate:
	$(PYTHON) $(SCRIPTS)/07_evaluate.py --config $(CONFIG)

## audit: run the Fitzpatrick equity / fairness audit
audit:
	$(PYTHON) $(SCRIPTS)/08_bias_audit.py --config $(CONFIG)

## all: run the full pipeline end to end
all: data gan teacher distill export evaluate audit

## test: run all model-level unit tests with full reports
test:
	$(PYTEST) tests/ -v -s

## test-preprocess: preprocessing output shape / range checks
test-preprocess:
	$(PYTEST) tests/test_preprocessing.py -v -s

## test-dataset: dataset loader sanity (label distribution, patient overlap)
test-dataset:
	$(PYTEST) tests/test_dataset_split.py -v -s

## test-tflite: TFLite conversion numerical-equivalence check
test-tflite:
	$(PYTEST) tests/test_tflite_equivalence.py -v -s

## test-validation: validation curves / overfitting audit for the final model
test-validation:
	$(PYTEST) tests/test_training_validation.py -v -s

## test-parity: compare the Flutter app's predictions against PyTorch (needs test-integration first)
test-parity:
	$(PYTEST) tests/test_flutter_parity.py -v -s

## test-integration: run the Flutter/Dart half, then the Python comparison
test-integration:
	cd ../flutter_app && flutter test test/integration/model_parity_test.dart
	$(PYTEST) tests/test_flutter_parity.py -v -s

## curves: replot validation curves from the notebook logs into outputs/figures
curves:
	$(PYTHON_VENV) scripts/09_plot_validation_curves.py

## clean: remove generated artefacts (processed data, synthetic, models, logs)
clean:
	rm -rf data/processed data/synthetic models/*.tflite models/*.pt \
	       outputs logs wandb __pycache__ */__pycache__
