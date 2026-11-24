# 김동윤 — 형상관리 · BE 개발가이드

> 기준: 2026-11-24 05:53 KST, backend develop `f562a7b`, docs develop `cf9ef3f`. 담당 기능은 **추천안**(확정 Assignee 아님, [01](../01_P0_핵심기능_담당배정.md)). 공통 내용은 [03 환경](../03_공통_클론_개발환경.md)·[05 협업](../05_공통_협업_개발절차.md)을 본다.

## 1. 내 역할과 책임

| 구분 | 내용 |
|---|---|
| 운영 역할 (확정 D-14) | 형상관리 — 이슈 생성·라벨·마일스톤, PR·릴리스, CI, `.github/`·`.claude/`·`scripts/`·CONTRIBUTING·CONVENTIONS 주인(CODEOWNERS `@dyk816`) |
| 개발 역할 (추천) | BE: `domain/cycle`(1), `domain/account`(2), `screen/visit`(8). 12(target·home)는 김예린에게 이관한 추천안. **FE 2개**: 6-1(S-06 차량 추가), 16(S-04 재점검 대상) — PM 결정, 예외 배치([01](../01_P0_핵심기능_담당배정.md) 개정) |
| 추가 검증 | 권한·격리 공통(X9·X10·X18, `EndpointGuardTest`), M2 통합 검증 판정, 릴리스 점검 |
| 주 협업 | 김예린(cycle·account 검증, PM), 이재성(S-01·공통 머리·메뉴 FE), 이영주(API 10의 입력 = 정비 기록, 6-1의 08), 최은정(S-07·S-08 FE, S-06 화면 주인), 김예린(14·11 API = 16의 BE), 이재성(M-02 모달 = 16이 `pages/S04`에서 조립) |

## 2. 현재 상태

- 있음: `global/` 전체(SecurityConfig 기본 거부, JWT **검증**, `LoginStaff`·`LoginAdmin`·`@CurrentStaff`, ErrorCode·GlobalExceptionHandler, ApiResponse, Clock, PageLimit, RequestIdFilter), `V1__init.sql`, `EndpointGuardTest`(CI 통과), `JwtVerificationTest`·`TestJwts`.
- 없음: `domain/cycle`·`domain/account`·`screen/visit` 전부(`package-info.java`만). 로그인·토큰 **발급**.
- 테스트 상태: `ArchitectureTest` 18개 SKIPPED — cycle이 생기면 `cycle은_순수_계산이다` 등이 실제로 돌기 시작한다.
- 착수 가능: **1번 cycle 바로 가능**(선행 B-1 완료). 2번 account도 선행(B-1·B-3) 완료.

## 3. 내 P0-핵심 담당 (추천)

| 순번 | 기능 ID | 기능 | API (08) | 화면 | 테이블 (읽기/쓰기) | GitHub 이슈 | 상태 | 선행 | 협업 |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | F-CYC-01 | 항목 상태 계산 + T1~T13 | 없음 (04·10·14·17이 사용) | — | 없음 (순수 계산) | 미생성 | 추천 | B-1 ✅ | 김예린 |
| 2 | F-AUTH-01·02 | 로그인·관리자 로그인·내 계정 | 01 `POST /api/auth/login`, 02 `POST /api/admin/auth/login`, 03 `GET /api/me` | (S-01) | staff·shop·platform_admin / — | 미생성 | 추천 | B-1 ✅, B-3 ✅ | 김예린 (FE 짝 이재성: 3·3-1) |
| 8 | F-VIS-01·CUS-05 | 항목 상태·저장 전 미리보기 | 10 `GET /api/vehicles/{vehicleId}/item-status?mileage=` | (S-07·08) | vehicle·maintenance_record·service_item / — | 미생성 | 추천 | 1, 7-2 | 이영주 (FE 짝 최은정) |
| 6-1 (FE) | F-CUS-03 | 기존 고객에 차량 추가 | 08 `POST /api/customers/{customerId}/vehicles` | S-06 (차량 추가, 인라인) | 없음 (FE) | 미생성 | 추천 | 6 (최은정) | 이영주 (BE 4-2), S-06 화면 주인 최은정 |
| 16 (FE) | F-TGT-01 | 재점검 대상 (목록에서 예약) | 14 `GET /api/targets`, 16 `POST /api/reservations` | S-04 | 없음 (FE) | 미생성 | 추천 | 14-2 (이재성) | 김예린 (BE 12-1·11-1) |

