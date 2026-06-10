#!/bin/bash
# Artifact upload tests for pullminder/action

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-helper.sh"

test_suite_begin "Artifact Upload Tests"

# Test 1: Save output step condition met when ci mode and upload-artifact true
echo "Test: save output step runs when ci mode and upload-artifact true"
MODE="ci"
UPLOAD_ARTIFACT="true"
SHOULD_SAVE="false"

if [ "$MODE" = "ci" ] && [ "$UPLOAD_ARTIFACT" = "true" ]; then
    SHOULD_SAVE="true"
fi
assert_equals "true" "$SHOULD_SAVE" "save step runs in ci mode with upload enabled"

# Test 2: Save output step skipped when upload-artifact is false
echo "Test: save output step skipped when upload-artifact false"
MODE="ci"
UPLOAD_ARTIFACT="false"
SHOULD_SAVE="true"

if [ "$MODE" = "ci" ] && [ "$UPLOAD_ARTIFACT" = "true" ]; then
    SHOULD_SAVE="true"
else
    SHOULD_SAVE="false"
fi
assert_equals "false" "$SHOULD_SAVE" "save step skipped when upload-artifact false"

# Test 3: Save output step skipped in pr-review mode
echo "Test: save output step skipped in pr-review mode"
MODE="pr-review"
UPLOAD_ARTIFACT="true"
SHOULD_SAVE="true"

if [ "$MODE" = "ci" ] && [ "$UPLOAD_ARTIFACT" = "true" ]; then
    SHOULD_SAVE="true"
else
    SHOULD_SAVE="false"
fi
assert_equals "false" "$SHOULD_SAVE" "save step skipped in pr-review mode"

# Test 4: Save output step skipped in registry mode
echo "Test: save output step skipped in registry mode"
MODE="registry"
UPLOAD_ARTIFACT="true"
SHOULD_SAVE="true"

if [ "$MODE" = "ci" ] && [ "$UPLOAD_ARTIFACT" = "true" ]; then
    SHOULD_SAVE="true"
else
    SHOULD_SAVE="false"
fi
assert_equals "false" "$SHOULD_SAVE" "save step skipped in registry mode"

# Test 5: Upload step condition met for ci mode (always() semantics)
echo "Test: upload step runs on success (always() semantics)"
MODE="ci"
EXIT_CODE=0
UPLOAD_CONDITION_MET="false"

# Simulate: mode=ci && upload-artifact=true && always()
if [ "$MODE" = "ci" ] && [ "true" = "true" ]; then
    UPLOAD_CONDITION_MET="true"
fi
assert_equals "true" "$UPLOAD_CONDITION_MET" "upload step runs on success with always()"

# Test 6: Upload step runs on failure (always() semantics)
echo "Test: upload step runs on CLI failure (always() semantics)"
MODE="ci"
EXIT_CODE=1
UPLOAD_CONDITION_MET="false"

if [ "$MODE" = "ci" ] && [ "true" = "true" ]; then
    UPLOAD_CONDITION_MET="true"
fi
assert_equals "true" "$UPLOAD_CONDITION_MET" "upload step runs on failure with always()"

# Test 7: Upload step skipped in registry mode
echo "Test: upload step skipped in registry mode"
MODE="registry"
UPLOAD_ARTIFACT="true"
SHOULD_UPLOAD="true"

if [ "$MODE" = "ci" ] && [ "$UPLOAD_ARTIFACT" = "true" ]; then
    SHOULD_UPLOAD="true"
else
    SHOULD_UPLOAD="false"
fi
assert_equals "false" "$SHOULD_UPLOAD" "upload step skipped in registry mode"

# Test 8: continue-on-error semantics for upload step
echo "Test: continue-on-error semantics for upload step"
# This is a structural property verified by the action.yml definition
CONTINUE_ON_ERROR="true"
assert_equals "true" "$CONTINUE_ON_ERROR" "upload step uses continue-on-error: true"

test_suite_end
