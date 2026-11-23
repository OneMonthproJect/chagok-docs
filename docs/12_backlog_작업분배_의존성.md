# 12 백로그·작업 분배·의존성

> 기능 ID ↔ 이슈 ↔ 담당 ↔ 선행 작업 (계속 수정)

상태: 1차 계획 (2026-11-22 · 최은정(eunjung01230)) — 담당은 D-14, 이슈 번호는 GitHub에 올린 뒤 채운다
근거: 00 단계, 04 기능, 10 연결표, CONTRIBUTING 3·9장, 13 changelog D-51~D-59
작업 상태의 원본은 Organization `OneMonthproJect`의 Projects 보드다. 이 문서에는 계획과 연결만 둔다. 이슈는 `chagok-issue-writer`로 만든다.

---

## 1. 쪼개는 규칙

- 백엔드 이슈 = 도메인 패키지 하나(또는 screen 하나), 프론트 이슈 = 화면 하나. 하루 안에 PR 하나.
- 기능 하나가 API와 화면을 가지면 BE·FE 두 이슈로 나누고 「짝 이슈」로 잇는다. 08 JSON 예시가 있으므로 FE는 목업으로 먼저 시작할 수 있다.
- 레포 표기: BE = `chagok-backend`, FE = `chagok-frontend`, DOC = `chagok-docs`.
- 마일스톤: P0-핵심 → M2 통합 검증, P0-나머지·P1 → M3 MVP 검증, P2 → M4 기능 동결.

## 2. M1 설계 확정까지 (DOC)

| 순서 | 레포 | 작업 | 담당 | 상태 |
|---|---|---|---|---|
| 0-1 | DOC | 00·04·07·08 확정 (이 1차본 검토) | PM·도메인관리·DB관리 | 1차 작성됨 |
| 0-2 | DOC | 💡 제안값 확인 | 전원 | |
| 0-3 | DOC | 결정 20 패키지 구조 확정 | 형상관리·백엔드 | |
| 0-4 | DOC | 결정 14·15 담당·마일스톤 날짜 | PM | |
| 0-5 | DOC | 와이어프레임(D-19) → 09 맞추기 | | |

## 3. 기반 (M1 설계 확정 직후)

| 순서 | 레포 | 이슈 | 선행 |
|---|---|---|---|
| B-0 | BE·FE | 초기 레포 구성: 의존성, 폴더, 환경변수 예시, Gradle Wrapper(9.8.2), Flyway 설정, CI(wrapper 검증·build·dbTest·프론트 lint/build), pr-check(비밀값·DB 규칙), ArchitectureTest 기반, 시연 시드 구조 | **구성 완료.** 프론트 lint·build는 확인, 백엔드 빌드·CI는 첫 push에서 확인 필요 |
| B-1 | BE | [기반] global: JWT 인증 필터·로그인 정보, ErrorCode(08 0.3)·전역 처리기, ApiResponse(08 0.2, `details` 포함), Clock, PageLimit + `EndpointGuardTest` 구현(아래 9장) | M1 설계 확정 |
| B-2 | FE | [기반] shared: client.ts(공통 응답·오류 처리 05 POL-120~129, 토큰, 자동 재전송 없음), StatusBadge, Layout, Button(저장 중 비활성) + 라우팅·로그인 가드 | M1 설계 확정 |
| B-3 | BE | [기반] Flyway `V1__init.sql`(07, `reservation.version` 포함, 담당 정비사 스키마: `staff` UNIQUE(shop_id, id)·`reservation.assignee_staff_id` 복합 FK·`maintenance_record.staff_id` 복합 FK, D-51) + 시연 시드 `db/seed/demo_seed.sql`(07 7장, 시연 계정 1234, 차종·담당 정비사 값 포함) — DB 담당자 | ERD 확정 |

## 4. P0-핵심 (→ M2 통합 검증)

