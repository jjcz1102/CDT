#!/usr/bin/env bash
set -euo pipefail

# Quick CDT health check: model init + forward/backward on GPU.
# Usage:
#   bash scripts/smoke_cdt.sh
#   DEVICE=cuda:0 STEPS=10 BATCH_SIZE=64 bash scripts/smoke_cdt.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

DEVICE="${DEVICE:-cuda:0}"
STEPS="${STEPS:-5}"
BATCH_SIZE="${BATCH_SIZE:-32}"

echo "[smoke] repo: ${REPO_ROOT}"
echo "[smoke] device=${DEVICE}, steps=${STEPS}, batch_size=${BATCH_SIZE}"

python -m examples.train.smoke_cdt \
  --device "${DEVICE}" \
  --steps "${STEPS}" \
  --batch-size "${BATCH_SIZE}"

echo "[smoke] done"
