# Hook Types Reference

Claude Code Hooks의 4가지 유형에 대한 상세 가이드.

## 목차

1. [PreToolUse](#1-pretooluse)
2. [PostToolUse](#2-posttooluse)
3. [Notification](#3-notification)
4. [Stop](#4-stop)

---

## 1. PreToolUse

도구 실행 전에 검증하고 차단하는 훅.

### 사용 시나리오

| 시나리오 | matcher | 검증 로직 |
|----------|---------|-----------|
| 민감 파일 보호 | `Edit`, `Write` | file_path에 `.env`, `credentials` 포함 여부 |
| 위험 명령어 차단 | `Bash` | command에 `rm -rf`, `sudo`, `chmod 777` 포함 여부 |
| 특정 디렉터리 보호 | `Edit`, `Write` | file_path가 `config/`, `secrets/`로 시작하는지 |
| git 위험 명령 차단 | `Bash` | `git push --force`, `git reset --hard` 포함 여부 |

### 입력 예시

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  },
  "session_id": "abc123"
}
```

### 출력 형식

**차단:**
```json
{
  "decision": "block",
  "reason": "rm -rf 명령어는 허용되지 않습니다."
}
```

**허용:** 빈 출력 또는 `{"decision": "allow"}`

### 구현 패턴

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 위험 명령어 패턴
DANGEROUS_PATTERNS=(
  "rm -rf"
  "sudo"
  "chmod 777"
  "git push --force"
  "git reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"'$pattern' 명령어는 허용되지 않습니다.\"}"
    exit 0
  fi
done
```

---

## 2. PostToolUse

도구 실행 완료 후 후처리를 수행하는 훅.

### 사용 시나리오

| 시나리오 | matcher | 실행 작업 |
|----------|---------|-----------|
| 자동 포맷팅 | `Edit`, `Write` | prettier, black, google-java-format 실행 |
| 린트 검사 | `Edit`, `Write` | eslint, pylint 실행 후 결과 피드백 |
| 테스트 실행 | `Edit`, `Write` | 관련 테스트 파일 자동 실행 |
| 타입 체크 | `Edit`, `Write` | tsc --noEmit, mypy 실행 |

### 입력 예시

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/project/src/utils.ts",
    "content": "..."
  },
  "session_id": "abc123"
}
```

### 출력 형식

```json
{
  "result": "ESLint: 2 errors found in utils.ts\n- Line 10: 'unused' is defined but never used\n- Line 15: Missing semicolon"
}
```

### 구현 패턴

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# 파일 확장자 확인
EXT="${FILE_PATH##*.}"

case "$EXT" in
  ts|tsx|js|jsx)
    RESULT=$(npx eslint "$FILE_PATH" 2>&1 || true)
    ;;
  py)
    RESULT=$(pylint "$FILE_PATH" 2>&1 || true)
    ;;
  java)
    RESULT=$(./gradlew spotlessCheck 2>&1 || true)
    ;;
  *)
    exit 0
    ;;
esac

if [[ -n "$RESULT" ]]; then
  # JSON 이스케이프 처리
  ESCAPED=$(echo "$RESULT" | jq -Rs '.')
  echo "{\"result\": $ESCAPED}"
fi
```

---

## 3. Notification

특정 이벤트 발생 시 외부로 알림을 전송하는 훅.

### 사용 시나리오

| 시나리오 | matcher | 알림 내용 |
|----------|---------|-----------|
| 주요 파일 수정 알림 | `Edit`, `Write` | 수정된 파일 경로와 변경 내용 요약 |
| 에러 발생 알림 | `Bash` | 실패한 명령어와 에러 메시지 |
| 작업 완료 알림 | `Stop` | 세션 요약 및 완료 메시지 |

### 알림 채널별 구현

#### Slack Webhook

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

WEBHOOK_URL="${SLACK_WEBHOOK_URL}"
MESSAGE="파일 수정됨: $FILE_PATH"

# 비동기 전송 (블로킹 방지)
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$MESSAGE\"}" &
```

#### macOS 시스템 알림

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

osascript -e "display notification \"$TOOL_NAME 실행 완료\" with title \"Claude Code\""
```

#### 이메일 (sendmail)

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

{
  echo "Subject: Claude Code 알림"
  echo "Content-Type: text/plain; charset=utf-8"
  echo ""
  echo "파일 수정됨: $FILE_PATH"
} | sendmail user@example.com &
```

---

## 4. Stop

에이전트 루프 종료 시 실행되는 훅.

### 사용 시나리오

| 시나리오 | 실행 작업 |
|----------|-----------|
| 작업 리포트 생성 | 세션 동안 수정된 파일 목록, 실행된 명령어 요약 |
| 최종 검증 | 빌드, 테스트 실행하여 작업 결과 확인 |
| 정리 작업 | 임시 파일 삭제, 로그 저장 |

### 무한 루프 방지

Stop 훅은 에이전트 종료 시 실행되므로, 훅 내에서 Claude가 다시 호출되면 무한 루프가 발생할 수 있다.

```bash
#!/bin/bash
# 무한 루프 방지
if [[ "$stop_hook_active" == "true" ]]; then
  exit 0
fi

export stop_hook_active=true

# 최종 빌드 검증
./gradlew build --quiet

# 결과 리포트 생성
echo "=== 세션 완료 리포트 ===" >> .claude/session-report.txt
echo "종료 시각: $(date)" >> .claude/session-report.txt
git diff --stat >> .claude/session-report.txt
```

### 구현 패턴

```bash
#!/bin/bash
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# 세션 요약 생성
if [[ -f "$TRANSCRIPT_PATH" ]]; then
  echo "세션 기록: $TRANSCRIPT_PATH"
fi

# 최종 테스트
TEST_RESULT=$(./gradlew test --quiet 2>&1 || true)

if [[ $? -eq 0 ]]; then
  osascript -e 'display notification "모든 테스트 통과" with title "Claude Code 완료"'
else
  osascript -e 'display notification "테스트 실패 확인 필요" with title "Claude Code 완료"'
fi
```

---

## 공통 유틸리티

### jq 필수 확인

```bash
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required" >&2
  exit 0  # 항상 exit 0
fi
```

### 안전한 JSON 출력

```bash
# 멀티라인 텍스트를 JSON으로 안전하게 출력
safe_json_output() {
  local key="$1"
  local value="$2"
  local escaped=$(echo "$value" | jq -Rs '.')
  echo "{\"$key\": $escaped}"
}
```

### 로깅

```bash
LOG_FILE="${HOME}/.claude/hooks.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}
```