| 순서 | 기능 ID | 레포 | 이슈 제목 (안) | 패키지 / 화면 | 선행 |
|---|---|---|---|---|---|
| 1 | F-CYC-01 | BE | [F-CYC-01] 항목 상태 계산 + T1~T13 | domain/cycle | B-1 |
| 2 | F-AUTH-01·02 | BE | [F-AUTH-01] 로그인·서비스 관리자 로그인·내 계정 (API 01~03) | domain/account | B-1, B-3 |
| 3 | F-AUTH-01 | FE | [F-AUTH-01] 로그인 화면 S-01 | pages/S01 | B-2 |
| 4 | F-CUS-01~05 | BE | [F-CUS-01] 고객·차량 검색·등록(차종 필수, D-58)·차량 추가·상세 (API 05~09) + X1·X2·X7 | domain/customer | 2 |
| 5 | F-CUS-01·02 | FE | [F-CUS-01] 고객·차량 목록 S-05 + 등록 M-01(차종 필수) | pages/S05, features/customer | 3 |
| 6 | F-CUS-04 | FE | [F-CUS-04] 고객 상세 S-06 | pages/S06 | 5 |
| 7 | F-MNT-01 | BE | [F-MNT-01] 방문 기록 저장·이력 조회·항목 목록 (API 11~13, 차량에 연식·주행거리가 비어 있으면 첫 저장 때 필수, D-58) + X5 | domain/maintenance, domain/item | 4 |
| 8 | F-VIS-01·CUS-05 | BE | [F-VIS-01] 항목 상태·미리보기 (API 10) + X6 | screen/visit | 1, 7 |
| 9 | F-CUS-05 | FE | [F-CUS-05] 차량 상세 S-07 | pages/S07 | 6 |
| 10 | F-MNT-01·VIS-01 | FE | [F-MNT-01] 방문·정비 기록 S-08 (미리보기) | pages/S08, features/maintenance | 9 |
| 11 | F-RSV-01·02·04·06 | BE | [F-RSV-01] 예약 등록·기간 조회·방문 완료·변경 (API 15·16·18·19, P0-핵심은 서버가 등록자를 담당으로 자동 지정, D-51) + R1~R5·R7~R14 + X4·X11·X12(18·19) | domain/reservation | 4 |
| 12 | F-TGT-01·HOME-01 | BE | [F-TGT-01] 재점검 대상·홈 (API 14·04) + X7 | screen/target | 8, 11 |
| 13 | F-RSV-03 | BE | [F-RSV-03] 예약 상세 패널 (API 17, 최근 방문 2건 + `totalVisitCount`, D-54) + X3 | screen/booking | 8, 11 |
| 14 | F-RSV-01·02·06 | FE | [F-RSV-02] 홈 S-02의 오늘 예약 목록(앞뒤 날짜 이동) + 등록·변경 M-02 (기존 예약 발견 → 패널, 409 처리) | pages/S02, features/reservation | 5 |
| 15 | F-RSV-03·04 | FE | [F-RSV-03] 예약 상세 패널(최근 방문 2회, 총 3회 이상이면 상세 이동 활성) + 방문 완료 → S-08 | features/reservation | 14, 10 |
| 16 | F-TGT-01 | FE | [F-TGT-01] 재점검 대상 S-04 (목록에서 예약) | pages/S04, features/target | 14 |
| 17 | F-HOME-01 | FE | [F-HOME-01] 홈 S-02 (요약 숫자 + 오늘 예약 목록) | pages/S02 | 15, 16 |
| 18 | — | 전원 | M2 통합 검증: 빈 DB에서 시나리오 A·B, 07 7.5 기대값 확인 → `v0.5-m2-integration` | | 1~17 |

## 5. P0-나머지 (M2 통합 검증 후)

| 순서 | 기능 ID | 레포 | 이슈 제목 (안) | 선행 |
|---|---|---|---|---|
| V2 | — | BE | [기반] Flyway `V2` (07 6장: `inspect_result`, `NO_SHOW`, `customer`·`vehicle` version 4건 + `IN_PROGRESS`, `maintenance_record.updated_at`·`version`·UNIQUE, `maintenance_record_revision`, `reservation_revision`, 한 파일) — DB 담당자 | 18 |
| 19 | F-MNT-02·03, F-CYC-02 | BE | [F-MNT-02] 외부·거절·점검 결과 저장 + 거절·주의 표시 + T14·T15 | 18, V2 |
| 20 | F-MNT-02·03 | FE | [F-MNT-02] S-08 외부·거절·점검 결과 입력 + 꼬리표(S-02·04·07·08) | 19 |
| 21 | F-RSV-07·08 | BE | [F-RSV-07] 취소(예약·진행중)·노쇼 (API 20·21) + R6·R10·R12·R13 + X12 | V2 |
| 22 | F-RSV-05 | FE | [F-RSV-05] 홈 S-02 캘린더(월·주, 일 보기 없음, 담당 색+이름 라벨) — 오늘 예약 목록을 캘린더로 교체 | 18, 25-6 |
| 23 | F-RSV-07·08 | FE | [F-RSV-07] 패널 취소·노쇼 | 21 |
| 24 | F-CUS-06·07 | BE | [F-CUS-06] 고객·차량 수정 (API 22·23, `version` 확인) + 목록 마스킹 + X12 | 18, V2 |
| 25 | F-CUS-06 | FE | [F-CUS-06] S-06·S-07 수정 | 24 |
| 25-1 | F-RSV-01·06 | BE | [F-RSV-01] 등록 때 담당 정비사 선택·정비사별 중복 제한(API 16·19 `assigneeId`, 12 `mechanicId`, 담당 후보 36, 409 `MECHANIC_SLOT_CONFLICT`) + R15~R20·X13 (D-51) | 18 |
| 25-2 | F-RSV-09 | BE | [F-RSV-09] 방문 접수(진행중) (API 39, 연식·주행거리 입력) + R21~R23 (D-52) | 18, V2 |
| 25-3 | F-RSV-06 | BE | [F-RSV-06] 담당 재배정(전날 마감, 사장 당일 예외·사유 필수) + `reservation_revision`(API 19·41) + R24 (D-53 재배정) | 25-1, V2 |
| 25-4 | F-RSV-10 | BE | [F-RSV-10] 지난 예약 정정(API 40·41) + `reservation_revision` + R25~R29 (D-53 정정) | V2 |
| 25-5 | F-MNT-04 | BE | [F-MNT-04] 정비 기록 수정·수정 이력(API 37·38, 11 응답 확장) + H1~H11·X14 (D-55) | 18, V2 |
| 25-6 | F-RSV-05 | BE | [F-RSV-05] 월 요약(API 42, 15 `assigneeId` 쿼리) | 18 |
| 25-7 | F-RSV-06·09·10 | FE | [F-RSV-09] 패널 방문 접수·정정·이력 보기, M-02 담당 선택·재배정 | 25-1~25-4 |
| 25-8 | F-MNT-04 | FE | [F-MNT-04] S-07 수정 버튼·수정 이력 패널 + M-03 정비 기록 수정 | 25-5 |

