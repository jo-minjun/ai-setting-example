# 컨텍스트 주입 가이드

각 에이전트 호출 시 필요한 컨텍스트를 조회하여 주입하는 방법을 정의한다.
3-tier 계층 구조 (Request → Task → Subtask)를 기반으로 한다.
Primary는 파일 조회, Secondary는 claude-mem 검색이다.

---

## 조회 방법

### 파일 조회 (Primary)

세션 상태, Contract, 지식은 파일에서 조회한다.

```
경로 패턴:
  .claude/orchestrator/sessions/{hash}/session.json
  .claude/orchestrator/sessions/{hash}/state.json
  .claude/orchestrator/sessions/{hash}/contracts/{requestId}/explored.yaml          # Request 레벨
  .claude/orchestrator/sessions/{hash}/contracts/{requestId}/task-breakdown.yaml    # Request 레벨
  .claude/orchestrator/sessions/{hash}/contracts/{requestId}/{taskId}/*.yaml        # Task 레벨
  .claude/orchestrator/sessions/{hash}/contracts/{requestId}/{taskId}/{subtaskId}/*.yaml  # Subtask 레벨
  .claude/orchestrator/knowledge/{hash}/knowledge.yaml
```

### claude-mem 검색 (Secondary)

과거 맥락, 실행 이력은 claude-mem에서 검색한다.

```
search: "{project_name} {keyword}"
```

---

## 에이전트별 컨텍스트 조회

### Code Explore (Request 레벨)

| 컨텍스트 | 조회 방법 | 비고 |
|----------|----------|------|
| 프로젝트 경로 | 오케스트레이터 제공 | |
| 참고 프로젝트 | 사용자 입력 (선택) | |

**최소 컨텍스트로 시작** - 탐색 결과를 생성하는 역할

**출력 경로:** `contracts/{requestId}/explored.yaml`

---

### Planner (Global Discovery용, Request 레벨)

| 컨텍스트 | 조회 방법 | 비고 |
|----------|----------|------|
| 프로젝트 경로 | 오케스트레이터 제공 | |
| CLAUDE.md 내용 | Read manifest.claude_md | session.json에서 경로 확인 |
| 사용자 원본 요청 | 오케스트레이터 제공 | |

**explored_files 미주입** - 병렬 실행이므로 탐색 결과 없이 시작

**출력 경로:** `contracts/{requestId}/task-breakdown.yaml`

---

### Architect (Task 레벨)

| 컨텍스트 | 조회 방법 |
|----------|----------|
| Design Brief | `Read: contracts/{requestId}/{taskId}/design-brief.yaml` |
| 프로젝트 패턴 | `Read: knowledge/{hash}/knowledge.yaml` → patterns |
| 이전 설계 결정 | `Read: knowledge/{hash}/knowledge.yaml` → decisions |
| (보조) 과거 맥락 | `search: "{project_name} 설계 결정"` |

**출력 경로:** `contracts/{requestId}/{taskId}/design-contract.yaml`

---

### QA Engineer (Test First, Subtask 레벨)

| 컨텍스트 | 조회 방법 |
|----------|----------|
| Design Contract | `Read: contracts/{requestId}/{taskId}/design-contract.yaml` |
| 현재 Subtask 정보 | `Read: state.json` → `current_subtask` |

**출력 경로:** `contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml`

---

### Implementer (Subtask 레벨)

| 컨텍스트 | 조회 방법 |
|----------|----------|
| Design Contract | `Read: contracts/{requestId}/{taskId}/design-contract.yaml` |
| Test Contract | `Read: contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml` |
| 주의사항 | `Read: knowledge/{hash}/knowledge.yaml` → pitfalls |
| 테스트 코드 | `Read: {test_file_path}` (test-contract.yaml에서 경로 확인) |
| 현재 Subtask 정보 | `Read: state.json` → `current_subtask` |

---

