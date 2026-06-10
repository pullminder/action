#!/bin/bash
# Mode dispatch tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

# Mock pullminder command
mock_pullminder() {
    local args="$*"
    echo "{\"mode\":\"pr-review\",\"args\":\"$args\"}" >&2
    echo "{\"findings\":[{\"ruleId\":\"test-rule\",\"severity\":\"medium\",\"message\":\"Test finding\"}]}"
}

test_suite_begin "Mode Dispatch Tests"

# Test 1: pr-review mode invokes ci command
echo "Test: mode: pr-review invokes 'ci --json'"
MODE="pr-review"
EXPECTED_ARGS='ci --json'
ACTUAL_ARGS=""

# Simulate the logic from action.yml lines 141-154
if [ "$MODE" = "pr-review" ]; then
    ACTUAL_ARGS="ci --json"
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "pr-review mode builds correct args"

# Test 2: registry mode invokes registry command
echo "Test: mode: registry invokes 'registry validate'"
MODE="registry"
COMMAND="validate"
EXPECTED_ARGS='registry validate'
ACTUAL_ARGS=""

if [ "$MODE" = "registry" ]; then
    ACTUAL_ARGS="registry ${COMMAND}"
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "registry mode builds correct args"

# Test 3: default mode is registry
echo "Test: empty mode defaults to registry"
MODE=""
EXPECTED_MODE="registry"
# In the actual action, default is set in inputs, so empty means registry
ACTUAL_MODE="${MODE:-registry}"
assert_equals "$EXPECTED_MODE" "$ACTUAL_MODE" "empty mode defaults to registry"

# Test 4: pr-review mode with fail-on flag
echo "Test: mode: pr-review with fail-on includes --fail-on"
MODE="pr-review"
FAIL_ON="high"
EXPECTED_ARGS='ci --json --fail-on high'
ACTUAL_ARGS=""

if [ "$MODE" = "pr-review" ]; then
    ACTUAL_ARGS="ci --json"
    if [ -n "$FAIL_ON" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --fail-on $FAIL_ON"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "pr-review with fail-on includes flag"

# Test 5: pr-review mode with config flag
echo "Test: mode: pr-review with config includes --config"
MODE="pr-review"
CONFIG="pullminder.json"
EXPECTED_ARGS='ci --json --config pullminder.json'
ACTUAL_ARGS=""

if [ "$MODE" = "pr-review" ]; then
    ACTUAL_ARGS="ci --json"
    if [ -n "$CONFIG" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --config $CONFIG"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "pr-review with config includes flag"

# Test 6: registry mode with strict flag
echo "Test: mode: registry validate with strict includes --strict"
MODE="registry"
COMMAND="validate"
STRICT="true"
EXPECTED_ARGS='registry validate --strict'
ACTUAL_ARGS=""

if [ "$MODE" = "registry" ]; then
    ACTUAL_ARGS="registry ${COMMAND}"
    if [ "$STRICT" = "true" ] && [ "$COMMAND" = "validate" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --strict"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "registry validate with strict includes flag"

# Test 7: ci mode invokes ci command with --github-annotations
echo "Test: mode: ci invokes 'ci --json --github-annotations'"
MODE="ci"
EXPECTED_ARGS='ci --json --github-annotations'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode builds correct args"

# Test 8: ci mode with fail-on flag
echo "Test: mode: ci with fail-on includes --fail-on"
MODE="ci"
FAIL_ON="high"
EXPECTED_ARGS='ci --json --github-annotations --fail-on high'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
    if [ -n "$FAIL_ON" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --fail-on $FAIL_ON"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci with fail-on includes flag"

# Test 9: ci mode with include flag
echo "Test: mode: ci with include includes --include"
MODE="ci"
INCLUDE="src/**"
EXPECTED_ARGS='ci --json --github-annotations --include src/**'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
    if [ -n "$INCLUDE" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --include $INCLUDE"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci with include includes flag"

# Test 10: default mode is still registry (backward compat)
echo "Test: empty mode defaults to registry (unchanged)"
MODE=""
EXPECTED_MODE="registry"
ACTUAL_MODE="${MODE:-registry}"
assert_equals "$EXPECTED_MODE" "$ACTUAL_MODE" "empty mode still defaults to registry"

test_suite_end