예약 변경은 P0-핵심으로 옮겼다(D-42). 취소·노쇼의 순서는 이 표를 정할 때 정한다.

- 25-1~25-8은 D-51~D-55로 생긴 이슈 단위다. 기존 번호를 바꾸지 않으려고 하위 번호로 잇는다. 이슈 번호는 GitHub에 올린 뒤 채운다.
- D-53 코드 이슈는 정정(25-4)과 재배정(25-3)으로 나눈다.
- 이슈는 도메인 1개 단위로 쪼개고 도메인 3개 이상을 건드리는 이슈는 만들지 않는다(CONTRIBUTING 3장). P0-나머지·P1 이슈는 M2 통합 검증 통과 전에 열지 않는다.

## 6. P1 (P0-나머지 후 → M3 MVP 검증)

| 순서 | 기능 ID | 레포 | 이슈 제목 (안) | 착수 전에 정할 것 |
|---|---|---|---|---|
| V3 | — | BE | [기반] Flyway `V3` (07 6장: `customer.status`·`anonymized_at`, `vehicle.active`, `staff.active`, 연락 기록 `contact_log` 등) — DB 담당자 | P0-나머지 완료 뒤(D-56 칼럼은 아래 착수 조건) |
| 26 | F-CYC-03 | BE | [F-CYC-03] 월평균 주행거리 추정 + T16·T17 | — |
| 27 | F-CUS-08 | FE | [F-CUS-08] 차량 약식 도면 | 도면 그림 준비 |
| 28 | F-CON-01·02 | BE | [F-CON-01] 문자 초안·연락 결과 (contact_log, API 28·29) | — (D-59: 결과 값 6개, "연락함" 꼬리표 30일) |
| 29 | F-CON-01·02 | FE | [F-CON-01] S-04 문자 초안·결과 기록 | 문자 앱 링크 기기별 확인 |
| 30 | F-ADM-01·02, F-AUTH-03 | BE | [F-ADM-01] 정비소 개설·정지·재발급, 비밀번호 변경 (API 24, 31~35) | — |
| 31 | F-ADM-01·02 | FE | [F-ADM-01] S-10 + 서비스 관리자 로그인 전환, S-01 비밀번호 변경 | — |
| 32 | F-STF-01, F-ITEM-01 | BE | [F-STF-01] 정비사 계정·기준표 (API 25~27) | — (D-59: 새 항목 추가 없음, P2) |
| 33 | F-STF-01, F-ITEM-01, F-NTF-01 | FE | [F-ITEM-01] S-09 설정 + 아침 알림 | — (D-59: 알림 설정은 브라우저 저장, 서버·API 없음) |
| 34 | F-STAT-01 | BE·FE | [F-STAT-01] 신규·재방문 집계 | — (D-59: 재방문 정의는 04 F-STAT-01, 화면은 홈 S-02 하단 "고객 집계" 카드) |
| 34-1 | F-CUS-10 | BE | [F-CUS-10] 고객·차량 비활성화·삭제 (API 43~47, 05 `includeInactive`) + K1~K5·K8·K9 | V3 필요. **POL-46 확인 후 착수** |
| 34-2 | F-CUS-11 | BE | [F-CUS-11] 보관 기간 경과 고객 목록·익명화 (API 48·49) + K6·K7 | V3 필요. **POL-46 확인 후 착수** |
| 34-3 | F-STF-01 | BE | [F-STF-01] 정비사 비활성화 (API 50, `ACCOUNT_INACTIVE`) + K10 | V3·32 필요 |
| 34-4 | F-CUS-09 | BE | [F-CUS-09] 고객 단위 지표 (API 05·07 응답 `lastVisitDate`·`visitCount`·`hasUpcomingCheck`) | V3 필요 |
| 34-5 | F-CUS-10·11 | FE | [F-CUS-10] S-05·06·07 비활성화·삭제 버튼·"비활성 포함", S-09 "보관 기간 경과 고객" 탭·정비사 비활성화 | 34-1~34-3 필요. **POL-46 확인 후 착수**(익명화·삭제 부분) |
| 34-6 | F-CUS-09 | FE | [F-CUS-09] S-05 목록 줄·S-06 상단 지표 | 34-4 필요 |
| 35 | — | 전원 | M3 MVP 검증 → `v0.8-m3-mvp` | |

