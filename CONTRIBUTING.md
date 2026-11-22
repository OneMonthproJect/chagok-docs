# 차곡 협업 규칙 (세 레포 공통)

> 형상관리 담당이 관리합니다. 바꾸려면 `chagok-docs`에 `결정` 이슈로 제안하고 팀 합의 후 이 문서를 고칩니다.
> 문서 역할: **이 문서 = 사람이 협업하는 규칙(Git·이슈·PR·릴리스)**, `CONVENTIONS.md` = 코드 구조 규칙, 각 레포 `CLAUDE.md` + `.claude/rules/ai-rules.md` = AI용 안내. 같은 규칙을 두 문서에 쓰지 않습니다.
> 이 문서는 `chagok-docs`에만 있고, `chagok-backend`·`chagok-frontend`에도 똑같이 적용됩니다.

## 0. 레포 3개

| 레포 | 담는 것 | 이슈로 만드는 것 |
|---|---|---|
| `chagok-docs` | 기획 문서 00~13, 이 문서, `CONVENTIONS.md`, 공용 AI 설정(`.claude/rules·skills·agents`) | 문서, `결정`(명세 변경·범위 추가·P2 착수·규칙 변경) |
| `chagok-backend` | Spring Boot API, Flyway 마이그레이션, 시연 시드(`db/seed/`) | 백엔드 기능(도메인 패키지 하나), 백엔드 버그, 백엔드 `기반` |
| `chagok-frontend` | React 화면 | 프론트 기능(화면 하나), 프론트 버그, 프론트 `기반` |

- **원본은 한 곳에만.** 기준 문서·협업 규칙·코드 규칙·공용 AI 설정은 `chagok-docs`에만 둡니다. 코드 레포에 복사해 커밋하지 않습니다.
- 세 레포는 작업 폴더 `chagok/` 안에 나란히 clone합니다(`scripts/setup-workspace.sh`). 코드 레포의 AI 설정은 `scripts/sync-claude.sh`로 복사해 쓰고, 복사본은 커밋되지 않습니다.
- 다른 레포의 이슈·PR은 `OneMonthproJect/chagok-docs#12`처럼 레포 이름을 붙여 적습니다. 진행 상태는 Organization의 Projects 보드 하나로 세 레포를 함께 봅니다.

## 1. 한눈에 보기

```
이슈 생성(해당 레포) → develop에서 브랜치 → 커밋 → develop으로 PR (Closes #n, 명세가 바뀌면 문서 PR 링크)
→ 자동 검사(❌면 머지하지 않음) + 팀원 확인 → Squash merge → 이슈 자동 클로즈
                         ↓ (중간 점검 · MVP 점검 · 관문 2 · 발표)
     형상관리자: 세 레포 각각 develop → main 릴리스 PR → (코드 레포) CodeRabbit 점검 → Merge commit + 같은 태그
```

## 2. 브랜치 (세 레포 같음)

| 브랜치 | 용도 | 누가 머지 | 머지 방식 |
|---|---|---|---|
| `main` | 중간 점검·MVP 점검·관문 2·발표 시점의 안정 버전 | 형상관리자 | Merge commit |
| `develop` | **기본 브랜치 · 통합 브랜치** | PR을 확인한 팀원 | Squash |
| `feature/#번호-이름` | 기능 | | |
| `fix/#번호-이름` | 버그 수정 | | |
| `docs/#번호-이름` | 문서만 | | |
| `chore/#번호-이름` | 설정·빌드·CI·AI 설정 | | |

- 이름은 영문 소문자·숫자·하이픈. 예: `feature/#12-cycle-calc`. 번호는 **그 레포의** 이슈 번호.
- 작업 브랜치는 항상 최신 `develop`에서 만든다.
- 이슈 하나 = 브랜치 하나 = PR 하나. 하루 안에 머지할 크기로 쪼갠다.
- `main`·`develop`에 직접 push하지 않는다. GitHub Free 기준으로 설정이 막아 주지 않으므로 **팀원이 지키는 규칙**이다(아래 「GitHub Free 운영」).
- 머지된 브랜치는 원격에서 자동 삭제된다. 로컬은 직접 정리: `git pull --prune` 후 `git branch -D <브랜치>` (Squash merge라 `-d`는 거부됨).

