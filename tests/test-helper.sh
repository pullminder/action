#!/bin/bash
# Test helper functions for pullminder/action tests

# Test counters - only initialize if not already set
: ${TESTS_RUN:=0}
: ${TESTS_PASSED:=0}
: ${TESTS_FAILED:=0}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-assertion failed}"

    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $msg"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-assertion failed}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  PASS: $msg"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        echo "    expected '$haystack' to contain '$needle'"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_not_empty() {
    local value="$1"
    local msg="${2:-assertion failed: value is empty}"

    if [ -n "$value" ]; then
        echo "  PASS: $msg"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-exit code assertion failed}"

    if [ "$expected" -eq "$actual" ]; then
        echo "  PASS: $msg"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: $msg"
        echo "    expected exit code: $expected"
        echo "    actual exit code:   $actual"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# Test suite functions
test_suite_begin() {
    local suite_name="$1"
    echo ""
    echo "$suite_name"
    echo "$(printf '%.0s-' {1..${#suite_name}})"
}

test_suite_end() {
    echo ""
}

# Summary function
print_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Total:   $TESTS_RUN"
    echo "Passed:  $TESTS_PASSED"
    echo "Failed:  $TESTS_FAILED"
    echo "=========================================="

    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}
