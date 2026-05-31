# collab-proof

> A Claude Code skill that infers AI collaboration evidence — not just logs it.

Most session-logging tools record what happened. collab-proof reasons about **what mattered and why** — using a three-layer signal pipeline that filters noise, classifies intent, and generates shareable proof artifacts.

```
/session-proof
```

That's the entire interface.

---

## The problem

Companies increasingly ask: **"Show me how you used AI in this project."**

You could write `DECISIONS.md` by hand after every session. But you won't — you're already focused on the next problem. The context evaporates.

collab-proof captures it while you're still in the session.

---

## What it generates

| Artifact | What it is |
|---|---|
| `DECISIONS.md` | Every architectural fork — with what Claude contributed vs what you decided |
| `session-history/YYYY-MM-DD-HHMM.md` | Session narrative: what shipped, what was figured out, where things got hard |
| `session-history/YYYY-MM-DD-HHMM-proof.html` | Self-contained shareable proof — attach to portfolio, link in PR |
| `WORKLOG.md` | Running one-liner log per session |

---

## How it works

Two architectures combined:

**Vela pipeline** (signal filtering) × **ADHD tree-of-thought** (multi-frame reasoning)

```
Layer 01 — WorkSignalDetector  (Vela)
  git log + diff + conversation → signal score
  Low signal → silence (avoids noise)

Layer 02 — WorkIntentClassifier  (Vela × ADHD)
  Fan out 4 cognitive frames simultaneously:
  ├── Frame A: Technical lens    "What choices were made?"
  ├── Frame B: Uncertainty lens  "Where was the developer unsure?"
  ├── Frame C: Fork lens         "What could have gone differently?"
  └── Frame D: AI contribution   "Where did Claude actually change the outcome?"
  Score each frame → prune weak ones → classify intent from survivors

Layer 03 — OutputGenerator  (Vela × ADHD)
  Generate from surviving frames only
  signal < 0.35   → silence
  signal 0.35–0.60 → WORKLOG one-liner
  signal ≥ 0.60   → full artifacts + HTML proof
```

No Python install. No config. Zero external dependencies.

---

## The thing other tools don't do

Every existing session logger answers: *"What did we talk about?"*

collab-proof answers: *"What decision was made, what was the alternative, and what did the AI actually contribute — versus what did the developer drive?"*

The `AI contribution` field in every DECISIONS.md entry is deliberately calibrated:

```markdown
## 2026-06-01 Rate limiter atomicity

**AI contribution**: Identified the TOCTOU window between ZCARD and ZADD
that the developer hadn't noticed. Suggested Lua EVAL after checking Redis docs.
Developer made the final call to use it over MULTI/EXEC.
```

Not "Claude helped." Not "Developer did everything." The actual split.

---

## Install

```bash
git clone https://github.com/YOUR_USERNAME/collab-proof
cd collab-proof
./install.sh
```

Then in any Claude Code session:

```
/session-proof
```

---

## Output example

**`proof.html`** preview:

```
┌─────────────────────────────────────────────────────┐
│  collab-proof report                                 │
│  project: my-api  ·  2026-06-01  ·  FEATURE_BUILDING│
│  signal score: 0.82                                  │
├─────────────────────────────────────────────────────┤
│  DECISIONS (2)                                       │
│  ├── Rate limiter atomicity          signal: 0.82   │
│  └── Retry policy algorithm         signal: 0.71   │
├─────────────────────────────────────────────────────┤
│  AI contribution                                     │
│  ├── Identified: TOCTOU race condition               │
│  ├── Suggested: Lua EVAL approach                    │
│  └── Developer-driven: final implementation         │
├─────────────────────────────────────────────────────┤
│  Verified by git: a3f2c91                            │
└─────────────────────────────────────────────────────┘
```

---

## Roadmap

- [x] SKILL.md pipeline (Vela 3-layer, prompt-native)
- [x] DECISIONS.md generation with AI contribution field
- [x] session-history narrative
- [x] WORKLOG one-liner
- [x] HTML proof artifact
- [ ] SessionEnd hook (waiting on [anthropics/claude-code#59273](https://github.com/anthropics/claude-code/issues/59273))
- [ ] Git-signed proof (tamper-evident via commit hash)
- [ ] WORKLOG → GitHub Gist auto-publish

---

## License

MIT
