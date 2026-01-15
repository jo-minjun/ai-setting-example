#!/usr/bin/env python3
"""
PreToolUse Hook - STUB

도구 실행 전 검증을 위한 훅.
향후 구현 예정:
- 위험 명령어 차단 (rm -rf, git push --force 등)
- 민감 파일 보호 (.env, credentials 등)
- 특정 디렉터리 보호

현재는 모든 도구 실행을 허용합니다.
"""

import sys
import os

# hooks 패키지 경로 추가
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from hooks.common import read_stdin_json


def main():
    """PreToolUse Hook 메인 함수 - STUB"""
    # stdin에서 입력 읽기 (프로토콜 준수)
    _ = read_stdin_json()

    # TODO: 향후 구현
    # 현재는 모든 도구 실행 허용 (아무것도 출력하지 않음)
    pass


if __name__ == "__main__":
    main()
