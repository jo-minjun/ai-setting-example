# 프로젝트 지식 관리 (파일 기반)

프로젝트별 학습 내용은 **파일 시스템**에 저장하고, claude-mem은 보조적인 컨텍스트 검색에 사용한다.

---

## 저장소

```
{project_root}/.claude/orchestrator/knowledge/{project-hash}/
└── knowledge.yaml
```

상세: [storage.md](storage.md)

---

## knowledge.yaml 스키마

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

  - id: "D2"
    topic: "데이터베이스"
    decision: "PostgreSQL"
    rationale: "JSON 지원, 기존 인프라 활용"
    refs:
      - "docker-compose.yml"
    created_at: "2024-01-20"

pitfalls:
  - id: "P1"
    description: "이 프로젝트는 Lombok 사용하지 않음"
    reason: "팀 정책 - 명시적 코드 선호"
    learned_from: "T3"

  - id: "P2"
    description: "@Transactional은 public 메서드에만 적용"
    reason: "Spring AOP 프록시 제한"
    learned_from: "T5"

updated_at: "2024-01-20T12:00:00Z"
```

---

## 지식 유형

### patterns (코딩 패턴)

프로젝트에서 사용하는 코딩 패턴과 규칙.

| 키 | 설명 | 예시 |
|----|------|------|
| error_handling | 에러 처리 방식 | Result<T, E> 패턴 |
| naming.methods | 메서드 명명 규칙 | camelCase |
| naming.classes | 클래스 명명 규칙 | PascalCase |
| testing | 테스트 프레임워크 | JUnit 5 + Mockito |
| architecture | 아키텍처 스타일 | 레이어드 아키텍처 |

### decisions (설계 결정)

과거 설계 결정 기록.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 결정 ID (D1, D2, ...) |
| topic | string | 결정 주제 |
| decision | string | 선택한 결정 |
| rationale | string | 선택 이유 |
| refs | array | 관련 파일 참조 |
| created_at | string | 결정 일자 |

### pitfalls (주의사항)

피해야 할 것들.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 주의사항 ID (P1, P2, ...) |
| description | string | 주의사항 설명 |
| reason | string | 이유 |
| learned_from | string | 학습 출처 (작업 ID) |

---

## 지식 조회

### 파일에서 조회 (Primary)

```
Read: .claude/orchestrator/knowledge/{hash}/knowledge.yaml

→ patterns, decisions, pitfalls 모두 포함
```

### claude-mem 검색 (Secondary)

파일에 없는 과거 맥락이 필요할 때:

```
search: "{project_name} 코딩 패턴"
search: "{project_name} 설계 결정 이유"
search: "{project_name} 주의사항"
```

---

## 자동 지식 축적

오케스트레이터는 세션 진행 중 자동으로 knowledge.yaml을 업데이트한다.

### Task 완료 시 (실시간)

각 Task가 완료될 때 자동으로 knowledge.yaml을 업데이트:

```
Task 완료 시:
  1. design-contract.yaml 분석
     - 새로운 설계 결정 → decisions에 추가
     - 아키텍처 패턴 → patterns에 추가

  2. knowledge.yaml 업데이트
     - 중복 제거 (같은 topic의 결정은 최신 것으로 대체)
     - updated_at 갱신
```

### Subtask 재시도 후 성공 시

실패 후 성공한 케이스에서 pitfall 학습:

```
Subtask 재시도 성공 시:
  1. 이전 실패한 test-result.yaml 분석
  2. 실패 원인 추출
  3. pitfalls에 추가:
     - description: 실패 원인
     - reason: 해결 방법
     - learned_from: {subtaskId}
```

### 세션 종료 시 (일괄)

세션이 완료되면 전체 Contract를 분석하여 누락된 지식 추가:

```
세션 종료 시:
  1. 모든 design-contract.yaml 스캔
     - decisions 병합 (중복 제거)
  2. 모든 test-result.yaml 스캔
     - 실패 패턴 분석 → pitfalls 추가
  3. 기존 knowledge.yaml과 병합
  4. 저장
```

---

## /orchestrator learn

지식 축적을 **수동으로** 실행하는 명령어. 이전 세션의 Contract와 실패 기록을 분석하여 지식으로 변환한다.

### 동작

```
/orchestrator learn
    │
    ├─ 1. 이전 Contract 분석
    │     ├─ contracts/ 디렉토리에서 이전 design-contract 읽기
    │     ├─ 반복되는 패턴 추출 → patterns에 추가
    │     └─ 설계 결정 추출 → decisions에 추가
    │
    ├─ 2. 실패 기록 분석
    │     ├─ test-result.yaml 파일들에서 실패 케이스 읽기
    │     ├─ 실패 원인 패턴 추출 → pitfalls에 추가
    │     └─ 자연어 요약 저장
    │
    └─ 3. knowledge.yaml 업데이트
          ├─ 새로운 patterns 병합
          ├─ 새로운 decisions 추가
          ├─ 새로운 pitfalls 추가
          └─ updated_at 갱신
```

### 출력 예시

```
/orchestrator learn 실행 결과:

[Contract 분석]
- 분석 대상: 5개 세션
- 새로운 패턴: 2개 추출
  - error_handling: Result 패턴 사용
  - architecture: 레이어드 아키텍처

[실패 기록 분석]
- 실패 케이스: 3건
- 새로운 pitfall: 1개 추가
  - P4: async 함수에서 try-catch 누락

지식 저장 완료: .claude/orchestrator/knowledge/{hash}/knowledge.yaml
```

---

## 에이전트별 지식 주입

### Architect

```
knowledge_context:
  patterns: Read knowledge.yaml → patterns
  decisions: Read knowledge.yaml → decisions (최근 5개)
  (보조) claude-mem search "{project_name} 설계 결정"
```

### Implementer

```
knowledge_context:
  patterns: Read knowledge.yaml → patterns
  pitfalls: Read knowledge.yaml → pitfalls
  (보조) claude-mem search "{project_name} 주의사항"
```

### Pitfall 경고

에이전트가 pitfall과 관련된 행동을 하려 할 때 경고:

```
[Knowledge Warning]
P1: 이 프로젝트는 Lombok 사용하지 않음
이유: 팀 정책 - 명시적 코드 선호
```

---

## 지식 파일 생성 시점

knowledge.yaml 파일이 없는 경우:

1. **첫 세션 시작 시**: 빈 스키마로 생성
2. **/orchestrator learn 실행 시**: 분석 결과로 채움
3. **수동 생성**: 사용자가 직접 작성

### 초기 knowledge.yaml

```yaml
version: 1
project:
  path: "/absolute/path/to/project"
  name: "my-project"
  hash: "a1b2c3d4"

patterns: {}

decisions: []

pitfalls: []

updated_at: "2024-01-15T10:00:00Z"
```

---

## 관련 문서

- [storage.md](storage.md) - 파일 저장소 구조
- [session.md](session.md) - 세션 관리
- [context-injection.md](context-injection.md) - 컨텍스트 조회 방법
- [search-guide.md](search-guide.md) - claude-mem 검색 가이드
