#!/bin/bash
# PreToolUse Hook Template
# 도구 실행 전 검증 및 차단
#
# 사용법: .claude/settings.json에 등록
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Bash",
#       "hooks": [".claude/hooks/pre-tool-use.sh"]
#     }]
#   }
# }

set -euo pipefail

# jq 필수 확인
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required" >&2
  exit 0
fi

# stdin에서 JSON 입력 읽기
INPUT=$(cat)

# 도구 정보 추출
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# === 검증 로직 (필요에 따라 수정) ===

# 예시 1: Bash 위험 명령어 차단
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  DANGEROUS_PATTERNS=(
    "rm -rf /"
    "sudo rm"
    "chmod 777"
    "git push --force"
    "git reset --hard"
    "> /dev/sda"
  )

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND" == *"$pattern"* ]]; then
      echo "{\"decision\": \"block\", \"reason\": \"위험한 명령어 '$pattern'이(가) 감지되었습니다.\"}"
      exit 0
    fi
  done
fi

# 예시 2: 민감 파일 수정 차단
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

  PROTECTED_PATTERNS=(
    ".env"
    "credentials"
    "secrets"
    ".pem"
    ".key"
  )

  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
      echo "{\"decision\": \"block\", \"reason\": \"보호된 파일 '$pattern' 수정이 차단되었습니다.\"}"
      exit 0
    fi
  done
fi

# 차단 조건에 해당하지 않으면 허용 (빈 출력)
exit 0
