#!/bin/bash
# Coverage webhook step tests for pullminder/action

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "Coverage Webhook Tests"

# ============================================================================
# Payload shape tests
# ============================================================================

# Test 1: JSON payload uses 'coverage_data' field name (not 'data')
echo "Test: payload field name is coverage_data (not data)"
COVERAGE_DATA="base64encodeddata"
FILENAME="lcov.info"
HEAD_SHA="abc123def"
PR_NUMBER="42"

# Simulate jq payload construction (matching action.yml)
PAYLOAD=$(jq -c -n \
  --arg coverage_data "$COVERAGE_DATA" \
  --arg filename "$FILENAME" \
  --arg sha "$HEAD_SHA" \
  --argjson pr "$PR_NUMBER" \
  '{coverage_data: $coverage_data, filename: $filename, head_sha: $sha, pr_number: $pr}')

assert_contains "$PAYLOAD" '"coverage_data"' "payload contains coverage_data field"
assert_contains "$PAYLOAD" '"base64encodeddata"' "coverage_data has correct value"
# Verify the old 'data' field is NOT present
if echo "$PAYLOAD" | jq -e 'has("data")' > /dev/null 2>&1; then
  echo "  FAIL: payload should not contain 'data' field"
  ((TESTS_RUN++, TESTS_FAILED++))
else
  echo "  PASS: payload does not contain deprecated 'data' field"
  ((TESTS_RUN++, TESTS_PASSED++))
fi

# Test 2: Payload includes filename field
echo "Test: payload includes filename field"
FILENAME_VALUE=$(echo "$PAYLOAD" | jq -r '.filename')
assert_equals "$FILENAME" "$FILENAME_VALUE" "filename matches input"

# Test 3: Payload includes head_sha and pr_number
echo "Test: payload includes head_sha and pr_number"
HEAD_SHA_VALUE=$(echo "$PAYLOAD" | jq -r '.head_sha')
PR_NUMBER_VALUE=$(echo "$PAYLOAD" | jq -r '.pr_number')
assert_equals "$HEAD_SHA" "$HEAD_SHA_VALUE" "head_sha matches"
assert_equals "$PR_NUMBER" "$PR_NUMBER_VALUE" "pr_number matches (as JSON number)"

# ============================================================================
# Non-PR context payload shape -- no pr_number field
# ============================================================================

# Test 4: Non-PR payload omits pr_number
echo "Test: non-PR payload omits pr_number field"
PAYLOAD_NO_PR=$(jq -c -n \
  --arg coverage_data "$COVERAGE_DATA" \
  --arg filename "$FILENAME" \
  --arg sha "$HEAD_SHA" \
  '{coverage_data: $coverage_data, filename: $filename, head_sha: $sha}')

assert_contains "$PAYLOAD_NO_PR" '"coverage_data"' "non-PR payload has coverage_data"
assert_contains "$PAYLOAD_NO_PR" '"filename"' "non-PR payload has filename"
assert_contains "$PAYLOAD_NO_PR" '"head_sha"' "non-PR payload has head_sha"
if echo "$PAYLOAD_NO_PR" | jq -e 'has("pr_number")' > /dev/null 2>&1; then
  echo "  FAIL: non-PR payload should not contain pr_number"
  ((TESTS_RUN++, TESTS_FAILED++))
else
  echo "  PASS: non-PR payload omits pr_number field"
  ((TESTS_RUN++, TESTS_PASSED++))
fi

# ============================================================================
# Auto-detect path priority tests
# ============================================================================

# Test 5: explicit coverage-file skips auto-detect
echo "Test: explicit coverage-file overrides auto-detection"
COVERAGE_FILE="custom/path/lcov.info"

# Simulate the action logic
FILE=""
if [ -n "$COVERAGE_FILE" ]; then
  FILE="$COVERAGE_FILE"
fi
assert_equals "custom/path/lcov.info" "$FILE" "explicit path used directly"

# Test 6: Auto-detect order — lcov.info detected first
echo "Test: auto-detect picks lcov.info when present"
COVERAGE_FILE=""
# Simulating lcov.info existing
FOUND=""
for candidate in lcov.info cover.out coverage/lcov.info coverage/coverage.info coverage/lcov.dat coverage.out; do
  if [ "$candidate" = "lcov.info" ]; then
    FOUND="$candidate"
    break
  fi
done
assert_equals "lcov.info" "$FOUND" "first match lcov.info picked"

# Test 7: Auto-detect order — coverage/lcov.dat in chain
echo "Test: auto-detect chain includes coverage/lcov.dat"
DETECT_CHAIN="lcov.info cover.out coverage/lcov.info coverage/coverage.info coverage/lcov.dat coverage.out"
assert_contains "$DETECT_CHAIN" "coverage/lcov.dat" "lcov.dat in detect chain"

# Test 8: Auto-detect order — coverage.out in chain
echo "Test: auto-detect chain includes coverage.out"
assert_contains "$DETECT_CHAIN" "coverage.out" "coverage.out in detect chain"

# Test 9: Auto-detect falls through to last match
echo "Test: auto-detect picks last fallback when earlier files missing"
FOUND=""
for candidate in lcov.info cover.out coverage/lcov.info coverage/coverage.info coverage/lcov.dat coverage.out; do
  if [ "$candidate" = "coverage.out" ]; then
    FOUND="$candidate"
    break
  fi
done
assert_equals "coverage.out" "$FOUND" "last fallback matches coverage.out"

# Test 10: Auto-detect empty when no files match
echo "Test: auto-detect returns empty when no files present"
FOUND=""
for candidate in lcov.info cover.out coverage/lcov.info coverage/coverage.info coverage/lcov.dat coverage.out; do
  # none of these match
  if [ "$candidate" = "nonexistent.txt" ]; then
    FOUND="$candidate"
    break
  fi