## 3. 이슈

- 작업은 이슈부터. 이슈는 0장 표의 레포에 만든다. 템플릿: `chagok-docs`는 문서 / 결정, 코드 레포는 기능 / 버그.
- 기능 이슈 제목: `[F-기능ID] 무엇을` — 기능 ID는 04 기능명세서 그대로.
- 기능 하나가 API와 화면을 모두 가지면 **백엔드 이슈와 프론트 이슈로 나누고** 서로 「짝 이슈」 칸에 링크한다.
- 라벨: 단계(`P0-핵심` / `P0-나머지` / `P1` / `P2` / `기반`) 하나는 반드시.
- 마일스톤(레포마다 같은 이름): 관문 1 / 중간 점검 / MVP 점검 / 관문 2 / 발표 중 하나.
- 담당자(Assignee)를 지정한다. 진행 상태는 Projects 보드가 자동으로 옮긴다.
- **단계 순서를 지킨다.** MVP = P0 + P1이다.
  - P1 이슈는 중간 점검 통과 전에 열지 않는다.
  - P2 이슈는 **MVP 점검 통과 + `chagok-docs`의 `결정` 이슈 합의** 전에 열지 않는다. 한 번에 하나씩, 00·13장 A 묶음부터.
  - Non-goal 기능은 이슈를 만들지 않는다.
- **개발 시작 후 범위 추가는 `결정` 이슈 + 전원 합의가 먼저다.** 합의 전에 브랜치를 열지 않는다. (놀이방: 합의 전 추가 9건이 부실공사의 원인) 추가 의견이 나오면 PM이 `chagok-scope-guard`로 먼저 판정하고, 결정 이슈 초안도 거기서 만든다.
- 백엔드 기능 이슈는 **도메인 패키지 하나** 단위, 프론트 기능 이슈는 **화면 하나** 단위로 쪼갠다. 이슈 본문에 "건드리는 패키지"를 적는다. 도메인 3개 이상이면 쪼갠다.
- 범위를 줄이면 **기능을 통째로** 뺀다. 같은 날 `chagok-docs`에서 00·04·08에 "보류"로 표시한다(문서에 살아 있는 유령 API 방지).

## 4. 커밋

```
타입: 무엇을 했는지 (#이슈번호)
```

| 타입 | 언제 |
|---|---|
| `feat` | 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 |
| `test` | 테스트 |
| `refactor` | 동작 변화 없는 정리 |
| `chore` | 설정·빌드·의존성·CI·AI 설정 |

- 제목은 한국어 50자 이내, 마침표 없음.
- 비밀번호·DB 접속 정보·`.env`는 커밋하지 않는다.
- **AI를 공동 작성자로 올리지 않는다.** 커밋·PR 본문에 `Co-authored-by: Claude`, `noreply@anthropic.com`, "Generated with Claude Code"를 넣지 않는다. 커밋 작성자는 항상 본인 계정이다. AI 사용 사실은 PR 템플릿 「AI 사용」과 `chagok-docs/docs/etc/AI_USAGE`에 사람이 적는다. (pr-check가 막음)
- Squash merge라 develop에는 PR 제목이 커밋으로 남는다. 작업 중 커밋은 자유롭게 하되 PR 제목은 규칙대로.

## 5. PR (팀원 → develop)