- **D-56 착수 조건**: 34-1·34-2·34-5(그리고 V3의 `customer.status`·`anonymized_at`·`vehicle.active`)의 구현 이슈는 05 POL-46(차량번호·정비 이력 영구 보존의 법적 근거 확인, 담당 PM, 시한 💡 M3 MVP 검증 전) 확인이 끝난 뒤에 연다. 문서는 확정되어 있다.

## 7. 담당 (D-14: 역할·소속 확정, 영역별 분담은 이슈 착수 때 채움)

| 영역 | 백엔드 | 프론트 |
|---|---|---|
| 기반 | | |
| 계정·인증 (account) | | |
| 고객·차량 (customer) | | |
| 정비 기록·항목 (maintenance·item) | | |
| 주기 계산 (cycle) | | (리뷰: 도메인관리 최은정(eunjung01230)) |
| 재점검 대상·홈 (screen/target) | | |
| 예약·패널 (reservation·screen/booking) | | |
| 방문 중 안내 (screen/visit) | | |
| DB·시드 | DB관리 2명: 이재성(godgeul-glitch)·이영주(softy20) | — |

## 8. 이슈 완료 기준

00 7장 「완료의 정의」를 따른다. 이슈마다 PR 본문에 아래 테스트 결과를 남긴다. 실행하지 못한 테스트는 "미검증 + 이유"로 적고, 완료로 세지 않는다.

| 단계 | 반드시 확인할 테스트 |
|---|---|
| P0-핵심 | 주요 사용자 흐름(시나리오 A·B), 예약 중복(R3·R4), 상태 전이(R5), 예약 변경·동시 수정(R7·R8), 권한(X9·X10), 정비소 격리(X1~X8), 저장 정합성(방문 기록 묶음·최근 주행거리), 저장 실패·네트워크 오류 때 화면 동작(05 POL-120~129) |
| P0-나머지 | 취소·노쇼(R6), 담당 중복·진행중·재배정·정정(R15~R29), 정비 기록 수정(H1~H11), 외부·거절·점검 결과(T13~T15), 캘린더·검색, 예외 입력, 격리(X13~X16), 화면 연결, 회귀(P0-핵심 테스트 전체 재실행) |
| P1 이후 | 월평균 추정(T16·T17), 연락 결과, 집계 정확성, 재방문 대상 계산, 비활성화·삭제·익명화(K1~K10) |

## 9. 자동 검사 준비 상태 (B-0 시점)

| 검사 | 지금 | 실제 검증이 시작되는 때 |
|---|---|---|
| ArchitectureTest: global → domain·screen 금지 | 실행됨 (global에 클래스 있음) | 지금 |
| ArchitectureTest: 도메인 api 경유, 의존 방향, 순환, screen import 금지, cycle 순수, Controller → Repository 금지, Entity setter 금지 | 대상 클래스가 없어 **SKIPPED(미검증)** | 해당 패키지·클래스가 생기는 이슈부터 자동 |
| EndpointGuardTest | **미구현** (보호할 API가 없음) | B-1: ① 등록 안 된 경로 → 거부 ② 토큰 없이 `/api/**` → 401 ③ 서비스 관리자 토큰으로 `/api/**` → 403 ④ 정비소 토큰으로 `/api/admin/**` → 403 ⑤ `/actuator/health`만 공개. 정비소 소유 일치(X1~X8)는 각 도메인 이슈 |
| X1~X10 | 미구현 | 각 도메인 이슈 (08 9장) |
| T·R | 미구현 | cycle·예약 이슈 (04) |