### QA Engineer (Verification, Subtask 레벨)

| 컨텍스트 | 조회 방법 |
|----------|----------|
| Test Contract | `Read: contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml` |
| Design Contract (불변 조건) | `Read: contracts/{requestId}/{taskId}/design-contract.yaml` → invariants |
| 현재 Subtask 정보 | `Read: state.json` → `current_subtask` |

**출력 경로:** `contracts/{requestId}/{taskId}/{subtaskId}/test-result.yaml`

---

## 컨텍스트 주입 흐름

```
┌──────────────────────────────────────────────────────────────────┐
│  파일 저장소                                                      │
│  .claude/orchestrator/sessions/{hash}/                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────┐     ┌─────────────────────┐                 │
│  │  [Code Explore] │     │     [Planner]        │   ◀── 병렬 실행 │
│  │       │         │     │         │            │   (Request 레벨)│
│  │       ▼         │     │         ▼            │                 │
│  │ contracts/R1/   │     │ contracts/R1/        │                 │
│  │ explored.yaml   │     │ task-breakdown.yaml  │                 │
│  └────────┬────────┘     └──────────┬───────────┘                 │
│           │                         │                             │
│           └────────────┬────────────┘                             │
│                        ▼                                          │
│              ┌─────────────────┐                                  │
│              │     [Merge]     │  ◀── 오케스트레이터 직접 수행   │
│              │ Read explored + │      (Request 레벨)              │
│              │ task-breakdown  │                                  │
│              │        │        │                                  │
│              │        ▼        │                                  │
│              │ contracts/R1/   │                                  │
│              │ T1/design-brief │                                  │
│              │ .yaml (Task별)  │                                  │
│              └────────┬────────┘                                  │
│                       │                                           │
│         ┌─────────────┴─────────────┐                             │
│         │   For each Task (순차)     │                            │
│         │                            │                            │
│         │  Read R1/T1/design-brief   │                            │
│         │            ▼               │                            │
│         │  [Architect] ─▶ R1/T1/     │  (Task 레벨)               │
│         │              design-       │                            │
│         │              contract.yaml │                            │
│         │            │               │                            │
│         │  ┌─────────┴──────────┐    │                            │
│         │  │ For each Subtask   │    │                            │
│         │  │                    │    │                            │
│         │  │ [QA: Test First]   │    │  (Subtask 레벨)            │
│         │  │   Read R1/T1/      │    │                            │
│         │  │   design-contract  │    │                            │
│         │  │         ▼          │    │                            │
│         │  │   R1/T1/T1-S1/     │    │                            │
│         │  │   test-contract    │    │                            │
│         │  │         │          │    │                            │
│         │  │ [Implementer]      │    │                            │
│         │  │   Read design +    │    │                            │
│         │  │   test contract    │    │                            │
│         │  │         │          │    │                            │
│         │  │ [QA: Verification] │    │                            │
│         │  │   Read test-       │    │                            │
│         │  │   contract         │    │                            │
│         │  │         ▼          │    │                            │
│         │  │   R1/T1/T1-S1/     │    │                            │
│         │  │   test-result      │    │                            │
│         │  └────────────────────┘    │                            │
│         └────────────────────────────┘                            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Merge 로직 (오케스트레이터 직접 수행)

병렬 실행된 Code Explore와 Planner 결과를 병합하여 각 Task별 design_brief 생성.

### 입력 조회

```
Read: contracts/{requestId}/explored.yaml
Read: contracts/{requestId}/task-breakdown.yaml
```

### 병합 알고리즘

```
1. assumptions 검증:
   for each assumption in task_breakdown.assumptions:
     - explored.explored_files에서 관련 파일 검색
     - 일치/불일치 판정
     - 불일치 시 correction 기록

