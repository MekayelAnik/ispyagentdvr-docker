#!/usr/bin/env bash
set -euo pipefail

SCRIPT=".github/scripts/registry-sync.sh"
if [[ ! -f "$SCRIPT" ]]; then
    echo "registry_sync_script_missing" >&2
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ORIG_PATH="$PATH"
cat > "$TMPDIR/docker" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${MOCK_STATE_FILE:-}"
if [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
    echo "mock state file missing" >&2
    exit 1
fi

cmd="${1:-}"
if [[ "$cmd" != "buildx" ]]; then
    echo "unexpected docker command: $*" >&2
    exit 1
fi

subcmd="${2:-}"
if [[ "$subcmd" != "imagetools" ]]; then
    echo "unexpected docker buildx subcommand: $*" >&2
    exit 1
fi

action="${3:-}"
shift 3

case "$action" in
  inspect)
    ref="$1"
    platforms=$(awk -F'=' -v k="$ref" '$1==k {print $2}' "$STATE_FILE")
    if [[ -z "$platforms" ]]; then
      exit 1
    fi
    # Emit Digest line so cached_digest() can parse it (deterministic per-content hash)
    echo "Digest: sha256:$(echo -n "$platforms" | sha256sum | cut -d' ' -f1)"
    IFS=',' read -ra arr <<< "$platforms"
    for p in "${arr[@]}"; do
      echo "Platform: $p"
    done
    ;;
  create)
    if [[ "$1" != "-t" ]]; then
      echo "unexpected create args: $*" >&2
      exit 1
    fi
    target="$2"
    source_ref="$3"
    source_platforms=$(awk -F'=' -v k="$source_ref" '$1==k {print $2}' "$STATE_FILE")
    if [[ -z "$source_platforms" ]]; then
      echo "missing source ref: $source_ref" >&2
      exit 1
    fi
    tmpf="${STATE_FILE}.tmp"
    awk -F'=' -v k="$target" '$1!=k {print $0}' "$STATE_FILE" > "$tmpf"
    echo "${target}=${source_platforms}" >> "$tmpf"
    mv "$tmpf" "$STATE_FILE"
    ;;
  *)
    echo "unexpected imagetools action: $action" >&2
    exit 1
    ;;
esac
MOCK
chmod +x "$TMPDIR/docker"

cat > "$TMPDIR/crane" <<'MOCK_CRANE'
#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${MOCK_STATE_FILE:-}"
if [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
    echo "mock state file missing" >&2
    exit 1
fi

action="${1:-}"
shift

case "$action" in
  digest)
    ref="$1"
    platforms=$(awk -F'=' -v k="$ref" '$1==k {print $2}' "$STATE_FILE")
    if [[ -z "$platforms" ]]; then
      exit 1
    fi
    echo "sha256:$(echo -n "$platforms" | sha256sum | cut -d' ' -f1)"
    ;;
  copy)
    src="$1"
    dst="$2"
    source_platforms=$(awk -F'=' -v k="$src" '$1==k {print $2}' "$STATE_FILE")
    if [[ -z "$source_platforms" ]]; then
      echo "missing source ref: $src" >&2
      exit 1
    fi
    tmpf="${STATE_FILE}.tmp"
    awk -F'=' -v k="$dst" '$1!=k {print $0}' "$STATE_FILE" > "$tmpf"
    echo "${dst}=${source_platforms}" >> "$tmpf"
    mv "$tmpf" "$STATE_FILE"
    ;;
  tag)
    src="$1"
    dst_tag="$2"
    repo="${src%%:*}"
    source_platforms=$(awk -F'=' -v k="$src" '$1==k {print $2}' "$STATE_FILE")
    if [[ -z "$source_platforms" ]]; then
      echo "missing source ref: $src" >&2
      exit 1
    fi
    tmpf="${STATE_FILE}.tmp"
    awk -F'=' -v k="${repo}:${dst_tag}" '$1!=k {print $0}' "$STATE_FILE" > "$tmpf"
    echo "${repo}:${dst_tag}=${source_platforms}" >> "$tmpf"
    mv "$tmpf" "$STATE_FILE"
    ;;
  *)
    echo "unexpected crane action: $action" >&2
    exit 1
    ;;
esac
MOCK_CRANE
chmod +x "$TMPDIR/crane"

run_case() {
    local name="$1"
    local tags="$2"
    local state_content="$3"

    local state_file="$TMPDIR/state-${name}.txt"
    local out_file="$TMPDIR/out-${name}.log"

    printf "%s\n" "$state_content" > "$state_file"

    PATH="$TMPDIR:$ORIG_PATH" \
    MOCK_STATE_FILE="$state_file" \
    DOCKERHUB_REPO="dockerhub/repo" \
    GHCR_REPO="ghcr.io/org/repo" \
    TAGS="$tags" \
    bash "$SCRIPT" >"$out_file" 2>&1

    case "$name" in
      missing-both)
        grep -q "Tag v1: not found in either registry - skipping" "$out_file"
        ;;
      backfill-dh-to-ghcr)
        grep -q "Syncing v1: Docker Hub -> GHCR (backfill mode)" "$out_file"
        grep -q "ghcr.io/org/repo:v1=linux/amd64,linux/arm64" "$state_file"
        ;;
      backfill-ghcr-to-dh)
        grep -q "Syncing v1: GHCR -> Docker Hub" "$out_file"
        grep -q "dockerhub/repo:v1=linux/amd64,linux/arm64" "$state_file"
        ;;
      matching-skip)
        grep -q "digests match" "$out_file"
        ;;
      mismatch-sync)
        grep -q "Syncing v1: digest mismatch, GHCR -> Docker Hub" "$out_file"
        grep -q "dockerhub/repo:v1=linux/amd64,linux/arm64" "$state_file"
        grep -q "Synced v1 successfully" "$out_file"
        ;;
      duplicate-tags)
        grep -q "duplicate - skipping" "$out_file"
        ;;
      *)
        echo "unknown test case: $name" >&2
        exit 1
        ;;
    esac

    echo "PASS: $name"
}

run_case "missing-both" "v1" ""
run_case "backfill-dh-to-ghcr" "v1" "dockerhub/repo:v1=linux/amd64,linux/arm64"
run_case "backfill-ghcr-to-dh" "v1" "ghcr.io/org/repo:v1=linux/amd64,linux/arm64"
run_case "matching-skip" "v1" $'ghcr.io/org/repo:v1=linux/amd64,linux/arm64\ndockerhub/repo:v1=linux/amd64,linux/arm64'
run_case "mismatch-sync" "v1" $'ghcr.io/org/repo:v1=linux/amd64,linux/arm64\ndockerhub/repo:v1=linux/amd64'
run_case "duplicate-tags" "v1,v1" "ghcr.io/org/repo:v1=linux/amd64,linux/arm64"

echo "registry_sync_checks_ok"
