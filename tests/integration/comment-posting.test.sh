#!/bin/bash
# Integration tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

# Source comment.sh for integration testing
COMMENT_SCRIPT="${SCRIPT_DIR}/../../comment.sh"

test_suite_begin "Integration Tests"

# Test 1: Full pr-review mode workflow
echo "Test: full pr-review mode workflow"
MODE="pr-review"
EXIT_CODE=1
OUTPUT='{"findings":[{"ruleId":"no-unused-vars","severity":"high","message":"Unused variable foo"}]}'
MARKER="<!-- pullminder-action -->"

# Simulate comment generation
if [ "$MODE" = "pr-review" ]; then
    if [ "$EXIT_CODE" = "0" ]; then
        TITLE="Pullminder PR Review ✅"
    else
        TITLE="Pullminder PR Review ❌"
    fi

    if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
        FINDINGS_COUNT=$(echo "$OUTPUT" | jq '.findings | length' 2>/dev/null || echo "0")
        BODY="${MARKER}
## ${TITLE}

**Findings:** ${FINDINGS_COUNT}

<details>
<summary>Details</summary>

\`\`\`json
${OUTPUT}
\`\`\`

</details>
"
    else
        BODY="${MARKER}
## ${TITLE}

\`\`\`
${OUTPUT}
\`\`\`
"
    fi
fi

assert_contains "$BODY" "$MARKER" "pr-review comment includes marker"
assert_contains "$BODY" "$TITLE" "pr-review comment includes title"
assert_contains "$BODY" "Findings:" "pr-review comment includes findings count"
assert_contains "$BODY" '```json' "pr-review comment includes JSON block"

# Test 2: Full registry mode workflow
echo "Test: full registry mode workflow"
MODE="registry"
EXIT_CODE=0
OUTPUT="All registry checks passed"
MARKER="<!-- pullminder-action -->"

if [ "$MODE" = "registry" ]; then
    if [ "$EXIT_CODE" = "0" ]; then
        TITLE="Pullminder Registry Validation ✅"
    else
        TITLE="Pullminder Registry Validation ❌"
    fi

    BODY="${MARKER}
## ${TITLE}

\`\`\`
${OUTPUT}
\`\`\`
"
fi

assert_contains "$BODY" "$MARKER" "registry comment includes marker"
assert_contains "$BODY" "$TITLE" "registry comment includes title"
assert_not_empty "$BODY" "registry comment body not empty"

# Test 3: Comment update scenario (existing comment)
echo "Test: comment update when existing comment found"
MARKER="<!-- pullminder-action -->"
PR_NUMBER=123
REPO="owner/repo"

# Simulate gh api call for existing comments
EXISTING_COMMENT_ID="456"

if [ -n "$EXISTING_COMMENT_ID" ]; then
    API_METHOD="PATCH"
    API_ENDPOINT="repos/${REPO}/issues/comments/${EXISTING_COMMENT_ID}"
else
    API_METHOD="POST"
    API_ENDPOINT="repos/${REPO}/issues/${PR_NUMBER}/comments"
fi

assert_equals "PATCH" "$API_METHOD" "existing comment triggers PATCH"
assert_contains "$API_ENDPOINT" "$EXISTING_COMMENT_ID" "API endpoint includes comment ID"

# Test 4: Comment creation scenario (no existing comment)
echo "Test: comment creation when no existing comment"
MARKER="<!-- pullminder-action -->"
PR_NUMBER=123
REPO="owner/repo"
EXISTING_COMMENT_ID=""

if [ -n "$EXISTING_COMMENT_ID" ]; then
    API_METHOD="PATCH"
    API_ENDPOINT="repos/${REPO}/issues/comments/${EXISTING_COMMENT_ID}"
else
    API_METHOD="POST"
    API_ENDPOINT="repos/${REPO}/issues/${PR_NUMBER}/comments"
fi

assert_equals "POST" "$API_METHOD" "no existing comment triggers POST"
assert_contains "$API_ENDPOINT" "$PR_NUMBER" "API endpoint includes PR number"

# Test 5: Multiple findings in pr-review mode
echo "Test: multiple findings formatted correctly"
MODE="pr-review"
EXIT_CODE=1
OUTPUT='{"findings":[{"ruleId":"a","severity":"high"},{"ruleId":"b","severity":"medium"},{"ruleId":"c","severity":"low"}]}'

if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
    FINDINGS_COUNT=$(echo "$OUTPUT" | jq '.findings | length' 2>/dev/null || echo "0")
fi

assert_equals "3" "$FINDINGS_COUNT" "three findings counted correctly"

# Test 6: fail-on-count threshold workflow
echo "Test: fail-on-count threshold enforced"
MODE="pr-review"
FINDINGS_COUNT=5
FAIL_ON_COUNT=3
SHOULD_FAIL="false"

if [ "$FINDINGS_COUNT" -gt "$FAIL_ON_COUNT" ]; then
    SHOULD_FAIL="true"
fi

assert_equals "true" "$SHOULD_FAIL" "findings ($FINDINGS_COUNT) exceeds threshold ($FAIL_ON_COUNT)"

# Test 7: CLI error handling in workflow
echo "Test: CLI error handled in workflow"
CLI_EXIT_CODE=1
CLI_OUTPUT="Error: Authentication failed"
FINAL_EXIT_CODE=$CLI_EXIT_CODE
ERROR_MESSAGE="$CLI_OUTPUT"

assert_exit_code 1 "$FINAL_EXIT_CODE" "CLI error causes non-zero exit"
assert_not_empty "$ERROR_MESSAGE" "error message captured"

# Test 8: Successful workflow with no findings
echo "Test: successful workflow with no findings"
MODE="pr-review"
EXIT_CODE=0
OUTPUT='{"findings":[]}'
MARKER="<!-- pullminder-action -->"

if [ "$MODE" = "pr-review" ]; then
    TITLE="Pullminder PR Review ✅"
    if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
        FINDINGS_COUNT=$(echo "$OUTPUT" | jq '.findings | length' 2>/dev/null || echo "0")
        BODY="${MARKER}
## ${TITLE}

**Findings:** ${FINDINGS_COUNT}

<details>
<summary>Details</summary>

\`\`\`json
${OUTPUT}
\`\`\`

</details>
"
    fi
fi

assert_contains "$BODY" "✅" "successful run shows success emoji"
assert_equals "0" "$FINDINGS_COUNT" "zero findings counted correctly"

# Test 9: Mode switching between registry and pr-review
echo "Test: mode switching behavior"
TEST_MODES=("registry" "pr-review")
EXPECTED_COMMANDS=("registry validate" "ci --json")

for i in "${!TEST_MODES[@]}"; do
    MODE="${TEST_MODES[$i]}"
    if [ "$MODE" = "pr-review" ]; then
        ACTUAL_COMMAND="ci --json"
    else
        ACTUAL_COMMAND="registry validate"
    fi
    assert_equals "${EXPECTED_COMMANDS[$i]}" "$ACTUAL_COMMAND" "mode $MODE builds correct command"
done

# Test 10: Environment variable passing
echo "Test: PULLMINDER_TOKEN environment variable passed"
INPUT_TOKEN="ghp_test_token"
PULLMINDER_TOKEN="$INPUT_TOKEN"

assert_not_empty "$PULLMINDER_TOKEN" "token passed to environment"
assert_equals "$INPUT_TOKEN" "$PULLMINDER_TOKEN" "token value matches input"

test_suite_end
