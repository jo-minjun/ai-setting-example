# 타임라인 이벤트 스키마

세션 진행 중 발생하는 모든 이벤트를 기록하는 JSONL 파일의 스키마 정의.

## 파일 정보

- **위치**: `~/.claude/claude-devkit/sessions/{project-hash}/timeline.jsonl`
- **형식**: JSON Lines (한 줄에 하나의 JSON 객체)
- **정책**: Append Only (수정 금지, 추가만)

---

## Event Types

| type | 설명 |
|------|------|
| `session_start` | 세션 시작 |
| `session_end` | 세션 종료 |
| `phase_enter` | 페이즈 진입 |
| `phase_exit` | 페이즈 종료 |
| `agent_start` | 에이전트 시작 |
| `agent_complete` | 에이전트 완료 |
| `contract_created` | Contract 생성 |
| `gate_check` | 게이트 검증 |
| `test_run` | 테스트 실행 |
| `task_complete` | 작업 완료 |
| `subtask_complete` | 하위 작업 완료 |

---

## 고정 값 (Enum)

### Phase

```
parallel_discovery | merge | design | test_first | implementation | verification | complete
```

### Agent

```
code-explore | planner | architect | qa-engineer | implementer
```

### Contract Type

```
design_brief | design_contract | test_contract | test_result
```

### Result

```
success | fail
```

### Gate

```
GATE-1 | GATE-2 | GATE-3 | GATE-4
```

### Gate Result

```
passed | failed
```

### Session End Reason

```
complete | user_stop | timeout | error
```

---

## Event별 스키마

### session_start

