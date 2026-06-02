#!/usr/bin/env bash
# PreCompact hook — fires before Claude Code compacts the conversation.
# Runs synchronously (timing matters — must complete before compaction).
# Kept minimal to avoid blocking Claude Code.

PROJECT_ROOT="${PWD}"
HISTORY_DIR="${PROJECT_ROOT}/session-history"

mkdir -p "${HISTORY_DIR}"

echo "[pre-compact] $(date '+%Y-%m-%d %H:%M:%S') — context compaction at ${PROJECT_ROOT}" \
  >> "${HISTORY_DIR}/.pre-compact-$(date +%Y%m%d-%H%M%S).txt"

exit 0
