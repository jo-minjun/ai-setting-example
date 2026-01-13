# 세션 컨텍스트 관리

오케스트레이터는 세션 디렉터리를 통해 작업 진행 상태와 Contract를 관리한다.

## 세션 디렉터리 구조

```
~/.claude/claude-devkit/sessions/{projectName}-{projectDirectoryHash}-{datetime}/
├── state.yaml           # 현재 상태 (자주 갱신)
├── timeline.jsonl       # 이벤트 로그 (append only)
├── contracts/           # Contract 파일들
│   ├── T1.preliminary-design-brief.yaml
│   ├── T1.design-brief.yaml
│   ├── T1.design-contract.yaml
│   ├── T1.test-contract.yaml
│   ├── T1.test-result.yaml
│   └── ...
└── explored/            # 탐색 결과 캐시
    └── files.yaml
```

### 디렉터리 이름 규칙

| 요소 | 설명 | 예시 |
|------|------|------|
| projectName | 프로젝트 디렉터리 이름 | `my-project` |
| projectDirectoryHash | 프로젝트 경로의 SHA-256 해시 앞 6자리 | `a1b2c3` |
| datetime | 세션 생성 시간 (분까지) | `20240115T1030` |

**projectDirectoryHash 생성:**
```bash
echo -n "/Users/minjun/my-project" | sha256sum | cut -c1-6
# 결과: a1b2c3
```

**예시:**
```
~/.claude/claude-devkit/sessions/
├── my-project-a1b2c3-20240115T1000/
├── my-project-a1b2c3-20240118T1400/
└── api-server-d4e5f6-20240116T0900/
```

### 세션 정책

| 명령 | 동작 |
|------|------|
| `/orchestrator` | 항상 새 세션 생성 |
| `/orchestrator resume` | 기존 세션 목록에서 선택 |

- 프로젝트 지식은 별도 관리: `~/.claude/claude-devkit/knowledge/`

---

## 태스크 ID 규칙

| 유형 | 형식 | 예시 |
|------|------|------|
| 작업 (Task) | `Tn` | T1, T2, T3 |
| 하위 작업 (Subtask) | `STn` | ST1, ST2, ST3 |

---

## state.yaml

현재 상태만 저장. 자주 갱신되는 파일.

```yaml
version: 1
project_path: /Users/.../my-project
reference_path: null
created_at: 2024-01-15T10:00:00
updated_at: 2024-01-15T14:30:00

# 현재 진행 상태
current:
  task: T2
  subtask: ST3
  phase: implementation

# 작업 목록
tasks:
  - id: T1
    name: Repository 인터페이스 생성
    status: completed
    subtasks:
      - id: ST1
        name: Store Repository 생성
        status: completed
      - id: ST2
        name: Customer Repository 생성
        status: completed

  - id: T2
    name: Service 레이어 구현
    status: in_progress
    subtasks:
      - id: ST1
        name: StoreService 구현
        status: completed
      - id: ST2
        name: CustomerService 구현
        status: completed
      - id: ST3
        name: Service 통합 테스트
        status: in_progress

  - id: T3
    name: Controller 구현
    status: pending
    subtasks: []

# Contract 파일 참조
contracts:
  T1:
    design_brief: contracts/T1.design-brief.yaml
    design_contract: contracts/T1.design-contract.yaml
    test_contract: contracts/T1.test-contract.yaml
    test_result: contracts/T1.test-result.yaml
  T2:
    design_brief: contracts/T2.design-brief.yaml
    design_contract: null
    test_contract: null
    test_result: null

# 프로젝트 매니페스트 참조 (복수 가능)
manifest:
  - /Users/.../my-project/CLAUDE.md
  - /Users/.../my-project/docs/AGENTS.md

# 게이트 상태
gates:
  GATE-1: pending
  GATE-2: pending
  GATE-3: pending
  GATE-4: pending

# 병렬 탐색 상태
parallel_discovery:
  status: completed
  code_explore:
    status: completed
    completed_at: 2024-01-15T10:01:30
  planner:
    status: completed
    completed_at: 2024-01-15T10:02:00
```

