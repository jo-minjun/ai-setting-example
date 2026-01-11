# Node/TypeScript MCP 서버 구현 가이드

## 개요

이 문서는 MCP TypeScript SDK를 사용하여 MCP 서버를 구현하기 위한 Node/TypeScript 전용 모범 사례와 예제를 제공한다. 프로젝트 구조, 서버 설정, 도구 등록 패턴, Zod를 사용한 입력 검증, 오류 처리, 완전한 작동 예제를 다룬다.

---

## 빠른 참조

### 주요 Import
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import express from "express";
import { z } from "zod";
```

### 서버 초기화
```typescript
const server = new McpServer({
  name: "service-mcp-server",
  version: "1.0.0"
});
```

### 도구 등록 패턴
```typescript
server.registerTool(
  "tool_name",
  {
    title: "도구 표시 이름",
    description: "도구가 하는 일",
    inputSchema: { param: z.string() },
    outputSchema: { result: z.string() }
  },
  async ({ param }) => {
    const output = { result: `처리됨: ${param}` };
    return {
      content: [{ type: "text", text: JSON.stringify(output) }],
      structuredContent: output // 구조화된 데이터를 위한 현대적 패턴
    };
  }
);
```

---

## MCP TypeScript SDK

공식 MCP TypeScript SDK는 다음을 제공한다:
- 서버 초기화를 위한 `McpServer` 클래스
- 도구 등록을 위한 `registerTool` 메서드
- 런타임 입력 검증을 위한 Zod 스키마 통합
- 타입 안전한 도구 핸들러 구현

**중요 - 현대적 API만 사용:**
- **사용**: `server.registerTool()`, `server.registerResource()`, `server.registerPrompt()`
- **사용 금지**: `server.tool()`, `server.setRequestHandler(ListToolsRequestSchema, ...)` 같은 오래된 사용 중단 API 또는 수동 핸들러 등록
- `register*` 메서드가 더 나은 타입 안전성, 자동 스키마 처리를 제공하며 권장 접근법

자세한 내용은 레퍼런스의 MCP SDK 문서 참조.

## 서버 명명 규칙

Node/TypeScript MCP 서버는 다음 명명 패턴을 따라야 한다:
- **형식**: `{service}-mcp-server` (하이픈과 소문자)
- **예**: `github-mcp-server`, `jira-mcp-server`, `stripe-mcp-server`

이름은:
- 일반적 (특정 기능에 묶이지 않음)
- 통합되는 서비스/API를 설명
- 작업 설명에서 쉽게 추론 가능
- 버전 번호나 날짜 없음

## 프로젝트 구조

Node/TypeScript MCP 서버를 위한 다음 구조 생성:

```
{service}-mcp-server/
├── package.json
├── tsconfig.json
├── README.md
├── src/
│   ├── index.ts          # McpServer 초기화가 있는 메인 진입점
│   ├── types.ts          # TypeScript 타입 정의 및 인터페이스
│   ├── tools/            # 도구 구현 (도메인당 하나의 파일)
│   ├── services/         # API 클라이언트 및 공유 유틸리티
│   ├── schemas/          # Zod 검증 스키마
│   └── constants.ts      # 공유 상수 (API_URL, CHARACTER_LIMIT 등)
└── dist/                 # 빌드된 JavaScript 파일 (진입점: dist/index.js)
```

## 도구 구현

### 도구 명명

도구 이름에 snake_case 사용 (예: "search_users", "create_project", "get_channel_info") 및 명확한 행동 지향적 이름.

**명명 충돌 방지**: 서비스 컨텍스트를 포함하여 겹침 방지:
- `send_message` 대신 `slack_send_message` 사용
- `create_issue` 대신 `github_create_issue` 사용
- `list_tasks` 대신 `asana_list_tasks` 사용

### 도구 구조

도구는 다음 요구사항과 함께 `registerTool` 메서드를 사용하여 등록된다:
- 런타임 입력 검증과 타입 안전성을 위해 Zod 스키마 사용
- `description` 필드는 명시적으로 제공해야 함 - JSDoc 주석은 자동 추출되지 않음
- `title`, `description`, `inputSchema`, `annotations` 명시적 제공
- `inputSchema`는 Zod 스키마 객체여야 함 (JSON 스키마 아님)
- 모든 매개변수와 반환값에 명시적 타입 지정

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({
  name: "example-mcp",
  version: "1.0.0"
});

// 입력 검증을 위한 Zod 스키마
const UserSearchInputSchema = z.object({
  query: z.string()
    .min(2, "쿼리는 최소 2자 이상이어야 함")
    .max(200, "쿼리는 200자를 초과할 수 없음")
    .describe("이름/이메일과 매칭할 검색 문자열"),
  limit: z.number()
    .int()
    .min(1)
    .max(100)
    .default(20)
    .describe("반환할 최대 결과 수"),
  offset: z.number()
    .int()
    .min(0)
    .default(0)
    .describe("페이지네이션을 위해 건너뛸 결과 수"),
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("출력 형식: 사람이 읽기 쉬운 'markdown' 또는 기계가 읽을 수 있는 'json'")
}).strict();

// Zod 스키마에서 타입 정의
type UserSearchInput = z.infer<typeof UserSearchInputSchema>;

server.registerTool(
  "example_search_users",
  {
    title: "Example 사용자 검색",
    description: `Example 시스템에서 이름, 이메일, 팀으로 사용자를 검색한다.

