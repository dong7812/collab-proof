#!/usr/bin/env bash
# Stop hook — fires when Claude finishes a turn.
# Lightweight: checks git for meaningful changes, writes a checkpoint to WORKLOG.
# Heavy processing stays in /session-proof.

set -euo pipefail

WORKLOG="${PWD}/WORKLOG.md"

# Only run if we're inside a git repo
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

# Count changed files since last commit
CHANGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((CHANGED + STAGED))

# Skip if nothing meaningful changed (< 2 files)
[ "$TOTAL" -lt 2 ] && exit 0

# Write a lightweight checkpoint
mkdir -p "$(dirname "$WORKLOG")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

echo "${TIMESTAMP} | checkpoint | files_changed:${TOTAL} | branch:${BRANCH}" >> "$WORKLOG"

exit 0
