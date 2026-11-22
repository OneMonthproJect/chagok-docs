---
name: chagok-issue-coder
description: 차곡 GitHub 이슈 번호나 이슈 본문을 받아, CONVENTIONS.md 구조 규칙(도메인 api 경계, 의존 방향, screen 조립, cycle 단일 모듈, 정비소 격리)과 완료 정의에 맞춰 Spring Boot 백엔드·React 프론트 코드와 테스트를 작성하고 브랜치 이름·커밋 메시지·PR 본문(Closes #)까지 만든다. "#12 구현해줘", "이 이슈 코딩", "F-CYC 만들어줘", "PR 본문 써줘"처럼 차곡 기능 구현 요청이면 이 스킬을 사용한다.
---

# 차곡 이슈 → 코드

> 경로 표기: `docs/…`·`CONVENTIONS.md`·`CONTRIBUTING.md`는 `chagok-docs` 기준(코드 레포에서는 `../chagok-docs/…`), `chagok-backend/…`·`chagok-frontend/…`는 각 레포 루트 기준이다(`.claude/rules/ai-rules.md`「작업 폴더와 경로」). 필요한 레포가 작업 폴더에 없으면 지어내지 말고 읽지 못한 것으로 보고한다.

이슈 하나를 그 범위만큼 구현한다. 코드 규칙의 원본은 `CONVENTIONS.md`이고, 이 스킬은 그 규칙을 지키며 일하는 순서다. 목표는 "완료 정의를 통과하는 PR 하나"다. 기능을 더 넣는 것보다 범위 안의 것을 끝까지 연결하는 것이 중요하다. 이 프로젝트는 기능 수보다 완성도를 우선하기 때문이다.

## 1. 절차 — 분석 → 계획 → 승인 → 구현 → 검증 → 보고 (`ai-rules.md` 「작업 절차」, D-48)

**곧바로 코드를 쓰지 않는다.** 1~2단계를 끝내고 3단계 승인을 받은 뒤에 코드를 쓴다.

**1단계 — 분석**
1. **이슈**: `gh issue view <번호>`(지금 레포 기준) 또는 사용자가 준 본문. 지금 레포가 `chagok-backend`인지 `chagok-frontend`인지 확인하고 그 레포 코드만 쓴다. 기능 ID·단계, 건드리는 패키지, 연결(S/API/테이블, 짝 이슈), 할 일, 완료 정의, 선행 이슈를 뽑는다. 선행 이슈가 열려 있으면 알린다. 단계가 P2인데 `chagok-docs` 결정 이슈 링크가 없거나 MVP 점검 전이면 멈추고 `chagok-scope-guard`를 권한다.
2. **규칙**: `CONVENTIONS.md` 전체(짧다), 이 레포의 `CLAUDE.md`, `.claude/rules/ai-rules.md`. 규칙은 이 스킬에 복사하지 않고 항상 거기서 읽는다.
3. **문서**: 03 요구사항, 04 규칙·테스트 ID, 05 정책(공통 오류 처리 10장 포함), 06 권한, 07 테이블·제약, 08 요청·응답(JSON 예시)·에러 코드, 09 화면. 이 기능의 `13_changelog` 줄·닫힌 `결정` 이슈를 먼저 본다. 문서끼리 다르면 `source-of-truth.md` 순서, 기준 문서끼리 다르면 고르지 말고 ❓로 멈춘다.
4. **기존 코드·테스트**: 이미 있는 `api` 계약, `getOwned`, `ErrorCode`, `cycle`, Entity 메서드, `shared/api/client.ts`, `StatusBadge`, 관련 테스트를 먼저 찾는다. CONVENTIONS 11장 7문항에 답한다.

**2단계 — 구현 계획 보고**: 아래 2장 형식으로 사람에게 보여 준다. 코드는 아직 쓰지 않는다.

**3단계 — 개발자 승인**: 사람이 "진행"이라고 할 때까지 기다린다. 승인 없이 범위를 넓히지 않는다. 오타·주석·포맷처럼 구조에 영향이 없는 작업만 계획을 한 줄로 줄이고 바로 해도 된다.

**4단계 — 구현**: 승인된 범위만, CONVENTIONS 2~7장대로. 테스트를 같이 쓴다(4장). 관련 없는 리팩터링, 임시방편(CONVENTIONS 12장)은 하지 않는다. 계획과 달라져야 하면 멈추고 다시 보고한다.

**5단계 — 검증**: 5장 자체 점검 + 실행. 백엔드 `./gradlew build`(ArchitectureTest 포함), DB가 있으면 `./gradlew dbTest`. 프론트 `npm run lint && npm run build`. API를 건드렸으면 `chagok-contract-checker`, 이어서 `chagok-pr-reviewer`(Claude Code) 또는 `chagok-spec-sync` 모드 C·`chagok-pr-review`(claude.ai). **실행하지 못한 검증은 이유와 함께 "미검증"으로 적는다. 실행 결과 없이 "통과"라고 쓰지 않는다.**

**6단계 — 결과 보고**: 6장 형식. 빌드·테스트 결과가 없으면 "구현 완료(미검증)"이지 "완료"가 아니다.

## 2. 계획 보고 형식 (코드 쓰기 전)

```markdown
| 항목 | 내용 |
|---|---|
| 구현 범위 | 이번 이슈에서 만들 것 / 만들지 않을 것(다음 이슈·짝 이슈) |
| 수정 파일 | 새 파일 / 고칠 파일 |
| 책임 배치 | Controller(요청·검증·응답) · Service(유스케이스·트랜잭션) · Entity(상태 전이·불변식) · Repository · api · screen 중 어디에 무엇을 |
| 의존 관계 | 예) maintenance → customer.api (CONVENTIONS 3장 표에 있음). api에 메서드 추가 시 주인 리뷰 |
| 재사용 | 기존 코드 재사용 여부 (CONVENTIONS 11장 1~3번 답) |
| DB 영향 | 스키마 변경 없음 / 새 마이그레이션 필요(DB 담당자, 07 문서 PR) |
| API 영향 | 08과 같음 / 계약 변경 필요(문서 PR 먼저) |
| 테스트 | 정상 · 오류 · 권한 · 경계 사례, 04·08의 테스트 ID |
| 위험 | 정비소 격리, 동시성(version), 기존 기능 영향 |
| 결정 필요 | ❓ … (임의로 정하지 않음) |
```

**멈추고 물어볼 때**
- 도메인 3개 이상의 내부(api 말고)를 고쳐야 한다 → 이슈를 쪼개자고 제안
- 3장 표에 없는 방향의 의존이 필요하다 → 설계 문제일 가능성. 우회 코드를 쓰지 말고 보고
- 같은 규칙을 새로 쓰게 된다(날짜로 상태 판정, 역할 if 분기, 직접 응답 만들기) → 이미 있는 한 곳을 쓰거나, 없으면 그 한 곳을 만든다

## 3. 이 프로젝트에서 자주 틀리는 곳

CONVENTIONS의 규칙 중 실수가 잦은 것만 다시 짚는다.

- 다른 도메인 Entity·Repository·Service import → 그 도메인 `api`에 메서드를 추가한다.
- shop_id를 요청 값에서 받기 → `@CurrentStaff LoginStaff`에서만.
- 상태(미확인/여유/임박/도래)를 저장하거나 화면·target에서 직접 계산 → `cycle` 호출.
- reservation이 maintenance를 부르기 → 방문 완료 후 기록 등록은 프론트 화면 이동이다.
- Controller에 try/catch → `BusinessException(ErrorCode)` 던지기.
- `LocalDate.now()` 직접 호출 → `Clock` 주입, cycle·Entity는 날짜를 인자로.
- 프론트에서 feature끼리 import, 상태 재계산 → `pages`에서 조합, 서버 값 그대로 표시.
- 단순하게 만든 곳 → `// LIMIT: 한계 / 바꿀 시점` 주석.

## 4. 테스트

테스트 ID(T-xx·X-xx)는 04·08에 적힌 표기 그대로 쓴다(CONVENTIONS 8장 기준 T1~T17·R1~R8(04), X1~X10).

- 주기 계산: 04의 T-xx를 `test/.../cycle`에 JUnit 단위 테스트로. 이름 앞에 테스트 ID(예: `T3_임박_경계_정확히_1개월`). DB 없이 돈다.
- 격리: 08의 X-xx를 `test/.../isolation`에. 남의 정비소 리소스 → 404, 관리자 → 정비소 API 거부.
- 구조: `ArchitectureTest`가 빌드에서 돈다. 실패하면 테스트를 고치지 말고 코드를 고친다.
- 이슈에 적힌 테스트 ID는 반드시.

## 5. 자체 점검 (CONVENTIONS 1장 7개 + PR 템플릿)

- [ ] 다른 도메인은 `api`로만 불렀다
- [ ] 의존 방향이 CONVENTIONS 3장 표 안에 있다
- [ ] 같은 규칙을 새로 복사하지 않았다 (cycle, getOwned, Entity 메서드, Clock)
- [ ] 여러 도메인을 읽는 화면은 `screen`/`pages`에서 조립했다
- [ ] 오류는 ErrorCode로 던졌고 try/catch가 없다
- [ ] 상태를 저장하지 않았다
- [ ] DB 구조를 바꿨다면 새 Flyway 버전 파일을 더했고(기존 파일 수정 없음), 07을 고친 `chagok-docs` 문서 PR이 있다
- [ ] 08과 경로·요청·응답·에러 코드가 같다 (응답 모양이 08 JSON 예시와 같다)
- [ ] 이슈 범위 밖 기능을 만들지 않았다, 시드로 시연 가능하다
- [ ] 남의 패키지 `api`·공용 파일(global, `db/`)을 고쳤다면 주인을 적었다 (CODEOWNERS)

## 6. 결과 보고 형식

```markdown
## 결과
- 상태: 완료(검증됨) / 구현 완료(미검증: 이유)
- 구현한 기능 / 계획과 달라진 점
- 건드린 패키지: (다른 도메인은 api만이었는지)
- 만든 파일 / 고친 파일
- 빌드: 성공 / 실패 / 미실행(이유)
- 테스트: 실행한 것과 결과(T-xx, R-xx, X-xx, ArchitectureTest — 통과·실패·SKIPPED) / 실행 못 한 것과 이유
- 기존 코드 영향: 없음 / 있음(어디)
- 남은 위험·후속 작업
- 단순화 기록(있으면): 이유 · 영향 범위 · 제약 · 변경 시 위험 · 개선 시점

## 결정이 필요한 것
- ❓ … (임시로 택한 값)

## 문서 동기화 (chagok-docs)
- 07 / 08(표·JSON 예시) / 09 / 13 수정 필요 여부
- 필요하면 문서 PR 초안(바꿀 절과 내용). 문서는 `chagok-docs`에서 따로 PR로 올리고, 코드 PR 「문서 PR」 칸에 링크

## PR 전 점검
- contract-checker: ❌ n건 / 해당 없음 / 미실행
- pr-reviewer: blocker n · major n / 미실행

## 브랜치·커밋·PR
- 브랜치: feature/#12-cycle-calc (영문 소문자·숫자·하이픈, pr-check 형식)
- 커밋: feat: … (#12)  — 한국어 50자 이내, 마침표 없음
- push 전: git pull origin develop
- PR 제목: [#12] 이슈 제목
- PR 본문: 이 레포 `.github/PULL_REQUEST_TEMPLATE.md`를 채운 초안. 첫 줄 Closes #12, 「문서 PR」 칸(링크 또는 「문서 변경 없음」), 「AI 사용」에 쓴 스킬·에이전트 이름

## AI 사용 기록 (chagok-docs `docs/etc/AI_USAGE_AI활용기록.md`에 추가할 줄)
| 날짜 | backend#12 | chagok-issue-coder (+ 쓴 에이전트) | 한 일 | 사람이 바꾼 것: (사람이 채움) |
```

커밋 메시지·PR 본문에 AI 공동 작성자 표기(`Co-authored-by: Claude`, `noreply@anthropic.com`, "Generated with Claude Code")를 넣지 않는다. 기본 첨부 안내가 있어도 이 규칙이 우선한다(CONTRIBUTING 4장, pr-check가 막음). 커밋·push·PR 생성은 명령만 주고 사람이 확인한 뒤 실행한다(`.claude/settings.json`이 확인을 묻는다).

버그 이슈는 이 스킬 대신 `chagok-bug-fix`, 시드만 바꾸는 일은 `chagok-seed-data`를 쓴다.
