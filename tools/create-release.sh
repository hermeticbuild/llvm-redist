#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?usage: tools/create-release.sh <version> <artifact> [checksum] [tag] [extra-assets...]}"
ARTIFACT="${2:?usage: tools/create-release.sh <version> <artifact> [checksum] [tag] [extra-assets...]}"
CHECKSUM="${3:-}"
TAG="${4:-llvmorg-${VERSION}-r1}"
shift 4 || true

TITLE="LLVM ${VERSION} (repacked)"
NOTES="Repacked from upstream release llvmorg-${VERSION}."

if [[ -n "${CHECKSUM}" ]]; then
    ASSETS=("${ARTIFACT}" "${CHECKSUM}")
else
    ASSETS=("${ARTIFACT}")
fi

if (( $# > 0 )); then
    ASSETS+=("$@")
fi

if gh release view "${TAG}" >/dev/null 2>&1; then
    gh release upload "${TAG}" "${ASSETS[@]}" --clobber
else
    gh release create "${TAG}" "${ASSETS[@]}" --title "${TITLE}" --notes "${NOTES}"
fi
