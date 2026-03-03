#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?usage: tools/create-release.sh <version> <artifact> [checksum]}"
ARTIFACT="${2:?usage: tools/create-release.sh <version> <artifact> [checksum]}"
CHECKSUM="${3:-}"

TAG="llvmorg-${VERSION}-zst"
TITLE="LLVM ${VERSION} source tar.zst"
NOTES="Repacked from upstream release llvmorg-${VERSION}."

if [[ -n "${CHECKSUM}" ]]; then
    ASSETS=("${ARTIFACT}" "${CHECKSUM}")
else
    ASSETS=("${ARTIFACT}")
fi

if gh release view "${TAG}" >/dev/null 2>&1; then
    gh release upload "${TAG}" "${ASSETS[@]}" --clobber
else
    gh release create "${TAG}" "${ASSETS[@]}" --title "${TITLE}" --notes "${NOTES}"
fi
