#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-21.1.8}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/out}"
TMP_BASE="${TMPDIR:-/tmp}"
WORK_DIR="$(mktemp -d "${TMP_BASE}/llvm-redist-${VERSION}.XXXXXX")"
LLVM_RELEASE_KEYS_URL="${LLVM_RELEASE_KEYS_URL:-https://releases.llvm.org/release-keys.asc}"

SRC_BASENAME="llvm-project-${VERSION}.src"
SRC_TAR_XZ="${SRC_BASENAME}.tar.xz"
SRC_TAR_GZ="${SRC_BASENAME}.tar.gz"
OUT_TAR_ZST="${OUT_DIR}/${SRC_BASENAME}.tar.zst"
SRC_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/${SRC_TAR_XZ}"
DOWNLOADED="${WORK_DIR}/${SRC_TAR_XZ}"
SIGNATURE_URL="${SRC_URL}.sig"
SIGNATURE="${DOWNLOADED}.sig"
RELEASE_KEYS="${WORK_DIR}/release-keys.asc"
GNUPG_HOME="${WORK_DIR}/gnupg"
ARCHIVE_ROOT="${SRC_BASENAME}"
VERIFY_SOURCE_SIGNATURE=1

cleanup() {
    rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

mkdir -p "${OUT_DIR}"

echo "Download: ${SRC_URL}"
if ! curl --fail --location --retry 5 --retry-delay 2 \
    --output "${DOWNLOADED}" \
    "${SRC_URL}"; then
    SRC_URL="https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${VERSION}.tar.gz"
    DOWNLOADED="${WORK_DIR}/${SRC_TAR_GZ}"
    ARCHIVE_ROOT="llvm-project-llvmorg-${VERSION}"
    VERIFY_SOURCE_SIGNATURE=0

    echo "Source archive asset not found; falling back to signed tag archive"
    echo "Download: ${SRC_URL}"
    curl --fail --location --retry 5 --retry-delay 2 \
        --output "${DOWNLOADED}" \
        "${SRC_URL}"
fi

if ((VERIFY_SOURCE_SIGNATURE)); then
    echo "Download: ${SIGNATURE_URL}"
    curl --fail --location --retry 5 --retry-delay 2 \
        --output "${SIGNATURE}" \
        "${SIGNATURE_URL}"

    echo "Download: ${LLVM_RELEASE_KEYS_URL}"
    curl --fail --location --retry 5 --retry-delay 2 \
        --output "${RELEASE_KEYS}" \
        "${LLVM_RELEASE_KEYS_URL}"

    if ! command -v gpg >/dev/null 2>&1; then
        echo "missing required dependency: gpg" >&2
        exit 1
    fi

    mkdir -m 700 "${GNUPG_HOME}"

    echo "Verify source signature"
    gpg --batch --quiet --homedir "${GNUPG_HOME}" --import "${RELEASE_KEYS}"
    gpg --batch --homedir "${GNUPG_HOME}" --verify "${SIGNATURE}" "${DOWNLOADED}"
else
    echo "Verify signed release tag"
    python3 -c 'import json, sys, urllib.request
ref = json.load(urllib.request.urlopen(sys.argv[1]))
if ref["object"]["type"] != "tag":
    raise SystemExit("release ref is not an annotated tag")
tag = json.load(urllib.request.urlopen(ref["object"]["url"]))
verification = tag.get("verification", {})
if verification.get("verified") is not True:
    raise SystemExit("release tag signature is not verified: " + str(verification.get("reason")))
' "https://api.github.com/repos/llvm/llvm-project/git/ref/tags/llvmorg-${VERSION}"
fi

echo "Extract: ${DOWNLOADED}"
bazel run //tools:bsdtar -- -xf "${DOWNLOADED}" -C "${WORK_DIR}"

if [[ "${ARCHIVE_ROOT}" != "${SRC_BASENAME}" ]]; then
    mv "${WORK_DIR}/${ARCHIVE_ROOT}" "${WORK_DIR}/${SRC_BASENAME}"
fi

echo "Repack: ${OUT_TAR_ZST}"
bazel run //tools:bsdtar -- \
    --options "zstd:compression-level=19,zstd:threads=16,zstd:frame-per-file" \
    -acf "${OUT_TAR_ZST}" \
    -C "${WORK_DIR}" \
    "${SRC_BASENAME}"

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${OUT_TAR_ZST}" > "${OUT_TAR_ZST}.sha256"
else
    shasum -a 256 "${OUT_TAR_ZST}" > "${OUT_TAR_ZST}.sha256"
fi

echo "Artifact: ${OUT_TAR_ZST}"
echo "Checksum: ${OUT_TAR_ZST}.sha256"
