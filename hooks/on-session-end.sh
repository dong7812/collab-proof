#!/usr/bin/env bash
# SessionEnd hook — fires when the Claude Code session ends.
# Runs the full collab-proof pipeline automatically.
# No user action required.

set -euo pipefail

PROJECT_ROOT="${PWD}"
RENDER_PY="${HOME}/.claude/skills/collab-proof/render.py"

# Only run inside a git repo with meaningful changes
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

# Check if session had meaningful work (2+ changed files)
CHANGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((CHANGED + STAGED + UNTRACKED))

[ "$TOTAL" -lt 2 ] && exit 0

# session-history 디렉토리 없으면 생성
mkdir -p "${PROJECT_ROOT}/session-history"

TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
SESSION_FILE="${PROJECT_ROOT}/session-history/${TIMESTAMP}-auto.md"
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")

# 자동 생성 세션 파일 작성
cat > "${SESSION_FILE}" << EOF
# Session ${TIMESTAMP} (auto)

**Intent**: AUTO_DETECTED
**Signal**: AUTO
**Branch**: ${BRANCH}
**Last commit**: ${LAST_COMMIT}
**Files changed**: ${TOTAL}

## What shipped
$(git diff --stat HEAD 2>/dev/null | head -20 || echo "No committed changes")

## What was figured out
*Run /collab-proof to generate full session narrative with AI contribution analysis.*

## Next steps inferred
*Run /collab-proof for complete analysis.*
EOF

# WORKLOG 체크포인트 기록
WORKLOG="${PROJECT_ROOT}/WORKLOG.md"
echo "$(date '+%Y-%m-%d %H:%M') | session-end | files_changed:${TOTAL} | branch:${BRANCH} | ${LAST_COMMIT}" >> "${WORKLOG}"

# HTML 렌더링 (render.py 있을 때만)
if [ -f "${RENDER_PY}" ]; then
    python3 "${RENDER_PY}" "${SESSION_FILE}" 2>/dev/null || true
fi

# git notes로 proof 앵커링
SIGN_HOOK="${HOME}/.claude/hooks/collab-proof-sign-proof.sh"
if [ -f "${SIGN_HOOK}" ]; then
    bash "${SIGN_HOOK}" 2>/dev/null || true
fi

exit 0
