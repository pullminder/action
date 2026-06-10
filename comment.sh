#!/bin/bash
set -e

MARKER="<!-- pullminder-action -->"
REPO="${GH_REPO}"

if [ "$MODE" = "pr-review" ]; then
  if [ "$EXIT_CODE" = "0" ]; then
    TITLE="Pullminder PR Review ✅"
  else
    TITLE="Pullminder PR Review ❌"
  fi

  if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
    FINDINGS_COUNT=$(echo "$OUTPUT" | jq '[.. | .findings? | objects] | add | length' 2>/dev/null || echo "0")
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
elif [ "$MODE" = "ci" ]; then
  if [ "$EXIT_CODE" = "0" ]; then
    TITLE="Pullminder CI ✅"
  else
    TITLE="Pullminder CI ❌"
  fi

  if command -v jq >/dev/null 2>&1 && echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
    FINDINGS_COUNT=$(echo "$OUTPUT" | jq '[.. | .findings? | objects] | add | length' 2>/dev/null || echo "0")
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
else
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
