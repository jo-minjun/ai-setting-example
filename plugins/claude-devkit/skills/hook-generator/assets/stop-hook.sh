#!/bin/bash
# Stop Hook Template
# 에이전트 루프 종료 시 실행
#
# 사용법: .claude/settings.json에 등록
# {
#   "hooks": {
#     "Stop": [{
#       "matcher": "",
#       "hooks": [".claude/hooks/stop-hook.sh"]
#     }]
#   }
# }

set -euo pipefail

# 무한 루프 방지
if [[ "${stop_hook_active:-}" == "true" ]]; then
  exit 0
fi
export stop_hook_active=true

# jq 필수 확인
if ! command -v jq &> /dev/null; then
  exit 0
fi

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# 세션 정보 추출
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# === 설정 ===
REPORT_DIR="${HOME}/.claude/reports"
ENABLE_FINAL_BUILD="${ENABLE_FINAL_BUILD:-false}"
ENABLE_DESKTOP_NOTIFICATION="${ENABLE_DESKTOP_NOTIFICATION:-true}"

# 리포트 디렉터리 생성
mkdir -p "$REPORT_DIR"

# === 종료 시 작업 (필요에 따라 수정) ===

# 1. 세션 리포트 생성
REPORT_FILE="$REPORT_DIR/session-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "=== Claude Code Session Report ==="
  echo "Session ID: $SESSION_ID"
  echo "Completed: $(date)"
  echo ""

  # Git 변경 사항
  if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
    echo "=== Git Changes ==="
    git diff --stat 2>/dev/null || true
    echo ""
  fi

} > "$REPORT_FILE"

# 2. 최종 빌드 검증 (선택적)
if [[ "$ENABLE_FINAL_BUILD" == "true" ]]; then
  BUILD_RESULT=""

  # 프로젝트 타입 감지 및 빌드
  if [[ -f "gradlew" ]]; then
    BUILD_RESULT=$(./gradlew build --quiet 2>&1 || echo "BUILD FAILED")
  elif [[ -f "package.json" ]]; then
    BUILD_RESULT=$(npm run build 2>&1 || echo "BUILD FAILED")
  elif [[ -f "Cargo.toml" ]]; then
    BUILD_RESULT=$(cargo build --release 2>&1 || echo "BUILD FAILED")
  fi

  if [[ -n "$BUILD_RESULT" ]]; then
    echo "=== Final Build Result ===" >> "$REPORT_FILE"
    echo "$BUILD_RESULT" >> "$REPORT_FILE"
  fi
fi

# 3. 데스크톱 알림
if [[ "$ENABLE_DESKTOP_NOTIFICATION" == "true" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "세션 종료됨" with title "Claude Code" sound name "Glass"' &>/dev/null &
  elif command -v notify-send &> /dev/null; then
    notify-send "Claude Code" "세션 종료됨" &>/dev/null &
  fi
fi

# 4. 임시 파일 정리 (선택적)
# rm -f /tmp/claude-* 2>/dev/null || true

exit 0
