#!/usr/bin/env bash
# =============================================================================
# Shared Retry Library
# =============================================================================
# Provides retry helpers with exponential backoff and rate-limit detection.
#
# Functions:
#   run_with_retry CMD [ARGS...]        — runs command, retries on failure
#   run_with_retry_output CMD [ARGS...] — same, but captures stdout
#
# Exit codes:
#   0  success
#   1  generic failure after all retries
#   2  rate-limited (429 / "toomanyrequests" detected in stderr)
#
# Environment:
#   RETRY_MAX       max attempts      (default: 5)
#   RETRY_DELAY     initial delay (s) (default: 2)
#   RETRY_BACKOFF   multiplier        (default: 2)
# =============================================================================

: "${RETRY_MAX:=5}"
: "${RETRY_DELAY:=2}"
: "${RETRY_BACKOFF:=2}"

# ── run_with_retry ──────────────────────────────────────────────────────────
# Runs a command with retries.  Returns 0 on success, 1 on generic failure,
# 2 when all failures were rate-limit related.
run_with_retry() {
  local attempt=1
  local delay="$RETRY_DELAY"
  local rate_limited=false
  local err_file
  err_file="$(mktemp)"

  while (( attempt <= RETRY_MAX )); do
    if "$@" 2>"$err_file"; then
      rm -f "$err_file"
      return 0
    fi

    if grep -qiE '429|toomanyrequests|rate.limit' "$err_file" 2>/dev/null; then
      rate_limited=true
      echo "::warning::Rate limited on attempt $attempt/$RETRY_MAX — backing off ${delay}s" >&2
    else
      cat "$err_file" >&2
      if (( attempt < RETRY_MAX )); then
        echo "::warning::Attempt $attempt/$RETRY_MAX failed — retrying in ${delay}s" >&2
      fi
    fi

    sleep "$delay"
    delay=$(( delay * RETRY_BACKOFF ))
    (( attempt++ ))
  done

  rm -f "$err_file"
  if [[ "$rate_limited" == "true" ]]; then
    return 2
  fi
  return 1
}

# ── run_with_retry_output ───────────────────────────────────────────────────
# Like run_with_retry but captures stdout (caller reads via $()).
run_with_retry_output() {
  local attempt=1
  local delay="$RETRY_DELAY"
  local rate_limited=false
  local out_file err_file
  out_file="$(mktemp)"
  err_file="$(mktemp)"

  while (( attempt <= RETRY_MAX )); do
    if "$@" >"$out_file" 2>"$err_file"; then
      cat "$out_file"
      rm -f "$out_file" "$err_file"
      return 0
    fi

    if grep -qiE '429|toomanyrequests|rate.limit' "$err_file" 2>/dev/null; then
      rate_limited=true
      echo "::warning::Rate limited on attempt $attempt/$RETRY_MAX — backing off ${delay}s" >&2
    else
      cat "$err_file" >&2
      echo "::warning::Attempt $attempt/$RETRY_MAX failed — retrying in ${delay}s" >&2
    fi

    sleep "$delay"
    delay=$(( delay * RETRY_BACKOFF ))
    (( attempt++ ))
  done

  rm -f "$out_file" "$err_file"
  if [[ "$rate_limited" == "true" ]]; then
    return 2
  fi
  return 1
}
