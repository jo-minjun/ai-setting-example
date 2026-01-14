# 페이즈 상세

오케스트레이션 루프의 각 페이즈별 상세 절차.
3-tier 계층 구조 (Request → Task → Subtask)를 기반으로 한다.

---

## 3-tier 계층 모델

```
Request (요청) - R1
  ├── Task (작업) - T1
  │   ├── Subtask (하위작업) - T1-S1 → [Mini TDD 루프]
  │   ├── Subtask (하위작업) - T1-S2 → [Mini TDD 루프]
  │   └── Subtask (하위작업) - T1-S3 → [Mini TDD 루프]
  │
  └── Task (작업) - T2
      ├── Subtask - T2-S1 → [Mini TDD 루프]
      └── Subtask - T2-S2 → [Mini TDD 루프]
```

| 계층 | 식별자 | 역할 | TDD 적용 |
|------|--------|------|----------|
| **Request** | R1 | 사용자 원본 요청 | - |
| **Task** | T1, T2 | 논리적 작업 단위 | Design |
| **Subtask** | T1-S1 | TDD 루프 적용 단위 | Mini TDD Loop |

---

## 페이즈 흐름도

```
┌────────────────────────────────────────────────────┐
│            GLOBAL DISCOVERY (한 번만)              │
│  ┌─────────────────┐    ┌─────────────────┐       │
│  │  [Code Explore] │    │    [Planner]    │       │
│  │        │        │    │        │        │       │
│  │        ▼        │    │        ▼        │       │
│  │  explored.yaml  │    │ task-breakdown  │       │
│  └────────┬────────┘    └────────┬────────┘       │
│           └──────────┬───────────┘                │
│                      ▼                            │
│                  [Merge]                          │
│                      │                            │
│              design-brief (per Task)              │
└──────────────────────┬───────────────────────────┘
                       ▼
         ┌───────────────────────────────┐
         │  For each Task (순차)          │
         │  ┌─────────────────────────┐  │
         │  │ [Task Design]           │  │
         │  │ Architect → design-     │  │
         │  │ contract.yaml           │  │
         │  └───────────┬─────────────┘  │
         │              ▼                 │
         │  ┌─────────────────────────┐  │
         │  │ For each Subtask        │  │
         │  │  ┌───────────────────┐  │  │
         │  │  │ [Mini TDD Loop]   │  │  │
         │  │  │                   │  │  │
         │  │  │ Test First        │  │  │
         │  │  │      ↓            │  │  │
         │  │  │ Implementation    │  │  │
         │  │  │      ↓            │  │  │
         │  │  │ Verification      │  │  │
         │  │  │      │            │  │  │
         │  │  │   ┌──┴──┐         │  │  │
         │  │  │ 실패   성공        │  │  │
         │  │  │   ↓     ↓         │  │  │
         │  │  │ 재시도  다음 S     │  │  │
         │  │  └───────────────────┘  │  │
         │  └─────────────────────────┘  │
         │              ▼                 │
         │        Task Complete           │
         │         다음 Task              │
         └───────────────┬───────────────┘
                         ▼
                Request Complete
```

---

## 0. Global Discovery 페이즈 (Request 레벨)

### 개요
Code Explore와 Planner를 병렬로 실행하여 프로젝트 탐색과 Task 분해를 동시에 수행한다.
**한 번만** 실행되며, 이후 Task Loop로 진입한다.

### 구성 요소

#### 0a. Code Explore (Task A)

**담당 에이전트**: Code Explore

**입력**
- 프로젝트 경로
- 참고 프로젝트 경로 (선택)

**절차**
1. 디렉토리 구조 파악
2. CLAUDE.md, AGENTS.md 등 설정 파일 확인
3. 주요 소스 파일 요약

**출력**
`contracts/{requestId}/explored.yaml`

#### 0b. Planner (Task B)

**담당 에이전트**: Planner

**입력**
- 사용자 원본 요청
- 프로젝트 기본 정보 (경로, CLAUDE.md)

**절차**
1. 사용자 요청 분석
2. 코드 탐색 결과 없이 Task/Subtask로 분해
3. 불확실한 부분은 assumptions로 명시
4. task-breakdown 생성

**출력**
`contracts/{requestId}/task-breakdown.yaml`

**특이사항**
- 코드 구조를 모르므로 가정(assumptions)을 명시적으로 기록
- 파일 경로는 일반적인 컨벤션 기반 추정

### 병렬 실행 제약
- 두 에이전트 간 직접 통신 불가
- 각 Task는 독립적으로 실행
- 오케스트레이터가 두 Task 완료를 모두 대기

### 다음 페이즈
Merge

---

## 1. Merge 페이즈 (Request 레벨)

### 담당
오케스트레이터 (서브에이전트 아님)

### 입력
- `explored.yaml` (Code Explore 결과)
- `task-breakdown.yaml` (Planner 결과)

### 절차

1. **가정 검증**
   - task-breakdown의 assumptions를 explored.yaml로 검증
   - 각 가정이 맞는지/틀린지 판정

2. **Task별 Design Brief 생성**
   - task-breakdown의 각 Task에 대해 design-brief 생성
   - explored.yaml의 file_refs 정보 반영
   - scope_in, scope_out 구체화

3. **Subtask 순서 확정**
   - 각 Task 내 Subtask 실행 순서 결정
   - 의존성 반영

### 출력
각 Task별 `contracts/{requestId}/{taskId}/design-brief.yaml`

### 다음 페이즈
Task Loop (Task Design)

