"""
Claude DevKit Hooks Package

Claude Code Hooks를 통한 세션 제어 시스템.

제공되는 Hook:
- SessionStart: 세션 시작 시 미완료 작업 복구 안내
- Stop: 미완료 작업 경고 및 연속 작업 유도
- PostToolUse: knowledge.yaml 자동 업데이트 및 코드 패턴 분석
- PreCompact: 컨텍스트 압축 전 세션 상태 주입
- SubagentStop: 서브에이전트 결과 수집

STUB (향후 구현):
- PreToolUse: 도구 실행 전 검증
- UserPromptSubmit: 키워드 감지
- Notification: 외부 알림
"""

__version__ = "1.0.0"
