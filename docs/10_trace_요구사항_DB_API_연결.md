# 10 요구사항·DB·API 연결표

> 기능 ID ↔ 요구사항 ↔ 테이블 ↔ API ↔ 화면 ↔ 테스트

상태: 작성됨 (2026-11-22 · @하다)
근거: 03(REQ), 04(F·T·R), 07(테이블·V1 검증), 08(API·X), 09(S·M), 관문 1 결정 A~D(4장)
ID가 바뀌면 원본 문서를 먼저 고치고 이 표를 맞춘다. 이 표와 원본이 다르면 원본이 맞다.

---

## 1. 기능 기준 연결

| 기능 ID | 단계 | 요구사항 | 테이블 (읽기 / 쓰기) | API | 화면 | 테스트 |
|---|---|---|---|---|---|---|
| F-AUTH-01 | P0-핵심 | REQ-01 | staff, shop / — | 01, 03 | S-01 | X10 |
| F-AUTH-02 | P0-핵심 | REQ-40 | platform_admin / — | 02 | (S-01) | X9 |
| F-HOME-01 | P0-핵심 | REQ-02 | reservation, vehicle, customer, maintenance_record, service_item / — | 04 | S-02 | X7, 07 7.5 기대값 |
| F-CUS-01 | P0-핵심 | REQ-03 | customer, vehicle / — | 05 | S-05, M-01, M-02 | X7 |
| F-CUS-02 | P0-핵심 | REQ-04 | — / customer, vehicle | 06 | M-01 | |
| F-CUS-03 | P0-핵심 | REQ-05 | customer / vehicle | 08 | S-06 | X1 |
| F-CUS-04 | P0-핵심 | REQ-06 | customer, vehicle, maintenance_record, service_item / — | 07 | S-06 | X1 |
| F-CUS-05 | P0-핵심 | REQ-07 | vehicle, customer, maintenance_record, service_item, staff / — | 09, 10, 11 | S-07 | X2 |
| F-MNT-01 | P0-핵심 | REQ-09 | vehicle, service_item / maintenance_record, vehicle(최근 주행거리) | 12, 13 | S-08 | X5, X11, T12 |
| F-VIS-01 | P0-핵심 | REQ-08 | vehicle, maintenance_record, service_item / — | 10 | S-08 | X6, T8~T11 |
| F-CYC-01 | P0-핵심 | REQ-07·08·10 | maintenance_record, service_item / — | 04, 10, 14, 17 | — | T1~T13 |
| F-TGT-01 | P0-핵심 | REQ-10·11 | customer, vehicle, maintenance_record, service_item, reservation / — | 14 | S-04 | X7 |
| F-RSV-01 | P0-핵심 | REQ-11·12 | vehicle, service_item, reservation(진행 중 확인) / reservation, reservation_item | 16, 13 | M-02 | X4, X11, R1~R4 |
| F-RSV-02 | P0-핵심 | REQ-13 | reservation, reservation_item, service_item, vehicle, customer / — | 15 | S-03 | X7 |
| F-RSV-03 | P0-핵심 | REQ-14 | reservation, reservation_item, customer, vehicle, maintenance_record, service_item, staff / — | 17 | S-02, S-03 | X3 |
| F-RSV-04 | P0-핵심 | REQ-15 | reservation / reservation (version) | 18 | S-03 | R5, R10, X12 |
| F-MNT-02 | P0-나머지 | REQ-16 | vehicle, service_item / maintenance_record | 12 | S-08 | T13, X11 |
| F-MNT-03 | P0-나머지 | REQ-17 | vehicle, service_item / maintenance_record(inspect_result, V2) | 12 | S-08 | T15 |
| F-CYC-02 | P0-나머지 | REQ-17 | maintenance_record / — | 10, 14, 17 | S-03, S-04, S-07, S-08 | T14, T15 |
| F-RSV-05 | P0-나머지 | REQ-18 | reservation / — | 15 | S-03 | |
| F-RSV-06 | P0-핵심 | REQ-19 | reservation, service_item / reservation, reservation_item (version) | 19 | M-02 | R7~R9, R11, X11, X12 |
| F-RSV-07 | P0-나머지 | REQ-19 | reservation / reservation (version) | 20 | S-03 | R10, X12 |
| F-RSV-08 | P0-나머지 | REQ-19 | reservation / reservation(NO_SHOW, V2) | 21 | S-03 | R6, R10, X12 |
| F-CUS-06 | P0-나머지 | REQ-20 | customer, vehicle / customer, vehicle (version, V2) | 22, 23 | S-06, S-07 | X12 |
| F-CUS-07 | P0-나머지 | (NFR) | customer / — | 04, 05, 14, 15 | S-02~S-05 | |
| F-CYC-03 | P1 | REQ-21 | maintenance_record / — | 10, 14 | — | T16, T17 |
| F-CUS-08 | P1 | REQ-22 | (10의 응답) | 10 | S-07 | |
| F-CON-01 | P1 | REQ-23 | customer, vehicle, maintenance_record, shop / — | 28 | S-04 | |
| F-CON-02 | P1 | REQ-24 | — / contact_log (P1 추가) | 29 | S-04 | |
| F-NTF-01 | P1 | REQ-32 | ❓ (브라우저 또는 staff) | ❓ | S-09 | |
| F-ADM-01 | P1 | REQ-41 | — / shop, staff, service_item | 31, 32 | S-10 | |
| F-ADM-02 | P1 | REQ-42 | — / shop, staff | 33, 34, 35 | S-10 | |
| F-AUTH-03 | P1 | REQ-26 | — / staff | 24 | S-01 | |
| F-STF-01 | P1 | REQ-30 | — / staff | 25, 26 | S-09 | |
| F-ITEM-01 | P1 | REQ-31 | — / service_item | 13, 27 | S-09 | |
| F-STAT-01 | P1 | REQ-25 | customer, maintenance_record / — | 30 | S-09 ❓ | |

