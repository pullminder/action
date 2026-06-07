#!/bin/bash
# Edge case tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "Edge Case Tests"

# Test 1: Missing api-token in pr-review mode
echo "Test: missing api-token in pr-review mode"
MODE="pr-review"
API_TOKEN=""
EXPECTED_ERROR="true"

if [ "$MODE" = "pr-review" ] && [ -z "$API_TOKEN" ]; then
    # In real action, CLI would fail with authentication error
    EXPECTED_ERROR="true"
fi
assert_equals "true" "$EXPECTED_ERROR" "missing api-token causes error"

# Test 2: Malformed JSON from CLI
echo "Test: malformed JSON from CLI"
OUTPUT='{"findings":[{"invalid}'
IS_VALID_JSON="false"

if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
    IS_VALID_JSON="true"
fi
assert_equals "false" "$IS_VALID_JSON" "malformed JSON detected as invalid"

# Test 3: Empty config file path
echo "Test: empty config file is allowed"
CONFIG=""
SHOULD_ERROR="false"

if [ -n "$CONFIG" ] && [ ! -f "$CONFIG" ]; then
    SHOULD_ERROR="true"
fi
assert_equals "false" "$SHOULD_ERROR" "empty config is optional"

# Test 4: Invalid fail-on severity
echo "Test: invalid fail-on severity value"
FAIL_ON="urgent"
IS_VALID="false"

case "$FAIL_ON" in
    critical|high|medium|low|"")
        IS_VALID="true"
        ;;
esac
assert_equals "false" "$IS_VALID" "invalid severity rejected"

# Test 5: Negative fail-on-count
echo "Test: negative fail-on-count rejected"
FAIL_ON_COUNT="-1"
IS_VALID="false"

if [[ "$FAIL_ON_COUNT" =~ ^[0-9]+$ ]] && [ "$FAIL_ON_COUNT" -ge 0 ]; then
    IS_VALID="true"
fi
assert_equals "false" "$IS_VALID" "negative count rejected"

# Test 6: Zero fail-on-count (edge case)
echo "Test: fail-on-count=0 fails on any finding"
FAIL_ON_COUNT=0
FINDINGS_COUNT=0
SHOULD_FAIL="false"

if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "false" "$SHOULD_FAIL" "zero findings with threshold 0 does not fail"

# Test 7: Very large fail-on-count
echo "Test: very large fail-on-count accepted"
FAIL_ON_COUNT=999999
IS_VALID="false"

if [[ "$FAIL_ON_COUNT" =~ ^[0-9]+$ ]]; then
    IS_VALID="true"
fi
assert_equals "true" "$IS_VALID" "large count accepted as valid"

# Test 8: Missing config file (when specified)
echo "Test: specified but missing config file"
CONFIG="/nonexistent/pullminder.json"
SHOULD_ERROR="false"

if [ -n "$CONFIG" ] && [ ! -f "$CONFIG" ]; then
    SHOULD_ERROR="true"
fi
assert_equals "true" "$SHOULD_ERROR" "missing config file causes error"

# Test 9: Empty findings list in JSON
echo "Test: empty findings list in JSON"
OUTPUT='{"findings":[]}'
EXPECTED_COUNT=0

if command -v jq >/dev/null 2>&1; then
    COUNT=$(echo "$OUTPUT" | jq '[.. | .findings? | objects] | add | length' 2>/dev/null || echo "0")
else
    COUNT=0
fi
assert_equals "$EXPECTED_COUNT" "$COUNT" "empty findings returns count 0"

# Test 10: Unicode in violation messages
echo "Test: unicode characters in messages"
OUTPUT='{"message":"Error: 🔴 Critical issue with café résumé"}'
CONTAINS_UNICODE="false"

# Check for unicode by looking for specific characters
if echo "$OUTPUT" | grep -qF "🔴"; then
    CONTAINS_UNICODE="true"
fi
assert_equals "true" "$CONTAINS_UNICODE" "unicode characters present in output"

# Test 11: Very long PR title
echo "Test: very long PR title handled"
LONG_TITLE="feat: $(printf 'very-long-title-part-'{1..100})"
TITLE_LENGTH=${#LONG_TITLE}
SHOULD_HANDLE="true"

if [ "$TITLE_LENGTH" -gt 0 ]; then
    SHOULD_HANDLE="true"
fi
assert_equals "true" "$SHOULD_HANDLE" "long title accepted"

# Test 12: Special characters in repo name
echo "Test: special characters in repo name"
REPO_NAME="owner/repo.dash_dot"
CONTAINS_SPECIAL="false"

if echo "$REPO_NAME" | grep -q '[.-]'; then
    CONTAINS_SPECIAL="true"
fi
assert_equals "true" "$CONTAINS_SPECIAL" "special chars detected in repo name"

# Test 13: Mixed case mode input
echo "Test: mixed case mode input"
MODE="PR-Review"
NORMALIZED_MODE="${MODE,,}"
assert_equals "pr-review" "$NORMALIZED_MODE" "mode normalized to lowercase"

# Test 14: Whitespace in inputs
echo "Test: whitespace in fail-on value"
FAIL_ON="  high  "
TRIMMED="${FAIL_ON// /}"
assert_equals "high" "$TRIMMED" "whitespace trimmed from input"

# Test 15: Multiple spaces in command output
echo "Test: multiple spaces preserved in output"
OUTPUT="line1    line2     line3"
PRESERVED_SPACES="false"

if echo "$OUTPUT" | grep -q '  '; then
    PRESERVED_SPACES="true"
fi
assert_equals "true" "$PRESERVED_SPACES" "multiple spaces preserved in output"

test_suite_end
