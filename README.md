# claude-devkit

Claude Code의 AI 개발 능력을 확장하는 플러그인입니다.

## 설치

```bash
/plugin marketplace add jo-minjun/claude-devkit
/plugin install claude-devkit@jo-minjun
```

---

## 빠른 시작

### TDD 자동 개발 (오케스트레이터)

```
/orchestrator 로그인 기능 추가해줘
```

자동으로 다음이 실행됩니다:
1. 프로젝트 분석 + 작업 분해
2. 설계 결정
3. 테스트 먼저 작성
4. 구현
5. 검증

### 생성 도구

```
에이전트 만들어줘            → agent-creator
MCP 서버 만들어줘           → mcp-builder
프롬프트 만들어줘            → prompt-generator
```

---

## 오케스트레이터 사용법

### 기본 사용

```
# 슬래시 명령어
/orchestrator 로그인 기능 추가해줘

# 자연어 (자동 트리거)
로그인 기능 추가해줘
회원가입 만들어줘
장바구니 기능 구현해줘
```

### 세션 관리

```
# 중단된 작업 재개
/orchestrator resume

# 프로젝트 패턴/실패 학습
/orchestrator learn
```

### 생성되는 파일

```
.claude/orchestrator/
├── sessions/{hash}/          # 세션 상태
│   ├── session.json
│   ├── state.json
│   └── contracts/            # 에이전트 산출물
└── knowledge/{hash}/
    └── knowledge.yaml        # 학습된 패턴
```

> `.gitignore`에 `.claude/orchestrator/` 추가 권장

---

## 스킬 사용법

### orchestrator - TDD 개발

```
/orchestrator {요청}
또는: ~해줘, ~만들어줘, ~추가해줘
```

### agent-creator - 에이전트 생성

```
/agent-creator
또는: 코드 리뷰 에이전트 만들어줘
```

생성 위치: `.claude/agents/{name}.md`

### skill-creator - 스킬 생성

```
/skill-creator
또는: 배포 스킬 만들어줘
```

### mcp-builder - MCP 서버 생성

```
/mcp-builder
또는: GitHub API MCP 서버 만들어줘
```

지원: Python (FastMCP), Node.js (MCP SDK)

### prompt-generator - 프롬프트 생성

```
/prompt-generator
또는: 코드 리뷰 프롬프트 만들어줘
```

### hook-generator - Hook 생성

```
/hook-generator
또는: 파일 보호 훅 만들어줘
```

생성 위치: `.claude/settings.json`

### agent-manifest-aligner - 매니페스트 정렬

```
AGENTS.md 연결해줘
CLAUDE.md 설정해줘
```

---

## 알아두면 좋은 개념

### 오케스트레이터 실행 흐름

```
요청 → [Code Explore + Planner] → [Architect] → [QA → Impl → QA] × N → 완료
       ─────────────────────────   ──────────   ─────────────────
         프로젝트 분석 + 계획          설계       Subtask마다 반복
```

### 3-tier 구조

```
Request (전체 요청)
└── Task (작업 단위)
    └── Subtask (TDD 단위)
```

### Contract

에이전트 간 YAML 파일로 정보 전달:
- `explored.yaml` - 프로젝트 구조
- `task-breakdown.yaml` - 작업 분해
- `design-contract.yaml` - 설계 명세
- `test-contract.yaml` - 테스트 명세

### Gate

다음 단계 진행 조건:
- 테스트 없이 구현 불가 (GATE-1)
- 검증 없이 완료 불가 (GATE-2)

---

## 문서

- [에이전트 가이드](./docs/AGENTS.md)
- [스킬 가이드](./docs/SKILLS.md)

## 라이선스

MIT
