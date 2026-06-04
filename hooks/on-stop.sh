#!/usr/bin/env bash
# Stop hook — fires when Claude finishes a turn.
# Exits immediately. Actual work runs in background to avoid blocking Claude Code.
# Writes to WORKLOG only when a new commit has been made since last checkpoint.

PROJECT_ROOT="${PWD}"
LOG="/tmp/collab-proof-stop.log"

(
  set -euo pipefail

  WORKLOG="${PROJECT_ROOT}/WORKLOG.md"
  LAST_COMMIT_FILE="${PROJECT_ROOT}/.collab-proof-last-commit"

  git -C "${PROJECT_ROOT}" rev-parse --git-dir > /dev/null 2>&1 || exit 0

  CURRENT_COMMIT=$(git -C "${PROJECT_ROOT}" log -1 --format="%H" 2>/dev/null || echo "")
  [ -z "$CURRENT_COMMIT" ] && exit 0

  LAST_LOGGED=$(cat "$LAST_COMMIT_FILE" 2>/dev/null || echo "")
  [ "$CURRENT_COMMIT" = "$LAST_LOGGED" ] && exit 0

  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  BRANCH=$(git -C "${PROJECT_ROOT}" symbolic-ref --short HEAD 2>/dev/null || echo "detached")
  SHORT=$(git -C "${PROJECT_ROOT}" log -1 --format="%h" 2>/dev/null)
  MSG=$(git -C "${PROJECT_ROOT}" log -1 --format="%s" 2>/dev/null)

  mkdir -p "$(dirname "$WORKLOG")"
  echo "${TIMESTAMP} | commit | ${SHORT} | branch:${BRANCH} | ${MSG}" >> "$WORKLOG"

  echo "$CURRENT_COMMIT" > "$LAST_COMMIT_FILE"
) >> "$LOG" 2>&1 &

disown $!
exit 0
