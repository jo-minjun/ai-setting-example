---
name: orchestrator
description: TDD 기반 개발 오케스트레이터. 기능 추가, 기능 변경, 기능 구현 요청 시 자동 발동한다. "~해줘", "~만들어줘", "~추가해줘", "~구현해줘", "~개발해줘", "~변경해줘", "~수정해줘" 같은 코드 변경 요청에 트리거된다. Planner, Architect, QA Engineer, Implementer를 조율하여 테스트 우선 개발 루프를 실행하고, 마일스톤 완료까지 자동으로 진행한다.
---

# TDD 오케스트레이터

서브에이전트를 마일스톤 단위로 조율하여 TDD 기반 개발 루프를 실행한다.

## 핵심 원칙

1. **마일스톤 단위**: 한 번에 하나의 마일스톤만 처리
2. **계약 기반**: 페이즈 간 Contract로 정보 전달
3. **게이트 통제**: 조건 미충족 시 다음 단계 차단
4. **자동 루프**: 마일스톤 완료까지 사용자 개입 없이 진행

## 오케스트레이션 루프

```
Planning → Design → Test First → Implementation → Verification → Complete
    ↑                                    │               │
    └────────────────────────────────────┴───────────────┘
                    (테스트 실패 또는 게이트 위반 시 복귀)
```

## 에이전트 호출 순서

| 순서 | 에이전트 | 역할 | 출력 |
|------|---------|------|------|
| 1 | Planner | 마일스톤 정의 | Design Brief |
| 2 | Architect | 설계 확정 | Design Contract |
| 3 | QA Engineer | 테스트 작성 | Test Contract + 테스트 코드 |
| 4 | Implementer | 구현 | 구현 코드 |
| 5 | QA Engineer | 테스트 실행 | Test Result Report |

보조 에이전트: Code Explore (코드 탐색), Web Explore (외부 문서 검색)

## 게이트 규칙 요약

| Gate | 조건 | 위반 시 |
|------|------|--------|
| GATE-1 | Test Contract 존재 | Implementation 차단 |
| GATE-2 | 테스트 결과 존재 | Complete 차단 |
| GATE-3 | 스코프 변경 없음 | Planning 복귀 |
| GATE-4 | 설계 불변 조건 유지 | Design 복귀 |

상세 규칙: [gate-rules.md](references/gate-rules.md)

## 상태 출력 (매 페이즈 후)

```
## Status Report
- **Phase**: [현재 페이즈]
- **Agent**: [실행 에이전트]
- **Gate**: [PASS|FAIL] - [사유]
- **Next**: [다음 작업]
- **Continue**: [YES|NO]
```

## 참조 문서

| 문서 | 내용 |
|------|------|
| [gate-rules.md](references/gate-rules.md) | 게이트 규칙 상세 |
| [contracts.md](references/contracts.md) | Contract 형식 (Design Brief, Design Contract, Test Contract) |
| [phases.md](references/phases.md) | 페이즈별 상세 절차 |
| [agent-contexts.md](references/agent-contexts.md) | 에이전트별 컨텍스트 주입 가이드 |

## 빠른 시작

### 1. 마일스톤 시작

```
Planner 호출:
- prompt: "[사용자 요청] 분석하여 Design Brief 생성"
- subagent_type: "planner"
```

### 2. 설계

```
Architect 호출:
- prompt: "[Design Brief] 기반으로 Design Contract 생성"
- subagent_type: "architect"
```

### 3. 테스트 작성

```
QA Engineer 호출:
- prompt: "[Design Contract] 기반으로 테스트 코드 작성"
- subagent_type: "qa-engineer"
```

### 4. 구현

```
Implementer 호출:
- prompt: "[테스트 코드]를 통과하는 최소 구현"
- subagent_type: "implementer"
```

### 5. 검증

```
QA Engineer 호출:
- prompt: "테스트 실행 및 결과 보고"
- subagent_type: "qa-engineer"
```

## 제약사항

- 한 번에 하나의 마일스톤만 처리
- Contract 불완전 시 다음 단계 진행 금지
- 테스트 없이 구현 완료 불가
- 게이트 위반 시 이전 단계로 복귀
