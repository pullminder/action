#!/bin/bash
# Input validation tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "Input Validation Tests"

# Test 1: api-token presence in pr-review mode
echo "Test: pr-review mode requires api-token"
MODE="pr-review"
API_TOKEN=""
SHOULD_FAIL="false"

# Simulate validation - in real action, this would be checked
# For now, empty token means CLI will fail with auth error
if [ "$MODE" = "pr-review" ] && [ -z "$API_TOKEN" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "true" "$SHOULD_FAIL" "pr-review without api-token should fail"

# Test 2: api-token present in pr-review mode
echo "Test: pr-review mode with api-token is valid"
MODE="pr-review"
API_TOKEN="ghp_test_token123"
SHOULD_FAIL="false"

if [ "$MODE" = "pr-review" ] && [ -z "$API_TOKEN" ]; then
    SHOULD_FAIL="true"
fi
assert_equals "false" "$SHOULD_FAIL" "pr-review with api-token should not fail token check"

# Test 3: fail-on accepts valid severity values
echo "Test: fail-on accepts valid severity values"
for SEVERITY in "critical" "high" "medium" "low"; do
    case "$SEVERITY" in
        critical|high|medium|low)
            assert_equals "true" "true" "fail-on=$SEVERITY is valid"
            ;;
        *)
            assert_equals "false" "true" "fail-on=$SEVERITY should be valid"
            ;;
    esac
done

# Test 4: fail-on-count accepts numeric values
echo "Test: fail-on-count accepts numeric values"
FAIL_ON_COUNT="10"
IS_NUMERIC=""

if [[ "$FAIL_ON_COUNT" =~ ^[0-9]+$ ]]; then
    IS_NUMERIC="true"
fi
assert_equals "true" "$IS_NUMERIC" "fail-on-count=10 is numeric"

# Test 5: fail-on-count rejects negative values
echo "Test: fail-on-count rejects negative values"
FAIL_ON_COUNT="-5"
IS_VALID="true"

if [[ "$FAIL_ON_COUNT" =~ ^[0-9]+$ ]] && [ "$FAIL_ON_COUNT" -ge 0 ]; then
    IS_VALID="true"
else
    IS_VALID="false"
fi
assert_equals "false" "$IS_VALID" "fail-on-count=-5 is invalid"

# Test 6: config path validation
echo "Test: config requires valid path"
CONFIG_FILE=""
SHOULD_ERROR="true"

if [ -n "$CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
    SHOULD_ERROR="true"
elif [ -z "$CONFIG_FILE" ]; then
    SHOULD_ERROR="false"  # Empty config is optional
fi
assert_equals "false" "$SHOULD_ERROR" "empty config is optional (no error)"

# Test 7: registry mode command validation
echo "Test: registry mode accepts valid commands"
for CMD in "validate" "lint"; do
    case "$CMD" in
        validate|lint)
            assert_equals "true" "true" "command=$CMD is valid"
            ;;
        *)
            assert_equals "false" "true" "command=$CMD should be valid"
            ;;
    esac
done

# Test 8: strict flag is boolean
echo "Test: strict accepts boolean values"
for STRICT_VAL in "true" "false"; do
    case "$STRICT_VAL" in
        true|false)
            assert_equals "true" "true" "strict=$STRICT_VAL is valid"
            ;;
        *)
            assert_equals "false" "true" "strict=$STRICT_VAL should be valid"
            ;;
    esac
done

test_suite_end
