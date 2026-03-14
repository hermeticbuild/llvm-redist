#!/usr/bin/env bash
set -euo pipefail

ARTIFACT="${1:?usage: tools/download-attestation.sh <artifact> <repo> [output]}"
REPO="${2:?usage: tools/download-attestation.sh <artifact> <repo> [output]}"
OUTPUT="${3:-${ARTIFACT}.attestation.jsonl}"

artifact_dir="$(cd "$(dirname "${ARTIFACT}")" && pwd)"
artifact_name="$(basename "${ARTIFACT}")"

if command -v sha256sum >/dev/null 2>&1; then
    digest="$(sha256sum "${ARTIFACT}" | awk '{print $1}')"
else
    digest="$(shasum -a 256 "${ARTIFACT}" | awk '{print $1}')"
fi

bundle_name="sha256:${digest}.jsonl"
if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OS:-}" == Windows_NT ]]; then
    bundle_name="sha256-${digest}.jsonl"
fi

(
    cd "${artifact_dir}"
    gh attestation download "${artifact_name}" --repo "${REPO}"
    mv "${bundle_name}" "$(basename "${OUTPUT}")"
)

printf '%s\n' "${OUTPUT}"
