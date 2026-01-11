---
name: hook-generator
description: Claude Code Hooks 생성 스킬. 도구 실행 전후 검증, 코드 품질 관리, 알림 전송을 자동화하는 훅을 생성한다. 사용자가 "훅 만들어줘", "hook 생성", "PreToolUse 훅", "PostToolUse 훅", "파일 보호 훅", "린트 훅", "알림 훅" 등을 요청할 때 트리거된다.
---

# Hook Generator

Claude Code Hooks를 생성하여 도구 실행 전후 검증, 코드 품질 관리, 알림 전송을 자동화한다.

## 워크플로우

### 1. 요구사항 수집

사용자에게 질문하여 훅 요구사항을 파악한다:

| 항목 | 질문 |
|------|------|
| 훅 유형 | PreToolUse, PostToolUse, Notification, Stop 중 어떤 유형인가? |
| 대상 도구 | 어떤 도구에 적용할 것인가? (Bash, Edit, Write 등) |
| 동작 | 무엇을 검증/실행할 것인가? |
| 알림 채널 | (Notification인 경우) Slack, 이메일, 시스템 알림 중 무엇인가? |

훅 유형별 상세 정보는 [references/hook-types.md](references/hook-types.md) 참조.

### 2. 훅 스크립트 생성

`assets/` 디렉터리의 템플릿을 기반으로 훅 스크립트를 생성한다:

- `assets/pre-tool-use.sh` - PreToolUse 템플릿
- `assets/post-tool-use.sh` - PostToolUse 템플릿
- `assets/notification.sh` - Notification 템플릿
- `assets/stop-hook.sh` - Stop 템플릿

생성 위치: 프로젝트 루트의 `.claude/hooks/` 디렉터리

### 3. settings.json 설정 추가

`.claude/settings.json`에 hooks 섹션을 추가한다:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "도구명",
        "hooks": [".claude/hooks/스크립트명.sh"]
      }
    ]
  }
}
```

### 4. 권한 설정 및 테스트

```bash
chmod +x .claude/hooks/*.sh
```

## 훅 스크립트 입출력

### 입력 (stdin JSON)

```json
{
  "tool_name": "도구명",
  "tool_input": { "파라미터": "값" },
  "session_id": "세션 ID",
  "transcript_path": "대화 기록 경로"
}
```

### 출력

**PreToolUse 차단:**
```json
{"decision": "block", "reason": "차단 사유"}
```

**PostToolUse 피드백:**
```json
{"result": "Claude에게 전달할 메시지"}
```

## 주의사항

1. 훅 스크립트는 exit code 0 유지 (에러 시에도)
2. JSON 파싱에 `jq` 사용 권장
3. 긴 작업은 비동기 처리 (& 사용)
4. Stop 훅은 `stop_hook_active` 환경변수로 무한 루프 방지
