---
name: agent-creator
description: Claude Code용 커스텀 서브에이전트 생성. .claude/agents 또는 ~/.claude/agents에 새 에이전트를 생성, 추가, 구성하려 할 때 사용한다. "에이전트 만들어줘", "에이전트 생성", "서브에이전트 추가", "~를 위한 에이전트 만들어줘" 같은 요청이나 /agent-creator 명령에 트리거된다.
---

# 에이전트 크리에이터

Claude Code의 기능을 전문 워크플로우로 확장하는 커스텀 서브에이전트를 생성한다.

## 워크플로우

### 1단계: 요구사항 수집

에이전트 구성을 위해 사용자에게 다음을 확인한다:

1. **이름**: 소문자와 하이픈 사용 (예: `code-reviewer`)
2. **목적**: 에이전트가 하는 일과 트리거 시점
3. **도구**: 에이전트에 필요한 도구 ([tools-reference.md](references/tools-reference.md) 참조)
4. **모델**: `sonnet` (균형), `opus` (복잡), `haiku` (빠름), 또는 `inherit`
5. **권한 모드**: 권한 처리 방법 (기본값: `default`)
6. **스킬**: 자동 로드할 스킬 (선택사항)
7. **위치**: 프로젝트 (`.claude/agents/`) 또는 사용자 (`~/.claude/agents/`)

### 2단계: 에이전트 파일 생성

필요시 디렉토리를 생성하고 에이전트 파일을 작성한다:

```bash
# 프로젝트 수준
mkdir -p .claude/agents

# 사용자 수준
mkdir -p ~/.claude/agents
```

YAML 프론트매터와 시스템 프롬프트로 에이전트 파일을 작성한다. 형식 세부사항은 [agent-format.md](references/agent-format.md), 예제는 [examples.md](references/examples.md) 참조.

### 3단계: 확인

에이전트 생성을 확인하고 사용법을 설명한다:
- 에이전트는 즉시 사용 가능 (재시작 불필요)
- Claude가 설명에 따라 자동으로 호출
- 에이전트 이름을 언급하여 명시적으로 호출 가능

## 빠른 참조

### 최소 에이전트 템플릿

```markdown
---
name: my-agent
description: 목적과 사용 시점. 자동 트리거를 위해 PROACTIVELY USE 또는 MUST BE USED 포함.
---

에이전트의 역할과 동작을 설명하는 시스템 프롬프트.
```

### 전체 에이전트 템플릿

```markdown
---
name: my-agent
description: 상세한 목적과 트리거 조건.
tools: Read, Edit, Bash, Grep, Glob
model: sonnet
permissionMode: default
skills: skill1, skill2
---

[목적]을 위한 전문 에이전트다.

호출 시:
1. 첫 번째 단계
2. 두 번째 단계
3. 세 번째 단계

가이드라인:
- 가이드라인 1
- 가이드라인 2
```

## 일반적인 에이전트 유형

| 유형 | 도구 | 모델 | 사용 사례 |
|------|------|------|----------|
| 코드 리뷰 | Read, Grep, Glob, Bash | inherit | 품질 검사 |
| 개발 | Read, Edit, Write, Bash, Grep, Glob | sonnet | 기능 개발 |
| 테스트 | Bash, Read, Grep, Glob, Edit | sonnet | 테스트 실행 |
| 리서치 | Read, Grep, Glob, WebFetch, WebSearch | haiku | 정보 수집 |
| 문서화 | Read, Write, Grep, Glob | haiku | 문서 작성 |

## 레퍼런스

- [에이전트 형식](references/agent-format.md): 파일 구조와 필드 참조
- [도구 레퍼런스](references/tools-reference.md): 사용 가능한 도구와 조합
- [예제](references/examples.md): 완전한 에이전트 예제

## 최신 사양 확인

에이전트 생성 전에 [공식 Claude Code 문서](https://code.claude.com/docs/en/settings#tools-available-to-claude)에서 최신 도구 목록과 사양을 확인한다. 접근 가능한 경우 WebFetch를 사용하여 최신 정보를 조회한다.
