# collab-proof

Claude Code 세션이 끝난 후, AI가 실제로 무엇을 기여했고 내가 무엇을 결정했는가?

collab-proof는 그 답을 교정하고 기록합니다.

![collab-proof 데모](demo/collab-proof-demo.gif)

[English](README.md)

---

## 문제

AI와 함께하는 세션은 빠르게 흘러갑니다. 결정이 내려지고, 트레이드오프가 논의되고, 버그가 잡힙니다 — 그리고 이미 다음 작업으로 넘어가 있습니다.

나중에 돌아보면 재구성이 안 됩니다. git log는 *무엇이* 바뀌었는지는 보여주지만, 대화는 사라지거나 압축됩니다. `MULTI/EXEC 대신 Lua EVAL을 선택한 이유`, Claude가 내가 놓친 경쟁 조건을 발견한 순간, 의식적으로 배제한 대안 — 이 모든 것이 증발합니다.

대부분의 도구는 *"무슨 대화를 했는가?"* 에 답합니다.  
collab-proof는 *"Claude가 실제로 무엇을 기여했고, 내가 무엇을 결정했는가?"* 에 답합니다 — 대화 기억이 아닌 git 히스토리에 근거해서.

---

## 차별점

핵심은 **AI 기여 필드** — 과장도 축소도 없이 교정된 기록입니다:

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

---

## 파이프라인

### Layer 01 — 신호 감지

`git log`와 `git diff`를 읽어 신호 수준 분류:

| 신호 | 조건 | 출력 |
|---|---|---|
| `HIGH` | 새 파일, 4개+ 수정, 명시적 대안 비교, 버그 진단 | 전체 산출물 |
| `MEDIUM` | 1~3개 수정, 주요 논의 없음 | WORKLOG 한 줄 |
| `LOW` | 코드 변경 없음 | 침묵 |

전체 세션의 약 30~40%에서 유용한 산출물이 생성됩니다.

### Layer 02 — 4-frame 분석

4개의 인지 프레임을 동시에 점수화하고, 0.4 미만은 제거:

| 프레임 | 잡아내는 것 |
|---|---|
| A — 기술적 | 코드 변경 깊이, 새 모듈, 아키텍처 변화 |
| B — 불확실성 | 롤백, 방향 전환, 개발자의 의심 신호 |
| C — 분기점 | 논의된 대안, 명시적 A vs B 비교 |
| D — AI 기여 | Claude가 결과를 바꾼 부분 vs 개발자 주도 부분 |

**Frame D가 핵심입니다.** *"Claude가 TOCTOU 구간을 발견했다"* 와 *"개발자 주도 세션"* 을 구분하는 것이 이 프레임입니다.

### Layer 03 — 출력

신호 수준에 비례한 산출물 생성. 토큰 사용량(캐시 히트율, 비싼 턴)은 HTML proof의 서브 패널로 포함됩니다.

---

## 설치

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

외부 의존성 없음. Python 표준 라이브러리만 사용. pip install 불필요.

훅 3개가 `~/.claude/settings.json`에 자동 등록됩니다:

| 훅 | 시점 | 동작 |
|---|---|---|
| `SessionEnd` | 세션 종료 | 전체 파이프라인 자동 실행 |
| `Stop` | 매 턴 종료 | 2개+ 파일 변경 시 WORKLOG 체크포인트 |
| `PreCompact` | 컨텍스트 압축 전 | 스냅샷 마커 기록 |

---

## 사용법

```
/collab-proof
```

---

## 산출물

### `DECISIONS.md`

실제 결정 분기점당 하나의 항목. AI 기여 필드가 핵심:

```markdown
## 2026-06-01 Rate limiter의 Lua EVAL 원자성

**Context**: Redis ZCARD + ZADD 두 번 왕복이 동시 요청 시 TOCTOU 경쟁 조건 생성.
**Decision**: PRUNE + CHECK + ADD를 단일 Lua EVAL 스크립트로 이동.
**고려한 대안**: MULTI/EXEC 파이프라인, 낙관적 잠금 + 재시도.
**Reasoning**: Lua 스크립트는 Redis에서 단일 스레드로 실행 — 중간 상태 없음.
**AI 기여**:
  - Identified: 개발자가 인지하지 못한 ZCARD와 ZADD 사이의 TOCTOU 구간
  - Suggested: Redis 원자성 문서 확인 후 Lua EVAL 방식 제안
  - Developer-driven: 최종 구현, Lua vs MULTI/EXEC 최종 결정
**신호 수준**: HIGH
```

### `session-history/YYYY-MM-DD-HHMM.md`

git log에 근거한 세션 서사. What shipped · What was figured out · 어디서 막혔나 · AI 기여 요약 · 다음 단계 추론.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

완전 자체 포함 HTML. `file://`에서 열림. 토큰 서브 패널 포함: 캐시 히트율, 비싼 턴 Top 3, 최적화 한 줄 제안.

### `WORKLOG.md`

D score가 세션마다 누적됩니다 — 내가 Claude와의 협업을 점점 잘하고 있는지 트렌드로 확인:

```
2026-06-02 | REFACTORING   | HIGH | D:0.7 | cache:98% | tok:27618K | render.py 제거, 포지셔닝 재정의
2026-06-01 | FEATURE_BUILD | HIGH | D:0.8 | cache:62% | tok:82K   | collab-proof 초기 릴리즈
2026-05-28 | BUG_FIXING    | HIGH | D:1.0 | cache:71% | tok:33K   | TOCTOU 레이스컨디션 진단
```

---

## 증명서 공유

```bash
# GitHub Gist
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public

# git notes 증명 확인
git notes --ref=collab-proof show
```

---

## 로드맵

- [x] 3-layer 파이프라인 (프롬프트 네이티브, 외부 의존성 없음)
- [x] 교정된 AI 기여 필드가 있는 4-frame WorkIntentClassifier
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
