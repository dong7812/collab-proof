# collab-proof

After a Claude Code session, what did the AI actually contribute — and what did you drive?

collab-proof is an **assisted retrospective** that structures the answer and keeps a record.

![collab-proof demo](demo/collab-proof-demo.gif)

[한국어](README.ko.md)

---

## What it is (and what it isn't)

collab-proof is not a measurement system. The D score is LLM-assessed using an explicit rubric — treat it as a directional indicator, not a precise metric.

What it does: after a session, it reads your git history to detect signal level, then uses conversation context to score four cognitive frames including AI contribution. The result is a structured artifact you can review, correct, and share.

The value isn't precision. It's that *something* is recorded — the decision that was made, the alternative that was ruled out, the moment Claude spotted something you missed — instead of evaporating.

---

## The core output

The AI contribution field — honest, not promotional:

```markdown
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, choice of Lua over MULTI/EXEC
```

vs sessions where Claude just executed instructions:

```markdown
**AI contribution**:
  - Developer-driven session. Claude executed instructions.
```

The rubric forces both sides to be named. You can read the output and correct it if wrong.

---

## Pipeline

### Layer 01 — Signal detection

Reads `git log` and `git diff`. This part is objective — file counts, commit messages, diff size.

| Signal | Condition | Output |
|---|---|---|
| `HIGH` | New file, 4+ files modified, explicit option comparison, or bug diagnosed | Full artifacts |
| `MEDIUM` | 1–3 files modified, no major discussion | WORKLOG one-liner only |
| `LOW` | No code changes | Silence |

Roughly 30–40% of sessions generate useful artifacts. The rest are correctly silenced.

### Layer 02 — 4-frame analysis

This part uses conversation context — which means it's LLM-assessed, not computed. Four frames are scored 0.0–1.0 using an explicit rubric and pruned below 0.4:

| Frame | What it catches |
|---|---|
| A — Technical | Code churn depth, new modules, architectural changes |
| B — Uncertainty | Reverts, direction changes, developer doubt signals |
| C — Fork | Alternatives discussed, explicit A-vs-B comparisons |
| D — AI contribution | Where Claude changed the outcome vs. developer-driven work |

Frame D is the core. The rubric has fixed anchors (0.2 / 0.6 / 1.0) to reduce variance, but scores can differ between runs. Use D score as a trend indicator across sessions, not as an absolute value.

### Layer 03 — Output

Generates artifacts proportional to signal level. Also reads token usage from `~/.claude/projects/` JSONL files (Python file I/O — no API calls, no additional cost) and includes cache hit rate, top expensive turns, and an optimization note as a sub-panel in the HTML proof.

---

## Install

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

Zero external dependencies. Python stdlib only. No pip install required.

Wires three hooks into `~/.claude/settings.json`:

| Hook | When | What | Blocking |
|---|---|---|---|
| `SessionEnd` | Session closes | Full pipeline automatically | No — async background process |
| `Stop` | Each turn | WORKLOG checkpoint if ≥2 files changed | No — async background process |
| `PreCompact` | Before compaction | Snapshot before context loss | Yes — minimal (one file write) |

`SessionEnd` and `Stop` run in a background subshell (`disown`) so Claude Code is never blocked. Errors are logged to `/tmp/collab-proof-*.log`. `PreCompact` stays synchronous because timing matters — it must complete before compaction — but is kept to a single file write.

Hooks are wired via `~/.claude/settings.json`. They are not an officially guaranteed API — a Claude Code update could change hook behavior. If hooks stop firing silently, check `/tmp/collab-proof-session-end.log` to diagnose.

---

## Usage

```
/collab-proof
```

---

## Output

### `DECISIONS.md`

One entry per real decision fork. Read the output — correct it if the AI contribution assessment is off.

```markdown
## 2026-06-01 Rate limiter atomicity via Lua EVAL

**Context**: Redis ZCARD + ZADD across two round trips creates a TOCTOU race.
**Decision**: Moved PRUNE + CHECK + ADD into a single Lua EVAL script.
**Alternatives considered**: MULTI/EXEC pipeline, optimistic locking with retry.
**AI contribution**:
  - Identified: TOCTOU window between ZCARD and ZADD developer had not noticed
  - Suggested: Lua EVAL approach after reviewing Redis atomicity guarantees
  - Developer-driven: Final implementation, choice of Lua over MULTI/EXEC
**Signal score**: HIGH
```

### `session-history/YYYY-MM-DD-HHMM.md`

Session narrative. What shipped · What was figured out · Where it got hard · AI contribution summary · Next steps inferred.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

Self-contained HTML. No CDN. Opens at `file://`. Includes token sub-panel: cache hit rate, top expensive turns, one-line optimization note.

### `WORKLOG.md`

D score accumulates across sessions. Use it as a trend, not a scoreboard:

```
2026-06-02 | REFACTORING   | HIGH | D:0.7 | cache:98% | tok:27618K | render.py 제거, 포지셔닝 재정의
2026-06-01 | FEATURE_BUILD | HIGH | D:0.8 | cache:62% | tok:82K   | collab-proof 초기 릴리즈
2026-05-28 | BUG_FIXING    | HIGH | D:1.0 | cache:71% | tok:33K   | TOCTOU 레이스컨디션 진단
```

---

## Sharing the proof

The HTML proof is self-contained and opens at `file://`. For external sharing:

```bash
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public
```

**git notes** anchor the proof to a specific commit SHA for tamper-evidence. This is a solo developer feature — it doesn't propagate automatically in team environments (squash merges orphan notes, and teammates need explicit `git fetch origin refs/notes/*` to see them).

```bash
git notes --ref=collab-proof show
```

---

## Roadmap

- [x] 3-layer pipeline (prompt-native, zero dependencies)
- [x] 4-frame WorkIntentClassifier with AI contribution field
- [x] DECISIONS.md
- [x] Session narrative
- [x] WORKLOG with D score + cache hit rate + token count
- [x] Token sub-panel in HTML proof
- [x] SessionEnd hook automation (Claude Code 1.0.84+)
- [x] Git-signed proof via `git notes`
- [ ] `/collab-review` — D score trend across sessions
- [ ] `awesome-claude-skills` listing

---

## License

MIT
