# collab-proof

Claude Code 세션이 끝난 후, AI가 실제로 무엇을 기여했고 내가 무엇을 결정했는가?

collab-proof는 그 답을 구조화하고 기록하는 **보조 회고 도구**입니다.

![collab-proof 데모](demo/collab-proof-demo.gif)

[English](README.md)

---

## 이 도구가 무엇인지 (그리고 무엇이 아닌지)

collab-proof는 정밀 측정 시스템이 아닙니다. D score는 명시적인 루브릭을 사용해 LLM이 평가한 값입니다 — 정확한 수치가 아닌 방향 지표로 사용하세요.

하는 일: 세션이 끝난 후 git 히스토리를 읽어 신호 수준을 감지하고, 대화 컨텍스트를 사용해 AI 기여를 포함한 4개의 인지 프레임을 점수화합니다. 결과물은 검토하고, 수정하고, 공유할 수 있는 구조화된 아티팩트입니다.

가치는 정밀도가 아닙니다. 어떤 결정이 내려졌는지, 어떤 대안이 기각됐는지, Claude가 내가 놓친 것을 발견한 순간 — 이것들이 증발하지 않고 *기록된다*는 데 있습니다.

---

## 핵심 출력

AI 기여 필드 — 과장도 축소도 없이:

```markdown
**AI 기여**:
  - Identified: 개발자가 인지하지 못한 ZCARD와 ZADD 사이의 TOCTOU 구간
  - Suggested: Redis 원자성 문서 확인 후 Lua EVAL 방식 제안
  - Developer-driven: 최종 구현, Lua vs MULTI/EXEC 최종 결정
```

Claude가 지시를 실행만 한 세션은:

```markdown
**AI 기여**:
  - Developer-driven session. Claude executed instructions.
```

루브릭이 양쪽 모두 명시하도록 강제합니다. 결과물을 읽고 틀렸으면 수정할 수 있습니다.

---

## 파이프라인

### Layer 01 — 신호 감지

`git log`와 `git diff`를 읽습니다. 파일 수, 커밋 메시지, diff 크기 — 이 부분은 객관적입니다.

| 신호 | 조건 | 출력 |
|---|---|---|
| `HIGH` | 새 파일, 4개+ 수정, 명시적 대안 비교, 버그 진단 | 전체 산출물 |
| `MEDIUM` | 1~3개 수정, 주요 논의 없음 | WORKLOG 한 줄 |
| `LOW` | 코드 변경 없음 | 침묵 |

전체 세션의 약 30~40%에서 유용한 산출물이 생성됩니다.

### Layer 02 — 4-frame 분석

이 부분은 대화 컨텍스트를 사용합니다 — LLM이 평가하는 것이지 계산되는 것이 아닙니다. 4개의 프레임을 명시적 루브릭으로 0.0~1.0 점수화하고 0.4 미만은 제거합니다:

| 프레임 | 잡아내는 것 |
|---|---|
| A — 기술적 | 코드 변경 깊이, 새 모듈, 아키텍처 변화 |
| B — 불확실성 | 롤백, 방향 전환, 개발자의 의심 신호 |
| C — 분기점 | 논의된 대안, 명시적 A vs B 비교 |
| D — AI 기여 | Claude가 결과를 바꾼 부분 vs 개발자 주도 부분 |

Frame D가 핵심입니다. 루브릭은 고정 앵커(0.2 / 0.6 / 1.0)를 사용해 분산을 줄이지만, 실행할 때마다 점수가 달라질 수 있습니다. D score는 세션 간 트렌드 지표로 사용하고, 절댓값으로 해석하지 마세요.

### Layer 03 — 출력

신호 수준에 비례한 산출물 생성. `~/.claude/projects/` JSONL 파일에서 토큰 사용량을 읽어(Python 파일 I/O — API 호출 없음, 추가 비용 없음) 캐시 히트율, 비싼 턴 Top 3, 최적화 힌트를 HTML proof 서브 패널로 포함합니다.

---

## 설치

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

외부 의존성 없음. Python 표준 라이브러리만 사용.

훅 3개가 `~/.claude/settings.json`에 자동 등록됩니다:

