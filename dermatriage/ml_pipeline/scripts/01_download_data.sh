#!/usr/bin/env bash
# ============================================================================
# DermaTriage — dataset download helper
#
# Fitzpatrick17k must be downloaded manually from Harvard Dataverse (no public
# API token-free download). HAM10000 is pulled from Kaggle via the Kaggle CLI.
# Existing data directories are left untouched.
# ============================================================================
set -euo pipefail

# Resolve ml_pipeline/ root regardless of where the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RAW_DIR="${ROOT_DIR}/data/raw"

FITZ_DIR="${RAW_DIR}/fitzpatrick17k"
HAM_DIR="${RAW_DIR}/ham10000"

mkdir -p "${RAW_DIR}"

# ----------------------------------------------------------------------------
# Fitzpatrick17k (manual download)
# ----------------------------------------------------------------------------
if [ -d "${FITZ_DIR}" ] && [ -n "$(ls -A "${FITZ_DIR}" 2>/dev/null)" ]; then
  echo "[skip] Fitzpatrick17k already present at ${FITZ_DIR}"
else
  cat <<EOF
============================================================================
Fitzpatrick17k — MANUAL DOWNLOAD REQUIRED
----------------------------------------------------------------------------
1. Open the Harvard Dataverse record:
     https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/DBY0RG
2. Download the dataset archive (images + fitzpatrick17k.csv metadata).
3. Extract its contents into:
     ${FITZ_DIR}/
   so that the metadata CSV and image folders live directly inside it.
============================================================================
EOF
fi

# ----------------------------------------------------------------------------
# HAM10000 (Kaggle CLI)
# ----------------------------------------------------------------------------
if [ -d "${HAM_DIR}" ] && [ -n "$(ls -A "${HAM_DIR}" 2>/dev/null)" ]; then
  echo "[skip] HAM10000 already present at ${HAM_DIR}"
else
  echo "[info] Downloading HAM10000 from Kaggle..."
  if ! command -v kaggle >/dev/null 2>&1; then
    echo "[error] The 'kaggle' CLI is not installed or not on PATH." >&2
    echo "        Install it with: pip install kaggle" >&2
    echo "        and place your kaggle.json token in ~/.kaggle/." >&2
    exit 1
  fi

  mkdir -p "${HAM_DIR}"
  ZIP_PATH="${RAW_DIR}/ham10000.zip"

  kaggle datasets download kmader/skin-lesion-analysis-toward-melanoma-detection \
    -p "${RAW_DIR}" --force
  # The Kaggle CLI names the archive after the dataset slug.
  DOWNLOADED_ZIP="${RAW_DIR}/skin-lesion-analysis-toward-melanoma-detection.zip"
  if [ -f "${DOWNLOADED_ZIP}" ]; then
    mv "${DOWNLOADED_ZIP}" "${ZIP_PATH}"
  fi

  echo "[info] Unzipping HAM10000 into ${HAM_DIR}/ ..."
  unzip -o -q "${ZIP_PATH}" -d "${HAM_DIR}"
  rm -f "${ZIP_PATH}"
  echo "[done] HAM10000 extracted to ${HAM_DIR}"
fi

echo "[done] Dataset download step complete."
