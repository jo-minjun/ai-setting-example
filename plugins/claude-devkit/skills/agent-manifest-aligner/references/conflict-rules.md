# 충돌 검사 규칙

CLAUDE.md와 AGENTS.md 간의 충돌을 검사할 때 사용하는 규칙이다.

## 검사 대상 섹션

| 섹션 | 검사 항목 | 충돌 판단 기준 |
|------|----------|---------------|
| 기술 스택 | 언어/프레임워크 버전 | 버전 번호 불일치 |
| 빌드 명령어 | build, test, run | 명령어 내용 상이 |
| 코드 스타일 | 포맷터, 린터, 들여쓰기 | 설정값 불일치 |
| 아키텍처 | 레이어 구조, 패키지 규칙 | 구조 정의 상이 |
| 개발 규칙 | 컨벤션, 금지 패턴 | 규칙 내용 충돌 |

## 기술 스택 충돌

### 버전 불일치 예시

```
CLAUDE.md: Java 21, Spring Boot 4.0.1
AGENTS.md: Java 17, Spring Boot 3.2.0
```

**심각도**: 높음
**권장 처리**: 최신 버전으로 통일하거나 실제 프로젝트 설정 확인

### 프레임워크 불일치

```
CLAUDE.md: Gradle
AGENTS.md: Maven
```

**심각도**: 높음
**권장 처리**: 실제 빌드 파일(build.gradle.kts, pom.xml) 확인 후 결정

## 빌드 명령어 충돌

### 패키지 매니저 불일치

```
CLAUDE.md: ./gradlew build
AGENTS.md: mvn clean install
```

**심각도**: 높음
**권장 처리**: 실제 프로젝트 구조 확인

### 테스트 명령어 불일치

```
CLAUDE.md: ./gradlew test
AGENTS.md: npm test
```

**심각도**: 중간
**권장 처리**: 프로젝트가 다중 언어인지 확인

## 코드 스타일 충돌

### 포맷터 불일치

```
CLAUDE.md: Google Java Format
AGENTS.md: Prettier
```

**심각도**: 낮음 (다른 언어를 위한 설정일 수 있음)

### 들여쓰기 불일치

```
CLAUDE.md: 2 spaces
AGENTS.md: 4 spaces
```

**심각도**: 중간
**권장 처리**: .editorconfig 또는 IDE 설정 확인

## 아키텍처 충돌

### 레이어 구조 불일치

```
CLAUDE.md: DDD (presentation/application/domain/infrastructure)
AGENTS.md: MVC (controller/service/repository)
```

**심각도**: 높음
**권장 처리**: 실제 패키지 구조 확인 후 결정

## 충돌 해결 우선순위

1. **실제 프로젝트 상태 확인**: 빌드 파일, 패키지 구조 등
2. **AGENTS.md 우선**: OpenAI/GitHub 표준 형식인 경우
3. **CLAUDE.md 우선**: 프로젝트별 커스텀 설정인 경우
4. **병합**: 두 파일이 서로 다른 영역을 다루는 경우

## 충돌이 아닌 경우

다음은 충돌로 판단하지 않는다:

- 한쪽 파일에만 섹션이 존재하는 경우 (보완 관계)
- 동일한 내용이 다른 형식으로 표현된 경우
- 주석이나 설명 부분의 차이
