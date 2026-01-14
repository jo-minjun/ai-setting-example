# claude-mem 검색 가이드

오케스트레이터에서 claude-mem의 검색 기능을 보조적으로 활용하는 방법을 정의한다.
세션 상태와 Contract는 파일로 관리하며, claude-mem은 자동 캡처된 이력 검색에만 사용한다.

---

## 역할 분리

| 용도 | 저장소 | 조회 방법 |
|------|--------|----------|
| 세션 상태 확인 | 파일 | Read session.json |
| Contract 조회 | 파일 | Read *.yaml |
| 프로젝트 지식 | 파일 | Read knowledge.yaml |
| **과거 맥락 검색** | claude-mem | search |
| **실행 이력 검색** | claude-mem | search |
| **자연어 질문** | claude-mem | search |

---

## MCP 도구

### search

자연어 또는 키워드로 과거 이력 검색

```
도구: search
파라미터: query, limit, offset, type, project, dateStart, dateEnd
반환: observation ID 목록 + 요약
```

### timeline

특정 이벤트 주변의 시간순 컨텍스트 조회

```
도구: timeline
파라미터: anchor/query, depth_before, depth_after, project
반환: 전후 observation 목록
```

### get_observations

상세 내용 조회

```
도구: get_observations
파라미터: ids (배열), orderBy, limit, project
반환: observation 전체 내용 (narrative, facts, concepts 등)
```

---

## 검색 쿼리 패턴

claude-mem은 FTS5 전문 검색을 사용한다. 자연어 쿼리가 효과적이다.

### 프로젝트 컨텍스트 검색

```
검색 예시:
"my-project 파일 구조"
"my-project src 디렉토리 구조"
"my-project 인증 관련 파일"
```

### 설계 결정 검색

```
검색 예시:
"my-project 인증 방식 결정"
"my-project JWT 선택 이유"
"my-project 아키텍처 결정"
```

### 실패 이력 검색

```
검색 예시:
"my-project 테스트 실패"
"my-project 빌드 오류"
"my-project 구현 문제"
```

### 코드 탐색 이력

```
검색 예시:
"my-project AuthService 구현"
"my-project 컨트롤러 패턴"
"my-project 에러 처리 방식"
```

---

## FTS5 검색 문법

### 기본 검색
```
"authentication"
→ authentication 포함된 모든 결과
```

### 부울 연산자
```
"authentication AND JWT"
→ 둘 다 포함

"authentication OR session"
→ 둘 중 하나 포함

"authentication NOT deprecated"
→ authentication 포함하지만 deprecated 미포함
```

### 구문 검색
```
"\"user authentication\""
→ 정확한 구문 검색
```

### 조합
```
"\"user auth\" AND (JWT OR session) NOT deprecated"
→ 복잡한 조건 조합
```

---

## 검색 결과 활용

### 3계층 워크플로우

1. **search** - 인덱스 조회 (50-100 토큰/결과)
2. **timeline** - 시간순 컨텍스트 (100-200 토큰/결과)
3. **get_observations** - 상세 내용 (500-1000 토큰/결과)

### 효율적인 검색
```
1. search로 관련 결과 목록 조회
2. 결과에서 관련 ID 선별
3. get_observations로 필요한 것만 상세 조회
```

---

## 사용 시나리오

### 1. 이전 설계 결정 참조

Architect 에이전트 호출 전 이전 결정 확인:

```
search: "{project_name} 설계 결정"
→ 이전 세션에서 내린 설계 결정들 확인
→ 일관성 유지에 활용
```

### 2. 실패 패턴 확인

Implementation 재시도 전 과거 실패 원인 확인:

```
search: "{project_name} {task_name} 실패"
→ 이전에 같은 작업에서 실패한 원인 확인
→ 같은 실수 방지
```

### 3. 코드 패턴 참조

기존 코드 패턴 확인:

```
search: "{project_name} error handling 패턴"
→ 프로젝트의 에러 처리 패턴 확인
→ 일관된 구현 유도
```

### 4. 왜 이렇게 했는지 확인

과거 맥락 이해:

```
search: "{project_name} {component} 결정 이유"
→ 특정 컴포넌트가 왜 이렇게 설계되었는지 확인
```

---

## 주의사항

### 검색은 보조 수단

- Primary: 파일 기반 저장소 (session.json, *.yaml)
- Secondary: claude-mem 검색 (과거 맥락 참조)

### 검색 결과 신뢰도

- 자동 캡처된 내용이므로 정확도가 완벽하지 않을 수 있음
- 중요한 정보는 파일로 저장된 Contract를 우선 참조

### 검색 쿼리 팁

- 프로젝트 이름을 항상 포함
- 구체적인 키워드 사용
- 너무 긴 쿼리보다 짧고 핵심적인 쿼리가 효과적

---

## 관련 문서

- [storage.md](storage.md) - 파일 저장소 구조 (primary)
- [session.md](session.md) - 세션 관리
- [context-injection.md](context-injection.md) - 컨텍스트 조회 방법
