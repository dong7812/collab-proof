#!/usr/bin/env bash
# Pre-compact hook — fires before Claude Code compacts the conversation.
# Writes a lightweight checkpoint so no context is silently lost.

set -euo pipefail

PROJECT_ROOT="${PWD}"
HISTORY_DIR="${PROJECT_ROOT}/session-history"
CHECKPOINT="${HISTORY_DIR}/.pre-compact-$(date +%Y%m%d-%H%M%S).txt"

mkdir -p "${HISTORY_DIR}"

# Write a timestamped marker. The next /collab-proof run will pick this up.
echo "[pre-compact checkpoint] $(date '+%Y-%m-%d %H:%M:%S') — context compaction triggered at ${PROJECT_ROOT}" >> "${CHECKPOINT}"

# Also append a reminder line to WORKLOG if it exists.
WORKLOG="${PROJECT_ROOT}/WORKLOG.md"
if [ -f "${WORKLOG}" ]; then
  echo "<!-- pre-compact checkpoint $(date '+%Y-%m-%d %H:%M:%S') -->" >> "${WORKLOG}"
fi

exit 0
