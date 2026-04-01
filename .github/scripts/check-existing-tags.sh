#!/usr/bin/env bash
set -euo pipefail

FORCE_BUILD="${FORCE_BUILD:-false}"
GHCR_REPO="${GHCR_REPO:-}"
VERSION="${VERSION:-}"

if [[ -z "$GHCR_REPO" || -z "$VERSION" ]]; then
    echo "Missing required inputs. Expected GHCR_REPO and VERSION" >&2
    exit 1
fi

if [[ "$FORCE_BUILD" == "true" ]]; then
    echo "skip_build=false"
    exit 0
fi

# Check if image exists: anonymous first, then authenticated fallback.
# This ensures read-only checks work even if registry credentials are
# misconfigured, since GHCR public images are readable without auth.
image_exists=false

if command -v crane >/dev/null 2>&1; then
    # Anonymous first (DOCKER_CONFIG=/dev/null ignores stored credentials)
    if DOCKER_CONFIG=/dev/null crane digest "${GHCR_REPO}:${VERSION}" >/dev/null 2>&1; then
        image_exists=true
    # Authenticated fallback (uses docker login credentials)
    elif crane digest "${GHCR_REPO}:${VERSION}" >/dev/null 2>&1; then
        image_exists=true
    fi
else
    # docker manifest inspect uses whatever auth is configured
    if docker manifest inspect "${GHCR_REPO}:${VERSION}" >/dev/null 2>&1; then
        image_exists=true
    fi
fi

if [[ "$image_exists" == "true" ]]; then
    echo "Image version already present in GHCR; skipping build"
    echo "skip_build=true"
    exit 0
fi

echo "Image version not found in GHCR; building"
echo "skip_build=false"
