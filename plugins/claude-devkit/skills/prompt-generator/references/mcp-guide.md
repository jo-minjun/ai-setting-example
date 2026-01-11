# MCP 서버 생성 프롬프트 가이드

## 프롬프트 구조

```markdown
# [서버명] MCP 서버 생성 요청

## 목적
[서버가 제공할 기능/연동할 외부 서비스]

## 제공할 도구 (Tools)
| 도구명 | 설명 | 파라미터 |
|--------|------|---------|
| tool_name | 기능 설명 | param1, param2 |
...

## 제공할 리소스 (Resources) - 선택
[읽기 전용 데이터 소스가 필요한 경우]
- resource://[type]/[id]

## 제공할 프롬프트 (Prompts) - 선택
[재사용 가능한 프롬프트 템플릿이 필요한 경우]

## 기술 스택
- 언어: Python (FastMCP) / TypeScript (MCP SDK)
- 의존성: [필요한 라이브러리]

## 인증/보안
[API 키, 토큰 등 인증 방식]

## 에러 처리
[예상되는 에러 상황과 처리 방식]
```

## 좋은 프롬프트 예시

```markdown
# GitHub MCP 서버 생성 요청

## 목적
GitHub API와 연동하여 이슈, PR, 레포지토리 관리 기능 제공

## 제공할 도구 (Tools)
| 도구명 | 설명 | 파라미터 |
|--------|------|---------|
| list_issues | 이슈 목록 조회 | repo, state, labels |
| create_issue | 이슈 생성 | repo, title, body |
| get_pr | PR 상세 조회 | repo, pr_number |
| list_repos | 레포지토리 목록 | org (optional) |

## 기술 스택
- 언어: Python (FastMCP)
- 의존성: httpx, fastmcp

## 인증/보안
- GitHub Personal Access Token (환경변수: GITHUB_TOKEN)
- 토큰 없으면 명확한 에러 메시지 반환

## 에러 처리
- Rate limit 초과: 재시도 안내 메시지
- 401/403: 토큰 확인 안내
- 404: 리소스 없음 명시
```

## 핵심 포인트

1. **도구 설계**: 명확한 이름, 설명, 파라미터 정의
2. **에러 처리**: MCP는 에러 처리가 중요 - 명확한 에러 메시지 필수
3. **인증 방식**: 환경변수 기반 설정 권장
4. **언어 선택**:
   - Python: FastMCP (간단, 빠른 개발)
   - TypeScript: MCP SDK (타입 안전성)
