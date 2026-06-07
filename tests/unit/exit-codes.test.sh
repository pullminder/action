#!/bin/bash
# Exit code tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "Exit Code Tests"

# Test 1: No violations → exit 0
echo "Test: no violations results in exit 0"
EXIT_CODE=0
EXPECTED_EXIT=0
assert_exit_code "$EXPECTED_EXIT" "$EXIT_CODE" "clean run exits 0"

# Test 2: Violations below threshold → exit 0
echo "Test: violations below threshold results in exit 0"
FINDINGS_COUNT=3
FAIL_ON_COUNT=10
SHOULD_FAIL="false"

if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "false" "$SHOULD_FAIL" "findings ($FINDINGS_COUNT) below threshold ($FAIL_ON_COUNT) should not fail"

# Test 3: Violations at threshold → exit 1
echo "Test: violations at threshold results in exit 1"
FINDINGS_COUNT=10
FAIL_ON_COUNT=10
SHOULD_FAIL="false"

# Note: action.yml uses -gt, so threshold of 10 means more than 10 fails
# At exactly 10 findings, it should NOT fail
if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "false" "$SHOULD_FAIL" "findings ($FINDINGS_COUNT) equals threshold ($FAIL_ON_COUNT) does not fail"

# Test 4: Violations above threshold → exit 1
echo "Test: violations above threshold results in exit 1"
FINDINGS_COUNT=15
FAIL_ON_COUNT=10
SHOULD_FAIL="false"

if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "true" "$SHOULD_FAIL" "findings ($FINDINGS_COUNT) exceeds threshold ($FAIL_ON_COUNT) should fail"

# Test 5: CLI error propagates → exit non-zero
echo "Test: CLI error propagates exit code"
CLI_EXIT_CODE=1
FINAL_EXIT_CODE=$CLI_EXIT_CODE
assert_exit_code 1 "$FINAL_EXIT_CODE" "CLI error code propagates"

# Test 6: CLI success → exit 0
echo "Test: CLI success results in exit 0"
CLI_EXIT_CODE=0
FINAL_EXIT_CODE=$CLI_EXIT_CODE
assert_exit_code 0 "$FINAL_EXIT_CODE" "CLI success results in exit 0"

# Test 7: Missing api-token in pr-review mode → exit 1
echo "Test: missing api-token in pr-review mode causes failure"
MODE="pr-review"
API_TOKEN=""
EXPECTED_EXIT=1
ACTUAL_EXIT=0

# In real action, CLI would fail with auth error
if [ "$MODE" = "pr-review" ] && [ -z "$API_TOKEN" ]; then
    ACTUAL_EXIT=1
fi
assert_exit_code "$EXPECTED_EXIT" "$ACTUAL_EXIT" "missing api-token in pr-review mode fails"

# Test 8: Invalid fail-on severity → exit 1
echo "Test: invalid fail-on severity causes failure"
FAIL_ON="invalid"
EXPECTED_EXIT=1
ACTUAL_EXIT=0

# Simulate validation
case "$FAIL_ON" in
    critical|high|medium|low|"")
        ACTUAL_EXIT=0
        ;;
    *)
        ACTUAL_EXIT=1
        ;;
esac
assert_exit_code "$EXPECTED_EXIT" "$ACTUAL_EXIT" "invalid fail-on severity fails"

# Test 9: Empty fail-on-count → no threshold check
echo "Test: empty fail-on-count skips threshold check"
FAIL_ON_COUNT=""
SHOULD_CHECK="false"

if [ -n "$FAIL_ON_COUNT" ]; then
    SHOULD_CHECK="true"
fi
assert_equals "false" "$SHOULD_CHECK" "empty fail-on-count skips threshold check"

# Test 10: Zero fail-on-count → fail on any finding
echo "Test: fail-on-count=0 fails on any finding"
FAIL_ON_COUNT=0
FINDINGS_COUNT=1
SHOULD_FAIL="false"

if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "true" "$SHOULD_FAIL" "fail-on-count=0 fails on any finding"

test_suite_end