- 제목: `[#이슈번호] 이슈 제목`
- 본문 첫 줄: `Closes #이슈번호` → develop(기본 브랜치)에 머지되면 이슈가 자동으로 닫힌다. 다른 레포 이슈를 닫을 때는 `Closes OneMonthproJect/chagok-docs#12`.
- 본문은 PR 템플릿대로. 기능 PR은 완료 정의를 모두 체크한다.
- **코드 레포 PR은 「문서 PR」 칸을 채운다.** 명세(07·08·09)가 바뀌는 변경이면 `chagok-docs` 문서 PR 링크, 아니면 「문서 변경 없음」 체크(7장).
- push 전 `git pull origin develop`. 충돌은 PR 올린 사람이 해결한다.
- 승인 인원을 강제하지 않는다. 다만 머지 전에 팀원 1명이 확인하는 것을 기본으로 한다(작은 문서·오타 수정은 생략 가능). 확인하는 사람은 브랜치를 받아 **다른 코드 레포의 develop과 함께 띄워** 실제로 실행해 본다. 점검 순서와 코멘트 초안은 `chagok-pr-review` 스킬이나 `chagok-pr-reviewer` 에이전트로 만들 수 있다(승인·코멘트 게시는 사람이). 작성자도 PR을 올리기 전에 같은 에이전트로 스스로 점검한다.
- 자동 검사(`pr-check`, 코드 레포는 빌드 CI도)가 실패(❌)한 PR은 **머지하지 않는다.** GitHub가 자동으로 막지 않으므로, 머지하는 사람이 ✅를 확인한다. ❌인데 머지된 것을 발견하면 형상관리자가 되돌리거나(`git revert`) 고치는 PR을 바로 요청한다.

### GitHub Free 운영 — 무엇이 자동으로 막히고, 무엇을 사람이 지키나

| 구분 | 내용 |
|---|---|
| GitHub가 실제로 하는 것 | 검사를 돌려 PR에 ✅/❌ 표시, 라벨 자동 부착, 이슈 자동 클로즈, 머지된 브랜치 삭제, CODEOWNERS 리뷰 요청 |
| GitHub가 막지 **않는** 것 (사람이 지킴) | ❌인 PR 머지, `main`·`develop` 직접 push, 확인 없는 머지, `feature/` PR의 동결 후 머지 |
| 지키는 사람 | 머지하는 사람: ✅와 확인 여부를 보고 머지. 형상관리자: 매일 `develop` 커밋 목록과 Actions 결과를 보고, 규칙을 어긴 머지를 되돌리거나 수정 PR을 요청. `main`은 형상관리자만 머지 |
| 선택 사항 | 공개 레포라 Free에서도 브랜치 보호·필수 검사를 켤 수 있다. 켜면 위의 일부가 자동으로 막힌다. 켜지 않아도 이 문서의 규칙은 같다 |

### 자동으로 일어나는 일

| 무엇 | 레포 | 언제 |
|---|---|---|
| 브랜치명·PR 제목·`Closes #` 검사 | 세 레포 | PR 생성·수정 |
| 커밋·PR 본문의 AI 공동 작성자 표기 차단 | 세 레포 | PR 생성·수정 |
| 관문 2 이후 `feature/` 차단 (`FEATURE_FREEZE`) | 세 레포 | PR 생성·수정 |
| **비밀값·민감 파일**(`.env`, 키 파일, 토큰 형태, 설정 파일의 평문 비밀번호) | 세 레포 | PR 생성·수정 (❌) |
| **DB·Flyway 규칙**: 이미 있는 마이그레이션 수정·삭제, 이름 규칙(`V{번호}__{설명}.sql`), `schema.sql`·`data.sql`, `src/main/resources`의 마이그레이션 밖 SQL, `ddl-auto`가 validate가 아님, `sql.init.mode` always | backend | PR 생성·수정 (❌) |
| 마이그레이션 변경인데 문서 PR 링크 없음 | backend | PR 생성·수정 (❌) |
| Controller·DTO·ErrorCode 변경인데 문서 PR 링크 없음, cycle 변경인데 테스트 없음, 도메인 3개 이상 → 경고 | backend | PR 생성·수정 |
| `features/*/api·types` 변경인데 문서 PR 링크 없음, 새 페이지, feature 3개 이상 → 경고 | frontend | PR 생성·수정 |
| 기준 문서 변경인데 13 changelog 없음, 공용 AI 설정·규칙 변경 → 경고 | docs | PR 생성·수정 |
| 패키지 주인에게 리뷰 요청 (CODEOWNERS) | 세 레포 | PR 생성 |
| Gradle Wrapper 확인·검증 → 빌드 + DB 없는 테스트(ArchitectureTest 등) → DB 테스트(빈 MySQL에 Flyway 적용·앱 기동). 결과는 작업 요약과 리포트 파일로 남김. 검사 대상이 아직 없는 규칙은 "건너뜀(검증 안 됨)"으로 따로 표시 | backend | 모든 PR, develop·main push (❌) |
| `npm ci`·lint(ESLint 경계 규칙)·빌드(타입 검사 포함) | frontend | 모든 PR, develop·main push (❌) |
| 영역 라벨(`backend`/`frontend`/`db`/`docs`/`ci`), 유형 라벨(`feature`/`fix`) | 세 레포 | PR 생성 |
| `review-me` 라벨 (표시용, 자동 리뷰 없음) | 코드 레포 | backend: cycle·global·마이그레이션, frontend: `src/app`·`src/shared/api` 변경 |
| `release` 라벨 → CodeRabbit 자동 리뷰 1회 | 코드 레포 | develop → main PR |
| 이슈 자동 클로즈 · 보드 완료 처리 | 세 레포 | develop 머지 |

