---
name: agent-manifest-aligner
description: AGENTS.md와 CLAUDE.md 파일 간 연결 및 충돌 해결. 프로젝트에 AGENTS.md가 존재할 때 CLAUDE.md가 이를 참조하도록 심볼릭 링크를 설정한다. 두 파일의 내용이 상충하면 사용자에게 확인하여 해결한다. "AGENTS.md 연결", "CLAUDE.md 설정", "매니페스트 정렬", "agents 연동" 같은 요청이나 프로젝트 초기화 시 트리거된다.
---

# Agent Manifest Aligner

AGENTS.md와 CLAUDE.md 간의 연결을 설정하고 충돌을 해결한다.

## 워크플로우

### 1. 파일 존재 확인

프로젝트 루트에서 파일 존재 여부 검사:

```bash
scripts/check_files.sh
```

| 상황 | 처리 |
|------|------|
| AGENTS.md 없음 | 메시지 출력 후 종료 |
| CLAUDE.md 없음 | AGENTS.md → CLAUDE.md 심볼릭 링크 생성 |
| 둘 다 존재 | 충돌 검사 진행 |

### 2. 충돌 검사

두 파일이 모두 존재할 때 충돌 여부 검사:

```bash
python3 scripts/detect_conflicts.py CLAUDE.md AGENTS.md
```

충돌 검사 대상 섹션은 [conflict-rules.md](references/conflict-rules.md) 참조.

### 3. 충돌 해결

충돌 발견 시 AskUserQuestion 도구로 사용자에게 질문:

```
CLAUDE.md와 AGENTS.md에서 충돌이 발견되었습니다:

[충돌 내용]

어떻게 처리할까요?
```

**선택지:**
1. **AGENTS.md 우선**: CLAUDE.md 백업 후 AGENTS.md로 심볼릭 링크
2. **CLAUDE.md 유지**: AGENTS.md 참조 구문만 추가
3. **수동 병합**: 사용자가 직접 편집

### 4. 링크 설정

충돌 해결 후 선택에 따라 처리:

```bash
# AGENTS.md 우선 시
scripts/create_symlink.sh --backup

# CLAUDE.md 유지 시
scripts/create_symlink.sh --include-only
```

### 5. 결과 보고

완료 후 보고:
- 처리 방식 (심볼릭 링크 / include 추가)
- 백업 파일 경로 (해당 시)
- 충돌 해결 내역

## 사용 예시

### 새 프로젝트 (CLAUDE.md 없음)

```
$ 프로젝트에 AGENTS.md가 있습니다.
  CLAUDE.md가 없어 심볼릭 링크를 생성합니다.

  완료: CLAUDE.md -> AGENTS.md
```

### 충돌 발생 시

```
CLAUDE.md와 AGENTS.md에서 충돌이 발견되었습니다:

[기술 스택]
- CLAUDE.md: Java 21, Spring Boot 4.0.1
- AGENTS.md: Java 17, Spring Boot 3.2.0

[빌드 명령어]
- CLAUDE.md: ./gradlew build
- AGENTS.md: mvn clean install

어떻게 처리할까요?
1. AGENTS.md 내용 사용 (CLAUDE.md 백업)
2. CLAUDE.md 내용 유지 (AGENTS.md는 참조만)
3. 수동으로 병합
```

## 제약사항

- Unix 계열 OS에서만 동작 (ln -s 사용)
- 기존 CLAUDE.md가 이미 심볼릭 링크인 경우 별도 처리
- 백업 파일명: `CLAUDE.md.backup.{timestamp}`
