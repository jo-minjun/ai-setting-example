#!/bin/bash
# PostToolUse Hook Template
# 도구 실행 후 코드 품질 검사
#
# 사용법: .claude/settings.json에 등록
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Edit|Write",
#       "hooks": [".claude/hooks/post-tool-use.sh"]
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

# 파일 경로 추출
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 파일 경로가 없으면 종료
if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# 파일 확장자 추출
EXT="${FILE_PATH##*.}"

RESULT=""

# === 언어별 린트/포맷 검사 (필요에 따라 수정) ===

case "$EXT" in
  ts|tsx)
    # TypeScript: ESLint
    if command -v npx &> /dev/null && [[ -f "package.json" ]]; then
      RESULT=$(npx eslint "$FILE_PATH" --format compact 2>&1 || true)
    fi
    ;;

  js|jsx)
    # JavaScript: ESLint
    if command -v npx &> /dev/null && [[ -f "package.json" ]]; then
      RESULT=$(npx eslint "$FILE_PATH" --format compact 2>&1 || true)
    fi
    ;;

  py)
    # Python: Ruff (빠른 린터)
    if command -v ruff &> /dev/null; then
      RESULT=$(ruff check "$FILE_PATH" 2>&1 || true)
    elif command -v pylint &> /dev/null; then
      RESULT=$(pylint "$FILE_PATH" --output-format=text 2>&1 || true)
    fi
    ;;

  java)
    # Java: Google Java Format 체크
    if command -v google-java-format &> /dev/null; then
      DIFF=$(google-java-format --dry-run "$FILE_PATH" 2>&1 || true)
      if [[ -n "$DIFF" ]]; then
        RESULT="포맷팅 필요: google-java-format 실행 권장"
      fi
    fi
    ;;

  go)
    # Go: gofmt + go vet
    if command -v gofmt &> /dev/null; then
      FMT_RESULT=$(gofmt -d "$FILE_PATH" 2>&1 || true)
      VET_RESULT=$(go vet "$FILE_PATH" 2>&1 || true)
      RESULT="$FMT_RESULT$VET_RESULT"
    fi
    ;;

  rs)
    # Rust: cargo clippy
    if command -v cargo &> /dev/null; then
      RESULT=$(cargo clippy --message-format=short 2>&1 || true)
    fi
    ;;

  *)
    # 지원하지 않는 확장자
    exit 0
    ;;
esac

# 결과가 있으면 피드백
if [[ -n "$RESULT" && "$RESULT" != *"0 problems"* && "$RESULT" != *"0 errors"* ]]; then
  # JSON 이스케이프
  ESCAPED=$(echo "$RESULT" | head -20 | jq -Rs '.')
  echo "{\"result\": $ESCAPED}"
fi

exit 0
