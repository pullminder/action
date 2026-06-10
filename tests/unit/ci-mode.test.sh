#!/bin/bash
# CI mode tests for pullminder/action

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "CI Mode Tests"

# Test 1: ci mode builds correct base args
echo "Test: mode: ci builds 'ci --json --github-annotations'"
MODE="ci"
EXPECTED_ARGS='ci --json --github-annotations'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode builds correct base args"

# Test 2: ci mode with fail-on flag
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
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode with fail-on includes flag"

# Test 3: ci mode with config flag
echo "Test: mode: ci with config includes --config"
MODE="ci"
CONFIG=".pullminder.yml"
EXPECTED_ARGS='ci --json --github-annotations --config .pullminder.yml'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
    if [ -n "$CONFIG" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --config $CONFIG"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode with config includes flag"

# Test 4: ci mode with include flag
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
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode with include flag"

# Test 5: ci mode with exclude flag
echo "Test: mode: ci with exclude includes --exclude"
MODE="ci"
EXCLUDE="vendor/**,node_modules/**"
EXPECTED_ARGS='ci --json --github-annotations --exclude vendor/**,node_modules/**'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
    if [ -n "$EXCLUDE" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --exclude $EXCLUDE"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode with exclude flag"

# Test 6: ci mode with all optional flags
echo "Test: mode: ci with all flags combined"
MODE="ci"
FAIL_ON="medium"
CONFIG=".pullminder.yml"
INCLUDE="src/**"
EXCLUDE="vendor/**"
EXPECTED_ARGS='ci --json --github-annotations --fail-on medium --config .pullminder.yml --include src/** --exclude vendor/**'
ACTUAL_ARGS=""

if [ "$MODE" = "ci" ]; then
    ACTUAL_ARGS="ci --json --github-annotations"
    if [ -n "$FAIL_ON" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --fail-on $FAIL_ON"
    fi
    if [ -n "$CONFIG" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --config $CONFIG"
    fi
    if [ -n "$INCLUDE" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --include $INCLUDE"
    fi
    if [ -n "$EXCLUDE" ]; then
        ACTUAL_ARGS="$ACTUAL_ARGS --exclude $EXCLUDE"
    fi
fi
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "ci mode with all flags combined"

# Test 7: ci mode --github-annotations flag presence
echo "Test: ci mode args always include --github-annotations"
MODE="ci"
ARGS="ci --json --github-annotations"
assert_contains "$ARGS" "--github-annotations" "ci mode includes --github-annotations"

# Test 8: empty include/exclude omitted from args
echo "Test: empty include and exclude are omitted"
MODE="ci"
INCLUDE=""
EXCLUDE=""
EXPECTED_ARGS='ci --json --github-annotations'
ACTUAL_ARGS="ci --json --github-annotations"
assert_equals "$EXPECTED_ARGS" "$ACTUAL_ARGS" "empty include/exclude omitted"

test_suite_end
