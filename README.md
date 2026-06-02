# collab-proof

A Claude Code skill that runs **static analysis on your AI collaboration sessions**.

Most session tools answer *"what did we talk about?"* or *"how many tokens did I use?"*  
collab-proof answers *"how well did I collaborate with AI — and how can I improve?"*

It reads git history and session context, scores the collaboration across four cognitive frames, and writes artifacts you can review later and share as proof.

![collab-proof demo](demo/collab-proof-demo.gif)

[한국어](README.ko.md)

---

## The mental model

Think of it like ESLint — but for AI collaboration quality.

```
ESLint:      code    → static analysis → quality report + improvement hints
collab-proof: session → static analysis → collaboration quality + improvement hints + proof
```

The output has two audiences:
- **Yourself** — where did AI actually contribute? where did I waste tokens? am I improving over sessions?
- **Others** — here is calibrated evidence of what the AI contributed and what I decided

---

## Why existing tools don't cover this

| Tool | What it answers |
|---|---|
| Claude Pulse, Rudel, AI Token Monitor | How many tokens, how much cost, activity heatmap |
| Claude Code Analytics | Session similarity, transcript search |
| **collab-proof** | **How well did we collaborate, and where did each side actually drive the outcome?** |

Token trackers tell you *cost per session*. collab-proof tells you *quality of the collaboration* — calibrated against git history, not conversation claims.

---

## Pipeline

collab-proof runs a three-layer pipeline on every `/collab-proof` invocation.

### Layer 01 — WorkSignalDetector

Reads `git log` and `git diff` to classify signal level:

| Signal | Condition | Output |
|---|---|---|
| `HIGH` | New file created, 4+ files modified, explicit option comparison, or bug diagnosed | Full artifacts |
| `MEDIUM` | 1–3 files modified, no major discussion | WORKLOG one-liner only |
| `LOW` | No code changes, planning only | Silence |

### Layer 02 — WorkIntentClassifier (ADHD 4-frame)

Fans out four cognitive frames simultaneously, scores each 0.0–1.0, prunes frames below 0.4:

| Frame | What it catches |
|---|---|
| A — Technical | Code churn depth, new modules, architectural changes |
| B — Uncertainty | Reverts, direction changes, developer doubt signals |
| C — Fork | Alternatives discussed, explicit A-vs-B comparisons |
| D — AI contribution | Where Claude changed the outcome vs. developer-driven work |

Classifies dominant intent from surviving frames:  
`FEATURE_BUILDING` · `BUG_FIXING` · `REFACTORING` · `EXPLORING` · `STUCK` · `FLOW_STATE`

### Layer 03 — OutputGenerator

Collects token usage from the current session (input / cache_read / cache_create / output), then generates artifacts proportional to signal level and surviving frame depth.

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

Wires hooks into `~/.claude/settings.json` automatically. Running `install.sh` again is safe.

**Zero external dependencies.** Python stdlib only. No pip install required.

---

## Usage

Inside any Claude Code session:

```
/collab-proof
```

Runs the full pipeline: signal detection → frame scoring → token analysis → artifacts → HTML proof.

---

## Output

### `WORKLOG.md` — the observation harness

Running log appended per session. Designed for trend analysis across sessions:

```
2026-06-02 12:10 | FEATURE_BUILDING | HIGH | D:0.9 | cache:85% | tok:45K | PR fork 관계 복구 후 재제출
2026-06-01 15:00 | FEATURE_BUILDING | HIGH | D:0.8 | cache:62% | tok:82K | collab-proof 초기 릴리즈
2026-05-28 09:30 | BUG_FIXING       | HIGH | D:1.0 | cache:71% | tok:33K | TOCTOU 레이스컨디션 진단
```

Fields: `D:` = AI contribution score · `cache:` = cache hit rate · `tok:` = total tokens (K)

Over time, WORKLOG becomes your collaboration quality history — D score trend, token efficiency per task type, which intent classes cost the most context.

### `DECISIONS.md`

One entry per real decision fork. The `AI contribution` field is the core — calibrated, not promotional:

```markdown
## 2026-06-01 Rate limiter atomicity via Lua EVAL

**Context**: Redis ZCARD + ZADD across two round trips creates a TOCTOU race.
**Decision**: Moved PRUNE + CHECK + ADD into a single Lua EVAL script.
**Alternatives considered**: MULTI/EXEC pipeline, optimistic locking with retry.
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD that developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, decision to use Lua over MULTI/EXEC
**Signal score**: HIGH
```

If no meaningful AI contribution occurred: *"Developer-driven session. Claude executed instructions."*

### `session-history/YYYY-MM-DD-HHMM.md`

Session narrative grounded in git log. Sections: What shipped · What was figured out · Where it got hard · AI contribution summary · Next steps inferred.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

Self-contained HTML. No CDN. Opens at `file://`. Includes token usage panel:
- Input / cache / output proportion bar
- Cache hit rate with efficiency label (≥80% efficient · 50–79% moderate · <50% high churn)
- Top 3 most expensive turns with prompt preview
- One-line optimization suggestion based on observed pattern

---

## Hooks

| Hook | Event | Behavior |
|---|---|---|
| `SessionEnd` | Session closes | Full pipeline — all artifacts + git notes anchoring |
| `Stop` | End of each turn | If ≥2 files changed, appends checkpoint to WORKLOG |
| `PreCompact` | Before context compaction | Writes snapshot marker to preserve context before loss |

---

## Sharing the proof

```bash
# GitHub Gist (one command)
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public

# Verify git-anchored proof
git notes --ref=collab-proof show
```

> **Squash merge warning**: `git notes` are tied to a commit SHA. Squash-and-merge rewrites the hash — use `--commit-footer` to embed the anchor in the commit message instead (survives squash).

---

## Roadmap

- [x] Vela 3-layer pipeline (prompt-native, zero dependencies)
- [x] ADHD 4-frame WorkIntentClassifier
- [x] DECISIONS.md with calibrated AI contribution field
- [x] Session narrative (session-history/)
- [x] WORKLOG with D score + cache hit rate + token count per entry
- [x] Token usage analysis — cache efficiency, top expensive turns, optimization hints
- [x] HTML proof with token panel (self-contained, `file://`-ready)
- [x] Full automation via `SessionEnd` hook (Claude Code 1.0.84+)
- [x] Git-signed proof via `git notes` (SHA-256 anchored, `refs/notes/collab-proof`)
- [ ] `/collab-review` — trend view across sessions (D score trajectory, token efficiency over time)
- [ ] `awesome-claude-skills` registry listing

---

## License

MIT
