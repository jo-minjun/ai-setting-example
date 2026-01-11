# Python MCP 서버 구현 가이드

## 개요

이 문서는 MCP Python SDK를 사용하여 MCP 서버를 구현하기 위한 Python 전용 모범 사례와 예제를 제공한다. 서버 설정, 도구 등록 패턴, Pydantic을 사용한 입력 검증, 오류 처리, 완전한 작동 예제를 다룬다.

---

## 빠른 참조

### 주요 Import
```python
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List, Dict, Any
from enum import Enum
import httpx
```

### 서버 초기화
```python
mcp = FastMCP("service_mcp")
```

### 도구 등록 패턴
```python
@mcp.tool(name="tool_name", annotations={...})
async def tool_function(params: InputModel) -> str:
    # 구현
    pass
```

---

## MCP Python SDK와 FastMCP

공식 MCP Python SDK는 MCP 서버 구축을 위한 고수준 프레임워크인 FastMCP를 제공한다:
- 함수 시그니처와 독스트링에서 자동 description 및 inputSchema 생성
- 입력 검증을 위한 Pydantic 모델 통합
- `@mcp.tool`을 사용한 데코레이터 기반 도구 등록

**완전한 SDK 문서는 WebFetch로 다음을 로드:**
`https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`

## 서버 명명 규칙

Python MCP 서버는 다음 명명 패턴을 따라야 한다:
- **형식**: `{service}_mcp` (밑줄과 소문자)
- **예**: `github_mcp`, `jira_mcp`, `stripe_mcp`

이름은:
- 일반적 (특정 기능에 묶이지 않음)
- 통합되는 서비스/API를 설명
- 작업 설명에서 쉽게 추론 가능
- 버전 번호나 날짜 없음

## 도구 구현

### 도구 명명

도구 이름에 snake_case 사용 (예: "search_users", "create_project", "get_channel_info") 및 명확한 행동 지향적 이름.

**명명 충돌 방지**: 서비스 컨텍스트를 포함하여 겹침 방지:
- `send_message` 대신 `slack_send_message` 사용
- `create_issue` 대신 `github_create_issue` 사용
- `list_tasks` 대신 `asana_list_tasks` 사용

### FastMCP로 도구 구조

도구는 입력 검증을 위한 Pydantic 모델과 함께 `@mcp.tool` 데코레이터를 사용하여 정의된다:

```python
from pydantic import BaseModel, Field, ConfigDict
from mcp.server.fastmcp import FastMCP

# MCP 서버 초기화
mcp = FastMCP("example_mcp")

# 입력 검증을 위한 Pydantic 모델 정의
class ServiceToolInput(BaseModel):
    '''서비스 도구 작업을 위한 입력 모델.'''
    model_config = ConfigDict(
        str_strip_whitespace=True,  # 문자열에서 공백 자동 제거
        validate_assignment=True,    # 할당 시 검증
        extra='forbid'              # 추가 필드 금지
    )

    param1: str = Field(..., description="첫 번째 매개변수 설명 (예: 'user123', 'project-abc')", min_length=1, max_length=100)
    param2: Optional[int] = Field(default=None, description="제약 조건이 있는 선택적 정수 매개변수", ge=0, le=1000)
    tags: Optional[List[str]] = Field(default_factory=list, description="적용할 태그 목록", max_items=10)

@mcp.tool(
    name="service_tool_name",
    annotations={
        "title": "사람이 읽을 수 있는 도구 제목",
        "readOnlyHint": True,     # 도구가 환경을 수정하지 않음
        "destructiveHint": False,  # 도구가 파괴적 작업을 수행하지 않음
        "idempotentHint": True,    # 반복 호출은 추가 효과 없음
        "openWorldHint": False     # 도구가 외부 엔티티와 상호작용하지 않음
    }
)
async def service_tool_name(params: ServiceToolInput) -> str:
    '''도구 설명은 자동으로 'description' 필드가 된다.

    이 도구는 서비스에서 특정 작업을 수행한다. 처리 전에
    ServiceToolInput Pydantic 모델을 사용하여 모든 입력을 검증한다.

    Args:
        params (ServiceToolInput): 다음을 포함하는 검증된 입력 매개변수:
            - param1 (str): 첫 번째 매개변수 설명
            - param2 (Optional[int]): 기본값이 있는 선택적 매개변수
            - tags (Optional[List[str]]): 태그 목록

    Returns:
        str: 작업 결과를 포함하는 JSON 형식 응답
    '''
    # 여기에 구현
    pass
```

