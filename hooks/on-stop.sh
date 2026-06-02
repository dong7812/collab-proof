#!/usr/bin/env bash
# Stop hook — fires when Claude finishes a turn.
# Exits immediately. Actual work runs in background to avoid blocking Claude Code.

PROJECT_ROOT="${PWD}"
LOG="/tmp/collab-proof-stop.log"

(
  set -euo pipefail

  WORKLOG="${PROJECT_ROOT}/WORKLOG.md"

  git -C "${PROJECT_ROOT}" rev-parse --git-dir > /dev/null 2>&1 || exit 0

  CHANGED=$(git -C "${PROJECT_ROOT}" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  STAGED=$(git -C "${PROJECT_ROOT}" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  TOTAL=$((CHANGED + STAGED))

  [ "$TOTAL" -lt 2 ] && exit 0

  mkdir -p "$(dirname "$WORKLOG")"
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  BRANCH=$(git -C "${PROJECT_ROOT}" symbolic-ref --short HEAD 2>/dev/null || echo "detached")

  echo "${TIMESTAMP} | checkpoint | files_changed:${TOTAL} | branch:${BRANCH}" >> "$WORKLOG"
) >> "$LOG" 2>&1 &

disown $!
exit 0
