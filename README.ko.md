# collab-proof

AI 협업 세션을 **정적 분석**하는 Claude Code 스킬.

대부분의 세션 도구는 *"무슨 대화를 했는가?"* 또는 *"토큰을 얼마나 썼는가?"* 에 답합니다.  
collab-proof는 *"AI와 협업을 얼마나 잘했고, 어떻게 개선할 수 있는가?"* 에 답합니다.

git 히스토리와 세션 컨텍스트를 읽어 4개의 인지 프레임으로 협업 품질을 점수화하고, 나중에 검토하거나 증거로 제출할 수 있는 산출물을 생성합니다.

![collab-proof 데모](demo/collab-proof-demo.gif)

[English](README.md)

---

## 핵심 개념

ESLint와 같은 구조입니다 — 단, AI 협업 품질을 분석합니다.

```
ESLint:      코드    → 정적 분석 → 품질 리포트 + 개선 힌트
collab-proof: 세션   → 정적 분석 → 협업 품질  + 개선 힌트 + 증명
```

산출물에는 두 가지 용도가 있습니다:
- **나 자신** — AI가 실제로 어디서 기여했나? 토큰을 어디서 낭비했나? 세션이 지날수록 나아지고 있나?
- **타인** — AI가 무엇을 기여했고 내가 무엇을 결정했는지에 대한 교정된 증거

---

## 기존 도구와의 차이

| 도구 | 답하는 질문 |
|---|---|
| Claude Pulse, Rudel, AI Token Monitor | 토큰 수, 비용, 활동 히트맵 |
| Claude Code Analytics | 세션 유사도, 대화 검색 |
| **collab-proof** | **협업 품질 — AI와 개발자가 각각 어디서 결과를 주도했나** |

토큰 트래커는 *세션당 비용*을 알려줍니다. collab-proof는 *협업의 품질*을 알려줍니다 — 대화 주장이 아닌 git 히스토리에 근거해서.

---

## 파이프라인

`/collab-proof` 실행 시마다 3단계 파이프라인이 동작합니다.

### Layer 01 — WorkSignalDetector

`git log`와 `git diff`를 읽어 신호 수준을 분류합니다:

| 신호 | 조건 | 출력 |
|---|---|---|
| `HIGH` | 새 파일 생성, 4개+ 파일 수정, 명시적 대안 비교, 또는 버그 원인 진단 | 전체 산출물 |
| `MEDIUM` | 1~3개 파일 수정, 주요 논의 없음 | WORKLOG 한 줄만 |
| `LOW` | 코드 변경 없음, 계획만 있음 | 침묵 |

### Layer 02 — WorkIntentClassifier (ADHD 4-frame)

4개의 인지 프레임을 동시에 전개하고, 각각 0.0~1.0으로 점수화하며, 0.4 미만은 제거합니다:

| 프레임 | 잡아내는 것 |
|---|---|
| A — 기술적 | 코드 변경 깊이, 새 모듈, 아키텍처 변화 |
| B — 불확실성 | 롤백, 방향 전환, 개발자의 의심 신호 |
| C — 분기점 | 논의된 대안, 명시적 A vs B 비교 |
| D — AI 기여 | Claude가 결과를 바꾼 부분 vs 개발자 주도 부분 |

생존한 프레임에서 주요 인텐트 분류:  
`FEATURE_BUILDING` · `BUG_FIXING` · `REFACTORING` · `EXPLORING` · `STUCK` · `FLOW_STATE`

### Layer 03 — OutputGenerator

현재 세션의 토큰 사용량(input / cache_read / cache_create / output)을 수집한 뒤, 신호 수준과 생존 프레임 깊이에 비례해 산출물을 생성합니다.

---

## 설치

```bash
git clone https://github.com/dong7812/collab-proof
cd collab-proof
./install.sh
```

`~/.claude/`에 파일을 복사하고 훅을 `settings.json`에 자동 등록합니다. 재실행해도 안전합니다.

```
~/.claude/skills/collab-proof/SKILL.md           ← 스킬 정의
~/.claude/commands/collab-proof.md               ← /collab-proof 커맨드
~/.claude/hooks/collab-proof-on-stop.sh          ← Stop 훅 (WORKLOG 체크포인트)
~/.claude/hooks/collab-proof-on-session-end.sh   ← SessionEnd 훅 (전체 파이프라인)
~/.claude/hooks/collab-proof-pre-compact.sh      ← PreCompact 훅
~/.claude/hooks/collab-proof-sign-proof.sh       ← git notes 증명 앵커링
```

