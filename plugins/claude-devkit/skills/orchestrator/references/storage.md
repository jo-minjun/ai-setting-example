# 파일 저장소 구조 명세

오케스트레이터는 세션 상태와 Contract를 파일 시스템에 저장한다.
claude-mem은 자동 캡처된 컨텍스트 검색에만 사용한다.

---

## 스키마 준수 원칙 (필수)

**중요**: 아래 파일들은 반드시 이 문서에 정의된 스키마 구조만 사용해야 한다.

- session.json, state.json, knowledge.yaml
- 모든 Contract YAML 파일 (explored.yaml, task-breakdown.yaml, design-*.yaml, test-*.yaml)

**금지 사항**:
- 문서에 정의되지 않은 필드 추가 금지
- 정의된 필드의 타입/구조 변경 금지
- 임의의 최상위 객체 생성 금지

**위반 시**: 파일 검증 실패로 처리하고 재생성 요청

---

## 저장소 위치

```
{project_root}/.claude/orchestrator/
├── sessions/
│   └── {projectHash}/
│       ├── session.json
│       ├── state.json                          # 3-tier 상태 (version: 2)
│       └── contracts/
│           └── {requestId}/                    # Request 레벨
│               ├── explored.yaml
│               ├── task-breakdown.yaml         # Task/Subtask 분해
│               │
│               └── {taskId}/                   # Task 레벨
│                   ├── design-brief.yaml
│                   ├── design-contract.yaml
│                   │
│                   └── {subtaskId}/            # Subtask 레벨
│                       ├── test-contract.yaml
│                       └── test-result.yaml
└── knowledge/
    └── {projectHash}/
        └── knowledge.yaml
```

**예시 경로:**
```
contracts/R1/explored.yaml                      # Request 레벨
contracts/R1/task-breakdown.yaml
contracts/R1/T1/design-brief.yaml               # Task 레벨
contracts/R1/T1/design-contract.yaml
contracts/R1/T1/T1-S1/test-contract.yaml        # Subtask 레벨
contracts/R1/T1/T1-S1/test-result.yaml
```

---

## 경로 규칙

### projectHash
프로젝트 루트 경로의 해시값 (충돌 방지용)

```
{projectHash} = md5(project_root)[:8]

예시:
/Users/dev/my-app → a1b2c3d4
```

### requestId
요청 식별자

```
R1, R2, R3, ...
```

### taskId
작업 식별자

```
T1, T2, T3, ...
```

### subtaskId
하위작업 식별자 (Task ID + Subtask 순번)

```
T1-S1, T1-S2, T2-S1, ...
```

---

## 파일 스키마

### session.json

세션 메타데이터