```json
{"ts":"2024-01-15T10:00:00","type":"session_start","project":"my-project"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `session_start` |
| project | string | 프로젝트 이름 |

---

### session_end

```json
{"ts":"2024-01-15T15:00:00","type":"session_end","reason":"complete"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `session_end` |
| reason | string | `complete` \| `user_stop` \| `timeout` \| `error` |

---

### phase_enter

```json
{"ts":"2024-01-15T10:00:05","type":"phase_enter","task":"T1","phase":"design"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `phase_enter` |
| task | string | 작업 ID (T1, T2, ...) |
| phase | string | Phase enum 값 |

---

### phase_exit

```json
{"ts":"2024-01-15T10:15:00","type":"phase_exit","task":"T1","phase":"design","result":"success"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `phase_exit` |
| task | string | 작업 ID |
| phase | string | Phase enum 값 |
| result | string | `success` \| `fail` |

---

### agent_start

```json
{"ts":"2024-01-15T10:00:10","type":"agent_start","task":"T1","agent":"architect"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `agent_start` |
| task | string | 작업 ID |
| agent | string | Agent enum 값 |

---

### agent_complete

```json
{"ts":"2024-01-15T10:01:30","type":"agent_complete","task":"T1","agent":"architect","result":"success","duration_sec":80,"tokens":12000}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `agent_complete` |
| task | string | 작업 ID |
| agent | string | Agent enum 값 |
| result | string | `success` \| `fail` |
| duration_sec | number | 소요 시간 (초) |
| tokens | number | 사용 토큰 수 |

---

### contract_created

```json
{"ts":"2024-01-15T10:15:00","type":"contract_created","task":"T1","contract":"design_contract","file":"contracts/T1.design-contract.yaml"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `contract_created` |
| task | string | 작업 ID |
| contract | string | Contract Type enum 값 |
| file | string | 파일 경로 (세션 디렉터리 기준 상대 경로) |

---

### gate_check

```json
{"ts":"2024-01-15T10:45:00","type":"gate_check","task":"T1","gate":"GATE-1","result":"passed"}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `gate_check` |
| task | string | 작업 ID |
| gate | string | Gate enum 값 |
| result | string | `passed` \| `failed` |

---

### test_run

```json
{"ts":"2024-01-15T11:30:00","type":"test_run","task":"T1","result":"success","passed":5,"failed":0}
{"ts":"2024-01-15T11:30:00","type":"test_run","task":"T1","result":"fail","passed":3,"failed":2}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `test_run` |
| task | string | 작업 ID |
| result | string | `success` \| `fail` |
| passed | number | 통과한 테스트 수 |
| failed | number | 실패한 테스트 수 |

---

### task_complete

```json
{"ts":"2024-01-15T12:00:30","type":"task_complete","task":"T1","duration_min":120}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `task_complete` |
| task | string | 작업 ID |
| duration_min | number | 총 소요 시간 (분) |

---

### subtask_complete

```json
{"ts":"2024-01-15T11:00:00","type":"subtask_complete","task":"T1","subtask":"ST1","duration_min":30}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| ts | string | ISO 8601 타임스탬프 |
| type | string | `subtask_complete` |
| task | string | 작업 ID |
| subtask | string | 하위 작업 ID (ST1, ST2, ...) |
| duration_min | number | 소요 시간 (분) |

---

## 전체 예시

```jsonl
{"ts":"2024-01-15T10:00:00","type":"session_start","project":"my-project"}
{"ts":"2024-01-15T10:00:05","type":"phase_enter","task":"T1","phase":"parallel_discovery"}
{"ts":"2024-01-15T10:00:10","type":"agent_start","task":"T1","agent":"code-explore"}
{"ts":"2024-01-15T10:00:10","type":"agent_start","task":"T1","agent":"planner"}
{"ts":"2024-01-15T10:01:30","type":"agent_complete","task":"T1","agent":"code-explore","result":"success","duration_sec":80,"tokens":12000}
{"ts":"2024-01-15T10:02:00","type":"agent_complete","task":"T1","agent":"planner","result":"success","duration_sec":110,"tokens":8500}
{"ts":"2024-01-15T10:02:05","type":"phase_exit","task":"T1","phase":"parallel_discovery","result":"success"}
{"ts":"2024-01-15T10:02:10","type":"phase_enter","task":"T1","phase":"merge"}
{"ts":"2024-01-15T10:05:00","type":"phase_exit","task":"T1","phase":"merge","result":"success"}
{"ts":"2024-01-15T10:05:05","type":"phase_enter","task":"T1","phase":"design"}
{"ts":"2024-01-15T10:05:10","type":"agent_start","task":"T1","agent":"architect"}
{"ts":"2024-01-15T10:15:00","type":"agent_complete","task":"T1","agent":"architect","result":"success","duration_sec":590,"tokens":15000}
{"ts":"2024-01-15T10:15:05","type":"contract_created","task":"T1","contract":"design_contract","file":"contracts/T1.design-contract.yaml"}
{"ts":"2024-01-15T10:15:10","type":"phase_exit","task":"T1","phase":"design","result":"success"}
{"ts":"2024-01-15T10:15:15","type":"phase_enter","task":"T1","phase":"test_first"}
{"ts":"2024-01-15T10:15:20","type":"agent_start","task":"T1","agent":"qa-engineer"}
{"ts":"2024-01-15T10:30:00","type":"agent_complete","task":"T1","agent":"qa-engineer","result":"success","duration_sec":880,"tokens":18000}
{"ts":"2024-01-15T10:30:05","type":"contract_created","task":"T1","contract":"test_contract","file":"contracts/T1.test-contract.yaml"}
{"ts":"2024-01-15T10:30:10","type":"gate_check","task":"T1","gate":"GATE-1","result":"passed"}
{"ts":"2024-01-15T10:30:15","type":"phase_exit","task":"T1","phase":"test_first","result":"success"}
{"ts":"2024-01-15T10:30:20","type":"phase_enter","task":"T1","phase":"implementation"}
{"ts":"2024-01-15T10:30:25","type":"agent_start","task":"T1","agent":"implementer"}
{"ts":"2024-01-15T11:00:00","type":"agent_complete","task":"T1","agent":"implementer","result":"success","duration_sec":1775,"tokens":25000}
{"ts":"2024-01-15T11:00:05","type":"phase_exit","task":"T1","phase":"implementation","result":"success"}
{"ts":"2024-01-15T11:00:10","type":"phase_enter","task":"T1","phase":"verification"}
{"ts":"2024-01-15T11:00:15","type":"agent_start","task":"T1","agent":"qa-engineer"}
{"ts":"2024-01-15T11:10:00","type":"test_run","task":"T1","result":"fail","passed":3,"failed":2}
{"ts":"2024-01-15T11:10:05","type":"agent_complete","task":"T1","agent":"qa-engineer","result":"fail","duration_sec":585,"tokens":8000}
{"ts":"2024-01-15T11:10:10","type":"phase_exit","task":"T1","phase":"verification","result":"fail"}
{"ts":"2024-01-15T11:10:15","type":"phase_enter","task":"T1","phase":"implementation"}
{"ts":"2024-01-15T11:10:20","type":"agent_start","task":"T1","agent":"implementer"}
{"ts":"2024-01-15T11:30:00","type":"agent_complete","task":"T1","agent":"implementer","result":"success","duration_sec":1180,"tokens":12000}
{"ts":"2024-01-15T11:30:05","type":"phase_exit","task":"T1","phase":"implementation","result":"success"}
{"ts":"2024-01-15T11:30:10","type":"phase_enter","task":"T1","phase":"verification"}
{"ts":"2024-01-15T11:30:15","type":"agent_start","task":"T1","agent":"qa-engineer"}
{"ts":"2024-01-15T11:40:00","type":"test_run","task":"T1","result":"success","passed":5,"failed":0}
{"ts":"2024-01-15T11:40:05","type":"agent_complete","task":"T1","agent":"qa-engineer","result":"success","duration_sec":585,"tokens":5000}
{"ts":"2024-01-15T11:40:10","type":"gate_check","task":"T1","gate":"GATE-2","result":"passed"}
{"ts":"2024-01-15T11:40:15","type":"phase_exit","task":"T1","phase":"verification","result":"success"}
{"ts":"2024-01-15T11:40:20","type":"task_complete","task":"T1","duration_min":100}
{"ts":"2024-01-15T15:00:00","type":"session_end","reason":"complete"}
```

---

## 활용

### 분석 쿼리 예시 (jq)

```bash
# 특정 작업의 모든 이벤트
cat timeline.jsonl | jq 'select(.task == "T1")'

# 실패한 테스트만 조회
cat timeline.jsonl | jq 'select(.type == "test_run" and .result == "fail")'

# 에이전트별 총 토큰 사용량
cat timeline.jsonl | jq 'select(.type == "agent_complete") | {agent, tokens}' | jq -s 'group_by(.agent) | map({agent: .[0].agent, total_tokens: map(.tokens) | add})'

# 페이즈별 소요 시간 (초)
cat timeline.jsonl | jq 'select(.type == "agent_complete") | {phase: .phase, duration: .duration_sec}'
```

---

## 관련 문서

- [session.md](session.md) - 세션 컨텍스트 관리
- [knowledge.md](knowledge.md) - 프로젝트 지식 관리