**외부 의존성 없음.** Python 표준 라이브러리만 사용. pip install 불필요.

---

## 사용법

Claude Code 세션 안에서:

```
/collab-proof
```

신호 감지 → 프레임 점수화 → 토큰 분석 → 산출물 생성 → HTML 증명서 순서로 파이프라인이 실행됩니다.

---

## 산출물

### `WORKLOG.md` — 관측 하네스

세션마다 추가되는 로그. 세션 간 트렌드 분석을 위해 설계되었습니다:

```
2026-06-02 12:10 | FEATURE_BUILDING | HIGH | D:0.9 | cache:85% | tok:45K | PR fork 관계 복구 후 재제출
2026-06-01 15:00 | FEATURE_BUILDING | HIGH | D:0.8 | cache:62% | tok:82K | collab-proof 초기 릴리즈
2026-05-28 09:30 | BUG_FIXING       | HIGH | D:1.0 | cache:71% | tok:33K | TOCTOU 레이스컨디션 진단
```

필드: `D:` = AI 기여 점수 · `cache:` = 캐시 히트율 · `tok:` = 총 토큰 수 (K 단위)

WORKLOG가 쌓일수록 협업 품질 히스토리가 됩니다 — D 점수 추이, 작업 유형별 토큰 효율, 어떤 인텐트 클래스가 컨텍스트를 가장 많이 소비하는지.

### `DECISIONS.md`

실제 결정 분기점당 하나의 항목. `AI 기여` 필드가 핵심입니다:

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

의미 있는 AI 기여가 없었다면: *"개발자 주도 세션. Claude는 지시를 실행했습니다."*

### `session-history/YYYY-MM-DD-HHMM.md`

git log에 근거한 세션 서사. 섹션: What shipped · What was figured out · 어디서 막혔나 · AI 기여 요약 · 다음 단계 추론.

### `session-history/YYYY-MM-DD-HHMM-proof.html`

완전 자체 포함 HTML. CDN 없음. `file://`에서 열림. 토큰 사용량 패널 포함:
- Input / cache / output 비율 바
- 캐시 히트율 효율 라벨 (≥80% 효율적 · 50~79% 보통 · <50% 컨텍스트 낭비)
- 가장 비싼 턴 Top 3 (토큰 수 + 프롬프트 미리보기)
- 관찰된 패턴 기반 한 줄 최적화 제안

---

## 훅

| 훅 | 이벤트 | 동작 |
|---|---|---|
| `SessionEnd` | 세션 종료 시 | 전체 파이프라인 — 전체 산출물 + git notes 앵커링 |
| `Stop` | Claude 턴 종료마다 | 2개+ 파일 변경 시 WORKLOG에 체크포인트 추가 |
| `PreCompact` | 컨텍스트 압축 전 | 컨텍스트 손실 방지를 위한 스냅샷 마커 기록 |

---

## 증명서 공유

```bash
# GitHub Gist (한 명령어, 영구 URL)
gh gist create session-history/YYYY-MM-DD-HHMM-proof.html --public

# git notes 증명 확인
git notes --ref=collab-proof show
```

> **Squash merge 주의**: `git notes`는 커밋 SHA에 연결됩니다. GitHub Squash and Merge는 해시를 재생성해 노트가 유실됩니다. `--commit-footer` 옵션으로 커밋 메시지에 앵커를 삽입하면 squash 이후에도 생존합니다.

---

## 로드맵

- [x] Vela 3-layer 파이프라인 (프롬프트 네이티브, 외부 의존성 없음)
- [x] ADHD 4-frame WorkIntentClassifier
- [x] 교정된 AI 기여 필드가 있는 DECISIONS.md
- [x] session-history 서사
- [x] D 점수 + 캐시 히트율 + 토큰 수가 포함된 WORKLOG
- [x] 토큰 사용량 분석 — 캐시 효율, 비싼 턴 Top 3, 최적화 힌트
- [x] 토큰 패널이 포함된 HTML 증명서 (자체 포함, `file://` 지원)
- [x] SessionEnd 훅 전체 자동화 (Claude Code 1.0.84+)
- [x] git notes 증명 앵커링 (`refs/notes/collab-proof`)
- [ ] `/collab-review` — 세션 간 트렌드 뷰 (D 점수 추이, 토큰 효율 변화)
- [ ] awesome-claude-skills 레지스트리 등록

---

## 라이선스

MIT
