# Architecture

## Pipeline overview

collab-proof runs a three-layer pipeline adapted from [Vela](https://github.com/dong7812/vela)'s signal filtering architecture.

```
Layer 01 — WorkSignalDetector    git log + diff → HIGH / MEDIUM / LOW
Layer 02 — WorkIntentClassifier  4-frame ADHD tree-of-thought → intent class + JSON
Layer 03 — OutputGenerator       artifacts proportional to signal × frame depth
```

---

## Layer 01 — Signal detection

Classifies session signal before any LLM reasoning runs.
Low-signal sessions are silenced immediately (Horvitz 1999: act only when E[utility(act)] > E[utility(wait)]).

Thresholds:
- **HIGH** → full artifacts
- **MEDIUM** → WORKLOG only
- **LOW** → silence

Special case: BUG_FIXING overrides file count when root cause diagnosis is present in conversation.

---

## Layer 02 — WorkIntentClassifier

Four cognitive frames run simultaneously, scored 0.0–1.0, pruned below 0.4.

### Scoring rubric

| Frame | 1.0 | 0.5 | 0.0–0.1 |
|---|---|---|---|
| A — Technical | New module/file, complex logic | Existing function modified | Typo, comment |
| B — Uncertainty | Rollback, explicit doubt | Advice-seeking, 2+ revisions | Direct execution |
| C — Fork | Explicit A-vs-B comparison | Tradeoff mention | No alternatives |
| D — AI contribution | Bug/edge case caught | Boilerplate scaffold | Transcription only |

### High-Speed Execution Guard

If `Frame A ≥ 0.8` AND `Frame D ≥ 0.6` → classify `FEATURE_BUILDING / HIGH` regardless of Frame B/C scores.
Rationale: boilerplate-heavy sessions have genuine AI contribution even when uncertainty and fork are absent.

### Intent mapping

| Surviving frames | Dominant intent |
|---|---|
| A high + D mid-high (B, C low) | `FEATURE_BUILDING` |
| B high + A/D high | `BUG_FIXING` or `STUCK` |
| C high + A high | `REFACTORING` or `EXPLORING` |
| All frames < 0.4 | `FLOW_STATE` or LOW |

### Output schema (Layer 02 → Layer 03 handoff)

```json
{
  "frames": { "technical": 0.0, "uncertainty": 0.0, "fork": 0.0, "ai_contribution": 0.0 },
  "pruned": [],
  "intent": "FEATURE_BUILDING",
  "signal": "HIGH",
  "calibration_note": "reason for any exception rule applied"
}
```

---

## Layer 03 — OutputGenerator

Writes artifacts proportional to signal × surviving frame depth:

| Signal | Artifacts |
|---|---|
| HIGH | DECISIONS.md + session-history + proof.html + WORKLOG |
| MEDIUM | WORKLOG only |
| LOW | silence |

---

## Theoretical foundations

collab-proof's pipeline structure traces to the academic literature behind Vela:

| Paper | Where it applies |
|---|---|
| Horvitz (1999) *Mixed-Initiative Interaction*, CHI | Layer 01 silence threshold |
| Liu et al. (2021) *ESConv*, ACL | Layer 02 intent classification |
| Deng et al. (2023) *Survey on Proactive Dialogue Systems*, IJCAI | 3-layer pipeline structure |
| Deng, Liao et al. (2023) *Prompting LLMs for Proactive Dialogues*, EMNLP | Layer 03 prompt separation |
| Bohus & Rudnicky (2005) *Error Handling in Conversational Systems* | Frame B uncertainty signals |
| Reimers & Gurevych (2019) *Sentence-BERT*, EMNLP | Frame scoring depth proxy |
| Sacks, Schegloff & Jefferson (1974) *Turn-taking in Conversation* | Conversation signal weighting |

---

## Tamper-evident proof

Session HTML is SHA-256 hashed and attached to the current git commit via `git notes`.
No file tree modification. Uses `refs/notes/collab-proof` namespace (separate from default git notes).
Shareable via `git push origin refs/notes/collab-proof`.
See `hooks/sign-proof.sh` for implementation.
