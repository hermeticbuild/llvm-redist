#!/usr/bin/env bash
set -euo pipefail

ARTIFACT="${1:?usage: tools/verify-attestation.sh <artifact> [source-ref]}"
SOURCE_REF="${2:-${SOURCE_REF:-}}"
REPO="${REPO:-hermeticbuild/llvm-redist}"
SIGNER_WORKFLOW="${SIGNER_WORKFLOW:-hermeticbuild/llvm-redist/.github/workflows/reusable-repack.yml}"

cmd=(
    gh attestation verify
    "${ARTIFACT}"
    --repo "${REPO}"
    --signer-workflow "${SIGNER_WORKFLOW}"
)

if [[ -n "${SOURCE_REF}" ]]; then
    cmd+=(--source-ref "${SOURCE_REF}")
fi

"${cmd[@]}"