### 검증 실패 시
- 가정이 대부분 틀린 경우: Planner 재호출 (explored.yaml 주입, 순차 모드)
- 사소한 조정만 필요한 경우: 오케스트레이터가 직접 수정

---

## 2. Task Design 페이즈 (Task 레벨)

### 담당 에이전트
Architect

### 입력
- `contracts/{requestId}/{taskId}/design-brief.yaml`
- 프로젝트 아키텍처 패턴 (DDD 레이어 등)
- 기존 인터페이스/타입 정의

### 절차
1. Design Brief 검토
2. 설계 불변 조건 정의
3. 인터페이스 계약 작성
4. 의존성 경계 설정
5. 레이어 할당
6. Design Contract 생성

### 출력
`contracts/{requestId}/{taskId}/design-contract.yaml`

### 다음 페이즈
Subtask Loop (Mini TDD Loop)

### 실패 조건
- 기존 아키텍처와 충돌 → Design Brief 수정 필요 (Merge 복귀)

---

## 3. Mini TDD Loop (Subtask 레벨)

각 Subtask에 대해 Test First → Implementation → Verification을 순환한다.

### 3a. Test First 페이즈

#### 담당 에이전트
QA Engineer

#### 입력
- `contracts/{requestId}/{taskId}/design-contract.yaml`
- 프로젝트 테스트 프레임워크 (JUnit 5 등)
- 기존 테스트 패턴
- 현재 Subtask 정보 (state.json의 current_subtask)

#### 절차
1. Design Contract의 인터페이스별 테스트 케이스 설계
2. Given-When-Then 형식으로 명세
3. 카테고리 분류 (happy_path, error_case, edge_case)
4. 테스트 코드 작성 (Red 상태 - 컴파일만 되고 실패)
5. Test Contract 생성

#### 출력
- `contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml`
- 테스트 코드 파일

#### 다음 페이즈
Implementation (GATE-1 통과 필수)

#### 게이트 검증
**GATE-1**: Test Contract와 테스트 코드가 존재해야 함

---

### 3b. Implementation 페이즈

#### 담당 에이전트
Implementer

#### 입력
- `contracts/{requestId}/{taskId}/design-contract.yaml` (불변 조건)
- `contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml` (통과해야 할 테스트)
- 테스트 코드 (전문)

#### 절차
1. 테스트 코드 분석
2. 테스트 통과를 위한 최소 구현
3. 설계 불변 조건 준수 확인
4. 스코프 확장 금지 (scope_out 구현 금지)
5. 빌드 성공 확인

#### 출력
구현 코드

#### 다음 페이즈
Verification

#### 게이트 검증 (Verification 전)
- **GATE-3**: 스코프 변경 없음
- **GATE-4**: 설계 불변 조건 유지

#### 주의사항
- 테스트가 요구하지 않는 기능 추가 금지
- 불필요한 추상화 금지
- 설계 위반 발견 시 즉시 중단하고 보고

---

### 3c. Verification 페이즈

#### 담당 에이전트
QA Engineer

#### 입력
- 구현된 코드
- `contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml`
- 테스트 실행 명령

#### 절차
1. 테스트 실행 (`./gradlew test`)
2. 결과 수집
3. 실패 시 원인 분석 및 분류
4. Test Result 생성
5. 다음 action 결정

#### 출력
`contracts/{requestId}/{taskId}/{subtaskId}/test-result.yaml`

#### 다음 페이즈 결정

| 결과 | action | 다음 |
|------|--------|------|
| 모든 테스트 통과 | complete | 다음 Subtask 또는 Task Complete |
| 구현 오류 | retry_implementation | Implementation 재시도 |
| 설계 위반 | retry_design | Task Design 복귀 |

#### 게이트 검증
**GATE-2**: 테스트 실행 결과가 존재해야 함

---

## 4. Task Complete (Task 레벨)

### 조건
- 해당 Task의 **모든 Subtask 완료**
- 각 Subtask의 test-result.yaml이 "complete" 상태

### 절차
1. Task 상태를 "completed"로 변경
2. 다음 Task가 있으면 Task Design으로 진행
3. 모든 Task 완료 시 Request Complete로 진행

---

## 5. Request Complete

### 조건
- **모든 Task 완료**
- 각 Task의 모든 Subtask 테스트 통과

### 절차
1. Request 상태를 "completed"로 변경
2. 최종 상태 출력
3. 작업 완료 선언
4. (선택) Doc Writer 에이전트 호출하여 문서화

### 출력
작업 완료 리포트

---

## 페이즈 전환 요약

### Request 레벨

| 현재 페이즈 | 성공 시 | 실패 시 |
|------------|--------|--------|
| Global Discovery | → Merge | 재시도 |
| Merge | → Task Loop | → Planner 재호출 |
| Request Complete | 종료 | - |

### Task 레벨

| 현재 페이즈 | 성공 시 | 실패 시 |
|------------|--------|--------|
| Task Design | → Subtask Loop | → Merge |
| Task Complete | → 다음 Task 또는 Request Complete | - |

### Subtask 레벨 (Mini TDD Loop)

| 현재 페이즈 | 성공 시 | 실패 시 |
|------------|--------|--------|
| Test First | → Implementation | - |
| Implementation | → Verification | → Merge (GATE-3) 또는 → Task Design (GATE-4) |
| Verification | → 다음 Subtask 또는 Task Complete | → Implementation 또는 → Task Design |

---

## 관련 문서

- [gate-rules.md](gate-rules.md) - 게이트 검증 규칙
- [contracts.md](contracts.md) - Contract 형식
- [storage.md](storage.md) - 저장소 구조
