#!/bin/bash
# Self-check for the download-API version discovery spliced into docker-build.yml's
# fetch-releases step.
#
# Case 1 runs against live upstream. Cases 2-4 replay the same logic against fixture
# data to cover the paths that live data does not currently exercise: the release-history
# page lagging a stable release, the page failing to parse at all, and every source dead.
set -eu

RELEASE_URL='https://www.ispyconnect.com/producthistory?productid=27'
BETA_API_URL='https://www.ispyconnect.com/api/Agent/DownloadLocation5?platform=Linux64&useVersion=0&useBeta=True'
STABLE_API_URL='https://www.ispyconnect.com/api/Agent/DownloadLocation5?platform=Linux64&useVersion=0&useBeta=False'
VERSION_LIMIT=20
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*"; exit 1; }

channel_version() {
  local url=$1 dl=""
  dl=$(curl -sfL "$url") || return 0
  echo "${dl//\"/}" | sed -nE 's#.*_([0-9]+)_([0-9]+)_([0-9]+)_([0-9]+)\.zip$#\1.\2.\3.\4#p'
}

splice_version() {
  local version=$1 is_beta=$2
  if [ -z "$version" ]; then return 0; fi
  if grep -qx "$version" "$WORK/versions.txt"; then return 0; fi
  { echo "$version"; cat "$WORK/versions.txt"; } > "$WORK/v.new" && mv "$WORK/v.new" "$WORK/versions.txt"
  { echo '-'; cat "$WORK/dates.txt"; } > "$WORK/d.new" && mv "$WORK/d.new" "$WORK/dates.txt"
  { echo "${version}|${is_beta}"; cat "$WORK/beta_status.txt"; } > "$WORK/b.new" && mv "$WORK/b.new" "$WORK/beta_status.txt"
}

# Mirrors the fetch-releases step. Reads the page from $WORK/releases.html and the two
# channel versions from $1/$2, and writes versions/dates/beta_status/releases into $WORK.
build_lists() {
  local stable_ver=$1 beta_ver=$2
  grep -oP '<td[^>]*>\d+\.\d+\.\d+\.\d+</td>' "$WORK/releases.html" | sed 's/<[^>]*>//g' | head -"$VERSION_LIMIT" > "$WORK/versions.txt" || true
  if [ ! -s "$WORK/versions.txt" ] && [ -z "$stable_ver" ] && [ -z "$beta_ver" ]; then
    return 1
  fi
  grep -oP '<td[^>]*>\d{1,2}/\d{1,2}/\d{4}</td>' "$WORK/releases.html" | sed 's/<[^>]*>//g' | head -"$VERSION_LIMIT" > "$WORK/dates.txt" || true
  tr '\n' ' ' < "$WORK/releases.html" | sed 's/  */ /g' > "$WORK/oneline.html"
  : > "$WORK/beta_status.txt"
  while IFS= read -r version; do
    ROW=$(grep -oP "<tr><td[^>]*>${version}</td><td[^>]*>.*?</td><td[^>]*>\d{1,2}/\d{1,2}/\d{4}</td></tr>" "$WORK/oneline.html" | head -1 || true)
    if echo "$ROW" | grep -q '(Beta):'; then echo "$version|true" >> "$WORK/beta_status.txt"
    else echo "$version|false" >> "$WORK/beta_status.txt"; fi
  done < "$WORK/versions.txt"

  HISTORY_LATEST_IS_BETA=$(head -1 "$WORK/beta_status.txt" | cut -d'|' -f2)
  splice_version "$stable_ver" "false"
  splice_version "$beta_ver" "true"

  paste -d'|' "$WORK/versions.txt" "$WORK/dates.txt" > "$WORK/temp.txt"
  paste -d'|' "$WORK/temp.txt" <(cut -d'|' -f2 "$WORK/beta_status.txt") > "$WORK/releases.txt"

  LATEST_VERSION=$(awk -F'|' '$3 != "true" { print $1; exit }' "$WORK/releases.txt")
  LATEST_IS_BETA="$HISTORY_LATEST_IS_BETA"
  LATEST_BETA_VERSION=$(grep '|true$' "$WORK/beta_status.txt" | head -1 | cut -d'|' -f1)
  if [ -n "$LATEST_BETA_VERSION" ] && [ -n "$LATEST_VERSION" ] && \
     [ "$(printf '%s\n%s\n' "$LATEST_BETA_VERSION" "$LATEST_VERSION" | sort -V | tail -1)" = "$LATEST_VERSION" ]; then
    LATEST_BETA_VERSION=""
  fi
  BETA_VERSIONS=$(awk -F'|' '{printf "\"%s\":%s,", $1, $2}' "$WORK/beta_status.txt" | sed 's/,$//' | sed 's/^/{/' | sed 's/$/}/')

  # check-stable: newest non-beta row, held when its date is unknown
  CANDIDATE_VERSION=""; CANDIDATE_DATE=""
  while IFS='|' read -r V D B; do
    if [ "$B" != "true" ] && [ -n "$V" ]; then CANDIDATE_VERSION="$V"; CANDIDATE_DATE="$D"; break; fi
  done < "$WORK/releases.txt"
  if [ -n "$CANDIDATE_VERSION" ] && ! echo "$CANDIDATE_DATE" | grep -qE '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'; then
    STABLE_CANDIDATE="<held>"
  else
    STABLE_CANDIDATE="$CANDIDATE_VERSION"
  fi
  return 0
}

