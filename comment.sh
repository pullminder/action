#!/bin/bash
set -e

MARKER="<!-- pullminder-action -->"
REPO="${GH_REPO}"

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

# Find existing comment
COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
  --jq ".[] | select(.body | startswith(\"${MARKER}\")) | .id" \
  2>/dev/null || echo "")

if [ -n "$COMMENT_ID" ]; then
  gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" \
    --method PATCH \
    --field body="$BODY" > /dev/null
else
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --method POST \
    --field body="$BODY" > /dev/null
fi