## 2. 테이블 기준 (쓰는 곳)

| 테이블 | 쓰는 기능 | 쓰는 API |
|---|---|---|
| platform_admin | (시드), P1 없음 | — |
| shop | F-ADM-01·02 (P1) | 32~34 |
| staff | F-STF-01, F-AUTH-03, F-ADM-01·02 (P1) | 24, 26, 32, 35 |
| customer | F-CUS-02·06 | 06, 22 |
| vehicle | F-CUS-02·03·06, F-MNT-01(최근 주행거리) | 06, 08, 12, 23 |
| service_item | F-ITEM-01, F-ADM-01 (P1) | 27, 32 |
| maintenance_record | F-MNT-01·02·03 | 12 |
| reservation | F-RSV-01·04·06·07·08 | 16, 18~21 |
| reservation_item | F-RSV-01·06 | 16, 19 |

## 3. 백엔드 패키지 연결 💡 (CONVENTIONS 2장)

| 패키지 | 기능 | API |
|---|---|---|
| global | 인증 필터, 공통 응답, 오류 | 전부 |
| domain/account | F-AUTH-01·02·03, F-STF-01 | 01, 02, 03, 24~26 |
| domain/shop | F-ADM-01·02 | 31~35 |
| domain/customer | F-CUS-01~04·06·07 | 05~09, 22, 23 |
| domain/item | F-ITEM-01 | 13, 27 |
| domain/maintenance | F-MNT-01~03, 이력 조회 | 11, 12 |
| domain/reservation | F-RSV-01·02·04~08 | 15, 16, 18~21 |
| domain/cycle | F-CYC-01·02·03 | (다른 패키지가 호출) |
| screen/visit | F-VIS-01, F-CUS-05 항목 상태 | 10 |
| screen/target | F-TGT-01, F-HOME-01 | 04, 14 |
| screen/booking | F-RSV-03 | 17 |
| (P1) domain/contact | F-CON-01·02 | 28, 29 |
| (P1) screen/stats | F-STAT-01 | 30 |

## 4. 관문 1 결정 연결

결정의 원문은 13 changelog(관문 1, chagok-docs#12). 이 표는 결정이 어느 문서·테스트에 반영됐는지만 잇는다.

| 결정 | 05 정책 | 07 ERD | 08 API | 04·08 테스트 | 07 V1 검증 |
|---|---|---|---|---|---|
| A 정비소별 데이터 무결성 (9개 테이블 유지, 서비스 404 + 복합 FK) | POL-20·21·25 | 1장, 3.4~3.9, 5장 I-2, 5.1 | 0.1 요청 본문 안의 id, 0.3 DB 제약 위반 | X1~X8, X11, X12 | V1-2~V1-5 |
| B 예약 상태 변경 충돌 (`version`, 409 두 가지, 실패 시 유지) | POL-102·104·124 | 3.8 `version` | 6장 18·19·20·21, 상태 변경 요약 | R5, R6, R8~R11 | — |
| C 예약 ↔ 방문 기록 (방문 테이블 없음, `visit_key`, 직접 FK 없음) | POL-50·95·97·101 | 3.7 `visit_key`, 3.8 | 11, 12, 18 | T12 (기록), 수동 확인(TEST 7장) | V1-12 |
| D P0-나머지 API 확정 범위 | POL-96·100·124 | 4장, 6장 V2 | 7.0 | R6, R10, X12 | V1-8, V1-12 |

## 5. 마이그레이션 버전 연결

| 버전 | 단계 | 담는 것 (07 6장) | 쓰는 기능 |
|---|---|---|---|
| `V1__init.sql` | P0-핵심 (B-3) | 9개 테이블, 복합 FK 6개, 부모 UNIQUE(shop_id, id) 4개, CHECK·인덱스 | P0-핵심 전부 |
| `V2__…` | P0-나머지 (12 백로그 V2) | `inspect_result`, `NO_SHOW`, `customer.version`, `vehicle.version` | F-MNT-03, F-CYC-02, F-RSV-08, F-CUS-06 |
| 이후 | P1 | `contact_log` 등 | F-CON-02 등 |
