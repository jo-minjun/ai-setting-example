#!/bin/bash
# 프로젝트 루트에서 AGENTS.md와 CLAUDE.md 존재 여부 확인

PROJECT_ROOT="${1:-.}"

AGENTS_FILE="$PROJECT_ROOT/AGENTS.md"
CLAUDE_FILE="$PROJECT_ROOT/CLAUDE.md"

echo "=== 파일 존재 확인 ==="
echo "프로젝트 루트: $PROJECT_ROOT"
echo ""

# AGENTS.md 확인
if [ -f "$AGENTS_FILE" ]; then
    echo "AGENTS.md: 존재"
    AGENTS_EXISTS=true
else
    echo "AGENTS.md: 없음"
    AGENTS_EXISTS=false
fi

# CLAUDE.md 확인
if [ -L "$CLAUDE_FILE" ]; then
    echo "CLAUDE.md: 심볼릭 링크 (-> $(readlink "$CLAUDE_FILE"))"
    CLAUDE_EXISTS=true
    CLAUDE_IS_SYMLINK=true
elif [ -f "$CLAUDE_FILE" ]; then
    echo "CLAUDE.md: 존재 (일반 파일)"
    CLAUDE_EXISTS=true
    CLAUDE_IS_SYMLINK=false
else
    echo "CLAUDE.md: 없음"
    CLAUDE_EXISTS=false
    CLAUDE_IS_SYMLINK=false
fi

echo ""
echo "=== 상태 판단 ==="

if [ "$AGENTS_EXISTS" = false ]; then
    echo "STATUS: NO_AGENTS"
    echo "설명: AGENTS.md가 없습니다. 스킬을 종료합니다."
    exit 0
fi

if [ "$CLAUDE_EXISTS" = false ]; then
    echo "STATUS: CREATE_SYMLINK"
    echo "설명: CLAUDE.md가 없습니다. 심볼릭 링크를 생성합니다."
    exit 0
fi

if [ "$CLAUDE_IS_SYMLINK" = true ]; then
    LINK_TARGET=$(readlink "$CLAUDE_FILE")
    if [ "$LINK_TARGET" = "AGENTS.md" ] || [ "$LINK_TARGET" = "./AGENTS.md" ]; then
        echo "STATUS: ALREADY_LINKED"
        echo "설명: CLAUDE.md가 이미 AGENTS.md를 가리키고 있습니다."
        exit 0
    else
        echo "STATUS: DIFFERENT_LINK"
        echo "설명: CLAUDE.md가 다른 파일을 가리키고 있습니다: $LINK_TARGET"
        exit 0
    fi
fi

echo "STATUS: CHECK_CONFLICTS"
echo "설명: 두 파일 모두 존재합니다. 충돌 검사가 필요합니다."
