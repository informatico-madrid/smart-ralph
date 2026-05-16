#!/usr/bin/env bats
REPO_ROOT="$(dirname "$BATS_TEST_DIRNAME")"

@test "flock-both-role-files" {
    local driver="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-driver.md"
    local navigator="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-navigator.md"
    grep -q 'flock' "$driver"
    grep -q 'flock' "$navigator"
}

@test "flock-blocks-self-contained" {
    local driver="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-driver.md"
    local navigator="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-navigator.md"
    ! grep -q 'CLAUDE_PLUGIN_ROOT' "$driver"
    ! grep -q 'CLAUDE_PLUGIN_ROOT' "$navigator"
}

@test "flock-syntax-correct" {
    local driver="${REPO_ROOT}/plugins/ralphharness/agents/pair-debug-driver.md"
    grep -q 'exec 200' "$driver"
    grep -q 'exec 202' "$driver"
}
