---
name: chagok-issue-writer
description: 차곡 프로젝트에서 04 기능명세서의 기능 ID(F-AUTH, F-CUS, F-MNT, F-CYC, F-TGT, F-RSV 등)를 받아 GitHub 이슈 제목·본문·라벨·마일스톤을 만든다. "이슈 만들어줘", "F-CUS 이슈", "백로그를 이슈로 쪼개줘", "기반 이슈", "12 백로그 채워줘"처럼 이슈나 작업 단위를 만드는 요청이면 기능 ID가 명시되지 않아도 이 스킬을 사용한다.
---

# 차곡 이슈 작성

> 경로 표기: `docs/…`·`CONVENTIONS.md`·`CONTRIBUTING.md`는 `chagok-docs` 기준(코드 레포에서는 `../chagok-docs/…`), `chagok-backend/…`·`chagok-frontend/…`는 각 레포 루트 기준이다(`.claude/rules/ai-rules.md`「작업 폴더와 경로」). 필요한 레포가 작업 폴더에 없으면 지어내지 말고 읽지 못한 것으로 보고한다.

기능 하나를 하루 안에 머지할 수 있는 이슈로 쪼개고, 구현 담당이 다른 문서를 뒤지지 않아도 되도록 필요한 ID와 규칙을 이슈 본문에 모은다. 이슈 본문은 `chagok-issue-coder`의 입력이 되므로 ID가 정확해야 한다.

## 1. 읽을 문서

| 문서 | 무엇을 가져오나 |
|---|---|
| `docs/00_PRD_*` | 단계(P0-핵심 / P0-나머지 / P1 / P2), MVP = P0 + P1, Non-goal, 결정 D-xx |
| `docs/04_features_*` | 기능 ID, 입력·출력, 완료 기준, 권한, 주기 규칙, 테스트 T-xx |
| `docs/07_data_*` | 관련 테이블·컬럼·제약, 격리 규칙 I-xx, 필요한 시드 |
| `docs/08_api_*` | 관련 API 번호·메서드·경로, 에러 코드, 격리 테스트 X-xx |
| `docs/09_screens_*` | 관련 화면 ID S-xx |
| `docs/12_backlog_*` | 이미 만든 이슈, 담당 방식(레이어 단위 / 기능 단위), 의존성 |
| `docs/13_changelog_*`, 닫힌 `결정` 이슈 | 범위·ID가 바뀐 결정 (본문보다 우선) |
| `CONTRIBUTING.md` | 이슈 규칙(3장), 단계별 규칙(9장) |
| `chagok-backend`·`chagok-frontend`의 `.github/ISSUE_TEMPLATE/feature.md` | 이슈 본문 칸 순서 (출력이 이 칸을 그대로 채운다. 백엔드·프론트 칸이 조금 다르다) |
| `chagok-docs/README.md` 마일스톤 표, 마일스톤 | 지금 단계, 마일스톤 이름 |
| `CONVENTIONS.md` | 패키지 구조(2장), 의존 방향(3장), 변경 검증표(9장) |
| 코드 레포의 `.github/CODEOWNERS` | 패키지 주인 = 담당 후보 |

이미 GitHub 이슈가 있는지 `gh issue list --repo OneMonthproJect/chagok-backend --search "F-XXX"`(프론트도 같이)로 확인할 수 있으면 확인한다.

## 2. 쪼개는 규칙