check_alignment() {
  [ "$(wc -l < "$WORK/versions.txt")" = "$(wc -l < "$WORK/dates.txt")" ] || fail "dates.txt misaligned"
  [ "$(wc -l < "$WORK/versions.txt")" = "$(wc -l < "$WORK/beta_status.txt")" ] || fail "beta_status.txt misaligned"
  awk -F'|' 'NF!=3{exit 1}' "$WORK/releases.txt" || fail "releases.txt has a row without 3 fields"
}

# --- Case 1: live upstream -------------------------------------------------------------
echo "== Case 1: live upstream =="
curl -sfL "$RELEASE_URL" -o "$WORK/releases.html"
LIVE_STABLE=$(channel_version "$STABLE_API_URL")
LIVE_BETA=$(channel_version "$BETA_API_URL")
[ -n "$LIVE_STABLE" ] || fail "stable channel unresolved"
[ -n "$LIVE_BETA" ] || fail "beta channel unresolved"
build_lists "$LIVE_STABLE" "$LIVE_BETA" || fail "build_lists returned no-sources with live data"
echo "  latest=$LATEST_VERSION beta=$LATEST_BETA_VERSION stable_candidate=$STABLE_CANDIDATE is_beta=$LATEST_IS_BETA"
check_alignment
[ "$LATEST_IS_BETA" = "false" ] || fail "beta hijacked latest_is_beta"
[ "$LATEST_VERSION" != "$LATEST_BETA_VERSION" ] || fail ":latest points at the beta"
echo "$BETA_VERSIONS" | jq -e --arg v "$LATEST_BETA_VERSION" '.[$v] == true' > /dev/null || fail "beta_versions json wrong"
# the binaries setup.sh builds its URL from must exist for the beta
U="${LATEST_BETA_VERSION//./_}"
for b in Linux64 LinuxARM64 LinuxARM; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "https://files.ispyconnect.com/downloads/Agent_${b}_${U}.zip")
  [ "$code" = "200" ] || fail "Agent_${b}_${U}.zip -> HTTP $code"
done
echo "  beta binaries present for $LATEST_BETA_VERSION"
LIVE_PAGE_TOP=$(grep -oP '<td[^>]*>\d+\.\d+\.\d+\.\d+</td>' "$WORK/releases.html" | sed 's/<[^>]*>//g' | head -1)

# --- Case 2: page lags a stable release ------------------------------------------------
echo "== Case 2: release-history page missing the current stable release =="
LAG_STABLE="7.9.2.5"   # page still tops out at 7.9.2.0; beta channel is ahead of both
build_lists "$LAG_STABLE" "$LIVE_BETA" || fail "build_lists returned no-sources"
check_alignment
[ "$LATEST_VERSION" = "$LAG_STABLE" ] || fail "spliced stable not picked as latest (got $LATEST_VERSION)"
[ "$LATEST_BETA_VERSION" = "$LIVE_BETA" ] || fail "beta lost when stable also spliced"
[ "$(head -1 "$WORK/versions.txt")" = "$LIVE_BETA" ] || fail "beta not on top after both splices"
[ "$STABLE_CANDIDATE" = "<held>" ] || fail ":stable promoted off a dateless entry ($STABLE_CANDIDATE)"
echo "  latest=$LATEST_VERSION (built), :stable held, beta=$LATEST_BETA_VERSION"

