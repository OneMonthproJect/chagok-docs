# 초기 CI 기준 보고서 (2026-11-22)

> D-49 반영 직후 세 레포의 GitHub Actions·로컬 검사 결과와 협업 자동화 상태. 이후 CI 결과를 비교하는 기준점

상태: 작성됨 (2026-11-22), 같은 날 초기 릴리스(develop → main) 결과 반영(H장) — 이 날짜의 실제 실행 결과만 적는다. 이후 결과는 새 보고서나 `TEST_테스트명세서.md`에 남긴다
근거: GitHub Actions 실행 기록(아래 URL), 로컬 실행 로그, D-46·D-47·D-49(00 결정표), CONTRIBUTING 5장·부록

**이 문서의 PASS는 "그 검사가 실제로 실행되어 성공했다"는 뜻이다. 기능 완성이나 관문 1 통과를 뜻하지 않는다.**

## 0. 상태 표기

| 표기 | 뜻 |
|---|---|
| PASS | 실제로 실행되어 성공 |
| FAIL | 실제로 실행되어 실패 |
| SKIPPED | 실행됐지만 검사 대상이 없어 건너뜀 → **검증 안 됨** |
| NOT RUN | 이번에 실행하지 않음 |
| BLOCKED | 선행 조건이 없어 실행할 수 없음 |
| NOT VERIFIED | 결과를 확인할 수 없음 (권한·환경 부족 등) |

「GitHub CI」와 「로컬」은 따로 적는다. 로컬 성공을 CI 성공으로 세지 않는다.

---

## A. 환경 및 저장소

| 항목 | 값 |
|---|---|
| GitHub Organization | `OneMonthproJect` (GitHub Free, 브랜치 보호·ruleset 없음 — D-46) |
| 검증 날짜 | 2026-11-22 (UTC 03:20~03:40 실행분) |
| 기본 브랜치 | 세 레포 모두 `main` (D-49) |
| 통합 브랜치 | 세 레포 모두 `develop` |