- 이슈 하나 = 하루 안에 PR 하나로 머지할 크기가 기본. 커지면 같은 이슈로 `Refs` 부분 PR을 여러 개 올릴 수 있으므로, PR을 나누려고 이슈를 새로 쪼개지 않는다(D-71). 이슈를 나누는 기준은 아래의 패키지·화면 단위다.
- **이슈 하나는 백엔드 도메인 패키지 하나(또는 screen 하나, 프론트 화면 하나)를 본체로 한다.** 다른 도메인은 `api` 메서드 추가 정도만 허용한다. 본체가 둘 이상이면 이슈를 나눈다. 여러 도메인을 한 번에 건드리는 작업이 도메인 사이 결합을 만들기 때문이다.
- 이슈마다 "건드리는 패키지"를 적고 CONVENTIONS 3장 의존 방향 표와 맞는지 확인한다. 표에 없는 방향이 필요하면 이슈를 만들지 말고 설계 문제로 보고한다.
- 담당(Assignee)은 반드시 정한다(CONTRIBUTING 3장). CODEOWNERS의 패키지 주인이 1순위, 비어 있으면 `❓ 담당`으로 두고 마지막에 모아 묻는다.
- **레포가 나뉘어 있으므로 API와 화면은 항상 다른 이슈다.** 백엔드 이슈는 `chagok-backend`에, 프론트 이슈는 `chagok-frontend`에 만들고, 서로 「짝 이슈」 칸에 링크한다. 화면 이슈의 선행에 API 이슈를 둔다(08 JSON 예시로 목업을 먼저 만들 수 있으면 선행 없이 병행 가능).
- 담당 방식(같은 사람이 짝 이슈 둘을 맡을지, 나눠 맡을지)은 12 백로그(결정 14)를 따른다. 정해져 있지 않으면 사용자에게 묻는다.
- 순서: `기반` → cycle → 고객·차량 → 정비 기록 → 재점검 대상·방문 중 안내 → 예약·날짜별 목록·방문 완료 → (M2 통합 검증) → P0-나머지 → P1 → (M3 MVP 검증).
- MVP = P0 + P1. P1 이슈는 사용자가 "M2 통합 검증 통과"를 확인해 주기 전에는 만들지 않는다.
- P2 이슈는 만들지 않는다(D-70, M3 MVP 검증을 통과한 뒤에도 같다). 요청이 오면 scope-guard로 넘긴다.
- 00의 Non-goal 기능은 이슈를 만들지 않는다. 요청받으면 이유를 말하고 멈춘다.
- 기반 이슈 세트를 요청받으면 CONTRIBUTING 9장의 3개를 만든다(라벨 `기반`, 마일스톤 M2 통합 검증):
  1. (`chagok-backend`) 백엔드 생성 + `global`(SecurityConfig 기본 거부, LoginStaff, ErrorCode·전역 처리기(표준 예외 포함), ApiResponse, Clock, RequestIdFilter, OSIV off) + `ArchitectureTest` + `EndpointGuardTest` (`chagok-backend/README.md`「지금 상태」)
  2. (`chagok-frontend`) 프론트 생성 + `shared`(client.ts, StatusBadge, Layout) + ESLint 경계 규칙 (`chagok-frontend/README.md`)
  3. (`chagok-backend`) Flyway `V1__init.sql`(07 기준) + 시연 시드 `db/seed/demo_seed.sql` (`chagok-seed-data`) — DB 담당자
  - 각 도메인의 빈 `api` 패키지와 계약 interface 초안(팀 합의용, 구현 없음)은 CONTRIBUTING 9장에 없는 4번째 이슈다. 팀이 쓰기로 정했다고 사용자가 확인해 줄 때만 만든다. 만들면 쓰지 않을 메서드를 미리 넣지 않는다.

## 3. ID 규칙

- 기능 ID·화면 ID·API 번호·테이블명·테스트 ID는 문서에 있는 그대로 쓴다.
- 문서에서 찾지 못한 것은 지어내지 않고 `❓(문서에 없음)`으로 둔 뒤 마지막에 모아서 보고한다.
- 문서끼리 ID가 다르면 `.claude/rules/source-of-truth.md` 순서로 판단한다(예: 09·10의 ID가 04와 다르면 04). 기준 문서(00·04·07·08)끼리 다르면 그 기능의 이슈를 만들지 말고 ❓로 보고하고 `결정` 이슈를 제안한다.

## 4. 출력 형식

