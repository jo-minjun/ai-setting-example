# Contract 형식

오케스트레이터가 페이즈 간 전달하는 계약 문서 형식이다.

## 파일 저장 위치

Contract는 세션 디렉터리 내 개별 파일로 저장된다.

```
~/.claude/claude-devkit/sessions/{projectName}-{projectDirectoryHash}-{datetime}/contracts/
├── T1.preliminary-design-brief.yaml
├── T1.design-brief.yaml
├── T1.design-contract.yaml
├── T1.test-contract.yaml
├── T1.test-result.yaml
└── ...
```

> 세션 디렉터리 구조 상세: [session.md](session.md)

---

## Preliminary Design Brief

Planner → Orchestrator(Merge)로 전달되는 잠정 작업 정의서.
코드 탐색 결과 없이 생성되므로 **assumptions 필드가 필수**이다.

### 파일명

`contracts/{task_id}.preliminary-design-brief.yaml`

### 형식

```yaml
version: 1
task_id: T1
created_at: 2024-01-15T10:00:00
created_by: planner

task_name: 사용자 인증 기능
objective: JWT 기반 로그인/로그아웃 구현

# 필수: 코드 구조를 모르는 상태에서의 가정
assumptions:
  - "인증 관련 코드는 auth/ 또는 security/ 디렉토리에 있을 것"
  - "Spring Security를 사용 중일 것"
  - "User 엔티티가 이미 존재할 것"

completion_criteria:
  - 로그인 API 동작
  - JWT 토큰 발급
  - 토큰 검증 미들웨어 동작

scope_in:
  - POST /auth/login 엔드포인트
  - POST /auth/logout 엔드포인트
  - JwtTokenProvider 클래스 (추정)

scope_out:
  - 회원가입 기능
  - 소셜 로그인

dependencies:
  - Spring Security 설정 (추정)
  - User 엔티티 (추정)
```

### 필수 필드

| 필드 | 설명 |
|------|------|
| task_id | 작업 ID (T1, T2, ...) |
| task_name | 작업 식별 이름 |
| objective | 달성 목표 |
| **assumptions** | **코드 구조에 대한 가정 목록 (필수)** |
| completion_criteria | 완료 판단 기준 |
| scope_in | 구현 범위 내 항목 |
| scope_out | 명시적 제외 항목 |

---

## Design Brief

Planner → Architect로 전달되는 작업 정의서.
Merge 페이즈에서 preliminary_design_brief + explored_files를 기반으로 생성.

### 파일명

`contracts/{task_id}.design-brief.yaml`

### 형식

```yaml
version: 1
task_id: T1
created_at: 2024-01-15T10:05:00
created_by: orchestrator

task_name: 사용자 인증 기능
objective: JWT 기반 로그인/로그아웃 구현

completion_criteria:
  - 로그인 API 동작
  - JWT 토큰 발급
  - 토큰 검증 미들웨어 동작

scope_in:
  - POST /auth/login 엔드포인트
  - POST /auth/logout 엔드포인트
  - JwtTokenProvider 클래스
  - JwtAuthenticationFilter

scope_out:
  - 회원가입 기능
  - 소셜 로그인
  - 리프레시 토큰

# 실제 파일 참조
file_refs:
  - entity: User
    path: src/main/java/com/example/user/User.java:1
    status: exists

  - entity: SecurityConfig
    path: src/main/java/com/example/config/SecurityConfig.java:1
    status: exists
```

### file_refs status

| status | 설명 |
|--------|------|
| exists | 이미 존재하는 파일 |
| to_create | 새로 생성할 파일 |
| to_modify | 수정할 파일 |

---

## Design Contract

Architect → QA Engineer로 전달되는 설계 명세서.

### 파일명

`contracts/{task_id}.design-contract.yaml`

### 형식