FE 2개는 PM 결정으로 맡은 예외 배치다. 설계는 [07](../07_프론트_화면구조_라우팅_컴포넌트_설계.md), 파일 단위 소유·충돌 방지는 [08](../08_구현_파일_소유_충돌방지.md).

## 4. 첫 개발 순서

1. `develop` 최신화, `.claude` 동기화 ([03](../03_공통_클론_개발환경.md) 3·7장).
2. **형상관리 먼저**: PM 확인이 끝나면 [02](../02_P0_개발이슈_생성계획.md) 9장 체크 → `chagok-issue-writer`로 02의 생성 후보(분할·추가 확정 후, 하위 번호 포함) 이슈 생성, 짝 이슈 링크. FU-1~3 초안 처리.
3. 1번 이슈를 연다 → 04 F-CYC-01(T1~T13), CONVENTIONS 2·3장(cycle은 Spring·JPA 없음).
4. `feature/#<번호>-cycle-calc` 브랜치.
5. cycle 구현: 기준 기록 = 교체·외부 중 가장 늦은 것(점검·거절 제외), 도래(오늘 ≥ 다음 정비일 또는 km ≥ 기준+주기, 경계 포함), 임박(오늘+1개월 ≥ 다음 정비일), `plusMonths` 말일. 날짜는 인자로 받는다(Clock 직접 사용 금지).
6. T1~T13 단위 테스트(`./gradlew build`, DB 없음). `ArchitectureTest`가 SKIPPED → 실행으로 바뀌는지 확인.
7. PR (L2, `review-me` 자동) → `chagok-pr-reviewer` 자가 점검 → 김예린 확인.
8. 병행: 2번 account (L3, `SecurityConfig`에 01·02 공개 경로). FU-1(backend#17, `/error`·406·AccessDenied)과 같은 파일이라 **순서를 먼저 정한다**(추천: 2번 머지 뒤 FU-1).
9. 2번 머지 뒤 이재성에게 01·03 실제 연결 요청 → 401·403 함께 확인.
10. 7-2(이영주) 머지 후 8번. (12 target·home은 김예린 담당 — 12-1·12-2가 8번의 `api`를 쓰므로 8번 계약을 김예린과 먼저 합의)
11. **FE 6-1**: 최은정의 6번(S-06)이 머지된 뒤 시작. `AddVehicleInline`은 새 파일로 만들고 `pages/S06`에는 import 한 줄만 더해 충돌을 줄인다(08 문서). 4-2 머지 후 실제 연결.
12. **FE 16**: 이재성의 14-2(M-02 모달) 머지 뒤 시작. `features/target`·`pages/S04`를 만들고 모달은 `pages/S04`에서 조립(feature끼리 import 금지). 공통 메뉴(3-1)에 "재점검 대상" 항목 한 줄 등록. FE 환경은 [03](../03_공통_클론_개발환경.md) 프론트 장(Node 22, `npm ci`, lint·test·build).

## 5. 코드 경로 (`src/main/java/com/wanted/chagok/`)

| 경로 | 상태 |
|---|---|
| `global/config/SecurityConfig.java` | **있음** — 2번에서 01·02 `permitAll` 추가 (L3) |
| `global/auth/{LoginStaff,LoginAdmin,CurrentStaff,JwtVerification,TokenClaims,StaffRole}.java` | **있음** — 토큰 발급은 2번에서 추가 (검증 규약과 같은 클레임) |
| `global/error/ErrorCode.java` | **있음** — `LOGIN_FAILED` 등 08 0.3 코드 확인 (추가 시 L3) |
| `domain/cycle/` | 생성 예정 (순수 계산, `api/`로 노출) |
| `domain/account/{api,controller,dto,service,entity,repository}/` | 생성 예정 (staff·platform_admin) |
| `screen/visit/` | 생성 예정 (표 없음, 도메인 `api`만 import) |
| `src/test/java/.../global/EndpointGuardTest.java` | **있음** — 2번에서 01·02 공개 경로 케이스 추가 |

FE(`chagok-frontend/src/`): 6-1은 `features/customer/components/AddVehicleInline`(새 파일)과 `pages/S06`의 import 한 줄, 16은 `features/target/…`·`pages/S04/…`(생성 예정, 파일 이름은 [08](../08_구현_파일_소유_충돌방지.md)).

## 6. 협업과 연동 시점

| 기능 | 상대 | 계약 | Mock | 연동 시점 |
|---|---|---|---|---|
| 2 → 3·3-1 | 이재성 (S-01·공통 머리) | 01·03 응답(03은 머리의 이름·역할), `LOGIN_FAILED` 하나, `expiresIn` 43200 | FE가 08 예시로 먼저 | 2번 develop 머지 직후 |
| 8 → 9·10 | 최은정 (S-07·08) | 10 응답(`status`·`dueReason`·`sortOrder` 순) | FE Mock 먼저 | 8번 머지 후 |
| 4-2 → 6-1 (내가 FE) | 이영주 | 08 차량 추가(차종 필수 400) | 내가 08 예시로 Mock | 4-2 머지 후 |
| 12-1·11-1 → 16 (내가 FE) | 김예린 | 14 도래·임박·"예약 있음", 16 예약 | 〃 | 11-1·12-1 머지 후 |

계약을 바꿔야 하면: 짝 FE 담당 + 도메인 최은정에게 먼저 알리고 docs 08 PR을 함께 낸다.

## 7. 구현 정책·주의

- **cycle**: 서버가 상태의 단일 원본. 미확인(기록 없음)은 대상 아님. 상태를 칼럼으로 저장하지 않는다.
- **account**: 실패는 `LOGIN_FAILED` 하나(아이디 없음·비밀번호 틀림 구분 안 함). 아이디 1~50·비밀번호 1~100, 새 비밀번호 규칙 적용 안 함(08 01). ADMIN 토큰에는 shopId 없음. 응답·로그에 비밀번호·토큰 금지. P1(비밀번호 변경 강제·약관·`ACCOUNT_INACTIVE` 확인)은 만들지 않는다.
- **visit**: 기록을 남기지 않는다. mileage 없으면 날짜 기준만. 둘 다 해당하면 `dueReason`=DATE.
- 격리: 다른 정비소 id → 404. shopId는 토큰에서만.
- **FE 6-1·16**: 상태(미확인/여유/임박/도래)는 서버 값 그대로. S-04는 미동의 고객 제외·미확인은 대상 아님·"예약 있음" 표시, 줄의 [예약 등록]은 M-02(차량 채움). 6-1은 차종 필수 400을 칸 아래에 보이고 입력을 지우지 않으며 저장 버튼은 요청 중 비활성. feature끼리 import 금지(`pages`에서 조립), Mock은 `api.ts`에서만 고름(CONVENTIONS 7장).

## 8. 테스트·검증

| 이슈 | 테스트 | 명령 |
|---|---|---|
| 1 | T1~T13 단위, 말일·경계 km | `./gradlew build` |
| 2 | 로그인 성공·실패, 401(없음·만료·위조), X9·X10·X18, E1~E5 회귀, C01 공개 경로 | `build` + 빈 DB `dbTest` |
| 8 | X6, T8~T11, mileage 없음 | `dbTest` |
| 6-1 (FE) | 차량 추가 400(차종 필수) 표시, 입력 보존, 중복 제출 방지 | `npm run lint && npm test && npm run build` |
| 16 (FE) | 시나리오 A 흐름: 대상 → 예약 → "예약 있음" → (방문 완료 후) 목록에서 빠짐, 미동의 제외 | 〃 |

미구현 선행 때문에 못 하는 테스트는 PR에 "미검증 + 이유"로 적는다.

## 9. PR·완료 기준

base `develop`, 제목 `[#번호] …`, 본문 `Closes #번호`, CI ✅, `chagok-pr-reviewer` 결과, 짝 FE 연결 확인 → 확인한 팀원이 `done-verified` → Squash. `review-me` PR은 필요하면 `@coderabbitai review`. 1·2는 다른 BE(김예린) 확인 권장.

## 10. 착수 체크리스트

- [ ] JDK 21·MySQL 8, 개발 DB·빈 테스트 DB 준비, `.env`(JWT_SECRET 직접 생성)
- [ ] `./gradlew build` 통과, `bootRun` → health UP
- [ ] PM과 담당 확정 (01 5장 1·2번: 12 이관, 이슈 분할·추가)
- [ ] 02의 생성 후보 이슈 생성 (Assignee는 확정 후)
- [ ] 1번 브랜치 생성, T1~T13 목록 확인
- [ ] FU-1(backend#17)과 2번의 `SecurityConfig` 순서 결정
- [ ] (FE 6-1·16 착수 전) Node 22, `npm ci`, `npm run lint && npm test && npm run build` 통과, [07](../07_프론트_화면구조_라우팅_컴포넌트_설계.md)·[08](../08_구현_파일_소유_충돌방지.md) 확인

## 11. 형상관리 업무

- 이슈 생성·라벨·마일스톤·짝 링크, 12 4장 실제 번호 반영 docs PR(PM과).
- 모든 PR CI ✅ 확인 후에만 머지되는지 감시(GitHub가 막지 않음). 머지된 ❌ PR은 revert.
- 릴리스: `chagok-release-check` → docs → backend → frontend 순, Merge commit, `Refs`만, 같은 태그. 코드 릴리스 PR의 CodeRabbit 실행 여부 확인(지금까지 기록 없음).
- #73(settings ask, L3) 주인. #72는 D-66으로 결정됨 — 마일스톤 점검 때 원격 브랜치 정리 승인, 사후 리뷰 확인(PR #82·#87, 서브 형상관리 머지 #85·#88), `chagok-branch-audit` 구현(별도 L2).
- 업무량: BE 3개(1·2·8, 계산·로그인·읽기 위주) + **FE 2개(6-1·16, PM 결정)** + 형상관리. FE는 예외 배치이므로 운영 업무가 몰리면 6-1부터 최은정에게 되돌린다(PM 확인). 12는 김예린에게 이관한 추천안이다.

## 12. 미결·확인

- 담당 확정 전 (추천안)
- FU-1 = chagok-backend#17 담당·2번과 순서 조율. FU-3은 D-68로 결정됨(CORS 허용 목록 없음 → backend CORS 설정 변경 없음)
- 02 3장 Q12(2번 테스트 ID), Q7(X8 담당)
- **❓ Q14**(API 07 `dueCount` 조립 위치): (a)로 결정되면 07은 8번 뒤의 별도 `screen/` 이슈로 내가 맡게 된다 — [08](../08_구현_파일_소유_충돌방지.md) 6장
- 1번 첫 PR은 `cycle/api/`(계약)만 — 이영주·김예린이 쓴다. 파일 소유는 08 4장
- CodeRabbit App 설치·동작 확인

## 부록. 2026-11-24 일정 분리·P0-나머지 추천 (01 6장)

추천안이다. 담당 지정은 PM이 GitHub에서 한다. 시작 후 10~12일 목표라서 큰 이슈를 새 파일 중심으로 나눴다(02 10장, 08).

- **#41** cycle 거절·점검 표시 판정(T14·T15), **#44** `account.api` 담당 정비사 후보 조회(API 36, #35보다 먼저 머지), **#45** P0-나머지 ErrorCode 일괄 추가(기능 이슈보다 먼저 머지).
- reservation 이슈(#33·#36 등)는 김예린 담당으로 옮겼다(3판). 김동윤은 reservation 파일을 고치지 않는다.
- ❓ Q14가 (a)로 결정되면 고객 상세(#43)가 `screen/`으로 와서 김동윤 담당.

