#!/bin/bash
# Notification Hook Template
# 특정 이벤트 발생 시 알림 전송
#
# 사용법: .claude/settings.json에 등록
# {
#   "hooks": {
#     "Notification": [{
#       "matcher": "Edit|Write",
#       "hooks": [".claude/hooks/notification.sh"]
#     }]
#   }
# }

set -euo pipefail

# jq 필수 확인
if ! command -v jq &> /dev/null; then
  exit 0
fi

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# 도구 정보 추출
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# === 알림 설정 (환경변수로 설정 권장) ===
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
ENABLE_DESKTOP_NOTIFICATION="${ENABLE_DESKTOP_NOTIFICATION:-true}"

# === 알림 함수 ===

# Slack 알림 (비동기)
send_slack() {
  local message="$1"
  if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
    curl -s -X POST "$SLACK_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$message\"}" &>/dev/null &
  fi
}

# macOS 데스크톱 알림
send_desktop() {
  local title="$1"
  local message="$2"
  if [[ "$ENABLE_DESKTOP_NOTIFICATION" == "true" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      osascript -e "display notification \"$message\" with title \"$title\"" &>/dev/null &
    elif command -v notify-send &> /dev/null; then
      # Linux
      notify-send "$title" "$message" &>/dev/null &
    fi
  fi
}

# === 알림 로직 (필요에 따라 수정) ===

case "$TOOL_NAME" in
  Edit|Write)
    if [[ -n "$FILE_PATH" ]]; then
      FILENAME=$(basename "$FILE_PATH")

      # 중요 파일 수정 시 알림
      IMPORTANT_PATTERNS=("config" "settings" "package.json" "build.gradle")
      for pattern in "${IMPORTANT_PATTERNS[@]}"; do
        if [[ "$FILE_PATH" == *"$pattern"* ]]; then
          send_slack ":pencil2: 중요 파일 수정됨: \`$FILENAME\`"
          send_desktop "Claude Code" "파일 수정: $FILENAME"
          break
        fi
      done
    fi
    ;;

  Bash)
    if [[ -n "$COMMAND" ]]; then
      # 빌드/테스트 명령어 실행 시 알림
      if [[ "$COMMAND" == *"build"* || "$COMMAND" == *"test"* ]]; then
        send_desktop "Claude Code" "명령어 실행: ${COMMAND:0:50}..."
      fi

      # git push 시 Slack 알림
      if [[ "$COMMAND" == *"git push"* ]]; then
        send_slack ":rocket: Git push 실행됨"
      fi
    fi
    ;;
esac

exit 0
