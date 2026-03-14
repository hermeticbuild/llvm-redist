#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?usage: tools/next-release-tag.sh <version>}"
REPO="${REPO:-}"

prefix="llvmorg-${VERSION}-r"
max_revision=0

if [[ -n "${REPO}" ]]; then
    release_tags="$(gh release list --repo "${REPO}" --limit 1000 --json tagName --jq '.[].tagName')"
else
    release_tags="$(gh release list --limit 1000 --json tagName --jq '.[].tagName')"
fi

while IFS= read -r tag; do
    if [[ "${tag}" =~ ^${prefix}([0-9]+)$ ]]; then
        revision="${BASH_REMATCH[1]}"
        if (( revision > max_revision )); then
            max_revision="${revision}"
        fi
    fi
done <<< "${release_tags}"

printf 'llvmorg-%s-r%d\n' "${VERSION}" "$((max_revision + 1))"
