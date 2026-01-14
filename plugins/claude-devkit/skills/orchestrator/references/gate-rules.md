# 게이트 규칙

오케스트레이터가 다음 단계로 진행하기 전 검증하는 규칙이다.
게이트는 **Subtask 레벨 (Mini TDD Loop)** 에서 적용된다.

## 게이트 적용 범위

```
Request (R1)
  └── Task (T1)
        └── Subtask (T1-S1) ← 게이트 적용 단위
              ┌───────────────────────────────────┐
              │  Mini TDD Loop                     │
              │                                    │
              │  Test First ──GATE-1──▶ Impl      │
              │      │                    │        │
              │      │         GATE-3, GATE-4     │
              │      │                    ▼        │
              │      │          Verification      │
              │      │                    │        │
              │      │               GATE-2       │
              │      │                    ▼        │
              │      └────────────── Complete     │
              └───────────────────────────────────┘
```

## 게이트 요약

| Gate | 적용 레벨 | 검증 시점 | 조건 | 위반 시 동작 |
|------|----------|----------|------|-------------|
| GATE-1 | Subtask | Implementation 진입 전 | Test Contract 존재 | Implementation 진입 차단 |
| GATE-2 | Subtask | Subtask Complete 전 | 테스트 실행 결과 존재 | Complete 선언 차단 |
| GATE-3 | Subtask | Implementation 완료 후 | 스코프 변경 없음 | Planning으로 복귀 |
| GATE-4 | Subtask | Implementation 완료 후 | 설계 불변 조건 유지 | Task Design으로 복귀 |

---

## GATE-1: Test Contract 필수

### 목적
테스트 없이 구현을 시작하는 것을 방지한다.

### 적용 레벨
**Subtask** - 각 Subtask의 Test First → Implementation 전환 시

### 검증 항목
```yaml
required:
  - contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml 존재
  - 최소 1개 이상의 test_cases 정의
  - 테스트 파일 경로 명시 (test_file_path)
  - 테스트 코드 생성 완료
```

### 위반 시
- Implementation 페이즈 진입 차단
- "Test First 페이즈로 복귀" 메시지 출력
- QA Engineer 에이전트 재호출

---

## GATE-2: 테스트 결과 필수

### 목적
테스트 실행 없이 완료 선언하는 것을 방지한다.

### 적용 레벨
**Subtask** - 각 Subtask의 Verification → Complete 전환 시

### 검증 항목
```yaml
required:
  - contracts/{requestId}/{taskId}/{subtaskId}/test-result.yaml 존재
  - 테스트 실행 명령 실행됨
  - result 필드가 pass 또는 fail
  - pass인 경우에만 Subtask Complete 허용
```

### 위반 시
- Subtask Complete 선언 차단
- fail인 경우: Implementation 또는 Task Design으로 복귀
- 미실행인 경우: Verification 페이즈 재실행

---

## GATE-3: 스코프 확장 금지

### 목적
요청 범위를 벗어난 구현을 방지한다.

### 적용 레벨
**Subtask** - Implementation 완료 후 Verification 진입 전

### 검증 항목
```yaml
compare:
  - Design Brief의 scope_in vs 실제 구현
  - Design Brief의 scope_out 항목이 구현되지 않았는지
  - 새로운 파일/클래스가 스코프 내인지
```

### 위반 사례
- scope_out에 명시된 기능 구현
- 요청하지 않은 리팩토링
- 불필요한 유틸리티 클래스 추가

### 위반 시
- Planning 페이즈로 즉시 복귀 (Request 레벨)
- 스코프 재정의 필요
- 확장된 부분 제거 또는 별도 작업으로 분리

---

## GATE-4: 설계 불변 조건 유지

### 목적
아키텍트가 정의한 설계 원칙 위반을 방지한다.

### 적용 레벨
**Subtask** - Implementation 완료 후 Verification 진입 전

### 검증 항목
```yaml
verify:
  - contracts/{requestId}/{taskId}/design-contract.yaml의 invariants 모두 충족
  - interfaces 계약 준수
  - boundaries 위반 없음
  - layer_assignments 준수 (DDD 레이어 규칙)
```

### 위반 사례
- 도메인 레이어에서 인프라 의존성 추가
- 인터페이스 시그니처 임의 변경
- 불변 조건에 명시된 규칙 무시

### 위반 시
- Task Design 페이즈로 즉시 복귀
- Architect 에이전트 재호출
- 설계 재검토 또는 불변 조건 수정

---

## 게이트 검증 순서

### Subtask 내 (Mini TDD Loop)

```
Test First 완료 후:
  1. GATE-1 검증 (Test Contract)
  2. 통과 시 → Implementation 진행

Implementation 완료 후:
  1. GATE-3 검증 (스코프)
  2. GATE-4 검증 (설계 불변)
  3. 통과 시 → Verification 진행

Verification 완료 후:
  1. GATE-2 검증 (테스트 결과)
  2. 통과 시 → Subtask Complete → 다음 Subtask
```

### 복귀 대상

| 게이트 | 위반 시 복귀 대상 |
|--------|------------------|
| GATE-1 | Test First (같은 Subtask) |
| GATE-2 (fail) | Implementation (같은 Subtask) 또는 Task Design |
| GATE-3 | Planning (Request 레벨) |
| GATE-4 | Task Design (같은 Task) |

---

## state.json의 게이트 상태

각 Subtask별로 게이트 통과 상태를 기록한다.

```json
{
  "tasks": {
    "T1": {
      "subtasks": {
        "T1-S1": {
          "phase": "verification",
          "gates": {
            "GATE-1": "passed",
            "GATE-2": "pending",
            "GATE-3": "passed",
            "GATE-4": "passed"
          }
        }
      }
    }
  }
}
```

게이트 상태:
- `pending`: 아직 검증 전
- `passed`: 통과
- `failed`: 실패 (복귀 필요)

---

## 관련 문서

- [phases.md](phases.md) - 페이즈 상세
- [error-recovery.md](error-recovery.md) - 에러 복구 전략
- [contracts.md](contracts.md) - Contract 형식