| 레포 | develop 최신 커밋 (D-49 머지 시점) | main 커밋 (릴리스 전, 릴리스 후는 H장) |
|---|---|---|
| chagok-docs | `4917e9d350fac52cb7afbb8ee19ac196b36838d5` — [#1] D-49 … (#2) | `a892001` 초기 커밋 |
| chagok-backend | `00b360488660b803f3d99b520ff12640dcb2403d` — [#1] D-49 … (#2) | `c7706c6` 초기 커밋 |
| chagok-frontend | `1351f92a3bfa0ad0dd29b8e1a38b099505255acb` — [#1] D-49 … (#2) | `d73ef4c` 초기 커밋 |

| 구분 | GitHub CI | 로컬 (Windows 11) |
|---|---|---|
| Java | Temurin 21 (`setup-java`, 실행 시 21.0.13) | OpenJDK 21.0.12.1 |
| Spring Boot | 4.1.2 (`build.gradle`) | 같음 |
| Gradle | Wrapper 9.8.2 | 같음 (Wrapper) |
| Node.js | 22 (`setup-node`, 실행 시 v22.23.5) | **v24.20.0** / npm 11.19.0 — CI와 메이저 버전 다름 |
| React / Router | react 19.1.0, react-router-dom 7.6.0 | 같음 (lockfile) |
| Vite / TypeScript | vite 6.3.5, typescript 5.8.3 | 같음 |
| MySQL | `mysql:8.0` 서비스 컨테이너 (db-test 작업) | 사용 안 함 |
| Flyway | `spring-boot-starter-flyway` + `flyway-mysql`, `locations: classpath:db/migration`, `ddl-auto: validate` | — |
| 마이그레이션 | **버전 파일 0개** (`db/migration/` 비어 있음, V1은 07 확정 후 DB 담당 — D-41) | — |

---

## B. GitHub Actions 결과

### B-1. 워크플로 목록

| 레포 | 워크플로 | 트리거 |
|---|---|---|
| 세 레포 | `pr-check` | `pull_request` opened·edited·synchronize·reopened |
| 세 레포 | `labeler` | `pull_request_target` |
| 세 레포 | `issue-close` (D-49 신규) | `pull_request` closed·labeled, base `develop` |
| backend | `backend-ci` (wrapper → build → db-test) | `pull_request`·`push` (develop, main) |
| frontend | `frontend-ci` (build) | `pull_request`·`push` (develop, main) |

### B-2. D-49 PR #2 (머지 직전 최신 커밋 기준)

| 레포 · head | 작업 | 결과 | URL |
|---|---|---|---|
| docs `554b0f7` | label | PASS | https://github.com/OneMonthproJect/chagok-docs/actions/runs/44978615869 |
| | pr-check | PASS | https://github.com/OneMonthproJect/chagok-docs/actions/runs/44978646644 |
| backend `e986fb9` | wrapper · build · db-test | PASS · PASS · PASS | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44978624321 |
| | label | PASS | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44978620867 |
| | pr-check | PASS | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44978649179 |
| frontend `a29b584` | build | PASS | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44978626751 |
| | label | PASS | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44978625233 |
| | pr-check | PASS | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44978652896 |

### B-3. develop 머지 후

| 레포 | 워크플로 (이벤트) | 결과 | URL |
|---|---|---|---|
| docs | issue-close (labeled, 머지 전) | SKIPPED — 조건(`merged == true`) 불충족, 설계대로 | https://github.com/OneMonthproJect/chagok-docs/actions/runs/44980262575 |
| docs | issue-close (closed, 머지) | PASS — Issue #1 닫음 | https://github.com/OneMonthproJect/chagok-docs/actions/runs/44980267517 |
| docs | (push 워크플로 없음) | — | — |
| backend | issue-close (labeled) | SKIPPED — 설계대로 | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44980603481 |
| backend | issue-close (closed) | PASS — Issue #1 닫음 | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44980608471 |
| backend | backend-ci (push develop `00b3604`) | PASS (wrapper·build·db-test) | https://github.com/OneMonthproJect/chagok-backend/actions/runs/44980607963 |
| frontend | issue-close (labeled) | SKIPPED — 설계대로 | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44980826446 |
| frontend | issue-close (closed) | PASS — Issue #1 닫음 | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44980829916 |
| frontend | frontend-ci (push develop `1351f92`) | PASS | https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44980829784 |

여기서 SKIPPED는 "검사 대상 없음"이 아니라 워크플로 조건에 따라 job이 건너뛰어진 것이다(머지 전 라벨 부착 → 닫지 않음이 기대 동작).

---

## C. 백엔드 검증

| 항목 | GitHub CI | 로컬 | 비고 |
|---|---|---|---|
| Gradle Wrapper 존재·공식 jar | PASS (`wrapper` 작업, `wrapper-validation`) | — | |
| `./gradlew build` | PASS | PASS (`BUILD SUCCESSFUL in 18s`) | 컴파일 + DB 없는 테스트 |
| ArchitectureTest | 19건 중 **실행 1 · SKIPPED 18** · 실패 0 | 같음 (1 · 18 · 0) | 아래 설명 |
| `./gradlew dbTest` | PASS (1건: `ChagokApplicationTests.contextLoads`) | NOT RUN — 로컬 MySQL을 쓰지 않음 | |
| MySQL 서비스 | 사용 (`mysql:8.0`, 일회용 계정) | 사용 안 함 | |
| Flyway | 실행됨 — `No migrations found`, `<< Empty Schema >>`, 마이그레이션 0건 | — | **스키마 검증 BLOCKED** (V1 없음) |

**ArchitectureTest SKIPPED 18건**: 사유는 모두 `Assumption failed: 검사 대상 클래스가 아직 없음 (…) → 이 규칙은 아직 검증되지 않음`. 도메인·Controller·Entity 코드가 아직 없기 때문이다. 실제로 실행되어 통과한 규칙은 `global은_domain과_screen을_모른다()` 1건뿐이다. 도메인 의존 방향 7건, api 경계 6건, Controller·Repository, cycle 순수성, 순환 없음, Entity setter, screen import 규칙은 **검증 안 됨**이다.

**DB 없이 지금 검증되는 범위**: 컴파일, Wrapper, `global` 의존 규칙 1건. DB 테스트는 "빈 MySQL에 Flyway가 붙고 앱이 기동된다"까지만 확인한다. 테이블·Entity `validate`·격리(X-xx)·통합 테스트는 V1 마이그레이션과 기능 코드가 생긴 뒤에야 의미가 있다.

---

## D. 프론트엔드 검증

| 항목 | GitHub CI (Node 22, ubuntu) | 로컬 (Node 24, Windows) |
|---|---|---|
| `npm ci` | PASS (npm 10.9.9, 193 packages, 10 vulnerabilities 표시) | PASS (193 packages, 10 vulnerabilities 표시) |
| ESLint (`npm run lint`) | PASS | PASS |
| TypeScript (`tsc --noEmit`) | PASS — `npm run build` 안에서 실행 (별도 단계 없음) | PASS (별도 실행 + build 안) |
| Vite production build | PASS (`built in 892ms`) | PASS (41 modules, `index-*.js` 220.03 kB / gzip 70.90 kB) |

**Windows 로컬 빌드 오류**: 이번 로컬 실행(Node 24.20.0)에서는 오류가 **재현되지 않았다**. 이전에 보고된 오류의 원문 로그는 이 보고서 작성 시 확보하지 못해 원인 비교는 NOT VERIFIED다. 다시 나면 원문을 `DEV_REVIEW_트러블슈팅.md`에 남긴다. 로컬 Node가 CI(22)와 메이저 버전이 다르다는 점도 차이 원인 후보다.

**로컬에서만 보인 경고**: npm 11의 `install-scripts … esbuild@0.25.12 (postinstall)` 경고. 빌드는 성공했다. CI(npm 10.9.9) 로그에는 이 경고가 없다.

### D-1. npm audit (10건: moderate 7 · high 3 · critical 0)

| 패키지 | 심각도 | 직접 의존 | 런타임 번들 포함 | 수정 버전 (audit 제안) |
|---|---|---|---|---|
| `react-router-dom` 7.6.0 → `react-router` 7.6.0 | high (2건) | 예 (`dependencies`) | **예** | react-router-dom 7.18.6 (같은 7.x, 고정 버전이라 "범위 밖"으로 표시됨) |
| `vite` 6.3.5 | high | 예 (`devDependencies`) | 아니오 — dev 서버·빌드 도구 | vite 6.4.6 |
| `typescript-eslint` 8.32.1 + `@typescript-eslint/*` 5개 + `minimatch` 9.0.9 | moderate (7건) | `typescript-eslint`만 직접 | 아니오 — lint 도구 | typescript-eslint 8.73.0 |

**영향 범위**
- 현재 배포 환경이 없고 기능 코드도 없어서 **실제로 노출된 곳은 없다.**
- `react-router` 권고 중 상당수는 SSR·framework 모드 대상이라, 이 프로젝트(SPA)에는 해당하지 않는 것이 섞여 있다. 그래도 `<Link>`·`useNavigate` open redirect와 XSS 권고는 클라이언트 라우팅에도 해당할 수 있으므로, 라우팅 코드(B-2)를 쓰기 전에 올리는 것이 안전하다.
- `vite` 권고는 개발 서버(`server.fs`, Windows 경로 우회 포함) 대상이라 개발자 PC에 영향을 준다.
- `eslint@9.27.0`은 지원 종료(deprecated) 경고가 나온다.

`npm audit fix --force`는 실행하지 않았다(의존성 변경은 별도 이슈·PR로).

---

## E. 협업 자동화 검증

| 항목 | 결과 | 근거 |
|---|---|---|
| main 기본 브랜치 | PASS | 세 레포 `default_branch=main` |
| develop 통합 브랜치 | PASS | D-49 PR이 모두 develop으로 머지, main 변경 없음 |
| Squash 커밋 = PR 제목 | PASS | `squash_merge_commit_title=PR_TITLE`, `message=BLANK`. 실제 develop 커밋이 제목 한 줄이고 본문(닫는 키워드) 없음 |
| 브랜치 자동 삭제 끔 | PASS | `delete_branch_on_merge=false`, 머지 후 head 브랜치 남아 있음 |
| Rebase merge 끔 (CONTRIBUTING 부록) | **FAIL (설정 불일치)** | 세 레포 `allow_rebase_merge=true`. 부록 체크리스트는 「Squash merge와 Merge commit만 허용, Rebase 끔」 |
| `done-verified` 라벨 | PASS (존재·부착) | 세 레포 라벨 있음. PR #2 3건에 사용자가 완료 정의를 확인한 뒤 지시해 부착 |
| issue-close: 머지 + 라벨 + 검사 ✅ → 같은 레포 이슈 닫음 | **PASS** | 세 레포 Issue #1 `closed (completed)`, github-actions 댓글, 로그 `✓ Closed issue …#1` |
| issue-close: 새 워크플로가 자신을 추가한 PR의 머지에서 실행 | PASS | `pull_request` 이벤트는 머지 커밋의 워크플로를 읽어 첫 머지에서도 실행됨 |
| issue-close: 머지 전 라벨 부착은 닫지 않음 | PASS | labeled 실행 3건 SKIPPED |
| issue-close: 중복 실행 안전 | PASS | 성공 run 3건 재실행(attempt 2) 모두 success. 닫기 호출·notice/warning 출력 없음, 새 댓글 없음, `closed_at` 그대로 |
| issue-close: 라벨 없이 머지 → 열어 둠 | NOT VERIFIED | 이번 PR은 라벨을 먼저 붙여 이 경로가 실행되지 않음 (로컬 시뮬레이션만) |
| issue-close: 머지 후 라벨 부착 → 그때 닫음 | NOT VERIFIED | 위와 같음 |
| issue-close: 검사 실패 시 닫지 않음 | NOT VERIFIED | 실패한 PR 없음 |
| issue-close: 릴리스 PR(→ main)에서 실행 안 함 | **PASS** (H장) | 릴리스 PR 3건의 열기·머지에서 issue-close 실행 없음. 열린 docs Issue #3도 그대로 열림 |
| pr-check: 릴리스 PR 닫는 키워드·커밋 검사 | **PASS** (H장) | 릴리스 PR 3건에서 `릴리스 PR: 나머지 형식 검사 생략`, `릴리스 커밋: 열린 이슈를 닫는 키워드 없음` 출력. 위반 시 ❌ 경로는 NOT VERIFIED |
| PR 템플릿 AI 표기 문구 오탐 수정 | PASS | 수정된 템플릿으로 쓴 PR #2 3건과 docs PR #4의 pr-check PASS |
| CodeRabbit 설치 | NOT VERIFIED | 코드 레포에 `.coderabbit.yaml` 있음(docs는 없음, D-47). 조직 앱 설치 목록은 현재 토큰 권한(`admin:org` 없음)으로 조회 불가 |
| CodeRabbit 릴리스 리뷰 | **NOT RUN** (H장) | 코드 레포 릴리스 PR 2건에 `release` 라벨이 자동으로 붙었으나 10분 넘게 CodeRabbit 리뷰·댓글·check-run 없음. 설치·연결 여부는 위 항목대로 확인 불가 |
| Projects 보드·Done 자동 이동 | NOT VERIFIED | 토큰에 `read:project` 없음, 보드 유무 미확인. D-49 「이 결정이 깨지는 상황」 항목 |
| 브랜치 보호·필수 검사 | 없음 (의도) | D-46. ❌ PR은 사람이 머지하지 않음 |
| 마일스톤 | 없음 | 세 레포 0개. 부록 체크리스트는 5개(관문 1 / 중간 점검 / MVP 점검 / 관문 2 / 발표) |
| AI 사용 기록 (docs PR #4) | **사람 확인 대기** | CI PASS, 충돌 없음. 「사람이 바꾼 것」 칸을 담당자가 확인하기 전까지 머지하지 않음 |

---

## F. 문제별 후속 조치

| # | 문제 | 영향 범위 | 심각도 | 재현·근거 | 언제 | 담당 권장 | 이슈 |
|---|---|---|---|---|---|---|---|
| 1 | `react-router-dom` 7.6.0 high 취약점 | 프론트 런타임 번들 (아직 라우팅 코드 없음) | 중간 (노출 없음, 코드 작성 전 처리 권장) | `npm audit` (D-1) | 관문 1 직후, B-2 착수 전 | 프론트 | 필요 — chagok-frontend `chore` 이슈 (1·2·3 묶음) |
| 2 | `vite` 6.3.5 high 취약점 | 개발 서버 (개발자 PC) | 중간 | `npm audit` | 1과 함께 | 프론트 | 1에 포함 |
| 3 | `typescript-eslint` 계열 moderate 7건, `eslint@9.27.0` deprecated | lint 도구만 | 낮음 | `npm audit`, `npm ci` 경고 | 1과 함께 | 프론트 | 1에 포함 |
| 4 | Rebase merge가 켜져 있음 (부록과 다름) | 세 레포 머지 방식 | 낮음~중간 (Squash 외 방식으로 머지하는 실수 가능) | `allow_rebase_merge=true` | 지금 (설정만 바꿈) | 형상관리 | 불필요 — 부록 체크리스트대로 설정 |
| 5 | ArchitectureTest 18/19 SKIPPED | 구조 규칙 대부분 검증 안 됨 | 중간 (현재는 코드가 없어 정상) | B-2·C 표 | 관문 1 이후, 기반 이슈마다 SKIPPED 수 감소 확인 | 형상관리·백엔드 | 불필요 — `TEST_테스트명세서.md`에서 추적 |
| 6 | Flyway V1 없음 → 스키마 검증 BLOCKED | db-test는 빈 스키마 기동만 확인 | 중간 | `No migrations found` | 관문 1 이후 (07 확정 뒤, D-41) | DB관리 | 기존 계획 — `기반` 이슈 「V1 마이그레이션/시연 시드」 |
| 7 | issue-close 미검증 경로 3개 (라벨 없이 머지, 머지 후 라벨, 검사 실패). 릴리스 PR 미실행은 H장에서 PASS | 이슈 종료 자동화 | 낮음 (핵심 경로·중복 실행·릴리스 미실행은 PASS) | E 표 | 관문 1 이후 첫 기능 PR에서 실제로 확인. 테스트용 PR은 만들지 않음 | 형상관리 | 불필요 — 확인 결과를 이 문서 다음 판이나 13에 |
| 8 | CodeRabbit 릴리스 리뷰 미실행, 설치·연결 미확인 | 릴리스 리뷰 (D-47, 머지 차단 조건 아님) | 중간 (초기 릴리스는 CodeRabbit 없이 사람 검토로 머지됨) | 릴리스 PR 2건에 리뷰 없음 (H장) | 관문 1 전 (조직 관리자가 앱 설치·저장소 연결 확인 후 다음 릴리스에서 확인) | 형상관리 (조직 관리자) | 불필요 — `DEV_REVIEW_CodeRabbit.md`에 "초기 릴리스: 리뷰 미실행" 기록 권장 |
| 9 | Projects 보드·Done 이동 미확인 | 보드 운영 | 낮음 | 토큰 `read:project` 없음 | 보드를 만든 뒤 첫 issue-close에서 | PM·형상관리 | 불필요 |
| 10 | 마일스톤 0개 | 이슈 분류 (CONTRIBUTING 3장) | 낮음 | 세 레포 milestones 없음 | 관문 1 전 | PM·형상관리 | 불필요 |
| 11 | Actions 런타임 경고: Node.js 20 대상 액션(`checkout@v4`·`setup-node@v4`·`setup-java@v4`·`gradle/actions@v4`)이 Node 24로 강제 실행, `setup-java@v4` deprecated | CI 워크플로 | 낮음 (지금은 동작함) | backend-ci·frontend-ci 로그 `##[warning]` | 관문 1 이후 | 형상관리 | 필요 시 `chore` 이슈 (세 레포) |
| 12 | 로컬 Node 24 ↔ CI Node 22 | 로컬·CI 결과 차이 가능성 | 낮음 | `node -v` | 관문 1 전 팀 공지 (로컬 Node 22 권장) | 프론트 | 불필요 |
| 13 | 이전 Windows 로컬 빌드 오류 원문 없음 | 재발 시 원인 비교 불가 | 낮음 | 이번에는 재현 안 됨 | 재발 시 | 프론트 | 불필요 — 재발하면 트러블슈팅 기록 |

---

## G. 관문 1 준비와의 관계

CI 결과는 관문 1 통과 조건이 아니다. 관문 1은 00 「관문」 표와 12 백로그 2장 기준이다.

- 00·04·07·08 확정 (12 백로그 0-1), 💡 제안값 확인 (0-2), D-20 패키지 구조 (0-3), 결정 14·15 담당·관문 날짜 (0-4), 와이어프레임 → 09 (0-5)
- 이 보고서에서 관문 1 회의에 올릴 것: F-1~3 처리 시점(관문 1 직후 권장), F-4 Rebase 끔, F-8 CodeRabbit 설치 확인, F-10 마일스톤 생성, 결정 14 후 CODEOWNERS(부록), docs PR #4 사람 확인, 태그 정책(H장: 초기 릴리스 태그 보류, 첫 태그를 `v0.1-gate1`로 둘지)

---

## H. 초기 릴리스 (develop → main, 같은 날)

D-49와 이 보고서가 develop에 들어간 뒤 형상관리자 지시로 세 레포 `develop → main` 릴리스를 진행했다. CONTRIBUTING 2장대로 **Merge commit**을 썼다. CONTRIBUTING의 릴리스 시점(중간 점검·MVP 점검·관문 2·발표)에 들어 있지 않은 초기 기준판이다. 기능 코드·Flyway V1·DB 변경·ERD/API 수정안은 포함하지 않았다.

| 레포 | 릴리스 PR | PR 검사 | main 머지 커밋 | main CI (push) |
|---|---|---|---|---|
| docs | https://github.com/OneMonthproJect/chagok-docs/pull/7 | label·pr-check PASS | `646f047` | push 워크플로 없음 |
| backend | https://github.com/OneMonthproJect/chagok-backend/pull/3 | wrapper·build·db-test·label·pr-check PASS | `b095b4d` | PASS (wrapper·build·db-test) https://github.com/OneMonthproJect/chagok-backend/actions/runs/44983672961 |
| frontend | https://github.com/OneMonthproJect/chagok-frontend/pull/3 | build·label·pr-check PASS | `aa0bb4c` | PASS https://github.com/OneMonthproJect/chagok-frontend/actions/runs/44983678774 |

| 확인 항목 | 결과 | 근거 |
|---|---|---|
| `release` 라벨 자동 부착 (labeler) | PASS | 세 릴리스 PR에 자동 부착 |
| pr-check 릴리스 경로 | PASS | 세 레포 `릴리스 PR: 나머지 형식 검사 생략`, `릴리스 커밋: 열린 이슈를 닫는 키워드 없음` |
| 릴리스 PR에서 issue-close 미실행 | PASS | 세 레포 issue-close 실행 기록 없음, docs Issue #3 열림 유지 |
| 머지 커밋 메시지에 닫는 키워드 없음 | PASS | `Merge pull request #N from OneMonthproJect/develop` + PR 제목 |
| main 머지 후 브랜치 | PASS | `develop` 유지, 기본 브랜치 `main`, 자동 삭제 끔 유지. main 직접 push·강제 push 없음 |
| main ↔ develop 내용 | 같음 | 파일 차이 0. develop이 머지 커밋 1개 뒤(Merge commit 방식이라 정상) |
| CodeRabbit 릴리스 리뷰 | NOT RUN | 코드 레포 2건 모두 리뷰·댓글·check-run 없음. `@coderabbitai full review` 수동 요청은 하지 않음 |
| 사람 검토 | 진행됨 | 형상관리자가 포함 PR(세 레포 #2, docs #6)의 완료 정의·내용을 확인하고 Merge commit 방식과 main 머지를 지시 |
| 릴리스 태그 | 보류 | 이 릴리스용 태그 이름이 CONTRIBUTING에 없음. 첫 태그를 관문 1 `v0.1-gate1`로 둘지 형상관리자가 결정 |
| 포함 안 됨 | — | docs PR #4 / Issue #3 (AI_USAGE, 사람 확인 대기) |