```yaml
version: 1
task_id: T1
created_at: 2024-01-15T10:15:00
created_by: architect

task_name: 사용자 인증 기능

invariants:
  - id: INV-1
    rule: 도메인 레이어는 인프라에 의존하지 않는다
  - id: INV-2
    rule: 모든 인증 로직은 AuthService를 통해 처리한다
  - id: INV-3
    rule: 토큰 생성/검증은 JwtTokenProvider에 캡슐화한다

interfaces:
  - name: AuthService.login
    input:
      type: LoginRequest
      fields:
        - name: email
          type: string
        - name: password
          type: string
    output:
      type: "Result<TokenResponse, AuthError>"
    contract: 유효한 자격증명 시 토큰 반환, 실패 시 AuthError

  - name: JwtTokenProvider.createToken
    input:
      type: Authentication
    output:
      type: string
    contract: 표준 JWT 형식, 만료 시간 포함

boundaries:
  - from: AuthController
    to: AuthService
    allowed: true
  - from: AuthService
    to: UserRepository
    allowed: true
    note: 인터페이스만 의존
  - from: AuthService
    to: JwtTokenProvider
    allowed: true

layer_assignments:
  - component: AuthController
    layer: presentation
  - component: AuthService
    layer: application
  - component: JwtTokenProvider
    layer: infrastructure

# 실제 파일 참조
file_refs:
  - entity: AuthService
    path: src/main/java/com/example/auth/AuthService.java:1
    status: to_create

  - entity: LoginRequest
    path: src/main/java/com/example/auth/dto/LoginRequest.java:1
    status: to_create

  - entity: User
    path: src/main/java/com/example/user/User.java:1
    status: exists
```

### 필수 필드

| 필드 | 설명 |
|------|------|
| task_id | 작업 ID |
| invariants | 절대 위반 불가 규칙 |
| interfaces | 공개 인터페이스 계약 |
| boundaries | 의존성 경계 규칙 |
| file_refs | 관련 파일 참조 |

---

## Test Contract

QA Engineer → Implementer로 전달되는 테스트 명세서.

### 파일명

`contracts/{task_id}.test-contract.yaml`

### 형식

```yaml
version: 1
task_id: T1
created_at: 2024-01-15T10:30:00
created_by: qa-engineer

task_name: 사용자 인증 기능

test_cases:
  - id: TC-1
    name: 유효한_자격증명으로_로그인_성공
    target: AuthService.login
    given: 등록된 사용자 (email, password)
    when: login(LoginRequest) 호출
    then: TokenResponse 반환, accessToken 비어있지 않음
    category: happy_path

  - id: TC-2
    name: 잘못된_비밀번호로_로그인_실패
    target: AuthService.login
    given: 등록된 사용자, 틀린 비밀번호
    when: login(LoginRequest) 호출
    then: AuthError 반환
    category: error_case

  - id: TC-3
    name: 존재하지_않는_사용자_로그인_실패
    target: AuthService.login
    given: 미등록 이메일
    when: login(LoginRequest) 호출
    then: AuthError 반환
    category: error_case

  - id: TC-4
    name: 빈_이메일로_로그인_시_검증_실패
    target: AuthController.login
    given: 빈 문자열 이메일
    when: POST /auth/login 호출
    then: 400 Bad Request
    category: edge_case

coverage_targets:
  - AuthService.login
  - AuthService.logout
  - JwtTokenProvider.createToken
  - JwtTokenProvider.validateToken

# 테스트 파일 참조
file_refs:
  - entity: AuthServiceTest
    path: src/test/java/com/example/auth/AuthServiceTest.java:1
    status: to_create
```

### 테스트 카테고리

| 카테고리 | 설명 |
|----------|------|
| happy_path | 정상 흐름 |
| error_case | 예외/에러 흐름 |
| edge_case | 경계값, 특수 케이스 |

---

## Test Result

QA Engineer (Verification) → Orchestrator로 전달되는 테스트 결과.

### 파일명

`contracts/{task_id}.test-result.yaml`

### 형식

```yaml
version: 1
task_id: T1
created_at: 2024-01-15T11:00:00
created_by: qa-engineer

execution:
  command: ./gradlew test
  timestamp: 2024-01-15T11:00:00
  result: pass  # pass | fail

summary:
  total: 4
  passed: 4
  failed: 0
  skipped: 0

failed_tests: []
# 실패 시:
# - id: TC-2
#   name: 잘못된_비밀번호로_로그인_실패
#   reason: Expected AuthError but got NullPointerException
#   category: implementation_error

recommendation:
  action: complete  # complete | retry_implementation | retry_design
  reason: 모든 테스트 통과
```

### 고정 값 (Enum)

**result:**
- `pass`
- `fail`

**failed_tests.category:**
- `implementation_error` - 구현 버그
- `design_violation` - 설계 위반
- `test_error` - 테스트 자체 오류

**recommendation.action:**
- `complete` - 작업 완료
- `retry_implementation` - 구현 재시도
- `retry_design` - 설계 재검토

---

## 관련 문서

- [session.md](session.md) - 세션 컨텍스트 관리
- [timeline.md](timeline.md) - 타임라인 이벤트 스키마