2. Task별 design-brief 생성:
   for each task in task_breakdown.tasks:
     - explored.explored_files에서 관련 파일 추출
     - scope_in, scope_out 구체화
     - subtask_order 확정
     - file_refs 채우기

     결과 저장:
     Write: contracts/{requestId}/{taskId}/design-brief.yaml

3. state.json 초기화:
   - tasks 객체에 각 Task/Subtask 상태 추가
   - task_order 설정
   - current_task = task_order[0]
```

### 재실행 조건

- assumptions 중 50% 이상 불일치 → Planner 재호출 (explored 주입, 순차 모드)
- 사소한 불일치 → 오케스트레이터가 직접 조정

---

## 프롬프트 주입 방식

오케스트레이터가 에이전트 호출 시:

### Task 레벨 (Architect)
```
1. 파일에서 Contract 읽기
   content = Read(contracts/{requestId}/{taskId}/design-brief.yaml)

2. 프롬프트 템플릿에 주입
   prompt = template
     .replace("{{request_id}}", requestId)
     .replace("{{task_id}}", taskId)
     .replace("{{design_brief}}", content)

3. 에이전트 호출
   Task(prompt, subagent_type="architect")

4. 결과를 파일로 저장
   Write(contracts/{requestId}/{taskId}/design-contract.yaml, result)
```

### Subtask 레벨 (QA, Implementer)
```
1. 파일에서 Contract 읽기
   design_contract = Read(contracts/{requestId}/{taskId}/design-contract.yaml)
   test_contract = Read(contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml)

2. 프롬프트 템플릿에 주입
   prompt = template
     .replace("{{request_id}}", requestId)
     .replace("{{task_id}}", taskId)
     .replace("{{subtask_id}}", subtaskId)
     .replace("{{design_contract}}", design_contract)
     .replace("{{test_contract}}", test_contract)

3. 에이전트 호출
   Task(prompt, subagent_type="implementer")

4. 결과를 파일로 저장 또는 상태 업데이트
```

에이전트는 파일 경로를 알 필요 없이 **컨텍스트만 받으면 됨**

---

## claude-mem 검색 트리거 조건

오케스트레이터가 에이전트 호출 **전**에 다음 조건을 확인하고 검색을 수행한다.

### 트리거 조건표

| 에이전트 | 트리거 조건 | 검색 쿼리 |
|----------|------------|----------|
| Architect | 첫 세션 (이전 완료된 세션 없음) | `"{project_name} 설계 결정"` |
| Architect | 동일 도메인 Task가 이전 세션에 있음 | `"{project_name} {domain} 설계"` |
| Implementer | 동일 Subtask 재시도 (retry_count > 0) | `"{project_name} {subtask} 실패"` |
| Implementer | 이전 세션에서 같은 파일 수정 이력 | `"{project_name} {file} 수정"` |
| QA Engineer | 테스트 2회 이상 실패 | `"{project_name} 테스트 실패 패턴"` |

### 검색 수행 로직

```
에이전트 호출 전:
1. 트리거 조건 확인
   - state.json에서 retry_count 확인
   - 이전 세션 존재 여부 확인

2. 조건 충족 시 claude-mem search 실행
   - 검색 결과를 mem_context 변수에 저장

3. 프롬프트 템플릿에 주입
   - {{mem_context}} 변수 치환

4. 에이전트 호출
```

### Fallback 처리

claude-mem 미설치 또는 검색 실패 시:

```
[Warning] claude-mem 검색 불가: {이유}
파일 기반 지식(knowledge.yaml)만 사용하여 계속 진행합니다.
```

- MCP 도구 호출 실패 → 경고 메시지 출력 후 계속 진행
- 검색 결과 없음 → mem_context를 빈 값으로 설정
- 정상 동작에는 영향 없음 (claude-mem은 보조 역할)

---

## 관련 문서

- [storage.md](storage.md) - 파일 저장소 구조
- [agent-prompts.md](agent-prompts.md) - 프롬프트 템플릿
- [session.md](session.md) - 세션 관리
