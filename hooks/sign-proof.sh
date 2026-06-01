#!/usr/bin/env bash
# collab-proof-sign-proof.sh
#
# Attaches the SHA-256 hash of the session HTML proof to the current commit
# via git notes (refs/notes/collab-proof namespace).
#
# Zero external dependencies — uses only shasum (macOS) or sha256sum (Linux).
#
# Usage:
#   Called automatically by on-session-end.sh after HTML generation.
#   Can also be run manually: bash ~/.claude/hooks/collab-proof-sign-proof.sh
#
# Share proof with collaborators:
#   git push origin refs/notes/collab-proof
#
# Verify:
#   git notes --ref=collab-proof show
#   git log --notes=collab-proof

set -euo pipefail

# 1. Git 저장소 여부 검증
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    exit 0
fi

# 2. 최초 커밋 존재 여부 확인
git rev-parse HEAD > /dev/null 2>&1 || exit 0

# 3. 가장 최근 생성된 세션 HTML 찾기
LATEST_HTML=$(ls -t session-history/*-proof.html 2>/dev/null | head -n 1 || true)
if [ -z "$LATEST_HTML" ]; then
    exit 0
fi

CURRENT_COMMIT=$(git rev-parse HEAD)
SHORT=$(git rev-parse --short HEAD)
SESSION_DATE=$(basename "$LATEST_HTML" | cut -d'-' -f1-4)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 4. 플랫폼 독립적 SHA-256 (macOS: shasum, Linux: sha256sum, fallback: python3)
if command -v shasum >/dev/null 2>&1; then
    HTML_HASH=$(shasum -a 256 "$LATEST_HTML" | awk '{print $1}')
elif command -v sha256sum >/dev/null 2>&1; then
    HTML_HASH=$(sha256sum "$LATEST_HTML" | awk '{print $1}')
else
    HTML_HASH=$(python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$LATEST_HTML")
fi

# 5. git notes 메타데이터 구성
NOTE=$(cat <<EOF
[collab-proof] AI Collaboration Evidence Anchored
Session Date : $SESSION_DATE
Timestamp    : $TIMESTAMP
Commit       : $CURRENT_COMMIT
Proof HTML   : $LATEST_HTML
SHA-256      : $HTML_HASH
EOF
)

# 6. refs/notes/collab-proof 네임스페이스에 추가
#    같은 커밋에 여러 세션이 있을 경우 append로 누적
if git notes --ref=collab-proof show "$CURRENT_COMMIT" > /dev/null 2>&1; then
    git notes --ref=collab-proof append -m "$NOTE" "$CURRENT_COMMIT"
else
    git notes --ref=collab-proof add -m "$NOTE" "$CURRENT_COMMIT"
fi

echo "------------------------------------------------------------"
echo "  ✓ proof anchored → commit ${SHORT}"
echo "    SHA-256 : ${HTML_HASH:0:16}..."
echo "    file    : ${LATEST_HTML}"
echo ""
echo "    verify  : git notes --ref=collab-proof show"
echo "    share   : git push origin refs/notes/collab-proof"
echo "------------------------------------------------------------"
