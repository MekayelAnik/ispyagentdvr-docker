#!/usr/bin/env bash
# Self-check for the package-refresh rebuild in the auto-check branch of
# "Determine versions to build".
#
# The rule: with no missing versions to build, rebuild the LATEST version once its
# published image ages past MAX_IMAGE_AGE_DAYS, so Debian updates in the base image
# reach the shipped image. Older static version tags must never be touched.
#
# Config precedence mirrors the workflow: repository_dispatch client_payload >
# repo variable > default (enabled, 30 days). No registry is contacted; the image
# creation date is passed in.
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

LATEST_VERSION=7.9.2.0

# $1 = age in days of the latest version's image ("none" = unreadable)
# $2 = comma-separated versions already selected for build
decide() {
  local age=$1 MISSING_VERSIONS=$2
  local PACKAGE_REFRESH MAX_IMAGE_AGE_DAYS
  PACKAGE_REFRESH="${CP_PACKAGE_REFRESH:-${VAR_PACKAGE_REFRESH:-true}}"
  MAX_IMAGE_AGE_DAYS="${CP_MAX_IMAGE_AGE_DAYS:-${VAR_MAX_IMAGE_AGE_DAYS:-30}}"

  if [ "$PACKAGE_REFRESH" == "true" ] && [ "$MAX_IMAGE_AGE_DAYS" != "0" ] \
     && ! echo ",$MISSING_VERSIONS," | grep -q ",$LATEST_VERSION,"; then
    local CREATED=""
    [ "$age" != "none" ] && CREATED=$(date -u -d "${age} days ago" +%Y-%m-%dT%H:%M:%SZ)
    if [ -n "$CREATED" ]; then
      local CREATED_EPOCH AGE_DAYS
      CREATED_EPOCH=$(date -d "$CREATED" +%s 2>/dev/null || echo 0)
      if [ "$CREATED_EPOCH" -gt 0 ]; then
        AGE_DAYS=$(( ( $(date +%s) - CREATED_EPOCH ) / 86400 ))
        if [ "$AGE_DAYS" -ge "$MAX_IMAGE_AGE_DAYS" ]; then
          MISSING_VERSIONS="${LATEST_VERSION}${MISSING_VERSIONS:+,$MISSING_VERSIONS}"
        fi
      fi
    fi
  fi
  echo "$MISSING_VERSIONS"
}

echo "== fresh image, nothing else to build =="
[ "$(decide 5 '')" = "" ] || fail "rebuilt a 5-day-old image"
echo "  no rebuild"

echo "== 29 vs 30 days =="
[ "$(decide 29 '')" = "" ] || fail "rebuilt at 29d under a 30d threshold"
[ "$(decide 30 '')" = "$LATEST_VERSION" ] || fail "no rebuild at exactly 30d"
echo "  boundary correct"

echo "== latest only: old static versions are never added =="
out=$(decide 90 '')
[ "$out" = "$LATEST_VERSION" ] || fail "expected only $LATEST_VERSION, got '$out'"
echo "  only $LATEST_VERSION selected"

echo "== does not duplicate a version already queued =="
out=$(decide 90 "$LATEST_VERSION")
[ "$out" = "$LATEST_VERSION" ] || fail "duplicated the latest version: '$out'"
echo "  no duplicate"

echo "== prepends without dropping other missing versions =="
out=$(decide 90 "7.8.1.0,7.8.2.0")
[ "$out" = "$LATEST_VERSION,7.8.1.0,7.8.2.0" ] || fail "backfill list mangled: '$out'"
echo "  backfill preserved"

echo "== disabled via dispatch payload package_refresh=false =="
out=$(CP_PACKAGE_REFRESH=false decide 400 '')
[ "$out" = "" ] || fail "payload false ignored -- the GitHub-expression trap"
echo "  no rebuild"

echo "== disabled via repo var =="
out=$(VAR_PACKAGE_REFRESH=false decide 400 '')
[ "$out" = "" ] || fail "repo var false ignored"
out=$(VAR_MAX_IMAGE_AGE_DAYS=0 decide 400 '')
[ "$out" = "" ] || fail "max_image_age_days=0 ignored"
echo "  no rebuild"

echo "== payload beats repo var, both directions =="
out=$(CP_PACKAGE_REFRESH=true VAR_PACKAGE_REFRESH=false decide 40 '')
[ "$out" = "$LATEST_VERSION" ] || fail "payload true did not override repo var false"
out=$(CP_PACKAGE_REFRESH=false VAR_PACKAGE_REFRESH=true decide 40 '')
[ "$out" = "" ] || fail "payload false did not override repo var true"
echo "  precedence correct"

echo "== payload threshold =="
[ "$(CP_MAX_IMAGE_AGE_DAYS=14 decide 20 '')" = "$LATEST_VERSION" ] || fail "20d not rebuilt at a 14d threshold"
[ "$(CP_MAX_IMAGE_AGE_DAYS=14 decide 10 '')" = "" ] || fail "10d rebuilt at a 14d threshold"
echo "  honoured both ways"

echo "== string payload values (as cronjob.org sends them) =="
[ "$(CP_PACKAGE_REFRESH='false' decide 400 '')" = "" ] || fail "string 'false' not honoured"
[ "$(CP_MAX_IMAGE_AGE_DAYS='14' decide 20 '')" = "$LATEST_VERSION" ] || fail "string threshold not honoured"
echo "  strings and booleans both work"

echo "== default enabled with nothing configured =="
[ "$(decide 40 '')" = "$LATEST_VERSION" ] || fail "default should be enabled"
echo "  defaults to true"

echo "== unreadable creation date degrades safely =="
[ "$(decide none '')" = "" ] || fail "built on an unreadable creation date"
echo "  skipped, no build"

echo "ALL CHECKS PASSED"