이슈마다 아래 형식을 그대로 쓴다. 칸 이름과 순서는 `.github/ISSUE_TEMPLATE/feature.md`와 같고, 작업 목적·범위·주의를 더한 것이다. `chagok-issue-coder`가 이 칸 이름으로 읽는다.

````markdown
### 제목
[F-XXX] 무엇을 한다

### 레포 / 라벨 / 마일스톤 / 담당
chagok-backend · P0-핵심 · M2 통합 검증 · @담당 (모르면 ❓ 담당)
(단계 라벨 하나는 필수, 마일스톤은 M1 설계 확정 / M2 통합 검증 / M3 MVP 검증 / M4 기능 동결 / M5 최종 시연 중 하나. P0 → M2 통합 검증·M3 MVP 검증, P1 → M3 MVP 검증. P2·Non-goal은 이슈를 만들지 않는다 — D-70)

### 본문
## 기능 ID / 단계
- 기능 ID: F-XXX
- 단계: P0-핵심

## 작업 목적
이 기능이 시나리오 A·B의 어느 단계를 위한 것인지 한두 문장.

## 범위
- 포함:
- 포함하지 않음: (다음 이슈, 짝 이슈, 다음 단계로 미루는 것을 명시)

## 건드리는 패키지 (CONVENTIONS 2장·7장)
- 본체: domain/xxx (백엔드) 또는 features/xxx · pages/Sxx (프론트)
- api 추가: xxx.api.메서드 (주인 리뷰)

## 연결
- 화면: S-xx
- API: (08 번호) METHOD /path
- 테이블: (07)
- 규칙 근거: 04 §… / 05 §…
- 짝 이슈: OneMonthproJect/chagok-frontend#번호 (또는 chagok-backend)
- 결정 이슈 (명세 변경 시): OneMonthproJect/chagok-docs#번호

## 할 일
- [ ] 구현:
- [ ] 시연 시드: db/seed/demo_seed.sql에 … (백엔드, DB 담당자)
- [ ] 테스트: 정상·오류·권한·경계 (테스트 ID)
- [ ] 테스트: T-xx / X-xx

## 완료 정의
- [ ] 화면 ↔ API 연결
- [ ] 공통 응답·예외 처리
- [ ] 시드 데이터
- [ ] 두 코드 레포 develop을 함께 띄워 빈 DB 실행 확인
- [ ] (주기·격리 관련) 로직 테스트
- [ ] 기능별 확인 항목: (04 완료 기준에서 옮김)

## 선행 이슈
#번호 (없으면 없음)

## 주의
- 다른 도메인은 api로만 (CONVENTIONS 1장)
- 공용 파일(global, db/ 마이그레이션)을 건드려야 하면 주인과 파일명
- 명세(07·08·09)가 바뀌어야 하면 `chagok-docs` 문서 PR이 먼저
- 격리: 로그인 계정의 shop_id로만 조회
````

여러 이슈를 만들면 마지막에 요약 표를 붙인다. 12 백로그 표(기능 ID ↔ 이슈 번호 ↔ 담당 ↔ 선행 이슈)에 그대로 옮길 수 있게 쓴다. 이슈 번호는 GitHub에 올린 뒤 채운다.

`| 순서 | 기능 ID | 레포 | 이슈 | 제목 | 단계 | 담당 | 짝 이슈 | 선행 |`

## 5. GitHub에 올리기

사용자가 원하면 이슈마다 명령을 준다. 사용자 확인 없이 직접 실행하지 않는다.

```bash
gh issue create --repo OneMonthproJect/chagok-backend --title "[F-XXX] …" --label "P0-핵심" --milestone "M2 통합 검증" \
  --assignee <GitHub아이디> --body-file issue-F-XXX-be.md
```

`gh issue create`는 `.claude/settings.json`이 실행 전에 확인을 묻는다. 담당이 ❓인 이슈는 `--assignee` 없이 올리고 사람이 지정한다.
