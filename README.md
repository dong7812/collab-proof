# collab-proof

After a Claude Code session, what did the AI actually contribute — and what did you drive?

collab-proof calibrates the answer and keeps a record.

![collab-proof demo](demo/collab-proof-demo.gif)

[한국어](README.ko.md)

---

## The problem

When you're deep in a session with Claude, you move fast. A decision gets made, a tradeoff gets discussed, a bug gets caught — and then you're already on to the next thing.

Later, you can't reconstruct it. The git log shows *what* changed. The conversation is gone or compacted. The reasoning that led to `Lua EVAL over MULTI/EXEC`, the moment Claude spotted the race condition you missed, the alternative you consciously ruled out — all of it evaporates.

Most tools answer *"what did we talk about?"*  
collab-proof answers *"what did Claude actually contribute, and what did I decide?"* — grounded in git history, not conversation claims.

---

## What makes it different

The key is the **AI contribution field** — calibrated, not promotional:

```markdown
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD that developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, decision to use Lua over MULTI/EXEC
```

vs sessions where Claude just executed instructions:

```markdown
**AI contribution**:
  - Developer-driven session. Claude executed instructions.
```

Neither overclaiming nor dismissing. Grounded in what actually happened.

---

## Pipeline

collab-proof runs a three-layer pipeline on every `/collab-proof` invocation.

### Layer 01 — Signal detection

Reads `git log` and `git diff`. Classifies signal level:

| Signal | Condition | Output |
|---|---|---|
| `HIGH` | New file, 4+ files modified, explicit option comparison, or bug diagnosed | Full artifacts |
| `MEDIUM` | 1–3 files modified, no major discussion | WORKLOG one-liner only |
| `LOW` | No code changes | Silence |

Low-signal sessions produce nothing. Roughly 30–40% of sessions generate useful artifacts.

### Layer 02 — 4-frame analysis

Four cognitive frames scored simultaneously, pruned below 0.4:

| Frame | What it catches |
|---|---|
| A — Technical | Code churn depth, new modules, architectural changes |
| B — Uncertainty | Reverts, direction changes, developer doubt signals |
| C — Fork | Alternatives discussed, explicit A-vs-B comparisons |
| D — AI contribution | Where Claude changed the outcome vs. developer-driven work |

**Frame D is the core.** It's what separates *"Claude identified the TOCTOU window"* from *"developer-driven session."*

Classifies dominant intent: `FEATURE_BUILDING` · `BUG_FIXING` · `REFACTORING` · `EXPLORING` · `STUCK` · `FLOW_STATE`

### Layer 03 — Output

Generates artifacts proportional to signal level. Also collects token usage (cache hit rate, expensive turns) and includes it as a sub-panel in the HTML proof.

---

## Install

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

Zero external dependencies. Python stdlib only. No pip install required.

Wires three hooks into `~/.claude/settings.json` automatically:

| Hook | When | What |
|---|---|---|
| `SessionEnd` | Session closes | Full pipeline automatically |
| `Stop` | Each turn | WORKLOG checkpoint if ≥2 files changed |
| `PreCompact` | Before compaction | Snapshot before context loss |

---

## Usage

```
/collab-proof
```

---

## Output

### `DECISIONS.md`

One entry per real decision fork. The AI contribution field is the point:

```markdown
## 2026-06-01 Rate limiter atomicity via Lua EVAL

**Context**: Redis ZCARD + ZADD across two round trips creates a TOCTOU race.
**Decision**: Moved PRUNE + CHECK + ADD into a single Lua EVAL script.
**Alternatives considered**: MULTI/EXEC pipeline, optimistic locking with retry.
**Reasoning**: Lua scripts run single-threaded — no observable intermediate state.
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, choice of Lua over MULTI/EXEC
**Signal score**: HIGH
```

### `session-history/YYYY-MM-DD-HHMM.md`

Session narrative grounded in git log. What shipped · What was figured out · Where it got hard · AI contribution summary · Next steps inferred.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

Self-contained HTML. No CDN. Opens at `file://`. Includes token sub-panel: cache hit rate, top expensive turns, one-line optimization note.

### `WORKLOG.md`

Running log. D score accumulates across sessions — you can see whether you're actually getting better at collaborating with Claude:

```
2026-06-02 | REFACTORING    | HIGH | D:0.7 | cache:98% | tok:27618K | render.py 제거, 포지셔닝 재정의
2026-06-01 | FEATURE_BUILD  | HIGH | D:0.8 | cache:62% | tok:82K   | collab-proof 초기 릴리즈
2026-05-28 | BUG_FIXING     | HIGH | D:1.0 | cache:71% | tok:33K   | TOCTOU 레이스컨디션 진단
```

---

## Sharing the proof

```bash
# GitHub Gist
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public

# Verify git-anchored proof
git notes --ref=collab-proof show
```

> **Squash merge warning**: `git notes` are tied to a commit SHA. Use `--commit-footer` if your team uses squash merges.

---

## Roadmap

- [x] 3-layer pipeline (prompt-native, zero dependencies)
- [x] 4-frame WorkIntentClassifier with calibrated AI contribution field
- [x] DECISIONS.md
- [x] Session narrative (session-history/)
- [x] WORKLOG with D score + cache hit rate + token count
- [x] Token sub-panel in HTML proof
- [x] SessionEnd hook automation (Claude Code 1.0.84+)
- [x] Git-signed proof via `git notes`
- [ ] `/collab-review` — D score trend across sessions
- [ ] `awesome-claude-skills` listing

---

## License

MIT
