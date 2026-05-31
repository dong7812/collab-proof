#!/usr/bin/env bash
# collab-proof installer — stdlib Python only, no pip required.

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills/collab-proof"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS="${CLAUDE_DIR}/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing collab-proof..."
echo ""

# 1. Skill
mkdir -p "${SKILLS_DIR}"
cp "${SCRIPT_DIR}/.claude/skills/collab-proof/SKILL.md" "${SKILLS_DIR}/SKILL.md"
echo "  ✓ skill        → ${SKILLS_DIR}/SKILL.md"

# 2. Renderer (used by /collab-proof automatically)
cp "${SCRIPT_DIR}/render.py" "${SKILLS_DIR}/render.py"
echo "  ✓ renderer     → ${SKILLS_DIR}/render.py"

# 3. Slash command
mkdir -p "${COMMANDS_DIR}"
cp "${SCRIPT_DIR}/commands/collab-proof.md" "${COMMANDS_DIR}/collab-proof.md"
echo "  ✓ command      → /collab-proof"

# 4. Hooks
mkdir -p "${HOOKS_DIR}"
cp "${SCRIPT_DIR}/hooks/pre-compact.sh" "${HOOKS_DIR}/collab-proof-pre-compact.sh"
cp "${SCRIPT_DIR}/hooks/on-stop.sh"    "${HOOKS_DIR}/collab-proof-on-stop.sh"
chmod +x "${HOOKS_DIR}/collab-proof-pre-compact.sh"
chmod +x "${HOOKS_DIR}/collab-proof-on-stop.sh"
echo "  ✓ hooks        → PreCompact + Stop"

# 5. Wire hooks into settings.json
[ -f "${SETTINGS}" ] || echo '{}' > "${SETTINGS}"

python3 - <<PYEOF
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
hooks_dir     = os.path.expanduser("~/.claude/hooks")

with open(settings_path) as f:
    cfg = json.load(f)

hooks = cfg.setdefault("hooks", {})

def wire(event, script_name):
    cmd = os.path.join(hooks_dir, script_name)
    entries = hooks.setdefault(event, [])
    entry = {"matcher": "", "hooks": [{"type": "command", "command": cmd}]}
    already = any(
        any(h.get("command") == cmd for h in g.get("hooks", []))
        for g in entries
    )
    if not already:
        entries.append(entry)
        return True
    return False

wired = []
if wire("PreCompact", "collab-proof-pre-compact.sh"): wired.append("PreCompact")
if wire("Stop",       "collab-proof-on-stop.sh"):     wired.append("Stop")

with open(settings_path, "w") as f:
    json.dump(cfg, f, indent=2)

if wired:
    print(f"  ✓ settings.json → wired: {', '.join(wired)}")
else:
    print("  · hooks already present in settings.json")
PYEOF

echo ""
echo "Done. Start a Claude Code session and run:"
echo ""
echo "  /collab-proof"
echo ""
echo "collab-proof will run the full pipeline and open the HTML proof automatically."
