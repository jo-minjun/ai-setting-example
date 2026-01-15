#!/usr/bin/env python3
"""
Notification Hook - STUB

Claude가 권한 요청이나 알림을 보낼 때 실행되는 훅.
향후 구현 예정:
- Slack 알림 전송
- 이메일 알림
- 시스템 알림 (macOS/Linux)
- 웹훅 호출

현재는 아무 동작도 하지 않습니다.
"""

import sys
import os

# hooks 패키지 경로 추가
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from hooks.common import read_stdin_json


def main():
    """Notification Hook 메인 함수 - STUB"""
    # stdin에서 입력 읽기 (프로토콜 준수)
    _ = read_stdin_json()

    # TODO: 향후 구현
    # - Slack 웹훅 전송
    # - 이메일 전송
    # - 시스템 알림
    pass


if __name__ == "__main__":
    main()
