#!/usr/bin/env bash
# PreCompact hook — fires before Claude Code compacts the conversation.
# Runs synchronously (timing matters — must complete before compaction).
# Writes a .tmp-TIMESTAMP.json snapshot per SKILL.md spec.
# Layer 01 signal is computed here (git, no LLM).
# Layer 02 frame scores are left null — Claude fills them in at session end.

set -euo pipefail

PROJECT_ROOT="${PWD}"
HISTORY_DIR="${PROJECT_ROOT}/session-history"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
FILENAME="${HISTORY_DIR}/.tmp-$(date '+%Y%m%d-%H%M%S').json"

mkdir -p "${HISTORY_DIR}"

# Layer 01 signal — git only, no LLM
SIGNAL="LOW"
if git -C "${PROJECT_ROOT}" rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED=$(git -C "${PROJECT_ROOT}" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    STAGED=$(git -C "${PROJECT_ROOT}" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "${PROJECT_ROOT}" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    TOTAL=$((CHANGED + STAGED + UNTRACKED))

    if [ "$TOTAL" -ge 4 ]; then
        SIGNAL="HIGH"
    elif [ "$TOTAL" -ge 1 ]; then
        SIGNAL="MEDIUM"
    fi
fi

# Write .tmp-TIMESTAMP.json per SKILL.md spec
cat > "${FILENAME}" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "trigger": "pre-compact",
  "signal": "${SIGNAL}",
  "frames": {
    "technical": null,
    "uncertainty": null,
    "fork": null,
    "ai_contribution": null
  },
  "intent": null,
  "key_moments": []
}
EOF

exit 0
