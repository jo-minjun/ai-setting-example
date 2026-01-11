# 에이전트별 컨텍스트 주입 가이드

각 에이전트 호출 시 역할에 맞는 컨텍스트를 주입한다.

## 1. Planner 에이전트

### 역할
요청 분석 및 마일스톤 정의

### 주입할 컨텍스트
```yaml
context:
  - 사용자 원본 요청 (전문)
  - 프로젝트 기술 스택 (CLAUDE.md 참조)
  - 기존 코드베이스 구조 (디렉토리 구조)
  - 관련 기존 코드 (있는 경우)
```

### 지시사항
```
다음 작업을 수행하라:
1. 요청을 분석하여 단일 마일스톤으로 축소
2. 마일스톤 완료 조건을 명확히 정의
3. 스코프 경계를 설정 (포함/미포함 항목 명시)
4. Design Brief를 다음 형식으로 출력

Design Brief 형식:
- milestone_name: [마일스톤명]
- objective: [목표]
- completion_criteria: [완료 조건 목록]
- scope_in: [포함 항목]
- scope_out: [미포함 항목]
- dependencies: [의존성]
```

### 출력
Design Brief

---

## 2. Architect 에이전트

### 역할
설계 확정 및 불변 조건 정의

### 주입할 컨텍스트
```yaml
context:
  - Design Brief (Planner 산출물)
  - 프로젝트 아키텍처 패턴 (CLAUDE.md의 DDD 레이어 등)
  - 기존 인터페이스/타입 정의 (관련 파일)
  - 의존성 방향 규칙
```

### 지시사항
```
다음 작업을 수행하라:
1. Design Brief를 바탕으로 설계 확정
2. 의존성 방향 규칙 준수 (도메인 → 외부 의존 금지)
3. 인터페이스 계약 정의
4. 설계 불변 조건 명시
5. Design Contract를 다음 형식으로 출력

Design Contract 형식:
milestone: [마일스톤명]
invariants:
  - [불변 조건 1]
  - [불변 조건 2]
interfaces:
  - name: [인터페이스명]
    input: [입력 타입]
    output: [출력 타입]
    contract: [계약 조건]
boundaries:
  - [경계 조건]
layer_assignments:
  - component: [컴포넌트명]
    layer: [presentation|application|domain|infrastructure]
```

### 출력
Design Contract

---

## 3. QA Engineer 에이전트 (Test First)

### 역할
테스트 계약 작성 및 테스트 코드 생성

### 주입할 컨텍스트
```yaml
context:
  - Design Contract (Architect 산출물)
  - 프로젝트 테스트 프레임워크 (JUnit 5, @SpringBootTest 등)
  - 기존 테스트 패턴/구조 (src/test/java 구조)
  - 테스트 실행 명령 (./gradlew test)
```

### 지시사항
```
다음 작업을 수행하라:
1. Design Contract의 인터페이스별 테스트 케이스 설계
2. Given-When-Then 형식으로 테스트 명세
3. 경계값, 예외 케이스 포함
4. 테스트 코드 먼저 작성 (Red 상태 - 컴파일만 되고 실패해야 함)
5. Test Contract + 테스트 코드 출력

Test Contract 형식:
milestone: [마일스톤명]
test_cases:
  - name: [테스트명]
    target: [테스트 대상 인터페이스]
    given: [전제 조건]
    when: [실행 동작]
    then: [기대 결과]
    category: [happy_path|edge_case|error_case]
coverage_targets:
  - [커버리지 대상]
test_file_path: [테스트 파일 경로]
```

### 출력
Test Contract + 테스트 코드

---

## 4. Implementer 에이전트

### 역할
테스트 통과를 위한 구현

### 주입할 컨텍스트
```yaml
context:
  - Design Contract (설계 불변 조건)
  - Test Contract (통과해야 할 테스트)
  - 테스트 코드 위치 및 내용 (전문)
  - 프로젝트 코드 스타일 (Google Java Format)
  - 기존 관련 코드 (있는 경우)
```

### 지시사항
```
다음 작업을 수행하라:
1. 테스트 통과만을 목표로 최소 구현
2. 설계 불변 조건 준수
3. 스코프 확장 금지 (Design Brief의 scope_out 항목 구현 금지)
4. Google Java Format 스타일 준수
5. 구현 코드 출력

구현 시 주의사항:
- 테스트가 요구하지 않는 기능 추가 금지
- 불필요한 추상화 금지
- 설계 불변 조건 위반 시 즉시 중단하고 보고
```

### 출력
구현 코드

---

## 5. QA Engineer 에이전트 (Verification)

### 역할
테스트 실행 및 검증

### 주입할 컨텍스트
```yaml
context:
  - 구현된 코드 (Implementer 산출물)
  - Test Contract
  - 테스트 실행 명령 (./gradlew test)
  - Design Contract (설계 불변 조건)
```

### 지시사항
```
다음 작업을 수행하라:
1. 테스트 실행 (./gradlew test)
2. 테스트 결과 분석
3. 실패 시 원인 분석 및 분류
   - 구현 오류: Implementation으로 복귀
   - 설계 불변 조건 위반: Design으로 복귀
4. 테스트 결과 리포트 출력

테스트 결과 리포트 형식:
test_execution:
  command: ./gradlew test
  result: [PASS|FAIL]
  summary:
    total: [총 테스트 수]
    passed: [통과 수]
    failed: [실패 수]
failed_tests:
  - name: [실패한 테스트명]
    reason: [실패 원인]
    category: [implementation_error|design_violation|test_error]
recommendation:
  action: [COMPLETE|RETRY_IMPLEMENTATION|RETRY_DESIGN]
  reason: [사유]
```

### 출력
테스트 결과 리포트
