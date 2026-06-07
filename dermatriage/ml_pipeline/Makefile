# ============================================================================
# DermaTriage — ML pipeline Makefile
# Each target invokes the matching numbered script in scripts/, passing the
# shared config. Run `make all` for the full pipeline or any stage on its own.
# ============================================================================

PYTHON  ?= python
CONFIG  ?= config.yaml
SCRIPTS := scripts

.PHONY: data teacher gan distill export evaluate audit all clean

## data: prepare, harmonise labels and split datasets
data:
	$(PYTHON) $(SCRIPTS)/01_prepare_data.py --config $(CONFIG)

## gan: train WGAN-GP and generate synthetic dark-skin images
gan:
	$(PYTHON) $(SCRIPTS)/02_train_gan.py --config $(CONFIG)

## teacher: train the EfficientNet-B4 teacher model
teacher:
	$(PYTHON) $(SCRIPTS)/03_train_teacher.py --config $(CONFIG)

## distill: distill teacher into the MobileNetV3-Small student
distill:
	$(PYTHON) $(SCRIPTS)/05_distill_student.py --config $(CONFIG)

## export: quantise and export the student to TFLite
export:
	$(PYTHON) $(SCRIPTS)/06_export_tflite.py --config $(CONFIG)

## evaluate: evaluate models and compute the Deployment Viability Score
evaluate:
	$(PYTHON) $(SCRIPTS)/07_evaluate.py --config $(CONFIG)

## audit: run the Fitzpatrick equity / fairness audit
audit:
	$(PYTHON) $(SCRIPTS)/08_audit_equity.py --config $(CONFIG)

## all: run the full pipeline end to end
all: data gan teacher distill export evaluate audit

## clean: remove generated artefacts (processed data, synthetic, models, logs)
clean:
	rm -rf data/processed data/synthetic models/*.tflite models/*.pt \
	       outputs logs wandb __pycache__ */__pycache__
