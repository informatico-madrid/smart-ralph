#!/usr/bin/env bats
# bats test suite for anti-anchoring rule verification

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
}

@test "anti-anchoring-rule-present" {
    local navigator_file="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-navigator.md"
    [ -f "$navigator_file" ]
    grep -qi 'BEFORE.*EXPERIMENT\|≥2 independent hypotheses' "$navigator_file"
}

@test "anti-anchoring-in-pair-debug-md" {
    local pair_debug="${REPO_ROOT}/plugins/ralphharness/references/pair-debug.md"
    [ -f "$pair_debug" ]
    grep -q 'Anti-Anchoring' "$pair_debug"
    grep -qi '>=2\|≥2' "$pair_debug"
}
