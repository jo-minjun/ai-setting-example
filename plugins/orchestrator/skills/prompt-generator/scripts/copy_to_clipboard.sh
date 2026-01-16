#!/bin/bash
# 프롬프트를 클립보드에 복사
# 사용법: ./copy_to_clipboard.sh "텍스트" 또는 echo "텍스트" | ./copy_to_clipboard.sh

if [ -n "$1" ]; then
    TEXT="$1"
else
    TEXT=$(cat)
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -n "$TEXT" | pbcopy
    echo "클립보드에 복사되었습니다."
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo -n "$TEXT" | clip
    echo "클립보드에 복사되었습니다."
else
    echo "오류: macOS 또는 Windows만 지원합니다."
    exit 1
fi
