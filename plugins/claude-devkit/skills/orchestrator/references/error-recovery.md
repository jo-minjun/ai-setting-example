# 에러 처리 및 복구 전략

오케스트레이터 실행 중 발생할 수 있는 에러와 복구 방법을 정의한다.

---

## 페이즈별 실패 처리

### parallel_discovery 실패

| 실패 유형 | 복구 방법 |
|-----------|----------|
| Code Explore 실패 | 순차 모드로 전환 (Planner 먼저, 이후 탐색) |
| Planner 실패 | 사용자에게 요청 명확화 요청 |
| 둘 다 실패 | 세션 중단, 에러 로깅 |

**에러 태깅:**
```
[orch:error] task=T1 phase=parallel_discovery type=agent_failure message="Code Explore 타임아웃"
```

---

### merge 실패

| 실패 유형 | 복구 방법 |
|-----------|----------|
| assumptions 50%+ 불일치 | Planner 재호출 (explored_files 주입) |
| 사소한 불일치 | 오케스트레이터가 직접 조정 |
| 병합 로직 오류 | 수동 개입 요청 |

**재실행 태깅:**
```
[orch:state] task=T1 phase=merge retry_count=1 reason="assumptions 70% 불일치"
```

---

### design 실패

| 실패 유형 | 복구 방법 |
|-----------|----------|
| 불변 조건 충돌 | 사용자에게 우선순위 결정 요청 |
| 의존성 순환 감지 | Architect 재호출, 구조 재설계 |
| 레이어 위반 | 경고 후 사용자 확인 |

---

### test_first 실패

| 실패 유형 | 복구 방법 |
|-----------|----------|
| 테스트 컴파일 실패 | QA Engineer 재호출 |
| 커버리지 부족 | 추가 테스트 케이스 요청 |
| Design Contract 불일치 | Architect에게 피드백 후 재설계 |

---

### implementation 실패

| 실패 유형 | 복구 방법 |
|-----------|----------|
| 컴파일 에러 | Implementer 재호출 |
| 설계 불변 조건 위반 | 구현 중단, Architect 피드백 |
| 스코프 초과 | 구현 롤백, scope_out 항목 제거 |

---

### verification 실패

| 실패 유형 | 복구 방법 | recommendation.action |
|-----------|----------|----------------------|
| implementation_error | Implementer 재호출 | retry_implementation |
| design_violation | Architect 재검토 | retry_design |
| test_error | QA Engineer 테스트 수정 | - |

**테스트 실패 분류 기준:**
```
implementation_error:
  - 예상 출력과 실제 출력 불일치
  - NullPointerException, 런타임 에러

design_violation:
  - 인터페이스 계약 위반
  - 레이어 경계 위반
  - 불변 조건 위반

test_error:
  - 테스트 설정 오류
  - 잘못된 테스트 데이터
  - 테스트 자체의 버그
```

---

## 게이트 실패 복구

### GATE-1: Design Brief 완성도

| 실패 사유 | 복구 방법 |
|-----------|----------|
| completion_criteria 누락 | Merge 재수행 |
| scope_in 구체화 부족 | Planner 재호출 |
| file_refs 매핑 실패 | Code Explore 재실행 |

---

### GATE-2: Design Contract 검증

| 실패 사유 | 복구 방법 |
|-----------|----------|
| invariants 누락 | Architect 재호출 |
| interfaces 불완전 | 인터페이스 상세화 요청 |
| boundaries 충돌 | 의존성 재설계 |

---

### GATE-3: Test Contract 커버리지

| 실패 사유 | 복구 방법 |
|-----------|----------|
| happy_path 누락 | QA Engineer 재호출 |
| error_case 누락 | 에러 케이스 추가 요청 |
| edge_case 부족 | 경계값 분석 재요청 |

---

### GATE-4: 테스트 통과

| 실패 사유 | 복구 방법 |
|-----------|----------|
| 테스트 실패 | recommendation.action에 따라 분기 |
| 테스트 미실행 | 테스트 환경 문제 해결 |
| 타임아웃 | 테스트 분할 또는 타임아웃 연장 |

---

## 세션 중단 복구

### 예기치 않은 종료

```
복구 절차:
1. search로 마지막 상태 조회
   쿼리: "[orch:state] task={taskId}"

2. 마지막 phase 확인

3. 해당 phase부터 재개
   - Contract 존재 확인
   - 없으면 이전 phase로 롤백
```

**세션 재개 표시:**
```
┌─────────────────────────────────────────────────────┐
│ 이전 세션 복구                                       │
├─────────────────────────────────────────────────────┤
│ 마지막 상태: T1 - implementation                    │
│ Design Contract: ✅ 존재                            │
│ Test Contract: ✅ 존재                              │
│ 구현 코드: ⚠️ 부분 완료                            │
│                                                      │
│ [1] implementation부터 재개                         │
│ [2] test_first부터 재시작                           │
│ [3] 새 세션 시작                                    │
└─────────────────────────────────────────────────────┘
```

---

### 수동 중단 (/orchestrator stop)

```
동작:
1. 현재 상태 저장
   기록: "[orch:state] task={taskId} phase={phase} status=stopped"

2. 세션 상태 업데이트
   기록: "[orch:session] project={projectName} status=stopped"

3. 재개 가능 상태로 유지
```

---

## 에러 태깅 규약

모든 에러는 다음 형식으로 기록:

```
[orch:error] task={taskId} phase={phase} type={errorType} message={msg}
```

### 에러 유형 (errorType)

| 유형 | 설명 |
|------|------|
| agent_failure | 에이전트 실행 실패 |
| gate_failure | 게이트 검증 실패 |
| merge_failure | 병합 로직 실패 |
| timeout | 타임아웃 |
| user_abort | 사용자 중단 |
| unknown | 알 수 없는 에러 |

---

## 재시도 정책

### 최대 재시도 횟수

| 작업 | 최대 횟수 |
|------|----------|
| 에이전트 호출 | 3회 |
| 게이트 검증 | 2회 |
| 테스트 실행 | 3회 |
| 전체 페이즈 | 2회 |

### 지수 백오프

재시도 시 대기 시간:
```
wait_time = base_delay * (2 ^ retry_count)
base_delay = 1초
최대 대기: 30초
```

---

## 관련 문서

- [session.md](session.md) - 세션 라이프사이클
- [tagging-spec.md](tagging-spec.md) - 태깅 규약
- [context-injection.md](context-injection.md) - 컨텍스트 관리