```json
{
  "version": 1,
  "project": {
    "path": "/absolute/path/to/project",
    "name": "my-project",
    "hash": "a1b2c3d4"
  },
  "status": "active",
  "current_task": "T1",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "manifest": {
    "claude_md": "/absolute/path/CLAUDE.md",
    "agents_md": null
  }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| version | number | 스키마 버전 |
| project.path | string | 프로젝트 절대 경로 |
| project.name | string | 프로젝트 이름 |
| project.hash | string | 프로젝트 해시 |
| status | string | active, completed, stopped |
| current_task | string | 현재 진행 중인 작업 ID |
| created_at | string | 세션 생성 시각 (ISO 8601) |
| updated_at | string | 마지막 업데이트 시각 |
| manifest.claude_md | string/null | CLAUDE.md 경로 |
| manifest.agents_md | string/null | AGENTS.md 경로 |

---

### state.json

작업 상태 (3-tier 계층 구조)

```json
{
  "version": 2,
  "request": {
    "id": "R1",
    "original_request": "XX컨트롤러 구현해줘",
    "status": "active",
    "current_task": "T1",
    "global_phase": "task_loop"
  },
  "tasks": {
    "T1": {
      "name": "a API 구현",
      "status": "in_progress",
      "current_subtask": "T1-S2",
      "subtasks": {
        "T1-S1": {
          "name": "API 스펙 확인",
          "status": "completed",
          "phase": "complete",
          "gates": {
            "GATE-1": "passed",
            "GATE-2": "passed"
          }
        },
        "T1-S2": {
          "name": "테스트 작성",
          "status": "in_progress",
          "phase": "implementation",
          "gates": {
            "GATE-1": "passed",
            "GATE-2": "pending",
            "GATE-3": "pending",
            "GATE-4": "pending"
          }
        }
      },
      "subtask_order": ["T1-S1", "T1-S2", "T1-S3"],
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  },
  "task_order": ["T1", "T2"]
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| version | number | 스키마 버전 (2) |
| request.id | string | 요청 ID (R1, R2, ...) |
| request.original_request | string | 원본 사용자 요청 |
| request.status | string | active, completed, stopped |
| request.current_task | string | 현재 진행 중인 Task ID |
| request.global_phase | string | 전역 페이즈 |
| tasks.{taskId}.name | string | 작업명 |
| tasks.{taskId}.status | string | pending, in_progress, completed |
| tasks.{taskId}.current_subtask | string | 현재 진행 중인 Subtask ID |
| tasks.{taskId}.subtasks | object | Subtask 상태들 |
| tasks.{taskId}.subtask_order | array | Subtask 순서 |
| task_order | array | Task 순서 |

**Global Phase (Request 레벨):**
- `global_discovery` - 병렬 탐색 중
- `task_loop` - Task 순회 중
- `complete` - 모든 Task 완료

**Subtask Phase (Subtask 레벨):**
- `test_first` - 테스트 작성 중
- `implementation` - 구현 중
- `verification` - 검증 중
- `complete` - Subtask 완료

**Gate 상태:**
- `pending` - 검증 전
- `passed` - 통과
- `failed` - 실패

---

### Contract YAML 파일

#### explored.yaml (Request 레벨)

Code Explore 에이전트 결과. 저장 경로: `contracts/{requestId}/explored.yaml`

```yaml
version: 1
request_id: R1
created_at: "2024-01-15T10:05:00Z"
created_by: code-explore

project_manifest:
  claude_md: "/path/to/CLAUDE.md"
  agents_md: null

explored_files:
  - path: "src/main/java/com/example/auth/AuthService.java"
    summary: "인증 서비스 인터페이스"
  - path: "src/main/java/com/example/user/User.java"
    summary: "사용자 엔티티"

directory_structure:
  src/main/java: "Java 소스 코드"
  src/test/java: "테스트 코드"
```

#### task-breakdown.yaml (Request 레벨, 신규)

Planner 에이전트 결과. 저장 경로: `contracts/{requestId}/task-breakdown.yaml`

```yaml
version: 1
request_id: R1
created_at: "2024-01-15T10:05:00Z"
created_by: planner

original_request: "XX컨트롤러 구현해줘"
objective: "XX 기능 전체 구현"

tasks:
  - id: T1
    name: "a API 구현"
    objective: "a 기능 API 엔드포인트 구현"
    subtasks:
      - id: T1-S1
        name: "API 스펙 확인"
        description: "요구사항 및 기존 API 패턴 분석"
      - id: T1-S2
        name: "테스트 작성"
        description: "단위 테스트 작성"
      - id: T1-S3
        name: "컨트롤러 구현"
        description: "엔드포인트 구현"

  - id: T2
    name: "b API 구현"
    objective: "b 기능 API 엔드포인트 구현"
    subtasks:
      - id: T2-S1
        name: "테스트 작성"
        description: "단위 테스트 작성"
      - id: T2-S2
        name: "컨트롤러 구현"
        description: "엔드포인트 구현"

assumptions:
  - "인증 관련 코드는 auth/ 디렉토리에 있을 것"
  - "Spring Security를 사용 중일 것"

task_order: ["T1", "T2"]
```

#### design-brief.yaml (Task 레벨)

Task별 설계 정의서. 저장 경로: `contracts/{requestId}/{taskId}/design-brief.yaml`

```yaml
version: 1
request_id: R1
task_id: T1
created_at: "2024-01-15T10:10:00Z"
created_by: orchestrator

task_name: "a API 구현"
objective: "a 기능 API 엔드포인트 구현"

subtasks:
  - id: T1-S1
    name: "API 스펙 확인"
  - id: T1-S2
    name: "테스트 작성"
  - id: T1-S3
    name: "컨트롤러 구현"

completion_criteria:
  - "API 엔드포인트 동작"
  - "테스트 통과"

scope_in:
  - "GET /api/a 엔드포인트"
  - "AController 클래스"

scope_out:
  - "인증 로직"

file_refs:
  - entity: "AController"
    path: "src/main/java/com/example/controller/AController.java"
    status: "to_create"
```

#### design-contract.yaml (Task 레벨)

Architect 에이전트 결과. 저장 경로: `contracts/{requestId}/{taskId}/design-contract.yaml`

```yaml
version: 1
request_id: R1
task_id: T1
created_at: "2024-01-15T10:15:00Z"
created_by: architect

task_name: "a API 구현"

invariants:
  - id: "INV-1"
    rule: "도메인 레이어는 인프라에 의존하지 않는다"
  - id: "INV-2"
    rule: "모든 비즈니스 로직은 Service를 통해 처리한다"

interfaces:
  - name: "AService.getData"
    input:
      type: "ARequest"
      fields:
        - name: "id"
          type: "string"
    output:
      type: "Result<AResponse, AError>"
    contract: "유효한 ID로 데이터 조회"

boundaries:
  - from: "AController"
    to: "AService"
    allowed: true
  - from: "AService"
    to: "ARepository"
    allowed: true
    note: "인터페이스만 의존"

layer_assignments:
  - component: "AController"
    layer: "presentation"
  - component: "AService"
    layer: "application"

file_refs:
  - entity: "AController"
    path: "src/main/java/com/example/controller/AController.java"
    status: "to_create"
```

#### test-contract.yaml (Subtask 레벨)

QA Engineer 에이전트 결과. 저장 경로: `contracts/{requestId}/{taskId}/{subtaskId}/test-contract.yaml`

```yaml
version: 1
request_id: R1
task_id: T1
subtask_id: T1-S2
created_at: "2024-01-15T10:30:00Z"
created_by: qa-engineer

subtask_name: "테스트 작성"

test_cases:
  - id: "TC-1"
    name: "유효한_ID로_데이터_조회_성공"
    target: "AService.getData"
    given: "존재하는 ID"
    when: "getData(ARequest) 호출"
    then: "AResponse 반환"
    category: "happy_path"

  - id: "TC-2"
    name: "존재하지_않는_ID로_조회_실패"
    target: "AService.getData"
    given: "존재하지 않는 ID"
    when: "getData(ARequest) 호출"
    then: "AError 반환"
    category: "error_case"

coverage_targets:
  - "AService.getData"
  - "AController.handleGet"

test_file_path: "src/test/java/com/example/service/AServiceTest.java"
```

#### test-result.yaml (Subtask 레벨)

QA Engineer 검증 결과. 저장 경로: `contracts/{requestId}/{taskId}/{subtaskId}/test-result.yaml`

```yaml
version: 1
request_id: R1
task_id: T1
subtask_id: T1-S2
created_at: "2024-01-15T11:00:00Z"
created_by: qa-engineer

execution:
  command: "./gradlew test"
  timestamp: "2024-01-15T11:00:00Z"
  result: "pass"

summary:
  total: 2
  passed: 2
  failed: 0
  skipped: 0

failed_tests: []

recommendation:
  action: "complete"
  reason: "모든 테스트 통과"
```

---

### knowledge.yaml

프로젝트 지식

```yaml
version: 1
project:
  path: "/absolute/path/to/project"
  name: "my-project"
  hash: "a1b2c3d4"

patterns:
  error_handling: "Result<T, E> 패턴 사용"
  naming:
    methods: "camelCase"
    classes: "PascalCase"
  testing: "JUnit 5 + Mockito"
  architecture: "레이어드 아키텍처"

decisions:
  - id: "D1"
    topic: "인증 방식"
    decision: "JWT + Refresh Token"
    rationale: "기존 시스템과 호환, 무상태 인증 필요"
    refs:
      - "src/main/java/com/example/auth/JwtTokenProvider.java"
    created_at: "2024-01-15"

pitfalls:
  - id: "P1"
    description: "이 프로젝트는 Lombok 사용하지 않음"
    reason: "팀 정책 - 명시적 코드 선호"
    learned_from: "T3"
  - id: "P2"
    description: "@Transactional은 public 메서드에만 적용"
    reason: "Spring AOP 프록시 제한"

updated_at: "2024-01-15T12:00:00Z"
```

---

## 파일 vs claude-mem 역할 분리

| 데이터 | 저장소 | 조회 방법 | 용도 |
|--------|--------|----------|------|
| 세션 상태 | 파일 (session.json) | Read | 세션 존재 확인, 재개 |
| 작업 상태 | 파일 (state.json) | Read | 페이즈/게이트 확인 |
| Contract | 파일 (*.yaml) | Read | 에이전트 간 데이터 전달 |
| 프로젝트 지식 | 파일 (knowledge.yaml) | Read | 에이전트 컨텍스트 주입 |
| 코드 탐색 이력 | claude-mem | search | 과거 탐색 결과 참조 |
| 실행 맥락 | claude-mem | search | "왜 이렇게 결정했는지" |
| 자연어 검색 | claude-mem | search | 관련 정보 찾기 |

---

## 관련 문서

- [session.md](session.md) - 세션 관리 로직
- [contracts.md](contracts.md) - Contract 형식 상세
- [knowledge.md](knowledge.md) - 지식 관리
- [context-injection.md](context-injection.md) - 컨텍스트 조회 방법
