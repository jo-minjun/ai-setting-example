# 프로젝트 지식 관리

세션에서 축적된 프로젝트별 학습 내용을 저장하고 활용하는 방법을 정의한다.

## 파일 위치

```
~/.claude/claude-devkit/knowledge/
└── {projectName}-{projectDirectoryHash}.yaml
```

| 요소 | 설명 | 예시 |
|------|------|------|
| projectName | 프로젝트 디렉터리 이름 | `my-project` |
| projectDirectoryHash | 프로젝트 경로의 SHA-256 해시 앞 6자리 | `a1b2c3` |

> projectDirectoryHash 생성 방법: [session.md](session.md#디렉터리-이름-규칙)

예시:
```
~/.claude/claude-devkit/knowledge/
├── my-project-a1b2c3.yaml
├── api-server-d4e5f6.yaml
└── frontend-app-g7h8i9.yaml
```

---

## 파일 구조

```yaml
version: 1
project_name: my-project
project_path: /Users/.../my-project
created_at: 2024-01-10T09:00:00
updated_at: 2024-01-15T14:30:00

# 동기화 정보
sync_info:
  last_synced_ts: "2024-01-15T11:40:20"   # timeline 분석 포인터
  last_scanned_at: "2024-01-15T14:00:00"  # 프로젝트 스캔 시점

# 프로젝트 패턴
patterns:
  error_handling: "Result<T, E> 패턴 사용"
  naming:
    methods: camelCase
    classes: PascalCase
    constants: UPPER_SNAKE_CASE
  testing: "JUnit 5 + Mockito"
  architecture: "레이어드 아키텍처 (Controller → Service → Repository)"

# 과거 설계 결정
decisions:
  - id: D1
    date: 2024-01-10
    topic: 인증 방식
    decision: JWT + Refresh Token
    rationale: 기존 시스템과 호환, 무상태 인증 필요
    refs:
      - src/main/java/com/example/auth/JwtTokenProvider.java:1

  - id: D2
    date: 2024-01-12
    topic: 예외 처리 전략
    decision: 글로벌 예외 핸들러 + 도메인별 커스텀 예외
    rationale: 일관된 에러 응답, 클라이언트 친화적
    refs:
      - src/main/java/com/example/common/GlobalExceptionHandler.java:1

# 주의 사항 (Pitfalls)
pitfalls:
  - id: P1
    description: "이 프로젝트는 Lombok 사용하지 않음"
    reason: "팀 정책: 명시적 코드 선호"
    learned_from: T3

  - id: P2
    description: "테스트에서 H2 인메모리 DB 사용"
    reason: "통합 테스트 격리"
    learned_from: T1

# 자주 사용되는 파일
frequently_used_files:
  - path: src/main/java/com/example/common/BaseEntity.java
    access_count: 15
    last_accessed: 2024-01-15

  - path: src/main/java/com/example/config/SecurityConfig.java
    access_count: 12
    last_accessed: 2024-01-14

# 의존성 정보
dependencies:
  - name: spring-boot
    version: "3.2.0"
  - name: junit-jupiter
    version: "5.10.0"
```

---

## /orchestrator learn

지식 축적을 실행하는 명령어.

### 동작

```
/orchestrator learn
    │
    ├─ 1. Timeline 분석 (세션 이벤트 기반)
    │     ├─ last_synced_ts 이후 이벤트만 분석
    │     ├─ 실패 패턴 추출 → pitfalls
    │     └─ last_synced_ts 업데이트
    │
    └─ 2. 프로젝트 스캔 (코드베이스 기반)
          ├─ 새 파일 / 삭제된 파일 감지
          ├─ 의존성 변화 감지 (package.json, build.gradle 등)
          ├─ 패턴 변화 감지
          └─ last_scanned_at 업데이트
```

### 프로젝트 스캔 감지 항목

| 항목 | 감지 방법 | 업데이트 대상 |
|------|----------|--------------|
| 새 파일/삭제된 파일 | explored/files.yaml과 비교 | frequently_used_files |
| 의존성 변화 | package.json, build.gradle 등 | dependencies |
| 패턴 변화 | 주요 파일 샘플링 | patterns |
| 설정 변화 | CLAUDE.md, .cursorrules 등 | patterns, pitfalls |

### 출력 예시

```
/orchestrator learn 실행 결과:

[Timeline 분석]
- 분석 이벤트: 25개 (2024-01-15T11:40:20 이후)
- 새로운 pitfall: 1개 추가
  - P4: async 함수에서 try-catch 누락

[프로젝트 스캔]
- 마지막 스캔: 3일 전
- 변경 감지:
  - 새 파일 12개 (src/api/v2/...)
  - 의존성 추가: axios@1.6.0

knowledge 업데이트 완료.
```

---

## 다음 세션 시작 시

```
1. 이전 세션의 state.yaml 확인
2. timeline.jsonl의 마지막 ts와 last_synced_ts 비교
3. 다르면 알림:

   ┌────────────────────────────────────────┐
   │ 미분석 이벤트가 있습니다.              │
   │ /orchestrator learn 으로 지식 축적     │
   └────────────────────────────────────────┘

4. 사용자가 실행하거나 무시
```

---

## 섹션별 설명

### patterns

프로젝트에서 사용하는 코딩 패턴과 규칙.

| 필드 | 설명 |
|------|------|
| error_handling | 에러 처리 패턴 |
| naming | 명명 규칙 |
| testing | 테스트 프레임워크 |
| architecture | 아키텍처 스타일 |

### decisions

과거 설계 결정 기록.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 결정 ID (D1, D2, ...) |
| date | string | 결정 날짜 (YYYY-MM-DD) |
| topic | string | 결정 주제 |
| decision | string | 결정 내용 |
| rationale | string | 결정 근거 |
| refs | list | 관련 파일 참조 (path:line) |

### pitfalls

피해야 할 것들.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | Pitfall ID (P1, P2, ...) |
| description | string | 피해야 할 것 |
| reason | string | 이유 |
| learned_from | string | 학습된 작업 ID (T1, T2, ...) |

---

## 에이전트 컨텍스트 주입

오케스트레이터는 세션 시작 시 knowledge 파일을 읽어 에이전트에게 주입한다.

### Architect

```yaml
knowledge_context:
  patterns: "{{knowledge.patterns}}"
  decisions: "{{knowledge.decisions | recent 5}}"
  pitfalls: "{{knowledge.pitfalls}}"
```

### Implementer

```yaml
knowledge_context:
  patterns: "{{knowledge.patterns}}"
  pitfalls: "{{knowledge.pitfalls}}"
  frequently_used_files: "{{knowledge.frequently_used_files | top 5}}"
```

### Pitfall 경고

에이전트가 pitfall과 관련된 행동을 하려 할 때 경고.

```
[Knowledge Warning]
P1: 이 프로젝트는 Lombok 사용하지 않음
이유: 팀 정책 - 명시적 코드 선호
```

---

## 관련 문서

- [session.md](session.md) - 세션 컨텍스트 관리
- [timeline.md](timeline.md) - 타임라인 이벤트 스키마