| 훅 | 시점 | 동작 | 블로킹 |
|---|---|---|---|
| `SessionEnd` | 세션 종료 | 전체 파이프라인 자동 실행 | 없음 — 비동기 백그라운드 |
| `Stop` | 매 턴 종료 | 2개+ 파일 변경 시 WORKLOG 체크포인트 | 없음 — 비동기 백그라운드 |
| `PreCompact` | 컨텍스트 압축 전 | 스냅샷 마커 기록 | 있음 — 파일 한 줄 쓰기만 |

`SessionEnd`와 `Stop`은 백그라운드 서브셸(`disown`)에서 실행되므로 Claude Code가 블로킹되지 않습니다. 에러는 `/tmp/collab-proof-*.log`에 기록됩니다. `PreCompact`는 타이밍이 중요해 동기 유지하지만 파일 한 줄 쓰기만 수행합니다.

훅은 공식적으로 안정성이 보장된 API가 아닙니다. Claude Code 업데이트 후 훅이 작동하지 않으면 `/tmp/collab-proof-session-end.log`를 확인하세요.

---

## 사용법

```
/collab-proof
```

---

## 산출물

### `DECISIONS.md`

실제 결정 분기점당 하나의 항목. 결과물을 읽고 AI 기여 평가가 틀렸으면 수정하세요.

```markdown
## 2026-06-01 Rate limiter의 Lua EVAL 원자성

**Context**: Redis ZCARD + ZADD 두 번 왕복이 동시 요청 시 TOCTOU 경쟁 조건 생성.
**Decision**: PRUNE + CHECK + ADD를 단일 Lua EVAL 스크립트로 이동.
**고려한 대안**: MULTI/EXEC 파이프라인, 낙관적 잠금 + 재시도.
**AI 기여**:
  - Identified: 개발자가 인지하지 못한 ZCARD와 ZADD 사이의 TOCTOU 구간
  - Suggested: Redis 원자성 문서 확인 후 Lua EVAL 방식 제안
  - Developer-driven: 최종 구현, Lua vs MULTI/EXEC 최종 결정
**신호 수준**: HIGH
```

### `session-history/YYYY-MM-DD-HHMM.md`

세션 서사. What shipped · What was figured out · 어디서 막혔나 · AI 기여 요약 · 다음 단계 추론.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

완전 자체 포함 HTML. `file://`에서 열림. 토큰 서브 패널 포함: 캐시 히트율, 비싼 턴 Top 3, 최적화 한 줄 제안.

### `WORKLOG.md`

D score가 세션마다 누적됩니다. 스코어보드가 아닌 트렌드 지표로 사용하세요:

```
2026-06-02 | REFACTORING   | HIGH | D:0.7 | cache:98% | tok:27618K | render.py 제거, 포지셔닝 재정의
2026-06-01 | FEATURE_BUILD | HIGH | D:0.8 | cache:62% | tok:82K   | collab-proof 초기 릴리즈
2026-05-28 | BUG_FIXING    | HIGH | D:1.0 | cache:71% | tok:33K   | TOCTOU 레이스컨디션 진단
```

---

## 증명서 공유

HTML proof는 자체 포함 파일입니다:

```bash
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public
```

**git notes**는 커밋 SHA에 증명을 앵커링하는 솔로 개발자 기능입니다. 팀 환경에서는 squash merge 시 노트가 유실되고, 팀원이 `git fetch origin refs/notes/*`를 명시적으로 실행해야 공유됩니다.

---

## 로드맵

- [x] 3-layer 파이프라인 (프롬프트 네이티브, 외부 의존성 없음)
- [x] AI 기여 필드가 있는 4-frame WorkIntentClassifier
- [x] DECISIONS.md
- [x] session-history 서사
- [x] D score + 캐시 히트율 + 토큰 수가 포함된 WORKLOG
- [x] HTML proof 토큰 서브 패널
- [x] SessionEnd 훅 자동화 (Claude Code 1.0.84+)
- [x] git notes 증명 앵커링
- [ ] `/collab-review` — 세션 간 D score 트렌드 뷰
- [ ] awesome-claude-skills 등록

---

## 라이선스

MIT