# --- Case 3: page parses to nothing ----------------------------------------------------
echo "== Case 3: release-history page unparseable =="
echo '<html><body>moved</body></html>' > "$WORK/releases.html"
build_lists "$LIVE_STABLE" "$LIVE_BETA" || fail "hard-failed even though the API answered"
check_alignment
[ "$LATEST_VERSION" = "$LIVE_STABLE" ] || fail "API fallback did not yield the stable release"
[ "$LATEST_BETA_VERSION" = "$LIVE_BETA" ] || fail "API fallback did not yield the beta release"
[ "$STABLE_CANDIDATE" = "<held>" ] || fail ":stable promoted with no release dates available"
echo "  degraded to API-only: latest=$LATEST_VERSION beta=$LATEST_BETA_VERSION, :stable held"

# --- Case 3b: misconfigured API URL ------------------------------------------------------
echo "== Case 3b: API URL returns an error =="
# A bad useBeta value 400s -- the likeliest misconfiguration if the repo var is edited.
BAD=$(channel_version "${STABLE_API_URL%False}banana")
[ -z "$BAD" ] || fail "a 400 response yielded a version ($BAD)"
UNREACHABLE=$(channel_version "https://ispyconnect.invalid/nope")
[ -z "$UNREACHABLE" ] || fail "an unreachable host yielded a version ($UNREACHABLE)"
curl -sfL "$RELEASE_URL" -o "$WORK/releases.html"
build_lists "$BAD" "$LIVE_BETA" || fail "build_lists hard-failed with a usable page"
check_alignment
[ "$LATEST_VERSION" = "$LIVE_PAGE_TOP" ] || fail "unresolved stable channel disturbed :latest"
echo "  unresolved channels splice nothing; latest=$LATEST_VERSION from the page"

# --- Case 3c: the beta is promoted to stable -----------------------------------------
echo "== Case 3c: beta promoted to stable =="
# Page now lists the former beta WITHOUT a "(Beta):" marker, with an older beta still
# inside the scan window. The promoted version must build as a plain stable tag, and the
# stale historical beta must not become the :beta rolling target.
cat > "$WORK/releases.html" <<'HTML'
<tr><td valign="top">7.9.3.0</td><td valign="top">Stable notes</td><td valign="top">08/22/2026</td></tr>
<tr><td valign="top">7.9.2.0</td><td valign="top">Update download UI</td><td valign="top">08/13/2026</td></tr>
<tr><td valign="top">7.7.5.0</td><td valign="top"><p>(Beta):</p>Major UI refresh</td><td valign="top">07/24/2026</td></tr>
HTML
build_lists "7.9.3.0" "7.9.3.0" || fail "build_lists returned no-sources"
check_alignment
[ "$LATEST_VERSION" = "7.9.3.0" ] || fail "promoted version is not latest (got $LATEST_VERSION)"
[ -z "$LATEST_BETA_VERSION" ] || fail "stale beta $LATEST_BETA_VERSION kept as the :beta target"
echo "$BETA_VERSIONS" | jq -e '."7.9.3.0" == false' > /dev/null \
  || fail "promoted version still flagged beta -- would publish 7.9.3.0-beta again"
[ "$STABLE_CANDIDATE" = "7.9.3.0" ] || fail "stable candidate wrong: $STABLE_CANDIDATE"
echo "  builds as plain 7.9.3.0, :beta target cleared, :stable candidate 7.9.3.0"

# --- Case 3d: a newer beta appears after promotion -----------------------------------
echo "== Case 3d: newer beta after promotion =="
build_lists "7.9.3.0" "7.9.4.0" || fail "build_lists returned no-sources"
check_alignment
[ "$LATEST_BETA_VERSION" = "7.9.4.0" ] || fail "new beta not picked up (got $LATEST_BETA_VERSION)"
[ "$LATEST_VERSION" = "7.9.3.0" ] || fail "new beta hijacked :latest"
echo "  :beta target advances to 7.9.4.0, :latest stays 7.9.3.0"

# --- Case 4: every source dead ---------------------------------------------------------
echo "== Case 4: page unparseable and API unresolved =="
echo '<html><body>moved</body></html>' > "$WORK/releases.html"
if build_lists "" ""; then fail "expected the no-sources hard-fail"; fi
echo "  hard-fails as intended"

echo "ALL CHECKS PASSED (page top row: $LIVE_PAGE_TOP, stable API: $LIVE_STABLE, beta API: $LIVE_BETA)"