(❌) = 실패로 표시되는 **차단 기준**. 나머지 경고는 리뷰 때 확인하는 **경고 기준**이다.

| 차단 기준 (❌, 머지하지 않음) | 경고·리뷰 기준 (확인 후 판단) |
|---|---|
| 컴파일·빌드 실패, 필수 테스트 실패, ArchitectureTest 실패, 비밀값·민감 파일, DB·Flyway 규칙 위반, 형식 검사(브랜치·제목·`Closes #`·AI 표기·동결) | 08 명세 불일치 의심(문서 PR 링크 없음), 문서 갱신 누락, 테스트 부족, 네이밍·스타일, 중복 코드, 선택적 리팩터링 |

자동 검사로 찾을 수 있는 것만 차단한다. 검사가 통과해도 "보안 문제 없음", "명세와 일치"가 보장되지는 않는다(리뷰와 `chagok-contract-checker`로 확인).

## 6. 릴리스 (형상관리자: develop → main, 세 레포 함께)

| 시점 | 태그 | 범위 |
|---|---|---|
| 중간 점검 | `v0.5-midcheck` | P0-핵심 |
| MVP 점검 | `v0.8-mvp` | P0 전체 + P1 (MVP 완성) |
| 관문 2 (기능 동결) | `v0.9-freeze` | MVP 점검 이후 변경분 (P2 포함 시 그 기능) |
| 발표 | `v1.0-demo` | 동결 이후 수정분 |

**세 레포에 같은 날 같은 태그를 단다.** 태그 이름이 같으면 "이 시점의 문서·백엔드·프론트"를 한 번에 맞춰 받을 수 있다.

순서:
1. `chagok-release-check` 스킬로 세 레포를 함께 점검한 보고서 작성 (완료 정의, 열린 P0·P1 이슈, 범위, 문서·코드 대조, 세 레포 develop을 함께 띄운 시연)
2. `chagok-docs`부터 `develop → main` PR. 문서 릴리스 PR은 CodeRabbit 없이 형상관리자가 확인 후 머지
3. `chagok-backend`·`chagok-frontend` 릴리스 PR → `release` 라벨이 자동으로 붙고 CodeRabbit이 자동 리뷰 1회 (리뷰가 시작되지 않으면 PR에 `@coderabbitai full review` 댓글). 이후 push에는 자동 리뷰가 없다. 다시 보려면 `@coderabbitai review`
4. CodeRabbit 지적을 분류한다 (아래 표)
5. 수정할 것은 `fix/` 브랜치로 해당 레포 develop에 머지 → 릴리스 PR에 자동 반영
6. 모든 지적에 처리 결과(수정·미룸·반영 안 함)를 답글로 남기고 해결 처리. CodeRabbit 리뷰는 머지 차단 조건이 아니며, 최종 판단은 형상관리자가 한다
7. 세 레포 main을 함께 받아 빈 DB에서 시나리오 A·B와 격리 시연 확인 후 **Merge commit**으로 머지
8. 세 레포에 같은 태그 생성 → GitHub Release의 "Generate release notes"로 변경 목록 자동 작성

CodeRabbit은 지적만 하고 머지하지 않는다. 브랜치 삭제와 이슈 close는 팀원 PR이 develop에 머지될 때 일어나고, 릴리스 PR에서는 둘 다 일어나지 않는다(develop은 기본 브랜치라 삭제되지 않음).

