#!/bin/bash
# =============================================================================
# Version Utilities for iSpy Agent DVR Docker Build
# =============================================================================
# Provides reusable functions for version parsing, validation, and management
# =============================================================================

set -euo pipefail

# Configuration
RELEASE_URL="${RELEASE_URL:-https://www.ispyconnect.com/producthistory.aspx?productid=27}"
MAX_VERSIONS="${MAX_VERSIONS:-20}"

# =============================================================================
# Fetch and parse release history
# =============================================================================
fetch_releases() {
    local output_file="${1:-/tmp/releases.txt}"
    
    curl -sf "$RELEASE_URL" -o /tmp/releases.html || {
        echo "::error::Failed to fetch release history"
        return 1
    }
    
    # Extract versions and dates
    grep -oP '(?<=<td>)\d+\.\d+\.\d+\.\d+(?=</td>)' /tmp/releases.html | head -"$MAX_VERSIONS" > /tmp/versions.txt
    grep -oP '(?<=<td>)\d{1,2}/\d{1,2}/\d{4}(?=</td>)' /tmp/releases.html | head -"$MAX_VERSIONS" > /tmp/dates.txt
    
    paste -d'|' /tmp/versions.txt /tmp/dates.txt > "$output_file"
    
    echo "$(wc -l < /tmp/versions.txt) versions found"
}

# =============================================================================
# Get latest version
# =============================================================================
get_latest_version() {
    fetch_releases > /dev/null 2>&1
    head -1 /tmp/versions.txt
}

# =============================================================================
# Get available versions as JSON array
# =============================================================================
get_versions_json() {
    fetch_releases > /dev/null 2>&1
    cat /tmp/versions.txt | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# =============================================================================
# Check if version exists in release history
# =============================================================================
version_exists() {
    local version="$1"
    fetch_releases > /dev/null 2>&1
    grep -q "^${version}$" /tmp/versions.txt
}

# =============================================================================
# Expand version range (e.g., 7.0.5.0-7.0.9.0)
# =============================================================================
expand_range() {
    local start="$1"
    local end="$2"
    local in_range=false
    local found=""
    
    fetch_releases > /dev/null 2>&1
    
    while IFS= read -r version; do
        [[ "$version" == "$start" ]] && in_range=true
        [[ "$in_range" == "true" ]] && found="${found:+$found,}$version"
        [[ "$version" == "$end" ]] && break
    done < /tmp/versions.txt
    
    echo "$found"
}

# =============================================================================
# Parse and validate version input
# Returns: comma-separated list of valid versions
# =============================================================================
parse_versions() {
    local input="$1"
    local valid=""
    local missing=""
    
    fetch_releases > /dev/null 2>&1
    
    # Check if range format
    if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        local start="${input%-*}"
        local end="${input#*-}"
        valid=$(expand_range "$start" "$end")
    else
        # Comma-separated or single version
        IFS=',' read -ra versions <<< "$input"
        for v in "${versions[@]}"; do
            v=$(echo "$v" | xargs)
            if version_exists "$v"; then
                valid="${valid:+$valid,}$v"
            else
                missing="${missing:+$missing,}$v"
                echo "::warning::Version $v not found" >&2
            fi
        done
    fi
    
    echo "$valid"
}

# =============================================================================
# Check image existence in registry
# =============================================================================
image_exists() {
    local registry="$1"
    local tag="$2"
    skopeo inspect "docker://${registry}:${tag}" > /dev/null 2>&1
}

# =============================================================================
# Calculate days since release
# =============================================================================
days_since_release() {
    local version="$1"
    
    fetch_releases > /dev/null 2>&1
    
    local date_str=$(grep "^${version}|" /tmp/releases.txt | cut -d'|' -f2)
    [[ -z "$date_str" ]] && return 1
    
    local month=$(echo "$date_str" | cut -d'/' -f1)
    local day=$(echo "$date_str" | cut -d'/' -f2)
    local year=$(echo "$date_str" | cut -d'/' -f3)
    
    local release_epoch=$(date -d "$year-$month-$day" +%s 2>/dev/null || echo 0)
    local current_epoch=$(date +%s)
    
    echo $(( (current_epoch - release_epoch) / 86400 ))
}

# =============================================================================
# Generate date tag in Bangladesh time
# =============================================================================
generate_date_tag() {
    TZ=Asia/Dhaka date +"%d%m%Y"
}

# =============================================================================
# Main: Run specified function
# =============================================================================
case "${1:-}" in
    fetch) fetch_releases "${2:-/tmp/releases.txt}" ;;
    latest) get_latest_version ;;
    json) get_versions_json ;;
    exists) version_exists "$2" && echo "true" || echo "false" ;;
    expand) expand_range "$2" "$3" ;;
    parse) parse_versions "$2" ;;
    image-exists) image_exists "$2" "$3" && echo "true" || echo "false" ;;
    days-since) days_since_release "$2" ;;
    date-tag) generate_date_tag ;;
    *) echo "Usage: $0 {fetch|latest|json|exists|expand|parse|image-exists|days-since|date-tag}" ;;
esac
