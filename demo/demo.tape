Output demo/collab-proof-demo.gif

Require echo

Set Shell "bash"
Set FontSize 14
Set Width 900
Set Height 550
Set Theme "Dracula"
Set Padding 20
Set Framerate 24
Set PlaybackSpeed 1

# 시작 - 프로젝트 디렉토리로 이동
Type "cd /tmp/demo-project" Sleep 200ms Enter
Sleep 800ms

# git 상태 보여주기
Type "git log --oneline" Sleep 200ms Enter
Sleep 1.5s

# /session-proof 시뮬레이션 시작
Type "# Running /session-proof pipeline..." Sleep 200ms Enter
Sleep 600ms

# Layer 01 — Signal detection
Type "echo ''" Enter
Type "echo '── Layer 01 · WorkSignalDetector ─────────────────────'" Sleep 100ms Enter
Sleep 400ms
Type "git diff --stat HEAD~3..HEAD" Sleep 200ms Enter
Sleep 1s
Type "echo ''" Enter
Type "echo '  Signal: HIGH'" Sleep 100ms Enter
Sleep 200ms
Type "echo '  Reason: 3 files modified · Lua EVAL vs MULTI/EXEC discussed'" Sleep 100ms Enter
Sleep 1s

# Layer 02 — ADHD frames
Type "echo ''" Enter
Type "echo '── Layer 02 · ADHD 4-Frame Analysis ──────────────────'" Sleep 100ms Enter
Sleep 400ms
Type "echo '  Frame A (Technical)    0.90  ✓ Lua EVAL replaces INCR+EXPIRE'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  Frame B (Uncertainty)  0.80  ✓ MULTI/EXEC tried first, direction changed'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  Frame C (Fork)         0.85  ✓ Lua EVAL vs MULTI/EXEC vs optimistic lock'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  Frame D (AI contrib)   0.90  ✓ Claude identified TOCTOU window'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  All frames survived pruning'" Sleep 100ms Enter
Sleep 400ms
Type "echo '  Intent: BUG_FIXING  (runner-up: REFACTORING)'" Sleep 100ms Enter
Sleep 1.2s

# Layer 03 — Output generation
Type "echo ''" Enter
Type "echo '── Layer 03 · OutputGenerator ────────────────────────'" Sleep 100ms Enter
Sleep 400ms
Type "echo '  writing DECISIONS.md ...'" Sleep 100ms Enter
Sleep 500ms
Type "echo '  writing session-history/2026-06-01-1422.md ...'" Sleep 100ms Enter
Sleep 500ms
Type "echo '  writing WORKLOG.md ...'" Sleep 100ms Enter
Sleep 500ms

# render.py 실행
Type "echo '  generating proof.html ...'" Sleep 100ms Enter
Sleep 300ms
Type "python3 /Users/dongkyu/과제/collab-proof/render.py session-history/2026-06-01-1422.md" Sleep 200ms Enter
Sleep 1.5s

# 완료 메시지
Type "echo ''" Enter
Type "echo '✓ Done.'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  → session-history/2026-06-01-1422-proof.html'" Sleep 100ms Enter
Sleep 1s

# HTML 열기
Type "open session-history/2026-06-01-1422-proof.html" Sleep 200ms Enter
Sleep 2s

Type "echo ''" Enter
Type "echo '  Install: git clone + ./install.sh'" Sleep 100ms Enter
Sleep 300ms
Type "echo '  Usage:   /session-proof'" Sleep 100ms Enter
Sleep 2s
