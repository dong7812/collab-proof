# collab-proof

A Claude Code skill that generates AI collaboration evidence from development sessions.

It answers a narrow but important question: **when you built something with AI, what exactly did each side contribute — and where is the proof?**

Most session-logging tools answer *"what did we talk about?"* collab-proof answers *"what decision was made, what was the alternative, and what did the AI actually contribute versus what did the developer drive?"* — grounded in git history, not conversation claims.

![collab-proof demo](demo/collab-proof-demo.gif)

---

## Why I built this

When you're deep in a coding session with AI, you move fast. A decision gets made, a tradeoff gets discussed, a bug gets caught — and then you're already on to the next thing.

Later, you can't reconstruct it. The git log shows *what* changed. The conversation is gone or compacted. The reasoning that led to `Lua EVAL over MULTI/EXEC`, the moment Claude spotted the race condition you missed, the alternative you consciously ruled out — all of it evaporates.

I built collab-proof because I wanted a way to **capture what I missed while I was moving**. Not a manual journal. Not a summary I'd forget to write. Something that watches the session, infers what mattered, and holds it for me — so I can review it later and know exactly what happened and why.

The review step is the point. The artifacts aren't just documentation — they're a checkpoint you come back to: *did the AI actually contribute something meaningful here, or did I just execute manually? what decision am I about to build on top of? what was I uncertain about that I should revisit?*

---

## Scope

- Claude Code skill (`SKILL.md`) + slash command (`/collab-proof`) + two lifecycle hooks.
- **Zero external dependencies.** No pip install required.
- **Read-only.** Reads git log, git diff, and conversation context. Makes no network calls, writes no config.
- Generates three artifact types per session: decision log, session narrative, shareable HTML proof.
- Signal filtering: low-signal sessions (routine implementation, no decision forks) produce no output.
- `SessionEnd` hook is supported since Claude Code 1.0.84. collab-proof uses `SessionEnd` (full pipeline on close) + `Stop` (per-turn WORKLOG checkpoint) + `PreCompact` (context compaction marker).

---

## Pipeline

collab-proof runs a three-layer pipeline on every `/collab-proof` invocation.

### Layer 01 — WorkSignalDetector

Reads `git log` and `git diff` to classify signal level:

| Signal | Condition | Output |
|---|---|---|
| `HIGH` | New file created, 4+ files modified, explicit option comparison in conversation, or bug diagnosed and fixed | Full artifacts |
| `MEDIUM` | 1–3 files modified, no major discussion | WORKLOG one-liner only |
| `LOW` | No code changes, planning only | Silence |

### Layer 02 — WorkIntentClassifier (ADHD tree-of-thought)

Fans out four cognitive frames simultaneously, scores each, prunes frames below 0.4:

| Frame | What it catches |
|---|---|
| A — Technical | Code churn depth, new modules, architectural changes |
| B — Uncertainty | Reverts, direction changes, developer doubt |
| C — Fork | Alternatives discussed, explicit A-vs-B comparisons |
| D — AI contribution | Where Claude changed the outcome vs. developer-driven work |

Classifies dominant intent from surviving frames:
`FEATURE_BUILDING` · `BUG_FIXING` · `REFACTORING` · `EXPLORING` · `STUCK` · `FLOW_STATE`

For scoring rubric and exception rules → [ARCHITECTURE.md](ARCHITECTURE.md)

### Layer 03 — OutputGenerator

Generates artifacts proportional to signal level and surviving frame depth.

---

## Install

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

`install.sh` copies files into `~/.claude/`:

```
~/.claude/skills/collab-proof/SKILL.md           ← skill definition
~/.claude/commands/collab-proof.md               ← /collab-proof command
~/.claude/hooks/collab-proof-on-stop.sh          ← Stop hook (WORKLOG checkpoints)
~/.claude/hooks/collab-proof-on-session-end.sh   ← SessionEnd hook (full pipeline)
~/.claude/hooks/collab-proof-pre-compact.sh      ← PreCompact hook
~/.claude/hooks/collab-proof-sign-proof.sh       ← git notes proof anchoring
```

And wires the hooks into `~/.claude/settings.json`. Running `install.sh` again is safe — it skips already-present hook entries.

---

## Usage

Inside any Claude Code session:

```
/collab-proof
```

Claude runs the pipeline, writes all artifacts, generates the HTML proof directly, and anchors the proof to the current git commit via `git notes`. The command prints all written file paths.

---

## Output

All artifacts are written into the project root where Claude Code is running.

### `DECISIONS.md`

Appended per session. One entry per real decision fork (Frame C must confirm alternatives existed).

