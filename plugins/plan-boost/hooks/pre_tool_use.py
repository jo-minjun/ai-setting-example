#!/usr/bin/env python3
"""
PreToolUse Hook: ExitPlanMode 전에 플랜 파일에 리팩터링 섹션 자동 삽입

플랜 파일에 "코드 변경 시 리팩터링" 지시를 추가하여
Claude가 구현 완료 후 자연스럽게 리팩터링을 진행하도록 합니다.
"""
import sys
from pathlib import Path


# 플랜 파일에 삽입할 리팩터링 섹션
REFACTORING_SECTION = """
## 리팩터링 (Plan Boost)

구현 완료 후, 변경된 코드 파일들에 대해 리팩터링을 진행해주세요.
- 코드 구현이 진행된 경우에만 리팩터링
- code-simplifier 서브에이전트가 있으면 사용
- 없으면 직접 리팩터링 진행
- 변경된 파일만 대상 (전체 코드베이스 X)
- 문서 파일(.md 등)은 제외
"""

# 리팩터링 섹션 식별자
SECTION_MARKER = "## 리팩터링 (Plan Boost)"


def find_plan_file() -> Path | None:
    """가장 최근에 수정된 플랜 파일 찾기"""
    plans_dir = Path.home() / ".claude" / "plans"

    if not plans_dir.exists():
        return None

    md_files = list(plans_dir.glob("*.md"))
    if not md_files:
        return None

    # 최근 수정된 파일 반환
    return max(md_files, key=lambda f: f.stat().st_mtime)


def has_refactoring_section(content: str) -> bool:
    """이미 리팩터링 섹션이 있는지 확인"""
    return SECTION_MARKER in content


def add_refactoring_section(plan_path: Path) -> bool:
    """플랜 파일에 리팩터링 섹션 추가"""
    try:
        content = plan_path.read_text(encoding="utf-8")

        # 이미 섹션이 있으면 스킵
        if has_refactoring_section(content):
            return False

        # 섹션 추가
        new_content = content.rstrip() + "\n" + REFACTORING_SECTION
        plan_path.write_text(new_content, encoding="utf-8")
        return True

    except (IOError, OSError):
        return False


def log_info(message: str) -> None:
    """stderr로 정보 출력"""
    print(f"[Plan Boost] {message}", file=sys.stderr)


def main():
    plan_path = find_plan_file()

    if not plan_path:
        return

    if add_refactoring_section(plan_path):
        log_info(f"리팩터링 섹션 추가됨: {plan_path.name}")


if __name__ == "__main__":
    main()
