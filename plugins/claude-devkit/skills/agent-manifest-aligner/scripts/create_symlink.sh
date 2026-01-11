#!/bin/bash
# CLAUDE.md -> AGENTS.md 심볼릭 링크 생성

PROJECT_ROOT="${PROJECT_ROOT:-.}"
CLAUDE_FILE="$PROJECT_ROOT/CLAUDE.md"
AGENTS_FILE="$PROJECT_ROOT/AGENTS.md"

# 옵션 파싱
BACKUP=false
INCLUDE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            BACKUP=true
            shift
            ;;
        --include-only)
            INCLUDE_ONLY=true
            shift
            ;;
        --project-root)
            PROJECT_ROOT="$2"
            CLAUDE_FILE="$PROJECT_ROOT/CLAUDE.md"
            AGENTS_FILE="$PROJECT_ROOT/AGENTS.md"
            shift 2
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            exit 1
            ;;
    esac
done

echo "=== 심볼릭 링크 설정 ==="
echo "프로젝트 루트: $PROJECT_ROOT"

# AGENTS.md 존재 확인
if [ ! -f "$AGENTS_FILE" ]; then
    echo "오류: AGENTS.md가 없습니다."
    exit 1
fi

# --include-only 모드: CLAUDE.md에 include 구문만 추가
if [ "$INCLUDE_ONLY" = true ]; then
    if [ ! -f "$CLAUDE_FILE" ]; then
        echo "오류: CLAUDE.md가 없습니다. --include-only는 기존 파일이 필요합니다."
        exit 1
    fi

    # 이미 include가 있는지 확인
    if grep -q "AGENTS.md" "$CLAUDE_FILE"; then
        echo "CLAUDE.md에 이미 AGENTS.md 참조가 있습니다."
        exit 0
    fi

    # CLAUDE.md 끝에 include 구문 추가
    echo "" >> "$CLAUDE_FILE"
    echo "---" >> "$CLAUDE_FILE"
    echo "" >> "$CLAUDE_FILE"
    echo "## 참조" >> "$CLAUDE_FILE"
    echo "" >> "$CLAUDE_FILE"
    echo "추가 에이전트 설정은 [AGENTS.md](./AGENTS.md)를 참조하세요." >> "$CLAUDE_FILE"

    echo "완료: CLAUDE.md에 AGENTS.md 참조를 추가했습니다."
    exit 0
fi

# 기존 CLAUDE.md 백업
if [ -f "$CLAUDE_FILE" ] || [ -L "$CLAUDE_FILE" ]; then
    if [ "$BACKUP" = true ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$CLAUDE_FILE.backup.$TIMESTAMP"

        if [ -L "$CLAUDE_FILE" ]; then
            # 심볼릭 링크인 경우 링크 자체를 백업
            LINK_TARGET=$(readlink "$CLAUDE_FILE")
            echo "$LINK_TARGET" > "$BACKUP_FILE"
            echo "기존 심볼릭 링크 백업: $BACKUP_FILE (-> $LINK_TARGET)"
        else
            cp "$CLAUDE_FILE" "$BACKUP_FILE"
            echo "기존 파일 백업: $BACKUP_FILE"
        fi

        rm -f "$CLAUDE_FILE"
    else
        echo "오류: CLAUDE.md가 이미 존재합니다. --backup 옵션을 사용하세요."
        exit 1
    fi
fi

# 심볼릭 링크 생성
ln -s AGENTS.md "$CLAUDE_FILE"

if [ -L "$CLAUDE_FILE" ]; then
    echo "완료: CLAUDE.md -> AGENTS.md 심볼릭 링크 생성"
    ls -la "$CLAUDE_FILE"
else
    echo "오류: 심볼릭 링크 생성 실패"
    exit 1
fi
