#!/usr/bin/env bash
set -euo pipefail

tag="$(
    curl --fail --silent --show-error \
        https://api.github.com/repos/llvm/llvm-project/releases/latest \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
)"

if [[ -z "${tag}" ]]; then
    echo "failed to resolve latest llvm release tag" >&2
    exit 1
fi

version="${tag#llvmorg-}"
if [[ "${version}" == "${tag}" ]]; then
    echo "unexpected llvm tag format: ${tag}" >&2
    exit 1
fi

echo "${version}"