### CodeRabbit 운영 — 릴리스 PR 중심

| 대상 | 처리 |
|---|---|
| 일반 PR → develop | 자동 리뷰 없음 |
| 중요·복잡한 PR → develop (`review-me` 라벨 등) | 작성자·확인자가 필요할 때 PR 댓글 `@coderabbitai review` |
| develop → main | `release` 라벨로 자동 리뷰 1회 |
| 추가 push | 자동 증분 리뷰 없음 |

- 모든 제안을 필수 수정으로 다루지 않는다. 실제 오류·보안·데이터 손상 위험·정비소 격리 위반을 먼저 고친다.
- 설정: 코드 레포의 `.coderabbit.yaml`(공식 스키마 v2 `reviews.auto_review`).

### CodeRabbit 지적 분류

| 분류 | 기준 | 처리 |
|---|---|---|
| 수정 | 정비소 격리(shop_id) 누락, cycle 규칙 위반, 실행 오류, 보안, 08 명세와 불일치 | `fix/`로 develop에 고친 뒤 반영 |
| 미룸 | 이름 짓기, 리팩터링, 작은 성능 개선 등 시연에 영향 없는 것 | "관문 2 이후 검토" 답글 후 해결 처리 |
| 반영 안 함 | 기획 결정과 충돌 (차량번호 중복 차단, 쓰지 않는 기능 추가 등) | 근거 문서를 답글로 남기고 해결 처리 |

- 판단: 형상관리자 1차 분류, 주기 계산은 도메인관리, 마이그레이션·시드는 DB관리. 수정은 그 코드를 쓴 담당자.
- 기록: `chagok-docs/docs/etc/DEV_REVIEW_CodeRabbit.md`에 한 줄씩 (레포 이름 포함).
- 시간: 릴리스 당일 오전 리뷰 → 점심 전 분류 → 오후 수정·머지.
- 수동 리뷰(develop 단계)도 같은 분류를 쓰고, 판단은 작성자와 확인자가 한다.

관문 2 이후에는 `FEATURE_FREEZE=true`로 바꾼다(Organization 변수 하나, 안 되면 세 레포 각각). 그때부터 `feature/` 브랜치 PR은 pr-check가 실패(❌)한다. 형상관리자는 동결 후 `feature/` PR이 머지되지 않게 확인한다.

## 7. 문서와 코드 맞추기

**기획이 기준이고, 기획은 `chagok-docs`에만 있다.** 관문 1 이후 명세를 바꾸려면:

1. `chagok-docs`에 `결정` 이슈 (무엇을 왜)
2. `chagok-docs`에 문서 PR: 문서 수정 + `13_changelog` 한 줄
3. 코드 레포에 코드 PR: 본문 「문서 PR」 칸에 2의 링크
4. **문서 PR을 먼저(또는 같은 날) 머지한다.** 코드가 먼저 develop에 들어가 문서와 다른 시간을 만들지 않는다.

| 문서 (chagok-docs) | 코드 | 규칙 |
|---|---|---|
| 07 ERD | backend `src/main/resources/db/migration/V*.sql`, `db/seed/demo_seed.sql`, Entity | 마이그레이션이 바뀌면 07 문서 PR 링크 필수 (pr-check ❌). 이미 있는 버전 파일은 고치지 않는다 |
| 08 API | backend Controller·DTO·ErrorCode, frontend `features/*/api.ts`·`types.ts` | 바뀌면 08 문서 PR (pr-check가 경고). **JSON 예시 블록도 같이**. 반대쪽 담당에게 PR 링크 공유 |
| 04 주기 규칙 | backend `domain/cycle`, 테스트 T1~T17(04) | 규칙을 바꾸면 테스트 기대값부터. 도메인관리 리뷰 필수 |
| 격리 규칙 | backend 모든 정비소 데이터 조회 | 테스트 X1~X10. 실패하면 머지 금지 |
| 09 화면 | frontend `src/pages` | 화면 ID와 페이지 1:1 |
| 00 범위 | 존재하는 기능 전체 | 차례가 오지 않은 단계(MVP 점검 전 P2 등)·Non-goal 기능은 빈 화면·버튼·API·테이블로도 만들지 않음 |