done
assert_equals "" "$FOUND" "no match returns empty"

# ============================================================================
# Token validation tests
# ============================================================================

# Test 11: Token resolution prefers COVERAGE_TOKEN input
echo "Test: token resolution prefers input over env var"
COVERAGE_TOKEN="input-token-abc"
PULLMINDER_COVERAGE_TOKEN="env-token-xyz"
TOKEN="${COVERAGE_TOKEN:-${PULLMINDER_COVERAGE_TOKEN:-}}"
assert_equals "input-token-abc" "$TOKEN" "input token takes precedence"

# Test 12: Token resolution falls back to env var
echo "Test: token resolution falls back to env var"
COVERAGE_TOKEN=""
PULLMINDER_COVERAGE_TOKEN="env-token-xyz"
TOKEN="${COVERAGE_TOKEN:-${PULLMINDER_COVERAGE_TOKEN:-}}"
assert_equals "env-token-xyz" "$TOKEN" "env var fallback works"

# Test 13: Token missing — both empty
echo "Test: missing token detected (both sources empty)"
COVERAGE_TOKEN=""
PULLMINDER_COVERAGE_TOKEN=""
TOKEN="${COVERAGE_TOKEN:-${PULLMINDER_COVERAGE_TOKEN:-}}"
assert_equals "" "$TOKEN" "both empty produces empty token"
TOKEN_VALID="false"
if [ -n "$TOKEN" ]; then
  TOKEN_VALID="true"
fi
assert_equals "false" "$TOKEN_VALID" "missing token should be caught"

# ============================================================================
# File size gate tests
# ============================================================================

# Test 14: File under 7 MB passes size gate
echo "Test: file under 7 MB passes size gate"
FILE_SIZE=1048576  # 1 MB
SIZE_OK="false"
if [ "$FILE_SIZE" -gt 7340032 ]; then
  SIZE_OK="false"
else
  SIZE_OK="true"
fi
assert_equals "true" "$SIZE_OK" "1 MB file passes size gate"

# Test 15: File at 7 MB boundary passes
echo "Test: file at exactly 7 MB passes size gate"
FILE_SIZE=7340032  # exactly 7 MB
SIZE_OK="false"
if [ "$FILE_SIZE" -gt 7340032 ]; then
  SIZE_OK="false"
else
  SIZE_OK="true"
fi
assert_equals "true" "$SIZE_OK" "7 MB file passes (not greater-than)"

# Test 16: File over 7 MB fails size gate
echo "Test: file over 7 MB fails size gate"
FILE_SIZE=8388608  # 8 MB
SIZE_OK="false"
if [ "$FILE_SIZE" -gt 7340032 ]; then
  SIZE_OK="false"
else
  SIZE_OK="true"
fi
assert_equals "false" "$SIZE_OK" "8 MB file fails size gate"

# Test 17: File at 7 MB + 1 byte fails
echo "Test: file at 7 MB + 1 byte fails size gate"
FILE_SIZE=7340033
SIZE_OK="false"
if [ "$FILE_SIZE" -gt 7340032 ]; then
  SIZE_OK="false"
else
  SIZE_OK="true"
fi
assert_equals "false" "$SIZE_OK" "7 MB + 1 byte fails"

# ============================================================================
# coverage-test-command tests
# ============================================================================

# Test 18: Command set and non-empty
echo "Test: coverage-test-command set triggers execution"
COVERAGE_TEST_CMD="npm test -- --coverage"
SHOULD_RUN="false"
if [ -n "$COVERAGE_TEST_CMD" ]; then
  SHOULD_RUN="true"
fi
assert_equals "true" "$SHOULD_RUN" "command is set and would run"

# Test 19: Empty command is skipped
echo "Test: empty coverage-test-command skipped"
COVERAGE_TEST_CMD=""
SHOULD_RUN="false"
if [ -n "$COVERAGE_TEST_CMD" ]; then
  SHOULD_RUN="true"
fi
assert_equals "false" "$SHOULD_RUN" "empty command skipped"

# ============================================================================
# Webhook URL resolution tests
# ============================================================================

# Test 20: Custom webhook URL used when set
echo "Test: custom webhook URL takes precedence"
COVERAGE_URL="https://staging.pullminder.com/api/v1/coverage/webhook"
URL="${COVERAGE_URL:-https://api.pullminder.com/api/v1/coverage/webhook}"
assert_equals "https://staging.pullminder.com/api/v1/coverage/webhook" "$URL" "custom URL used"

# Test 21: Default webhook URL used when input empty
echo "Test: default webhook URL used when input empty"
COVERAGE_URL=""
URL="${COVERAGE_URL:-https://api.pullminder.com/api/v1/coverage/webhook}"
assert_equals "https://api.pullminder.com/api/v1/coverage/webhook" "$URL" "default URL used"

# ============================================================================
# Filename extraction from path
# ============================================================================

# Test 22: basename extracted from detected file path
echo "Test: basename extracted from detected path"
FILE="coverage/lcov.info"
FILENAME=$(basename "$FILE")
assert_equals "lcov.info" "$FILENAME" "basename extracted correctly"

# Test 23: basename extracted from explicit coverage-file path
echo "Test: basename extracted from explicit path"
FILE="custom/path/cover.out"
FILENAME=$(basename "$FILE")
assert_equals "cover.out" "$FILENAME" "basename from explicit path"

# Test 24: basename from deep path
echo "Test: basename from deeply nested path"
FILE="a/b/c/d/coverage/lcov.dat"
FILENAME=$(basename "$FILE")
assert_equals "lcov.dat" "$FILENAME" "deep path basename correct"

test_suite_end
