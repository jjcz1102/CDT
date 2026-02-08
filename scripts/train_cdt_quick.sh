#!/usr/bin/env bash
set -euo pipefail

# Edit defaults below when needed, then run:
#   bash scripts/train_cdt_quick.sh
#
# This script includes:
# - cd repo root (auto-detected by default)
# - conda activate cdt-run (if available)

TASK="${TASK:-OfflineCarCircle-v0}"
DEVICE="${DEVICE:-cuda:0}"
UPDATE_STEPS="${UPDATE_STEPS:-20}"
EVAL_EVERY="${EVAL_EVERY:-20}"
EVAL_EPISODES="${EVAL_EPISODES:-1}"
BATCH_SIZE="${BATCH_SIZE:-128}"
NUM_WORKERS="${NUM_WORKERS:-0}"
LOGDIR="${LOGDIR:-/root/autodl-tmp/logs}"
DATASET_DIR="${DSRL_DATASET_DIR:-${HOME}/autodl-tmp/dsrl_datasets}"
WANDB_MODE="${WANDB_MODE:-online}"
WANDB_PROJECT="${WANDB_PROJECT:-OSRL-baselines}"
WANDB_GROUP="${WANDB_GROUP:-autodl-quick-test}"
WANDB_ENTITY="${WANDB_ENTITY:-sjjvic-university-of-kansas}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${REPO_DIR:-${DEFAULT_REPO_DIR}}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-cdt-run}"
LOCAL_ENV_FILE="${LOCAL_ENV_FILE:-${REPO_DIR}/scripts/cdt.env}"

if command -v conda >/dev/null 2>&1; then
  CONDA_BASE="$(conda info --base 2>/dev/null || true)"
  if [[ -n "${CONDA_BASE}" && -f "${CONDA_BASE}/etc/profile.d/conda.sh" ]]; then
    # shellcheck disable=SC1091
    source "${CONDA_BASE}/etc/profile.d/conda.sh"
  fi
fi

if [[ -f "${LOCAL_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${LOCAL_ENV_FILE}"
fi

cd "${REPO_DIR}"
if [[ "${CONDA_DEFAULT_ENV:-}" == "${CONDA_ENV_NAME}" ]]; then
  :
elif command -v conda >/dev/null 2>&1; then
  conda activate "${CONDA_ENV_NAME}" || echo "[train] skip conda activate: env '${CONDA_ENV_NAME}' not found"
else
  echo "[train] skip conda activate: conda not found"
fi
export DSRL_DATASET_DIR="${DATASET_DIR}"
export WANDB_MODE
export WANDB_ENTITY

if [[ "${WANDB_MODE}" == "online" ]]; then
  if [[ -n "${WANDB_API_KEY:-}" ]]; then
    # wandb 0.14 expects a legacy 40-char key; new keys start with "wandb_v1_".
    if [[ "${WANDB_API_KEY}" == wandb_v1_* ]]; then
      echo "[train] WANDB_API_KEY is 'wandb_v1_*' format; wandb 0.14 may reject it."
      echo "[train] Switch to WANDB_MODE=offline, or upgrade wandb, or use a legacy 40-char key."
      exit 1
    fi
    wandb login --relogin "${WANDB_API_KEY}"
  else
    echo "[train] WANDB_MODE=online but WANDB_API_KEY is not set."
    echo "[train] Please run: wandb login"
  fi
fi

echo "[train] repo=${REPO_DIR}"
echo "[train] task=${TASK}, device=${DEVICE}"
echo "[train] logdir=${LOGDIR}"
echo "[train] dsrl_dataset_dir=${DSRL_DATASET_DIR}"
echo "[train] wandb_mode=${WANDB_MODE}, entity=${WANDB_ENTITY}, project=${WANDB_PROJECT}, group=${WANDB_GROUP}"
python -m examples.train.train_cdt \
  --task "${TASK}" \
  --device "${DEVICE}" \
  --batch_size "${BATCH_SIZE}" \
  --num_workers "${NUM_WORKERS}" \
  --update_steps "${UPDATE_STEPS}" \
  --eval_every "${EVAL_EVERY}" \
  --eval_episodes "${EVAL_EPISODES}" \
  --project "${WANDB_PROJECT}" \
  --group "${WANDB_GROUP}" \
  --logdir "${LOGDIR}"

echo "[train] done"
