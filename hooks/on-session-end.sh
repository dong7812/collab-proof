#!/usr/bin/env bash
# SessionEnd hook — fires when the Claude Code session ends.
# Exits immediately. Full pipeline runs in background to avoid blocking Claude Code.

PROJECT_ROOT="${PWD}"
LOG="/tmp/collab-proof-session-end.log"

(
  set -euo pipefail

  git -C "${PROJECT_ROOT}" rev-parse --git-dir > /dev/null 2>&1 || exit 0

  CHANGED=$(git -C "${PROJECT_ROOT}" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  STAGED=$(git -C "${PROJECT_ROOT}" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git -C "${PROJECT_ROOT}" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  TOTAL=$((CHANGED + STAGED + UNTRACKED))

  [ "$TOTAL" -lt 2 ] && exit 0

  mkdir -p "${PROJECT_ROOT}/session-history"

  TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
  SESSION_FILE="${PROJECT_ROOT}/session-history/${TIMESTAMP}-auto.md"
  BRANCH=$(git -C "${PROJECT_ROOT}" symbolic-ref --short HEAD 2>/dev/null || echo "detached")
  LAST_COMMIT=$(git -C "${PROJECT_ROOT}" log --oneline -1 2>/dev/null || echo "no commits")

  cat > "${SESSION_FILE}" << EOF
# Session ${TIMESTAMP} (auto)

**Intent**: AUTO_DETECTED
**Signal**: AUTO
**Branch**: ${BRANCH}
**Last commit**: ${LAST_COMMIT}
**Files changed**: ${TOTAL}

## What shipped
$(git -C "${PROJECT_ROOT}" diff --stat HEAD 2>/dev/null | head -20 || echo "No committed changes")

## What was figured out
*Run /collab-proof to generate full session narrative with AI contribution analysis.*

## Next steps inferred
*Run /collab-proof for complete analysis.*
EOF

  WORKLOG="${PROJECT_ROOT}/WORKLOG.md"
  echo "$(date '+%Y-%m-%d %H:%M') | session-end | files_changed:${TOTAL} | branch:${BRANCH} | ${LAST_COMMIT}" >> "${WORKLOG}"

  SIGN_HOOK="${HOME}/.claude/hooks/collab-proof-sign-proof.sh"
  if [ -f "${SIGN_HOOK}" ]; then
    bash "${SIGN_HOOK}" 2>/dev/null || true
  fi

) >> "$LOG" 2>&1 &

disown $!
exit 0