## Pydantic v2 주요 기능

- 중첩된 `Config` 클래스 대신 `model_config` 사용
- 사용 중단된 `validator` 대신 `field_validator` 사용
- 사용 중단된 `dict()` 대신 `model_dump()` 사용
- 검증자는 `@classmethod` 데코레이터 필요
- 검증자 메서드에 타입 힌트 필요

```python
from pydantic import BaseModel, Field, field_validator, ConfigDict

class CreateUserInput(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True
    )

    name: str = Field(..., description="사용자 전체 이름", min_length=1, max_length=100)
    email: str = Field(..., description="사용자 이메일 주소", pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    age: int = Field(..., description="사용자 나이", ge=0, le=150)

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("이메일은 비어있을 수 없음")
        return v.lower()
```

## 응답 형식 옵션

유연성을 위해 여러 출력 형식 지원:

```python
from enum import Enum

class ResponseFormat(str, Enum):
    '''도구 응답의 출력 형식.'''
    MARKDOWN = "markdown"
    JSON = "json"

class UserSearchInput(BaseModel):
    query: str = Field(..., description="검색 쿼리")
    response_format: ResponseFormat = Field(
        default=ResponseFormat.MARKDOWN,
        description="출력 형식: 사람이 읽기 쉬운 'markdown' 또는 기계가 읽을 수 있는 'json'"
    )
```

**Markdown 형식**:
- 명확성을 위해 헤더, 목록, 서식 사용
- 타임스탬프를 사람이 읽을 수 있는 형식으로 변환 (예: epoch 대신 "2024-01-15 10:30:00 UTC")
- 괄호 안에 ID와 함께 표시 이름 표시 (예: "@john.doe (U123456)")
- 장황한 메타데이터 생략 (예: 모든 크기가 아닌 프로필 이미지 URL 하나만 표시)
- 관련 정보를 논리적으로 그룹화

**JSON 형식**:
- 프로그래밍 처리에 적합한 완전하고 구조화된 데이터 반환
- 사용 가능한 모든 필드와 메타데이터 포함
- 일관된 필드 이름과 타입 사용

## 페이지네이션 구현

리소스를 나열하는 도구의 경우:

```python
class ListInput(BaseModel):
    limit: Optional[int] = Field(default=20, description="반환할 최대 결과 수", ge=1, le=100)
    offset: Optional[int] = Field(default=0, description="페이지네이션을 위해 건너뛸 결과 수", ge=0)

async def list_items(params: ListInput) -> str:
    # 페이지네이션으로 API 요청
    data = await api_request(limit=params.limit, offset=params.offset)

    # 페이지네이션 정보 반환
    response = {
        "total": data["total"],
        "count": len(data["items"]),
        "offset": params.offset,
        "items": data["items"],
        "has_more": data["total"] > params.offset + len(data["items"]),
        "next_offset": params.offset + len(data["items"]) if data["total"] > params.offset + len(data["items"]) else None
    }
    return json.dumps(response, indent=2)
```

## 오류 처리

명확하고 실행 가능한 오류 메시지 제공:

```python
def _handle_api_error(e: Exception) -> str:
    '''모든 도구에서 일관된 오류 형식.'''
    if isinstance(e, httpx.HTTPStatusError):
        if e.response.status_code == 404:
            return "Error: 리소스를 찾을 수 없음. ID가 올바른지 확인."
        elif e.response.status_code == 403:
            return "Error: 권한 거부. 이 리소스에 대한 접근 권한 없음."
        elif e.response.status_code == 429:
            return "Error: 속도 제한 초과. 더 많은 요청 전에 잠시 대기."
        return f"Error: API 요청이 상태 {e.response.status_code}로 실패"
    elif isinstance(e, httpx.TimeoutException):
        return "Error: 요청 시간 초과. 다시 시도."
    return f"Error: 예상치 못한 오류 발생: {type(e).__name__}"
```

