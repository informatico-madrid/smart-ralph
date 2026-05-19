#!/usr/bin/env bats
# Bats suite for verify-fix-present.sh: committed/staged/working-tree diffs

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FIXER_SCRIPT="$REPO_ROOT/plugins/ralphharness/hooks/scripts/verify-fix-present.sh"

setup() {
    FIXTURE_DIR=$(mktemp -d)
    cd "$FIXTURE_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    # Create a base commit
    git commit -q --allow-empty -m "base"
    # Create a fake origin/main pointing to base
    git branch origin/main
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

@test "fix committed returns 0" {
    echo "new content" > "target.txt"
    git add target.txt
    git commit -q -m "add target"
    run "$FIXER_SCRIPT" "target.txt"
    [ "$status" -eq 0 ]
}

@test "fix staged not committed returns 0" {
    echo "staged content" > "staged.txt"
    git add staged.txt
    run "$FIXER_SCRIPT" "staged.txt"
    [ "$status" -eq 0 ]
}

@test "fix unstaged returns 0" {
    # File must be tracked for git diff --quiet to detect working-tree changes
    echo "base" > "unstaged.txt"
    git add unstaged.txt
    git commit -q -m "track unstaged"
    echo "modified" > "unstaged.txt"
    run "$FIXER_SCRIPT" "unstaged.txt"
    [ "$status" -eq 0 ]
}
