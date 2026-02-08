#!/usr/bin/env bash
# Source this script:
#   source scripts/setup_cdt_env.sh
#
# It sets your shell session for CDT training:
# - cd repo root (auto-detected by default)
# - conda activate cdt-run (if available)
# - dataset path
# - W&B mode/entity/project
# - optional local secrets from scripts/cdt.env (not tracked)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${REPO_DIR:-${DEFAULT_REPO_DIR}}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-cdt-run}"
export DSRL_DATASET_DIR="${DSRL_DATASET_DIR:-${HOME}/autodl-tmp/dsrl_datasets}"
export WANDB_MODE="${WANDB_MODE:-online}"
export WANDB_ENTITY="${WANDB_ENTITY:-sjjvic}"
export WANDB_PROJECT="${WANDB_PROJECT:-OSRL-baselines}"

LOCAL_ENV_FILE="${LOCAL_ENV_FILE:-${REPO_DIR}/scripts/cdt.env}"
if [[ -f "${LOCAL_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${LOCAL_ENV_FILE}"
fi

if command -v conda >/dev/null 2>&1; then
  CONDA_BASE="$(conda info --base 2>/dev/null || true)"
  if [[ -n "${CONDA_BASE}" && -f "${CONDA_BASE}/etc/profile.d/conda.sh" ]]; then
    # shellcheck disable=SC1091
    source "${CONDA_BASE}/etc/profile.d/conda.sh"
  fi
fi

cd "${REPO_DIR}"
if command -v conda >/dev/null 2>&1 && conda env list | awk '{print $1}' | grep -qx "${CONDA_ENV_NAME}"; then
  conda activate "${CONDA_ENV_NAME}"
else
  echo "[setup] skip conda activate: env '${CONDA_ENV_NAME}' not found"
fi

# Optional: set WANDB_API_KEY in your shell before sourcing this script.
if [[ -n "${WANDB_API_KEY:-}" ]]; then
  wandb login --relogin "${WANDB_API_KEY}"
fi

echo "[setup] pwd=$(pwd)"
echo "[setup] conda env=${CONDA_DEFAULT_ENV:-unknown}"
echo "[setup] DSRL_DATASET_DIR=${DSRL_DATASET_DIR}"
echo "[setup] WANDB_MODE=${WANDB_MODE}, WANDB_ENTITY=${WANDB_ENTITY}, WANDB_PROJECT=${WANDB_PROJECT}"