**08 API마다 JSON 예시 블록을 둔다.** 08이 API의 유일한 원본이라 예시도 08 안에만 둔다(별도 예시 파일 없음, 코드 레포에도 복사하지 않음).

- 요청 본문이 있는 API는 요청 예시, 모든 API는 성공 응답 예시(공통 응답으로 감싼 전체 모양)를 ```` ```json ```` 블록으로 둔다.
- 필드 이름·enum 값·날짜 형식은 예시와 표가 글자까지 같아야 한다. 표만 고치고 예시를 두고 가지 않는다.
- 값은 시드 데이터에서 가져온다(시연 때 실제로 보이는 값). 에러 응답 예시는 공통 절에 한 번만.
- 프론트 `types.ts`와 백엔드 연결 전 목업은 이 JSON을 기준으로 만든다.

영향 범위가 헷갈리면 `chagok-spec-sync` 스킬을 쓴다. 프론트와 백엔드가 처음 연결될 때·기능 묶음이 끝났을 때는 같은 스킬의 모드 C(API 계약 점검: 08 ↔ Controller·DTO ↔ `features/*/api.ts`·`types.ts`)를 돌린다. 세 레포가 작업 폴더에 함께 있어야 한다. 시드는 `chagok-seed-data`로 07 시드표에 맞춰 만든다. 코드 쪽 규칙(어느 패키지에 무엇을 두나)은 `CONVENTIONS.md`.

## 8. 패키지 주인 (CODEOWNERS)

**도메인 패키지 하나 = 주인 1명.** 주인은 그 패키지의 `api` 계약을 관리하고, 다른 사람이 그 패키지를 건드리는 PR을 리뷰한다. 레포마다 `.github/CODEOWNERS`에 적어 두면 GitHub이 자동으로 주인에게 리뷰를 요청한다.

| 레포 | 경로 | 주인 |
|---|---|---|
| backend | `global/`, `build.gradle`, `application.yaml` | 백엔드 기반 담당 |
| backend | `src/main/resources/db/` (마이그레이션), `db/seed/` (시연 시드) | DB관리 |
| backend | `domain/cycle` | 구현 담당 + 도메인관리 리뷰 |
| backend | `domain/<그 밖의 도메인>`, `screen/` | 도메인별 구현 담당 |
| frontend | `src/app`, `src/shared`, `eslint.config.js` | 프론트 기반 담당 |
| frontend | `src/features/<도메인>`, `src/pages` | 도메인별 구현 담당 |
| docs | `docs/` (07은 DB관리, 04는 도메인관리 함께) | PM |
| 세 레포 | `.github/`, `.claude/`, `CLAUDE.md`, (docs) `CONTRIBUTING.md`·`CONVENTIONS.md`·`scripts/` | 형상관리 |

이름은 결정 14(구현 담당) 후 CODEOWNERS에 채운다. 사람 팀원 계정만 쓴다(AI 계정 금지). 남의 패키지 `api`에 메서드가 필요하면 주인에게 이슈로 요청하거나, 직접 추가하고 주인 리뷰를 받는다.

## 9. 단계별 규칙

| 시점 | 규칙 |
|---|---|
| 기획·설계 | `chagok-docs` 작업 중심. 결정은 `결정` 이슈로 |
| 관문 1 | 세 레포 태그 `v0.1-gate1`. 초기 구성(B-0)은 완료 상태. `기반` 이슈 3개(백엔드 공통 기반·프론트 공통 기반·V1 마이그레이션/시연 시드)로 코드 시작 |
| 구현 시작 직후 | 로그인 → 고객 등록 → 정비 기록 → 대상 목록 → 예약이 이어진 뼈대를 두 코드 레포 develop에 |
| 매일 마감 전 | 두 코드 레포 develop을 받아 함께 띄우고 빈 DB에서 실행 확인 (대상 목록이 시드의 기대 상태표와 같은지) |
| 중간 점검 | 첫 릴리스. 미달이면 P0-핵심 보강 먼저, P0-나머지·P1 이슈 열지 않음 |
| MVP 점검 | P0·P1 완료 정의 + T·X 테스트 + 시연. 릴리스 `v0.8-mvp`. 통과 후에만 P2 `결정` 이슈 |
| P2 | 한 번에 하나, A 묶음부터. 하나를 완료 정의까지 마친 뒤 다음 |
| 관문 2 | 기능 동결. `FEATURE_FREEZE=true`. 이후 `fix/`·`docs/`만. 완료 정의를 못 채운 P2는 빼고 시연 |
| 발표 직전 | 기능 추가 금지. 통합 시연·버그 수정만. "시연에서 하지 말 것" 메모 작성 |
| 발표 | 세 레포 `main`(`v1.0-demo`)으로 다른 팀원 PC에서 시연 |

## 10. 라벨

| 종류 | 라벨 | 붙이는 쪽 |
|---|---|---|
| 단계 | `P0-핵심` `P0-나머지` `P1` `P2` `기반` | 이슈 작성자 |
| 이슈 유형 | `bug` `결정필요` `docs` | 템플릿 |
| PR 영역 | `backend` `frontend` `db` `docs` `ci` | 자동 |
| PR 유형 | `feature` `fix` | 자동 (브랜치 이름) |
| 리뷰 | `review-me` (중요 변경 표시, 필요하면 `@coderabbitai review`), `release` (릴리스 PR, CodeRabbit 자동 리뷰) | 자동, `review-me`는 손으로도 가능 |

`bash scripts/setup-labels.sh OneMonthproJect`로 세 레포에 한 번에 만든다.

---

## 부록: 초기 설정 체크리스트

레포 생성·첫 커밋은 @하다가, 이후 관리는 형상관리자가 맡는다. Organization 안의 레포라 소유권을 옮길 필요 없이 **형상관리자에게 세 레포 Admin 권한**을 주면 된다.

**Organization (한 번)**
- [ ] 레포를 만들 계정에 레포 생성 권한(Owner 또는 Member privileges의 레포 생성 허용)
- [ ] 팀원 초대. 형상관리자는 Owner 또는 세 레포 Admin
- [x] 레포 공개 범위: **공개 레포**로 확정 (Organization `OneMonthproJect`). GitHub Free 기준으로 운영한다(브랜치 보호는 선택). 공개이므로 비밀값(`.env`, DB 비밀번호, JWT 키)은 절대 커밋하지 않는다
- [ ] Actions 변수 `FEATURE_FREEZE=false` (Organization 변수로 세 레포에 공유)
- [ ] Projects 보드 1개(Organization 소유)에 세 레포 연결, 기본 워크플로(이슈 추가 → Todo, PR 연결 → In Progress, 닫힘 → Done) 켬
- [ ] CodeRabbit GitHub App 설치, `chagok-backend`·`chagok-frontend`만 허용

**레포마다 (세 개 모두)**
- [ ] `develop` 브랜치 생성 → 기본 브랜치 `develop`
- [ ] Pull Requests: Squash merge와 Merge commit만 허용, Rebase 끔
- [ ] "Always suggest updating pull request branches" 켬, "Automatically delete head branches" 켬
- [ ] (선택) 브랜치 보호·필수 상태 검사(`pr-check`, `backend-ci`, `frontend-ci`). 켜지 않아도 운영 규칙은 같다(5장 「GitHub Free 운영」)
- [ ] `main` 머지는 형상관리자만 한다 (팀 규칙)
- [ ] backend: Gradle Wrapper가 커밋돼 있는지 (`backend-ci`의 wrapper 작업이 확인)
- [ ] 마일스톤 5개: 관문 1 / 중간 점검 / MVP 점검 / 관문 2 / 발표
- [ ] 결정 14 후 `.github/CODEOWNERS` 채우고 주석 해제 (리뷰 요청이 자동으로 간다. 승인 강제는 하지 않음)

**그 밖**
- [ ] `bash scripts/setup-labels.sh OneMonthproJect` (세 레포 라벨)
- [ ] 코드 레포에 `.claude/settings.json`·`CLAUDE.md`가 커밋돼 있고, `.claude/rules·skills·agents`는 `.gitignore`로 빠져 있는지