이 도구는 Example 플랫폼의 모든 사용자 프로필을 검색하며, 부분 매칭과
다양한 검색 필터를 지원한다. 사용자를 생성하거나 수정하지 않고
기존 사용자만 검색한다.

Args:
  - query (string): 이름/이메일과 매칭할 검색 문자열
  - limit (number): 반환할 최대 결과 수, 1-100 사이 (기본값: 20)
  - offset (number): 페이지네이션을 위해 건너뛸 결과 수 (기본값: 0)
  - response_format ('markdown' | 'json'): 출력 형식 (기본값: 'markdown')

Returns:
  JSON 형식의 경우: 다음 스키마의 구조화된 데이터:
  {
    "total": number,           // 찾은 총 매칭 수
    "count": number,           // 이 응답의 결과 수
    "offset": number,          // 현재 페이지네이션 오프셋
    "users": [
      {
        "id": string,          // 사용자 ID (예: "U123456789")
        "name": string,        // 전체 이름 (예: "John Doe")
        "email": string,       // 이메일 주소
        "team": string,        // 팀 이름 (선택사항)
        "active": boolean      // 사용자 활성 여부
      }
    ],
    "has_more": boolean,       // 더 많은 결과 사용 가능 여부
    "next_offset": number      // 다음 페이지의 오프셋 (has_more가 true인 경우)
  }

Examples:
  - 사용 시: "마케팅 팀 멤버 전부 찾기" -> query="team:marketing"인 params
  - 사용 시: "John의 계정 검색" -> query="john"인 params
  - 사용 금지 시: 사용자 생성 필요 (대신 example_create_user 사용)

Error Handling:
  - 요청이 너무 많으면 "Error: Rate limit exceeded" 반환 (429 상태)
  - 검색이 비어 있으면 "No users found matching '<query>'" 반환`,
    inputSchema: UserSearchInputSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true
    }
  },
  async (params: UserSearchInput) => {
    // 구현...
  }
);
```

## 입력 검증을 위한 Zod 스키마

Zod는 런타임 타입 검증을 제공한다:

```typescript
import { z } from "zod";

// 검증이 있는 기본 스키마
const CreateUserSchema = z.object({
  name: z.string()
    .min(1, "이름은 필수")
    .max(100, "이름은 100자를 초과할 수 없음"),
  email: z.string()
    .email("잘못된 이메일 형식"),
  age: z.number()
    .int("나이는 정수여야 함")
    .min(0, "나이는 음수일 수 없음")
    .max(150, "나이는 150을 초과할 수 없음")
}).strict();  // .strict()를 사용하여 추가 필드 금지

// Enum
enum ResponseFormat {
  MARKDOWN = "markdown",
  JSON = "json"
}

const SearchSchema = z.object({
  response_format: z.nativeEnum(ResponseFormat)
    .default(ResponseFormat.MARKDOWN)
    .describe("출력 형식")
});
```

## 오류 처리

명확하고 실행 가능한 오류 메시지 제공:

```typescript
import axios, { AxiosError } from "axios";

function handleApiError(error: unknown): string {
  if (error instanceof AxiosError) {
    if (error.response) {
      switch (error.response.status) {
        case 404:
          return "Error: 리소스를 찾을 수 없음. ID가 올바른지 확인.";
        case 403:
          return "Error: 권한 거부. 이 리소스에 대한 접근 권한 없음.";
        case 429:
          return "Error: 속도 제한 초과. 더 많은 요청 전에 잠시 대기.";
        default:
          return `Error: API 요청이 상태 ${error.response.status}로 실패`;
      }
    } else if (error.code === "ECONNABORTED") {
      return "Error: 요청 시간 초과. 다시 시도.";
    }
  }
  return `Error: 예상치 못한 오류 발생: ${error instanceof Error ? error.message : String(error)}`;
}
```

