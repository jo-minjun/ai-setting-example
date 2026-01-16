# 에이전트 파일 형식 레퍼런스

## 파일 구조

에이전트 파일은 YAML 프론트매터와 마크다운 콘텐츠로 구성된다:

```markdown
---
name: agent-name
description: 이 에이전트를 사용할 시점
tools: Tool1, Tool2, Tool3
model: sonnet
permissionMode: default
skills: skill1, skill2
---

시스템 프롬프트 내용.
```

## 필수 필드

| 필드 | 설명 |
|------|------|
| `name` | 고유 식별자 (소문자, 하이픈만 사용) |
| `description` | 목적과 트리거 조건 |

## 선택 필드

| 필드 | 값 | 기본값 |
|------|------|--------|
| `tools` | 쉼표로 구분된 도구 이름 | 모든 도구 상속 |
| `model` | `sonnet`, `opus`, `haiku`, `inherit` | 구성된 기본값 |
| `permissionMode` | 권한 모드 참조 | `default` |
| `skills` | 쉼표로 구분된 스킬 이름 | 없음 |

## 권한 모드

| 모드 | 동작 |
|------|------|
| `default` | 사용자 승인 필요 |
| `acceptEdits` | 파일 편집 자동 승인 |
| `dontAsk` | 권한 요청 없음 |
| `bypassPermissions` | 모든 제한 우회 |
| `plan` | 계획 모드만 |
| `ignore` | 권한 무시 |

## 파일 위치

| 유형 | 경로 | 범위 |
|------|------|------|
| 프로젝트 | `.claude/agents/` | 현재 프로젝트만 |
| 사용자 | `~/.claude/agents/` | 모든 프로젝트 |

프로젝트 수준 에이전트가 같은 이름의 사용자 수준 에이전트를 재정의한다.
