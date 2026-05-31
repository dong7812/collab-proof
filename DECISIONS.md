# DECISIONS.md

---

## 2026-06-01 Vela pipeline을 Python 패키지가 아닌 prompt로 구현

**Context**: Vela는 로컬 Python 패키지로 존재. skill에 포함시키면 타인이 설치할 때 Vela 클론 + 환경 설정 필요.  
**Decision**: Vela의 3-layer 구조를 Python 코드 없이 SKILL.md 안의 추론 지시로 구현.  
**Alternatives considered**: Python 스크립트로 hook에서 Vela 호출, Vela를 pip 패키지로 배포 후 의존성 추가.  
**Reasoning**: inferred: star를 목적으로 하는 공개 skill에서 의존성은 채택률을 낮춘다. "설치 = 파일 복붙 하나"여야 한다.  
**AI contribution**:
  - Suggested: Vela Python 의존성이 공개 skill 목적과 충돌함을 지적
  - Suggested: pipeline 구조를 prompt-native로 변환하는 방향 제안
  - Developer-driven: Vela를 쓰겠다는 초기 방향 설정, 최종 채택 결정  
**Intent class**: FEATURE_BUILDING  
**Signal score**: 0.94  
**Outcome**: implemented

---

## 2026-06-01 ADHD tree-of-thought를 Layer 02에 통합

**Context**: Vela pipeline만으로는 단일 시선 분석. "개발자가 기억 못 하는 것을 잡아준다"는 목표에 단일 pass가 부족.  
**Decision**: Layer 02에 4개 인지 프레임(Technical/Uncertainty/Fork/AI contribution) 동시 발산 → 점수 매기고 가지치기 → 생존 프레임만 심화.  
**Alternatives considered**: 단순 체크리스트 방식으로 항목별 확인, Claude에게 자유롭게 요약하도록 위임.  
**Reasoning**: inferred: ADHD tree-of-thought의 핵심은 "각 프레임이 완전히 독립된 시선"이라는 점. Frame B(불확실 렌즈)가 없으면 revert 패턴에서 STUCK을 감지하지 못함. Frame D(AI contribution)가 없으면 기여가 과장되거나 누락됨.  
**AI contribution**:
  - Identified: Frame B와 Frame D가 "기억 못 하는 것을 잡는다"는 목표에 가장 핵심적임을 분석
  - Suggested: 4개 프레임 구성과 Layer 02 배치 설계
  - Developer-driven: "ADHD 구조도 섞으면 어떨까"라는 아이디어 자체  
**Intent class**: FEATURE_BUILDING  
**Signal score**: 0.94  
**Outcome**: implemented

---

## 2026-06-01 HTML proof artifact를 독립 파일로 생성

**Context**: 기존 도구들은 전부 로컬 markdown. "남에게 증명"하려면 공유 가능한 포맷 필요.  
**Decision**: 세션마다 self-contained HTML 파일 생성. 인라인 CSS, CDN 없음, file:// 동작.  
**Alternatives considered**: PDF export, GitHub Gist 자동 업로드, markdown 그대로 유지.  
**Reasoning**: HTML은 브라우저만 있으면 열림. 포트폴리오 첨부, PR 링크, 채용 제출에 바로 쓸 수 있음. PDF는 생성 복잡. Gist는 의존성 추가.  
**AI contribution**:
  - Suggested: "남에게 증명하려면 shareable artifact 필요" — 기존 도구와의 차별점으로 제시
  - Suggested: git commit hash를 footer에 포함해 조작 불가 타임스탬프 역할
  - Developer-driven: HTML 선택 최종 결정  
**Intent class**: FEATURE_BUILDING  
**Signal score**: 0.94  
**Outcome**: implemented