## 공유 유틸리티

공통 기능을 재사용 가능한 함수로 추출:

```typescript
// 공유 API 요청 함수
async function makeApiRequest<T>(
  endpoint: string,
  method: "GET" | "POST" | "PUT" | "DELETE" = "GET",
  data?: any,
  params?: any
): Promise<T> {
  try {
    const response = await axios({
      method,
      url: `${API_BASE_URL}/${endpoint}`,
      data,
      params,
      timeout: 30000,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    });
    return response.data;
  } catch (error) {
    throw error;
  }
}
```

## 패키지 구성

### package.json

```json
{
  "name": "{service}-mcp-server",
  "version": "1.0.0",
  "description": "{Service} API 통합을 위한 MCP 서버",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist"
  },
  "engines": {
    "node": ">=18"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.6.1",
    "axios": "^1.7.9",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^22.10.0",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "allowSyntheticDefaultImports": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## 빌드 및 실행

실행 전 항상 TypeScript 코드 빌드:

```bash
# 프로젝트 빌드
npm run build

# 서버 실행
npm start

# 자동 새로고침으로 개발
npm run dev
```

구현을 완료로 간주하기 전에 항상 `npm run build`가 성공적으로 완료되는지 확인.

## 품질 체크리스트

Node/TypeScript MCP 서버 구현을 마무리하기 전에 확인:

### 전략적 설계
- [ ] 도구가 API 엔드포인트 래퍼가 아닌 완전한 워크플로우를 가능하게 함
- [ ] 도구 이름이 자연스러운 작업 세분화를 반영
- [ ] 응답 형식이 에이전트 컨텍스트 효율성에 최적화
- [ ] 적절한 경우 사람이 읽을 수 있는 식별자 사용
- [ ] 오류 메시지가 에이전트를 올바른 사용으로 안내

### 구현 품질
- [ ] 가장 중요하고 가치 있는 도구 구현됨
- [ ] 모든 도구가 완전한 구성으로 `registerTool` 사용하여 등록
- [ ] 모든 도구에 `title`, `description`, `inputSchema`, `annotations` 포함
- [ ] 어노테이션 올바르게 설정 (readOnlyHint, destructiveHint, idempotentHint, openWorldHint)
- [ ] 모든 도구가 `.strict()` 적용과 함께 런타임 입력 검증을 위해 Zod 스키마 사용
- [ ] 모든 Zod 스키마에 적절한 제약 조건과 설명적인 오류 메시지
- [ ] 모든 도구에 명시적 입력/출력 타입이 있는 포괄적인 설명

### TypeScript 품질
- [ ] 모든 데이터 구조에 TypeScript 인터페이스 정의
- [ ] tsconfig.json에서 Strict TypeScript 활성화
- [ ] `any` 타입 사용 안 함 - 대신 `unknown` 또는 적절한 타입 사용
- [ ] 모든 비동기 함수에 명시적 Promise<T> 반환 타입
- [ ] 오류 처리가 적절한 타입 가드 사용 (예: `axios.isAxiosError`, `z.ZodError`)

### 프로젝트 구성
- [ ] package.json에 필요한 모든 의존성 포함
- [ ] 빌드 스크립트가 dist/ 디렉토리에 작동하는 JavaScript 생성
- [ ] 메인 진입점이 dist/index.js로 적절히 구성
- [ ] 서버 이름이 형식 따름: `{service}-mcp-server`
- [ ] strict 모드로 tsconfig.json 적절히 구성

### 코드 품질
- [ ] 해당되는 경우 페이지네이션 적절히 구현
- [ ] 대용량 응답이 CHARACTER_LIMIT 상수 확인하고 명확한 메시지로 잘림
- [ ] 대용량 결과 집합에 필터링 옵션 제공
- [ ] 모든 네트워크 작업이 타임아웃과 연결 오류를 우아하게 처리
- [ ] 공통 기능이 재사용 가능한 함수로 추출됨
- [ ] 반환 타입이 유사한 작업에서 일관적

### 테스트 및 빌드
- [ ] `npm run build`가 오류 없이 성공적으로 완료
- [ ] dist/index.js 생성되고 실행 가능
- [ ] 서버 실행: `node dist/index.js --help`
- [ ] 모든 import가 올바르게 해결
- [ ] 샘플 도구 호출이 예상대로 작동
