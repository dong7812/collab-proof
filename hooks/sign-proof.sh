#!/usr/bin/env bash
# collab-proof git notes proof anchoring
#
# Attaches the SHA-256 hash of the session HTML proof to the current commit
# via git notes — no file tree pollution, no merge conflicts, tamper-evident.
#
# Usage (manual):
#   bash ~/.claude/hooks/collab-proof-sign-proof.sh
#
# Usage (automatic): called by on-session-end.sh after HTML is generated.
#
# To share proof with collaborators:
#   git push origin refs/notes/commits
#
# To verify:
#   git notes show
#   git log --show-notes

set -euo pipefail

PROJECT_ROOT="${PWD}"
HISTORY_DIR="${PROJECT_ROOT}/session-history"

# Only run inside a git repo with at least one commit
git rev-parse --git-dir > /dev/null 2>&1 || exit 0
git rev-parse HEAD > /dev/null 2>&1 || exit 0

# Find the most recent proof HTML
PROOF_FILE=$(ls -t "${HISTORY_DIR}"/*-proof.html 2>/dev/null | head -1 || true)
[ -z "$PROOF_FILE" ] && exit 0

COMMIT=$(git rev-parse HEAD)
SHORT=$(git rev-parse --short HEAD)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
FILENAME=$(basename "$PROOF_FILE")

# Compute SHA-256 (stdlib python — no hashlib install needed)
PROOF_HASH=$(python3 -c "
import hashlib, sys
with open(sys.argv[1], 'rb') as f:
    print(hashlib.sha256(f.read()).hexdigest())
" "$PROOF_FILE")

NOTE=$(cat <<EOF
collab-proof session evidence
file: ${FILENAME}
sha256: ${PROOF_HASH}
timestamp: ${TIMESTAMP}
generated_by: collab-proof
EOF
)

# append if note exists, add if not
if git notes show "$COMMIT" > /dev/null 2>&1; then
    git notes append -m "$NOTE" "$COMMIT"
else
    git notes add -m "$NOTE" "$COMMIT"
fi

echo "  ✓ proof anchored → commit ${SHORT}"
echo "    file    : ${FILENAME}"
echo "    sha256  : ${PROOF_HASH:0:16}..."
echo ""
echo "    share   : git push origin refs/notes/commits"
echo "    verify  : git notes show"
