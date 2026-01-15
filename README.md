# claude-devkit

Claude Code의 AI 개발 능력을 확장하는 플러그인입니다.

## Quick Start

### 1. 설치

```bash
/plugin marketplace add jo-minjun/claude-devkit
/plugin install claude-devkit@jo-minjun
```

### 2. 바로 사용하기

```
# TDD 기반 자동 개발
로그인 기능 추가해줘

# 에이전트 생성
코드 리뷰 에이전트 만들어줘

# MCP 서버 생성
GitHub API MCP 서버 만들어줘

# 프롬프트 생성
코드 리뷰 프롬프트 만들어줘
```

설치 후 자연어로 요청하면 자동으로 적절한 도구가 실행됩니다.

---

## 선택적 의존성

### claude-mem (메모리 플러그인)

세션 간 컨텍스트를 유지하려면 [claude-mem](https://github.com/thedotmack/claude-mem) 플러그인을 함께 설치하세요.

```bash
> /plugin marketplace add thedotmack/claude-mem
> /plugin install claude-mem
```

**claude-mem 없이도 모든 기능이 정상 작동합니다.** claude-mem을 설치하면:
- 이전 세션의 작업 내용을 기억
- 프로젝트별 학습 내용 축적
- 세션 시작 시 관련 컨텍스트 자동 주입

---

## 주요 기능

### 오케스트레이터 - TDD 기반 자동 개발

복잡한 기능을 자동으로 분석, 설계, 테스트, 구현합니다.

```
# 슬래시 명령어
/orchestrator 로그인 기능 추가해줘

# 자연어 (자동 트리거)
회원가입 만들어줘
장바구니 기능 구현해줘
```

**자동 실행 흐름:**
```
요청 → 프로젝트 분석 → 작업 분해 → 설계 → 테스트 작성 → 구현 → 검증
```

**세션 관리:**
```
/orchestrator resume    # 중단된 작업 재개
/orchestrator learn     # 프로젝트 패턴 학습
```

### 에이전트 생성기

커스텀 에이전트를 쉽게 만들 수 있습니다.

```
/agent-creator
또는: 코드 리뷰 에이전트 만들어줘
```

생성 위치: `.claude/agents/{name}.md`

### 스킬 생성기

반복 작업을 자동화하는 스킬을 만듭니다.

```
/skill-creator
또는: 배포 스킬 만들어줘
```

### MCP 서버 빌더

외부 API와 연동하는 MCP 서버를 생성합니다.

```
/mcp-builder
또는: GitHub API MCP 서버 만들어줘
```

지원 언어: Python (FastMCP), Node.js (MCP SDK)

### 프롬프트 생성기

효과적인 프롬프트를 자동 생성합니다.

```
/prompt-generator
또는: 코드 리뷰 프롬프트 만들어줘
```

### Hook 생성기

Claude Code 이벤트에 반응하는 훅을 만듭니다.

```
/hook-generator
또는: 파일 보호 훅 만들어줘
```

---

## 생성 파일

오케스트레이터 사용 시 다음 파일들이 생성됩니다:

```
.claude/orchestrator/
├── sessions/{hash}/          # 세션 상태
│   ├── state.json
│   └── contracts/            # 에이전트 산출물
└── knowledge/{hash}/
    └── knowledge.yaml        # 학습된 패턴
```

> `.gitignore`에 `.claude/orchestrator/` 추가 권장

---

## 문서

- [에이전트 가이드](./docs/AGENTS.md)
- [스킬 가이드](./docs/SKILLS.md)

## 라이선스

MIT
