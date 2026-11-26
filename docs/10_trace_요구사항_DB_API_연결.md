# 10 요구사항·DB·API 연결표

> 기능 ID ↔ 요구사항 ↔ 테이블 ↔ API ↔ 화면 ↔ 테스트

상태: 작성됨 (2026-11-22 · 최은정(eunjung01230)), 2026-11-23 D-51~D-59 반영, 2026-11-23 D-60~D-63 반영(chagok-docs#65)
근거: 03(REQ), 04(F·T·R·H·K·L), 07(테이블·V1 검증), 08(API·X), 09(S·M), M1 결정 A~D(4장), 결정 D-51~D-63
ID가 바뀌면 원본 문서를 먼저 고치고 이 표를 맞춘다. 이 표와 원본이 다르면 원본이 맞다.

---

## 1. 기능 기준 연결

| 기능 ID | 단계 | 요구사항 | 테이블 (읽기 / 쓰기) | API | 화면 | 테스트 |
|---|---|---|---|---|---|---|
| F-AUTH-01 | P0-핵심 | REQ-01 | staff, shop / — | 01, 03 | S-01 | X10, X18, E1~E5, L5 |
| F-AUTH-02 | P0-핵심 | REQ-40 | platform_admin / — | 02 | (S-01) | X9 |
| F-HOME-01 | P0-핵심 | REQ-02 | reservation, vehicle, customer, maintenance_record, service_item / — | 04 | S-02 | X7, 07 7.5 기대값 |
| F-CUS-01 | P0-핵심 | REQ-03 | customer, vehicle / — | 05 | S-05, M-01, M-02 | X7 |
| F-CUS-02 | P0-핵심 | REQ-04 | — / customer, vehicle | 06 | M-01 | |
| F-CUS-03 | P0-핵심 | REQ-05 | customer / vehicle | 08 | S-06 | X1, X17 |
| F-CUS-04 | P0-핵심 | REQ-06 | customer, vehicle, maintenance_record, service_item / — | 07 | S-06 | X1 |
| F-CUS-05 | P0-핵심 | REQ-07 | vehicle, customer, maintenance_record, service_item, staff / — | 09, 10, 11 | S-07 | X2 |
| F-MNT-01 | P0-핵심 | REQ-09 | vehicle, service_item, staff(담당 검증, P0-나머지) / maintenance_record, vehicle(연식·최근 주행거리) | 12, 13 | S-08 | X5, X7(13), X11, T12, X13 |
| F-VIS-01 | P0-핵심 | REQ-08 | vehicle, maintenance_record, service_item / — | 10 | S-08 | X6, T8~T11 |
| F-CYC-01 | P0-핵심 | REQ-07·08·10 | maintenance_record, service_item / — | 04, 10, 14, 17 | — | T1~T13 |
| F-TGT-01 | P0-핵심 | REQ-10·11 | customer, vehicle, maintenance_record, service_item, reservation / — | 14 | S-04 | X7 |
| F-RSV-01 | P0-핵심 | REQ-11·12 | vehicle, service_item, staff(담당 후보·검증, P0-나머지), reservation(유효 예약·담당 중복 확인) / reservation(`assignee_staff_id`), reservation_item | 16, 13, 36 (36은 P0-나머지) | M-02 | X4, X11, R1~R4, R15~R20 (P0-나머지), X13 |
| F-RSV-02 | P0-핵심 | REQ-13 | reservation, reservation_item, service_item, vehicle, customer, staff(담당 이름·색, P0-나머지) / — | 15 | S-02 | X7 |
| F-RSV-03 | P0-핵심 | REQ-14 | reservation, reservation_item, customer, vehicle, maintenance_record, service_item, staff / — | 17 | S-02 | X3 |
| F-RSV-04 | P0-핵심 | REQ-15 | reservation / reservation (version) | 18 | S-02 패널 | R5, R10, R12, R13, X12 |
| F-MNT-02 | P0-나머지 | REQ-16 | vehicle, service_item / maintenance_record | 12 | S-08 | T13, X11 |
| F-MNT-03 | P0-나머지 | REQ-17 | vehicle, service_item / maintenance_record(inspect_result, V2) | 12 | S-08 | T15 |
| F-MNT-04 | P0-나머지 | REQ-27 | maintenance_record, maintenance_record_revision, service_item, staff / maintenance_record (version, V2), maintenance_record_revision (V2), vehicle(최근 주행거리) | 37, 38 | S-07, M-03 | H1~H11, X14 |
| F-CYC-02 | P0-나머지 | REQ-17 | maintenance_record / — | 10, 14, 17 | S-02, S-04, S-07, S-08 | T14, T15 |
| F-RSV-05 | P0-나머지 | REQ-18 | reservation, staff(담당 색) / — | 15, 42 | S-02 | |
| F-RSV-06 | P0-핵심 | REQ-19 | reservation, service_item, staff(재배정·담당 중복, P0-나머지) / reservation, reservation_item, reservation_revision(ASSIGNEE, V2) (version) | 19, 36, 41 (재배정·36·41은 P0-나머지) | M-02 | R7~R9, R11, R14, R18, R20, R24, X11~X13 |
| F-RSV-07 | P0-나머지 | REQ-19 | reservation / reservation (version) | 20 | S-02 패널 | R10, R12, R13, X12 |
| F-RSV-08 | P0-나머지 | REQ-19 | reservation / reservation(NO_SHOW, V2) | 21 | S-02 패널 | R6, R10, R12, R13, X12 |
| F-RSV-09 | P0-나머지 | REQ-28 | reservation, vehicle / reservation(IN_PROGRESS, V2) (version), vehicle(연식·최근 주행거리) | 39 | S-02 패널 | R21~R23, R10, R12, R13, X14 |
| F-RSV-10 | P0-나머지 | REQ-29 | reservation / reservation (version), reservation_revision(STATUS·MEMO, V2) | 40, 41 | S-02 패널 | R25~R29, X14 |
| F-CUS-06 | P0-나머지 | REQ-20 | customer, vehicle / customer, vehicle (version, V2) | 22, 23 | S-06, S-07 | X12 |
| F-CUS-07 | P0-나머지 | (NFR) | customer / — | 04, 05, 14, 15 | S-02, S-04, S-05 | |
| F-CYC-03 | P1 | REQ-21 | maintenance_record / — | 10, 14 | — | T16, T17 |
| F-CUS-08 | P1 | REQ-22 | (10의 응답) | 10 | S-07 | |
| F-CUS-09 | P1 | REQ-35 | customer, vehicle, maintenance_record, service_item, reservation / — | 05, 07 | S-05, S-06 | |
| F-CUS-10 | P1 | REQ-33 | customer, vehicle, reservation, maintenance_record / customer(status, V3), vehicle(active, V3) | 43~47 (05 `includeInactive`) | S-06, S-07 | K1~K5, K8, K9, X15 |
| F-CUS-11 | P1 | REQ-34 | customer, vehicle, reservation, maintenance_record / customer(status·anonymized_at, V3) | 48, 49 | S-09 | K6~K9, X15 |
| F-CON-01 | P1 | REQ-23 | customer, vehicle, maintenance_record, shop / — | 28 | S-04 | |
| F-CON-02 | P1 | REQ-24 | — / contact_log (P1 추가) | 29 | S-04 | |
| F-NTF-01 | P1 | REQ-32 | — (브라우저 저장) | — | S-09 | |
| F-ADM-01 | P1 | REQ-41 | staff(아이디 중복) / shop, staff, service_item | 31, 32 | S-10 | L1~L4, X18 |
| F-ADM-02 | P1 | REQ-42 | — / shop, staff | 33, 34, 35 | S-10 | L4, L15, X18 |
| F-AUTH-03 | P1 | REQ-26 | staff / staff(password_change_required) | 03, 24 | S-01 | L4~L8, L12, L16, X20 |
| F-AUTH-04 | P1 | REQ-37 | staff, terms_agreement(07 4.4 초안) / terms_agreement | 03, 52 | S-01 | L9~L12, X21 |
| F-STF-01 | P1 | REQ-30·36·38 | reservation, staff / staff(active V3, password_change_required) | 25, 26, 50, 51 | S-09 | K10, L1~L4, L13, L14, X15, X16, X19 |
| F-ITEM-01 | P1 | REQ-31 | — / service_item | 13, 27 | S-09 | |
| F-STAT-01 | P1 | REQ-25 | customer, maintenance_record / — | 30 | S-02 | |

X16(서비스 관리자 토큰으로 36~52 → 403)은 36~52를 쓰는 모든 기능(F-RSV-01·06·09·10, F-MNT-04, F-CUS-10·11, F-STF-01, F-AUTH-04)에 해당한다. F-AUTH-03의 API(03·24)는 X16 범위 밖이고 X9와 같은 공통 규칙(서비스 관리자 토큰 → 정비소 API 403)을 따른다. X18(사장·정비사 토큰으로 `/api/admin/**` → 403)은 F-AUTH-02·F-ADM-01·02에 해당한다. X19~X21(P1 계정 상태 확인, 08 0.6)은 모든 정비소 API의 공통 조건이다. R15~R20·X13은 P0-나머지부터 검증한다(P0-핵심은 등록자가 담당으로 자동 지정).

## 2. 테이블 기준 (쓰는 곳)

| 테이블 | 쓰는 기능 | 쓰는 API |
|---|---|---|
| platform_admin | (시드), P1 없음 | — |
| shop | F-ADM-01·02 (P1) | 32~34 |
| staff | F-STF-01(`active`·재발급), F-AUTH-03, F-ADM-01·02 (P1) | 24, 26, 32, 35, 50, 51 |
| terms_agreement (P1, 07 4.4 초안 — DB 담당자 검토 전) | F-AUTH-04 | 52 (03·계정 상태 확인에서 읽기) |
| customer | F-CUS-02·06, F-CUS-10·11 (P1: `status`·`anonymized_at`, 삭제) | 06, 22, 43~45, 49 |
| vehicle | F-CUS-02·03·06, F-MNT-01(연식·최근 주행거리), F-RSV-09(연식·최근 주행거리), F-CUS-10 (P1: `active`) | 06, 08, 12, 23, 39, 46, 47 |
| service_item | F-ITEM-01, F-ADM-01 (P1) | 27, 32 |
| maintenance_record | F-MNT-01·02·03·04 | 12, 37 |
| maintenance_record_revision | F-MNT-04 (V2) | 37 (읽기 38) |
| reservation | F-RSV-01·04·06·07·08·09·10 | 16, 18~21, 39, 40 |
| reservation_item | F-RSV-01·06 | 16, 19 |
| reservation_revision | F-RSV-06(재배정)·10 (V2) | 19, 40 (읽기 41) |

## 3. 백엔드 패키지 연결 💡 (CONVENTIONS 2장)

| 패키지 | 기능 | API |
|---|---|---|
| global | 인증 필터, 공통 응답, 오류 | 전부 |
| domain/account | F-AUTH-01·02·03·04, F-STF-01 (담당 후보 36 포함), 계정 상태 확인(08 0.6, 11 3.3) | 01, 02, 03, 24~26, 36, 50~52 |
| domain/shop | F-ADM-01·02 | 31~35 |
| domain/customer | F-CUS-01~04·06·07·09~11 | 05~09, 22, 23, 43~49 |
| domain/item | F-ITEM-01 | 13, 27 |
| domain/maintenance | F-MNT-01~04, 이력 조회 | 11, 12, 37, 38 |
| domain/reservation | F-RSV-01·02·04~10 | 15, 16, 18~21, 39~42 |
| domain/cycle | F-CYC-01·02·03 | (다른 패키지가 호출) |
| screen/visit | F-VIS-01, F-CUS-05 항목 상태 | 10 |
| screen/target | F-TGT-01, F-HOME-01 | 04, 14 |
| screen/booking | F-RSV-03 | 17 |
| (P1) domain/contact | F-CON-01·02 | 28, 29 |
| (P1) screen/stats | F-STAT-01 | 30 |

## 4. M1 결정 연결

결정의 원문은 13 changelog의 2026-11-22 행(당시 이름 「관문 1 결정 A~D」, chagok-docs#12). 이 표는 결정이 어느 문서·테스트에 반영됐는지만 잇는다.

| 결정 | 05 정책 | 07 ERD | 08 API | 04·08 테스트 | 07 V1 검증 |
|---|---|---|---|---|---|
| A 정비소별 데이터 무결성 (9개 테이블 유지, 서비스 404 + 복합 FK) | POL-20·21·25 | 1장, 3.4~3.9, 5장 I-2, 5.1 | 0.1 요청 본문 안의 id, 0.3 DB 제약 위반 | X1~X8, X11, X12 | V1-2~V1-5 |
| B 예약 상태 변경 충돌 (18~21 화면 `version` 필수, 409 두 가지, 실패 시 유지, 성공 응답 `version`) | POL-102·104·124 | 3.8 `version` | 6장 18·19·20·21, 상태 변경 요약 | R5, R6, R8~R14 | — |
| C 예약 ↔ 방문 기록 (방문 테이블 없음, `visit_key`, 직접 FK 없음) | POL-50·95·97·101 | 3.7 `visit_key`, 3.8 | 11, 12, 18 | T12 (기록), 수동 확인(TEST 7장) | V1-12 |
| D P0-나머지 API 확정 범위 | POL-96·100·124 | 4장, 6장 V2 | 7.0 | R6, R10, R12, R13, X12 | V1-8, V1-12 |
| 승인 항목 (쪽 나누기 기본 20·최대 50, 생성·수정 시각 서버 `Clock`) | 11장 입력 검증 | 1장, 6.1·6.2, 6.3 V1-13, 7장 | 0.1 | — | V1-13 |

## 5. 마이그레이션 버전 연결

| 버전 | 단계 | 담는 것 (07 6장) | 쓰는 기능 |
|---|---|---|---|
| `V1__init.sql` | P0-핵심 (B-3) | 9개 테이블, 복합 FK 8개(+ `reservation`·`maintenance_record`의 담당 정비사 → `staff`), 부모 UNIQUE(shop_id, id) 5개(`staff` 추가), `reservation.assignee_staff_id`, CHECK·인덱스 | P0-핵심 전부 |
| `V2__…` | P0-나머지 (12 백로그 V2) | `inspect_result`, `NO_SHOW`, `IN_PROGRESS`, `customer.version`, `vehicle.version`, `maintenance_record.updated_at`·`version`·UNIQUE, `maintenance_record_revision`, `reservation_revision`, `shop.brn`·`shop.shop_address`(D-73) | F-MNT-03·04, F-CYC-02, F-RSV-08·09·10, F-CUS-06, F-ADM-01(P1, 칼럼만 먼저) |
| `V3__…` | P1 | `customer.status`·`anonymized_at`, `vehicle.active`, `staff.active`, `contact_log` 등. 약관 동의 기록(07 4.4)은 V3 또는 별도 버전 — DB 담당자 결정 | F-CUS-10·11, F-STF-01, F-CON-02, F-AUTH-04 등 |