```markdown
## 2026-06-01 Rate limiter atomicity via Lua EVAL

**Context**: Redis ZCARD + ZADD across two round trips creates a TOCTOU race
under concurrent requests.
**Decision**: Moved PRUNE + CHECK + ADD into a single Lua EVAL script.
**Alternatives considered**: MULTI/EXEC pipeline, optimistic locking with retry.
**Reasoning**: Lua scripts run single-threaded on Redis — no observable intermediate
state. 1 round trip vs 3.
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD that developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, decision to use Lua over MULTI/EXEC
**Intent class**: BUG_FIXING
**Signal score**: HIGH
**Outcome**: implemented
```

The `AI contribution` field is the core of the skill. It is calibrated — neither
overclaiming ("Claude built this") nor dismissing ("developer did everything").
If no meaningful AI contribution occurred, the field reads: *"Developer-driven session. Claude executed instructions."*

### `session-history/YYYY-MM-DD-HHMM.md`

One file per session. Sections:

| Section | Content |
|---|---|
| `What shipped` | Concrete deliverables grounded in git log |
| `What was figured out` | Reasoning, tradeoffs, debugging — what developers forget |
| `Decisions made this session` | References to DECISIONS.md entries |
| `Where it got hard` | Frame B findings: uncertainty, reverts, STUCK signals |
| `AI contribution summary` | Frame D synthesis — one calibrated paragraph |
| `Next steps inferred` | What's obviously incomplete based on the session |

### `session-history/YYYY-MM-DD-HHMM-proof.html`

Self-contained single HTML file. No CDN. No external resources. Opens at `file://`.

Contents:
- Header: project name, date, intent badge, signal score bar
- Cognitive frames: which lenses fired, which were pruned, each score
- Decision cards: one per DECISIONS.md entry, AI contribution highlighted
- Session narrative sections
- Footer: last git commit hash of the session (tamper-evident timestamp)

### `WORKLOG.md`

Running one-liner log, appended per session:

```
2026-06-01 14:22 | BUG_FIXING | HIGH | Added Lua EVAL atomicity — eliminated TOCTOU race under concurrent requests
```

The `Stop` hook also writes lightweight checkpoints when ≥2 files change between turns:

```
2026-06-01 14:31 | checkpoint | files_changed:3 | branch:main
```

---

## Hooks

| Hook | Event | Behavior |
|---|---|---|
| `SessionEnd` | When the session closes | Runs full pipeline — WORKLOG + session file + HTML proof + git notes anchoring |
| `Stop` | End of each Claude turn | If ≥2 files changed, appends a checkpoint line to WORKLOG.md |
| `PreCompact` | Before context compaction | Writes a checkpoint marker to prevent silent context loss |

`sign-proof.sh` is called by `SessionEnd` automatically. Can also be run manually:
```bash
bash ~/.claude/hooks/collab-proof-sign-proof.sh

# verify
git notes --ref=collab-proof show

# share with collaborators
git push origin refs/notes/collab-proof
```

All hooks are no-ops outside a git repository and exit 0 silently.

---

## When it helps — and when it doesn't

collab-proof is signal-filtered. It produces nothing for routine sessions and full artifacts only when something worth recording actually happened.

**Produces useful output:**

| Session type | Why it's valuable |
|---|---|
| Design decision with alternatives | Records the fork — what was chosen and what was ruled out |
| Bug with root cause diagnosis | Captures the WHY, not just the fix — impossible to reconstruct from git log |
| Direction change mid-session | Frame B catches the uncertainty; documents what changed and why |
| Architecture discussion | Multiple frames fire; AI contribution field separates Claude's input from developer judgment |

**Produces little or nothing:**

| Session type | Why |
|---|---|
| "Change this text / fix this typo" | No decision, no diagnosis — nothing to infer |
| Pure implementation with no discussion | File changes exist but no reasoning to capture |
| Planning session with no code | LOW signal — no git changes to ground the narrative |

**The honest version:** roughly 30–40% of sessions produce genuinely useful artifacts. The rest are correctly silenced. A WORKLOG checkpoint still runs on active turns, so even quiet sessions leave a minimal trace.

---

## Roadmap

- [x] Vela 3-layer pipeline (prompt-native, no Python install)
- [x] ADHD 4-frame tree-of-thought in Layer 02
- [x] DECISIONS.md with calibrated AI contribution field
- [x] session-history narrative
- [x] WORKLOG one-liner + Stop hook checkpoints
- [x] HTML proof artifact (self-contained, `file://`-ready)
- [x] Full automation via `SessionEnd` hook (available since Claude Code 1.0.84)
- [x] Git-signed proof via `git notes` — SHA-256 anchored to commit in `refs/notes/collab-proof` namespace, shared via `git push origin refs/notes/collab-proof`
- [ ] `awesome-claude-skills` registry listing

---

## License

MIT
