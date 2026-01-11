#!/usr/bin/env python3
"""
CLAUDE.md와 AGENTS.md 간의 충돌을 검사한다.

사용법:
    python3 detect_conflicts.py CLAUDE.md AGENTS.md
"""

import re
import sys
from pathlib import Path


# 충돌 검사 대상 섹션 패턴
CONFLICT_SECTIONS = {
    "기술 스택": [
        r"(?:Java|JDK)\s*:?\s*(\d+)",
        r"Spring\s*Boot\s*:?\s*([\d.]+)",
        r"Gradle\s*:?\s*([\d.]+)",
        r"Maven\s*:?\s*([\d.]+)",
        r"Node\.?js?\s*:?\s*([\d.]+)",
        r"Python\s*:?\s*([\d.]+)",
    ],
    "빌드 명령어": [
        r"(?:빌드|build)[:\s]*[`]?([^`\n]+)[`]?",
        r"(?:테스트|test)[:\s]*[`]?([^`\n]+)[`]?",
        r"(?:실행|run)[:\s]*[`]?([^`\n]+)[`]?",
    ],
    "코드 스타일": [
        r"(?:포맷터|formatter)[:\s]*([^\n]+)",
        r"(?:린터|linter)[:\s]*([^\n]+)",
        r"(?:들여쓰기|indent)[:\s]*([^\n]+)",
    ],
    "아키텍처": [
        r"(?:레이어|layer)[:\s]*([^\n]+)",
        r"(?:패키지|package)[:\s]*([^\n]+)",
        r"(?:DDD|헥사고날|클린\s*아키텍처)",
    ],
}


def extract_sections(content: str) -> dict:
    """파일 내용에서 섹션별 정보 추출"""
    results = {}

    for section_name, patterns in CONFLICT_SECTIONS.items():
        matches = []
        for pattern in patterns:
            found = re.findall(pattern, content, re.IGNORECASE | re.MULTILINE)
            if found:
                matches.extend(found if isinstance(found[0], str) else [f[0] for f in found])
        if matches:
            results[section_name] = matches

    return results


def find_conflicts(claude_data: dict, agents_data: dict) -> list:
    """두 파일 간의 충돌 찾기"""
    conflicts = []

    all_sections = set(claude_data.keys()) | set(agents_data.keys())

    for section in all_sections:
        claude_values = set(claude_data.get(section, []))
        agents_values = set(agents_data.get(section, []))

        if claude_values and agents_values and claude_values != agents_values:
            conflicts.append({
                "section": section,
                "claude_md": list(claude_values),
                "agents_md": list(agents_values),
            })

    return conflicts


def format_conflicts(conflicts: list) -> str:
    """충돌 결과를 읽기 쉬운 형식으로 포맷"""
    if not conflicts:
        return "충돌 없음"

    output = []
    for conflict in conflicts:
        output.append(f"[{conflict['section']}]")
        output.append(f"  - CLAUDE.md: {', '.join(conflict['claude_md'])}")
        output.append(f"  - AGENTS.md: {', '.join(conflict['agents_md'])}")
        output.append("")

    return "\n".join(output)


def main():
    if len(sys.argv) < 3:
        print("사용법: python3 detect_conflicts.py <CLAUDE.md> <AGENTS.md>")
        sys.exit(1)

    claude_path = Path(sys.argv[1])
    agents_path = Path(sys.argv[2])

    if not claude_path.exists():
        print(f"오류: {claude_path} 파일이 없습니다.")
        sys.exit(1)

    if not agents_path.exists():
        print(f"오류: {agents_path} 파일이 없습니다.")
        sys.exit(1)

    claude_content = claude_path.read_text(encoding="utf-8")
    agents_content = agents_path.read_text(encoding="utf-8")

    claude_data = extract_sections(claude_content)
    agents_data = extract_sections(agents_content)

    conflicts = find_conflicts(claude_data, agents_data)

    print("=== 충돌 검사 결과 ===")
    print(f"CLAUDE.md 섹션: {list(claude_data.keys())}")
    print(f"AGENTS.md 섹션: {list(agents_data.keys())}")
    print("")

    if conflicts:
        print(f"충돌 발견: {len(conflicts)}개")
        print("")
        print(format_conflicts(conflicts))
        sys.exit(1)
    else:
        print("충돌 없음")
        sys.exit(0)


if __name__ == "__main__":
    main()