### 고정 값 (Enum)

**phase:**
- `parallel_discovery`
- `merge`
- `design`
- `test_first`
- `implementation`
- `verification`
- `complete`

**task/subtask status:**
- `pending`
- `in_progress`
- `completed`

**gate status:**
- `pending`
- `passed`
- `failed`

**parallel_discovery status:**
- `pending`
- `running`
- `completed`

---

## explored/files.yaml

Code Explore 에이전트가 탐색한 파일 캐시.

```yaml
version: 1
explored_at: 2024-01-15T10:01:30

files:
  - path: src/main/java/com/example/store/Store.java
    summary: "상점 엔티티. 필드: id, name, address. 메서드: create, update"
    line_count: 45

  - path: src/main/java/com/example/customer/Customer.java
    summary: "고객 엔티티. 필드: id, email, name. Store FK 참조"
    line_count: 38

  - path: src/main/java/com/example/store/StoreRepository.java
    summary: "Store JPA Repository 인터페이스"
    line_count: 12

structure:
  src/main/java/com/example:
    - store/
    - customer/
    - common/
  src/test/java/com/example:
    - store/
    - customer/
```

---

## 세션 라이프사이클

### 1. 새 세션 생성 (`/orchestrator`)

```
동작:
  1. 디렉터리 생성: {projectName}-{projectDirectoryHash}-{datetime}
  2. state.yaml 초기화
  3. current.phase = "parallel_discovery"
  4. timeline.jsonl에 session_start 기록
```

### 1-1. 세션 재개 (`/orchestrator resume`)

```
동작:
  1. 현재 프로젝트의 이전 세션 목록 표시
  2. 사용자가 세션 선택
  3. 선택한 세션의 state.yaml 로드
  4. 중단된 phase부터 재개
```

```
/orchestrator resume

┌─────────────────────────────────────────────────────────┐
│ 이전 세션 목록 (my-project)                             │
├─────────────────────────────────────────────────────────┤
│ [1] 20240115T1400 - T2 Service (implementation) 🔄      │
│ [2] 20240115T1000 - T1 Repository (complete) ✅         │
│ [3] 20240114T0900 - T3 Controller (test_first) ⏳       │
│                                                         │
│ 번호를 선택하세요:                                      │
└─────────────────────────────────────────────────────────┘
```

### 2. 페이즈 전환

```
동작:
  1. state.yaml의 current.phase 업데이트
  2. timeline.jsonl에 phase_enter/phase_exit 기록
  3. 해당 Contract 파일 생성 (contracts/ 디렉터리)
  4. state.yaml의 contracts 참조 업데이트
```

### 3. 작업 완료

```
동작:
  1. 현재 작업 status: completed
  2. 다음 작업 status: in_progress
  3. timeline.jsonl에 task_complete 기록
  4. current.task 업데이트
```

### 4. 세션 종료

```
조건:
  - 모든 작업 완료
  - 사용자 명시적 종료 (/orchestrator stop)
  - 24시간 비활성

동작:
  1. timeline.jsonl에 session_end 기록
  2. 세션 디렉터리 유지 (분석용)
```

---

## 명령어

| 명령 | 설명 |
|------|------|
| `/orchestrator status` | 현재 세션 상태 출력 |
| `/orchestrator resume` | 중단된 세션 재개 |
| `/orchestrator reset` | 세션 초기화 |
| `/orchestrator stop` | 세션 종료 |

---

## 관련 문서

- [timeline.md](timeline.md) - 타임라인 이벤트 스키마
- [contracts.md](contracts.md) - Contract 파일 형식
- [knowledge.md](knowledge.md) - 프로젝트 지식 관리
- [agent-contexts.md](agent-contexts.md) - 에이전트별 컨텍스트 주입