## 공유 유틸리티

공통 기능을 재사용 가능한 함수로 추출:

```python
# 공유 API 요청 함수
async def _make_api_request(endpoint: str, method: str = "GET", **kwargs) -> dict:
    '''모든 API 호출을 위한 재사용 가능 함수.'''
    async with httpx.AsyncClient() as client:
        response = await client.request(
            method,
            f"{API_BASE_URL}/{endpoint}",
            timeout=30.0,
            **kwargs
        )
        response.raise_for_status()
        return response.json()
```

## Async/Await 모범 사례

네트워크 요청과 I/O 작업에 항상 async/await 사용:

```python
# 좋음: 비동기 네트워크 요청
async def fetch_data(resource_id: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{API_URL}/resource/{resource_id}")
        response.raise_for_status()
        return response.json()

# 나쁨: 동기 요청
def fetch_data(resource_id: str) -> dict:
    response = requests.get(f"{API_URL}/resource/{resource_id}")  # 차단됨
    return response.json()
```

## 타입 힌트

전체에 타입 힌트 사용:

```python
from typing import Optional, List, Dict, Any

async def get_user(user_id: str) -> Dict[str, Any]:
    data = await fetch_user(user_id)
    return {"id": data["id"], "name": data["name"]}
```

## 품질 체크리스트

Python MCP 서버 구현을 마무리하기 전에 확인:

### 전략적 설계
- [ ] 도구가 API 엔드포인트 래퍼가 아닌 완전한 워크플로우를 가능하게 함
- [ ] 도구 이름이 자연스러운 작업 세분화를 반영
- [ ] 응답 형식이 에이전트 컨텍스트 효율성에 최적화
- [ ] 적절한 경우 사람이 읽을 수 있는 식별자 사용
- [ ] 오류 메시지가 에이전트를 올바른 사용으로 안내

### 구현 품질
- [ ] 가장 중요하고 가치 있는 도구 구현됨
- [ ] 모든 도구에 설명적인 이름과 문서 있음
- [ ] 반환 타입이 유사한 작업에서 일관적
- [ ] 모든 외부 호출에 오류 처리 구현됨
- [ ] 서버 이름이 형식 따름: `{service}_mcp`
- [ ] 모든 네트워크 작업이 async/await 사용
- [ ] 공통 기능이 재사용 가능한 함수로 추출됨
- [ ] 오류 메시지가 명확하고 실행 가능하며 교육적

### 도구 구성
- [ ] 모든 도구가 데코레이터에 'name'과 'annotations' 구현
- [ ] 어노테이션 올바르게 설정 (readOnlyHint, destructiveHint, idempotentHint, openWorldHint)
- [ ] 모든 도구가 Field() 정의와 함께 Pydantic BaseModel을 입력 검증에 사용
- [ ] 모든 Pydantic 필드에 명시적 타입과 제약 조건이 있는 설명
- [ ] 모든 도구에 명시적 입력/출력 타입이 있는 포괄적인 독스트링

### 코드 품질
- [ ] 파일에 Pydantic import를 포함한 적절한 import 포함
- [ ] 해당되는 경우 페이지네이션 적절히 구현
- [ ] 대용량 결과 집합에 필터링 옵션 제공
- [ ] 모든 비동기 함수가 `async def`로 적절히 정의
- [ ] HTTP 클라이언트 사용이 적절한 컨텍스트 매니저와 비동기 패턴 따름
- [ ] 코드 전체에 타입 힌트 사용
- [ ] 상수가 모듈 수준에서 UPPER_CASE로 정의

### 테스트
- [ ] 서버 성공적으로 실행: `python your_server.py --help`
- [ ] 모든 import가 올바르게 해결
- [ ] 샘플 도구 호출이 예상대로 작동
- [ ] 오류 시나리오가 우아하게 처리됨
