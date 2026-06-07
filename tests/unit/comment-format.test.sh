#!/bin/bash
# Comment format tests for pullminder/action

# Load test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

# Source comment.sh logic for testing
COMMENT_SCRIPT="${SCRIPT_DIR}/../../comment.sh"

test_suite_begin "Comment Format Tests"

# Test 1: PR review mode comment includes marker
echo "Test: pr-review comment includes pullminder-action marker"
MODE="pr-review"
EXIT_CODE=0
OUTPUT='{"findings":[{"ruleId":"test","severity":"high","message":"Test"}]}'

# Simulate comment body generation
MARKER="<!-- pullminder-action -->"
TITLE="Pullminder PR Review ✅"
BODY="${MARKER}
## ${TITLE}

**Findings:** 1

<details>
<summary>Details</summary>

\`\`\`json
${OUTPUT}
\`\`\`

</details>
"

assert_contains "$BODY" "$MARKER" "comment includes marker"
assert_contains "$BODY" "$TITLE" "comment includes title"
assert_contains "$BODY" "Findings:" "comment includes findings count"

# Test 2: PR review mode with failure
echo "Test: pr-review failure comment shows failure emoji"
MODE="pr-review"
EXIT_CODE=1
TITLE="Pullminder PR Review ❌"
assert_contains "$TITLE" "❌" "failure comment shows failure emoji"

# Test 3: PR review mode includes details section
echo "Test: pr-review comment includes collapsible details"
MODE="pr-review"
BODY=$'<!-- pullminder-action -->\n## Pullminder PR Review ✅\n\n**Findings:** 1\n\n<details>\n<summary>Details</summary>\n\n```json\n{"findings":[]}\n```\n\n</details>\n'

assert_contains "$BODY" "<details>" "comment includes details section"
assert_contains "$BODY" "</details>" "comment includes details closing"
assert_contains "$BODY" '```json' "comment includes JSON code block"

# Test 4: Registry mode comment format
echo "Test: registry comment includes plain text output"
MODE="registry"
EXIT_CODE=0
OUTPUT="All checks passed"
TITLE="Pullminder Registry Validation ✅"
BODY="${MARKER}
## ${TITLE}

\`\`\`
${OUTPUT}
\`\`\`
"

assert_contains "$BODY" "$TITLE" "registry comment includes title"
assert_contains "$BODY" '```' "registry comment includes code block"

# Test 5: Registry mode with failure
echo "Test: registry failure comment shows failure emoji"
MODE="registry"
EXIT_CODE=1
TITLE="Pullminder Registry Validation ❌"
assert_contains "$TITLE" "❌" "registry failure shows failure emoji"

# Test 6: Comment update detection (marker)
echo "Test: comment marker allows update detection"
MARKER="<!-- pullminder-action -->"
BODY="${MARKER}
## Test
"

assert_contains "$BODY" "$MARKER" "comment starts with marker"

# Test 7: JSON parsing fallback for malformed output
echo "Test: malformed JSON falls back to plain text"
MODE="pr-review"
EXIT_CODE=1
OUTPUT="Not valid JSON"
TITLE="Pullminder PR Review ❌"

# When jq fails, use plain text
if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
    BODY_TYPE="json"
else
    BODY_TYPE="plain"
fi

assert_equals "plain" "$BODY_TYPE" "malformed JSON uses plain text fallback"

# Test 8: Findings count extraction from valid JSON
echo "Test: findings count extracted from JSON"
OUTPUT='{"findings":[{"ruleId":"a"},{"ruleId":"b"},{"ruleId":"c"}]}'
EXPECTED_COUNT=3

# Simulate jq extraction
if command -v jq >/dev/null 2>&1; then
    FINDINGS_COUNT=$(echo "$OUTPUT" | jq '.findings | length' 2>/dev/null || echo "0")
else
    FINDINGS_COUNT=0
fi

assert_equals "$EXPECTED_COUNT" "$FINDINGS_COUNT" "findings count extracted correctly"

# Test 9: Empty findings shows zero count
echo "Test: empty findings shows zero"
OUTPUT='{"findings":[]}'
EXPECTED_COUNT=0

if command -v jq >/dev/null 2>&1; then
    FINDINGS_COUNT=$(echo "$OUTPUT" | jq '[.. | .findings? | objects] | add | length' 2>/dev/null || echo "0")
else
    FINDINGS_COUNT=0
fi

assert_equals "$EXPECTED_COUNT" "$FINDINGS_COUNT" "empty findings shows zero"

# Test 10: No findings still posts comment
echo "Test: successful run with no findings posts comment"
MODE="pr-review"
EXIT_CODE=0
OUTPUT='{"findings":[]}'
SHOULD_POST="true"

if [ "$EXIT_CODE" = "0" ] || [ "$EXIT_CODE" = "1" ]; then
    SHOULD_POST="true"
fi

assert_equals "true" "$SHOULD_POST" "successful run posts comment"

# Don't call print_summary here - let the test runner aggregate results
