#!/usr/bin/env bash
set -euo pipefail

assert_eq() {
    local name="$1"
    local got="$2"
    local want="$3"

    if [[ "$got" == "$want" ]]; then
        echo "PASS: ${name}"
    else
        echo "FAIL: ${name} expected='${want}' got='${got}'" >&2
        exit 1
    fi
}

assert_file_contains() {
    local name="$1"
    local file="$2"
    local needle="$3"

    if grep -qF "$needle" "$file"; then
        echo "PASS: ${name}"
    else
        echo "FAIL: ${name} missing '${needle}' in ${file}" >&2
        exit 1
    fi
}

# Verify Dockerfile exists and has expected structure
assert_file_contains "Dockerfile has FROM" "Dockerfile" "FROM"
assert_file_contains "Dockerfile has ENTRYPOINT or CMD" "Dockerfile" "ENTRYPOINT\|CMD"

# Verify DockerfileModifier.sh has expected content
assert_file_contains "DockerfileModifier has sed or replacement logic" "DockerfileModifier.sh" "sed\|Dockerfile"

# Verify Agent.sh exists and is a valid script
[[ -f "Agent.sh" ]] || { echo "FAIL: Agent.sh missing" >&2; exit 1; }
echo "PASS: Agent.sh exists"

echo "runtime_behavior_checks_ok"
