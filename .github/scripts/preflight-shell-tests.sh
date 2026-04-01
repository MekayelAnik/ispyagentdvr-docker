#!/usr/bin/env bash
set -euo pipefail

bash -n DockerfileModifier.sh
bash -n Agent.sh
bash -n banner.sh
bash -n cleanup.sh
bash -n setup.sh
bash -n .github/scripts/lib-retry.sh
bash -n .github/scripts/check-existing-tags.sh
bash -n .github/scripts/test-registry-sync.sh

echo "script_syntax_ok"

bash .github/scripts/test-runtime-behavior.sh

echo "preflight_shell_tests_ok"
