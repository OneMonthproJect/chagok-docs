# 07 ERD · DB 설계서

> 테이블·관계·제약조건·격리 규칙·시드 구성 — **테이블·컬럼·제약·격리 I-xx·시드표의 원본**

상태: 작성됨 (2026-11-22 · @하다) — 관문 1에서 확정. 확정 후 바꾸려면 `결정` 이슈 → 이 문서 + 13 changelog → 새 Flyway 버전 파일
근거: 00·04, 상세 기획안 v11 10장, 결정 D-04·D-05·D-07·D-11·D-17·D-21~D-27·D-36·D-38·D-42, 관문 1 결정 A~D (13 changelog, chagok-docs#12)
DB: MySQL 8 (InnoDB, utf8mb4), Flyway. 💡 = 제안값

---

## 1. 원칙

- 원안 8개 테이블 + 예약 목적 연결 표 1개 = **9개**. 차례가 오지 않은 단계의 테이블·컬럼은 미리 만들지 않는다(4장).
- `platform_admin`을 뺀 모든 테이블은 정비소에 속한다. 고객·차량·정비 기록·예약·예약 목적은 `shop_id`를 **직접** 가진다(D-05).
- PK는 `BIGINT AUTO_INCREMENT`. 전화번호·차량번호를 키로 쓰지 않는다.
- 상태(미확인/여유/임박/도래), "예약 있음", "처리 필요", "지난 방문 거절", "지난 점검 주의"는 **저장하지 않는다**. 조회 때 계산한다.
- enum은 `VARCHAR` + `CHECK`로 둔다(값 추가가 쉬움) 💡. 값 이름은 08 API와 글자까지 같다.
- 시각은 `DATETIME`(소수 초 없음 = 정밀도 0, Asia/Seoul 기준) 💡, 날짜는 `DATE`. 예약 시각만 초를 00으로 강제한다(3.8).
- 모든 테이블에 `created_at`. 수정되는 표에만 `updated_at`.
- **생성·수정 시각은 서버가 넣는다 (관문 1 확정).** `created_at`은 최초 생성 시각, `updated_at`은 생성 때도 같은 값으로 넣고 실제로 수정될 때 갱신한다. 값은 JPA Auditing이 넣고, Auditing의 시간 공급자(`DateTimeProvider`)는 주입한 `Clock` 빈(Asia/Seoul)을 쓴다. 두 칼럼은 `NOT NULL`이고 **DB `DEFAULT`·`CURRENT_TIMESTAMP`·`ON UPDATE`를 쓰지 않는다**(DB 세션 시간대와 서버 `Clock`이 어긋나지 않게). 시드는 시각을 직접 적는다(7장). 예약 `version`은 시각과 별개로 `@Version`이 관리한다.
- **정비소 일치는 두 겹으로 지킨다 (관문 1 결정 A).** ① 서버가 저장 전 부모를 `getOwned(shopId, id)`로 찾는다(없거나 남의 것이면 404). ② DB는 핵심 부모·자식 관계를 **복합 FK** `(shop_id, 부모_id) → 부모(shop_id, id)`로 묶어, 서버 검증이 빠져도 다른 정비소 부모를 가리키는 행이 저장되지 않게 한다. 복합 FK의 부모 쪽에는 `UNIQUE(shop_id, id)`를 둔다(MySQL 8.4부터 FK는 UNIQUE·PK 키만 참조할 수 있다). 대상 관계와 이유는 5.1.
- FK의 삭제·수정 동작은 모두 기본값(`RESTRICT`)이다. 삭제 기능이 없고(05 POL-39·58), `CASCADE`·`SET NULL`은 쓰지 않는다(`SET NULL`은 `shop_id NOT NULL`과 충돌).

## 2. ERD

```mermaid
erDiagram
  platform_admin ||--o{ shop : "만듦 (P1)"
  shop ||--o{ staff : ""
  shop ||--o{ customer : ""
  shop ||--o{ service_item : ""
  customer ||--o{ vehicle : ""
  vehicle ||--o{ maintenance_record : ""
  service_item ||--o{ maintenance_record : ""
  staff ||--o{ maintenance_record : "기록함"
  vehicle ||--o{ reservation : ""
  staff ||--o{ reservation : "등록함"
  reservation ||--o{ reservation_item : "예약 목적"
  service_item ||--o{ reservation_item : ""
```

`customer → vehicle`, `vehicle → maintenance_record·reservation`, `service_item → maintenance_record·reservation_item`, `reservation → reservation_item` 6개 관계는 `shop_id`를 함께 묶은 복합 FK다(5.1). 예약과 정비 기록 사이에는 선이 없다(3.8).

## 3. 테이블

### 3.1 `platform_admin` — 서비스 관리자 (D-07)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| login_id | VARCHAR(50) | NOT NULL, UNIQUE | |
| password_hash | VARCHAR(100) | NOT NULL | BCrypt 💡 |
| name | VARCHAR(50) | NOT NULL | |
| created_at | DATETIME | NOT NULL | |

`shop_id`가 없다. 정비소 데이터로 가는 경로가 구조적으로 없다.

### 3.2 `shop` — 정비소

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| name | VARCHAR(50) | NOT NULL | 문자 초안(P1)의 정비소명 |
| phone | VARCHAR(20) | NOT NULL | 문자 초안(P1)의 정비소 연락처 |
| status | VARCHAR(20) | NOT NULL, CHECK IN ('ACTIVE','SUSPENDED'), 기본 'ACTIVE' | 정지는 P1(F-ADM-02) |
| created_by_admin_id | BIGINT | NULL, FK → platform_admin.id | 시드 정비소는 NULL |
| created_at | DATETIME | NOT NULL | |

### 3.3 `staff` — 사장·정비사 계정

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| login_id | VARCHAR(50) | NOT NULL, UNIQUE | 정비소를 넘어 전체에서 유일 💡 |
| password_hash | VARCHAR(100) | NOT NULL | |
| name | VARCHAR(50) | NOT NULL | |
| role | VARCHAR(20) | NOT NULL, CHECK IN ('OWNER','MECHANIC') | |
| password_change_required | BOOLEAN | NOT NULL, 기본 FALSE | 임시 비밀번호 계정 (P1에서 사용) |
| created_at | DATETIME | NOT NULL | |

`login_id`는 `platform_admin`과 겹쳐도 된다(로그인 API가 다르다, 08).

### 3.4 `customer` — 고객

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| name | VARCHAR(50) | NOT NULL | |
| phone | VARCHAR(20) | NOT NULL | 숫자·하이픈 💡. 중복 허용 |
| consent | BOOLEAN | NOT NULL, 기본 FALSE | 안내 수신 동의 (D-11). "연락 가능 여부" 칸은 두지 않음 (D-25) |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

- UNIQUE(shop_id, id): 복합 FK 부모 키 (vehicle이 참조, 5.1). 정비소별 최근 등록순 목록(05 API)에도 쓰인다.
- 인덱스: (shop_id, phone), (shop_id, name) 💡

### 3.5 `vehicle` — 차량 (고객 1:N)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | 고객의 `shop_id`와 같아야 함 (I-2) |
| customer_id | BIGINT | NOT NULL, FK (shop_id, customer_id) → customer(shop_id, id) | 복합 FK (5.1) |
| plate_number | VARCHAR(20) | NOT NULL | 공백 제거. **중복 허용** (UNIQUE 없음) |
| model | VARCHAR(50) | NULL | 차종 |
| model_year | SMALLINT | NULL | 연식. 범위(1980~올해+1)는 서버 검증만 (올해는 CHECK에 쓸 수 없음) |
| latest_mileage | INT | NULL, CHECK ≥ 0 | 최근 주행거리. 등록 때 입력 또는 방문 기록으로 갱신 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

- UNIQUE(shop_id, id): 복합 FK 부모 키 (maintenance_record·reservation이 참조)
- 인덱스: (shop_id, plate_number), (shop_id, customer_id) — 뒤의 것은 복합 FK 인덱스이자 고객의 차량 목록 조회용 (이전 `(customer_id)` 대체)

### 3.6 `service_item` — 정비 항목·주기 (정비소별)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| code | VARCHAR(30) | NOT NULL | 아래 6개. UNIQUE(shop_id, code) |
| name | VARCHAR(30) | NOT NULL | 화면 표시명 |
| cycle_months | SMALLINT | NOT NULL, CHECK > 0 | |
| cycle_km | INT | NOT NULL, CHECK > 0 | |
| active | BOOLEAN | NOT NULL, 기본 TRUE | 끄기·켜기는 P1(F-ITEM-01) |
| sort_order | SMALLINT | NOT NULL | 표시 순서, 도면 위치와 연결 |
| created_at | DATETIME | NOT NULL | 1장 원칙 "모든 테이블에 `created_at`" 반영 (관문 1). 수정(P1 F-ITEM-01) 때의 `updated_at`은 P1 착수 때 더한다 |

- UNIQUE(shop_id, code), UNIQUE(shop_id, id): 뒤의 것은 복합 FK 부모 키 (maintenance_record·reservation_item이 참조)

기본 기준표 (D-01) — 정비소마다 이 6행을 가진다:

| code | name | cycle_months | cycle_km | sort_order |
|---|---|---|---|---|
| ENGINE_OIL | 엔진오일 | 6 | 10000 | 1 |
| AIR_CLEANER | 에어클리너 | 12 | 15000 | 2 |
| AC_FILTER | 에어컨필터 | 6 | 10000 | 3 |
| BRAKE_PAD | 브레이크패드 | 12 | 20000 | 4 |
| TIRE | 타이어 상태 점검 | 6 | 10000 | 5 |
| BATTERY | 배터리 | 36 | 60000 | 6 |

### 3.7 `maintenance_record` — 정비 기록 (항목마다 1행, D-04)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| vehicle_id | BIGINT | NOT NULL, FK (shop_id, vehicle_id) → vehicle(shop_id, id) | 복합 FK (5.1) |
| service_item_id | BIGINT | NOT NULL, FK (shop_id, service_item_id) → service_item(shop_id, id) | 복합 FK (5.1) |
| visit_key | CHAR(36) | NOT NULL | 한 번 저장한 방문의 묶음 번호(UUID) 💡. **서버가 저장 요청(API 12) 하나마다 새로 만든다.** 요청으로 받지 않고, 예약 번호와 잇지 않는다. 여러 행이 같은 값을 가지므로 UNIQUE 아님 |
| record_date | DATE | NOT NULL | 방문일. 외부는 고객이 말한 정비일 |
| mileage | INT | NULL, CHECK ≥ 0 | 방문 주행거리. 외부는 확인 가능할 때만 |
| record_type | VARCHAR(20) | NOT NULL, CHECK IN ('REPLACE','INSPECT','EXTERNAL','DECLINE') | 교체·점검·외부·거절 (D-06). 4개 모두 P0-핵심부터 |
| source | VARCHAR(20) | NOT NULL, CHECK IN ('SHOP','CUSTOMER_STATEMENT') | EXTERNAL이면 CUSTOMER_STATEMENT, 나머지는 SHOP |
| staff_id | BIGINT | NOT NULL, FK → staff.id | 저장한 계정 💡. 토큰의 계정이라 같은 정비소가 보장되므로 단일 FK (5.1) |
| memo | VARCHAR(200) | NULL | |
| created_at | DATETIME | NOT NULL | 같은 날 기록끼리의 순서 (같으면 `id`가 큰 것이 나중) |

- CHECK: `(record_type = 'EXTERNAL') = (source = 'CUSTOMER_STATEMENT')`
- 인덱스: (shop_id, vehicle_id, service_item_id, record_date) — 주기 계산 조회이자 vehicle 복합 FK 인덱스 (이전 `(vehicle_id, service_item_id, record_date)` 앞에 `shop_id`를 붙임), (shop_id, service_item_id) — service_item 복합 FK 인덱스, (shop_id, visit_key)
- 한 저장 요청의 행은 모두 같은 `visit_key`·`vehicle_id`·`staff_id`다. `record_date`는 외부면 고객이 말한 정비일, 나머지는 방문일. `mileage`는 외부면 확인된 주행거리(없으면 NULL), 나머지는 방문 주행거리. 같은 방문에 같은 항목 두 번 불가(05 POL-57)는 서버가 검증한다(요청 안의 중복이고 `visit_key`를 다시 쓰지 않으므로 DB 제약을 두지 않음).
- 수정·삭제하지 않는다(정정은 P2). `updated_at` 없음.
- **P0-나머지에 추가 (D-36)**: `inspect_result VARCHAR(20) NULL, CHECK IN ('GOOD','CAUTION')` + CHECK `inspect_result IS NULL OR record_type = 'INSPECT'`. V1에는 만들지 않고 `V2`로 더한다(6장).

### 3.8 `reservation` — 예약

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| vehicle_id | BIGINT | NOT NULL, FK (shop_id, vehicle_id) → vehicle(shop_id, id) | 복합 FK (5.1) |
| reserved_at | DATETIME | NOT NULL | 30분 단위 (D-21). 서버 검증 + CHECK `MINUTE(reserved_at) IN (0,30) AND SECOND(reserved_at) = 0` 💡 (08 16 "분 00·30, 초 00") |
| status | VARCHAR(20) | NOT NULL, CHECK IN ('RESERVED','COMPLETED','CANCELED') | P0-나머지 V2에 'NO_SHOW' 추가 (D-27). CHECK는 V2가 지우고 다시 만들 수 있게 이름을 붙인다(6장) |
| purpose_other | BOOLEAN | NOT NULL, 기본 FALSE | 예약 목적 "기타" (D-38) |
| purpose_memo | VARCHAR(200) | NULL | 예약 목적 메모 |
| created_by_staff_id | BIGINT | NOT NULL, FK → staff.id | 토큰의 계정이라 단일 FK (5.1) |
| version | INT | NOT NULL, 기본 0 | 동시 수정 확인(JPA `@Version`). 바뀔 때마다 1 증가 (D-42). 변경(19)·방문 완료(18)·취소(20)·노쇼(21) 모두 화면이 보낸 `version`을 이 값과 비교하고, 저장 때 `@Version`으로 다시 확인한다(관문 1 결정 B, 08 6장). 예약 목적 항목(`reservation_item`)만 바뀌어도 1 올린다. 실패한 요청은 이 값을 바꾸지 않는다 |
| created_at | DATETIME | NOT NULL | |
| updated_at | DATETIME | NOT NULL | |

- UNIQUE(shop_id, id): 복합 FK 부모 키 (reservation_item이 참조)
- 인덱스: (shop_id, reserved_at), (shop_id, vehicle_id, status, reserved_at) — 진행 중 예약 확인이자 vehicle 복합 FK 인덱스 (이전 `(vehicle_id, status, reserved_at)` 앞에 `shop_id`를 붙임)
- "같은 차량 진행 중 1건"(D-22)은 서버에서 확인한다. 진행 중 = 상태 `RESERVED` + 예약 **날짜** ≥ 오늘. 날짜 조건이 들어가 DB 유일 제약으로 막지 않는다. 동시 등록까지 막는 것은 P2.
- 정비 기록과 잇는 컬럼은 없다(관문 1 결정 C). 방문 완료 → 정비 기록은 화면 이동이고, 저장 순서·실패 처리는 05 POL-95.

### 3.9 `reservation_item` — 예약 목적으로 고른 항목 (D-38)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| shop_id | BIGINT | NOT NULL, FK → shop.id | |
| reservation_id | BIGINT | NOT NULL, FK (shop_id, reservation_id) → reservation(shop_id, id) | 복합 FK (5.1) |
| service_item_id | BIGINT | NOT NULL, FK (shop_id, service_item_id) → service_item(shop_id, id) | 복합 FK (5.1) |
| created_at | DATETIME | NOT NULL | 1장 원칙 반영 (관문 1) |

- UNIQUE(reservation_id, service_item_id)
- 인덱스: (shop_id, reservation_id), (shop_id, service_item_id) — 복합 FK 인덱스
- 예약을 변경하면(**P0-핵심**, F-RSV-06·D-42) 이 행들을 지우고 다시 넣는다 💡. JPA는 한 번의 flush에서 INSERT를 DELETE보다 먼저 보내므로, 같은 항목을 다시 넣으면 위 UNIQUE에 걸린다. 지우기를 먼저 실행(벌크 삭제 쿼리 또는 삭제 후 flush)한 뒤 넣는다.

## 4. 나중에 추가할 것 (지금 만들지 않음)

| 단계 | 추가 | 내용 |
|---|---|---|
| P0-나머지 | `maintenance_record.inspect_result` | 3.7 |
| P0-나머지 | `reservation.status`에 `NO_SHOW` | 3.8 |
| P0-나머지 | `customer.version`, `vehicle.version` | 고객·차량 수정(F-CUS-06)을 만들 때 동시 수정 확인용 (POL-124) |
| P1 | 연락 기록 표 💡 `contact_log` | shop_id, customer_id, result(❓ 값 목록), memo, contacted_at, staff_id. F-CON-02 착수 때 |
| P1 | `staff` 알림 시간 컬럼 | F-NTF-01 저장 위치를 `staff`로 정할 때만 |
| P2 | 방문 테이블 분리, 동의 이력, 노쇼 관리 등 | 상세 기획안 13장 |

## 5. 격리 규칙 (I-xx)

| ID | 규칙 | 지키는 곳 |
|---|---|---|
| I-1 | 정비소 데이터 테이블은 모두 `shop_id NOT NULL` | 이 문서, 마이그레이션 |
| I-2 | 자식의 `shop_id`는 부모의 `shop_id`와 같다 (차량↔고객, 기록·예약↔차량, 기록·예약 목적↔정비 항목, 예약 목적↔예약) | ① 서버: 저장 전 `getOwned(shopId, id)`로 부모를 먼저 찾아서 그 `shop_id`를 씀 ② DB: 복합 FK (5.1, V1 검증 6.3) |
| I-3 | 정비소 데이터 조회는 모두 토큰의 `shop_id` 조건을 건다. 요청 값의 `shop_id`는 쓰지 않는다 | Repository `…AndShopId`, X8 |
| I-4 | 없거나 남의 것이면 같은 404 | `getOwned`, X1~X6 |
| I-5 | `platform_admin`에는 `shop_id`가 없고, 관리자 토큰으로는 정비소 테이블을 조회할 경로가 없다 | SecurityConfig, X9 |

### 5.1 정비소 간 참조 분석 (관문 1 결정 A)

자식 행이 다른 정비소의 부모를 가리킬 수 있는지 관계마다 본 결과다. "요청 값"이면 화면이 보낸 id라 남의 id가 들어올 수 있고, "토큰"이면 서버가 로그인 정보에서 넣으므로 들어올 수 없다.

| 관계 (자식 → 부모) | 부모 id 출처 | 서버 검증 | DB 제약 | 남의 것을 가리킬 때 |
|---|---|---|---|---|
| staff → shop | 시드 / P1 개설 | — | FK `shop_id` | — |
| customer → shop | 토큰 | — | FK `shop_id` | — |
| service_item → shop | 시드 / P1 개설 | — | FK `shop_id`, UNIQUE(shop_id, code) | — |
| vehicle → customer | 요청 값 (경로 `customerId`, API 08) | `getOwned` | **복합 FK** (shop_id, customer_id) | 404 (X1) |
| maintenance_record → vehicle | 요청 값 (경로, API 12) | `getOwned` | **복합 FK** (shop_id, vehicle_id) | 404 (X5) |
| maintenance_record → service_item | 요청 값 (`records[].itemId`) | 그 정비소의 쓰는 항목인지 | **복합 FK** (shop_id, service_item_id) | 400 `INVALID_INPUT` (X11) |
| reservation → vehicle | 요청 값 (`vehicleId`, API 16) | `getOwned` | **복합 FK** (shop_id, vehicle_id) | 404 (X4) |
| reservation_item → reservation | 서버 (저장한 예약) | 16·19 안에서 같은 트랜잭션 | **복합 FK** (shop_id, reservation_id) | — |
| reservation_item → service_item | 요청 값 (`purpose.itemIds`) | 그 정비소의 쓰는 항목인지 | **복합 FK** (shop_id, service_item_id) | 400 `INVALID_INPUT` (X11) |
| maintenance_record → staff | 토큰 | — | FK `staff_id` | 구조상 없음 |
| reservation → staff (`created_by_staff_id`) | 토큰 | — | FK | 구조상 없음 |
| shop → platform_admin | P1 관리자 토큰 | — | FK (NULL 허용) | 정비소 범위 밖 |

- 복합 FK는 위 6개만 둔다. staff를 가리키는 두 관계는 값이 토큰에서만 오므로 복합 FK와 `staff`의 UNIQUE(shop_id, id)를 더하지 않는다(불필요한 제약을 늘리지 않음).
- 복합 FK의 부모 쪽 UNIQUE(shop_id, id)는 customer·vehicle·service_item·reservation 4개 테이블에만 있다. `id`가 PK라 값이 겹칠 일은 없고, FK가 참조할 키를 만드는 용도다.
- 각 테이블의 `shop_id → shop.id` 단일 FK도 그대로 둔다(I-1). 복합 FK 인덱스가 `shop_id`로 시작하므로 인덱스가 늘지 않는다.
- 서버 검증이 먼저다. 복합 FK 위반(MySQL 1452)이 실제로 나면 서버 검증이 빠진 버그이므로 500 `INTERNAL_ERROR`로 처리하고(트랜잭션 롤백), 404·409로 바꿔 숨기지 않는다(08 0.3).

## 6. 마이그레이션 계획 (Flyway)

| 버전 💡 | 단계 | 내용 |
|---|---|---|
| `V1__init.sql` | P0-핵심 (`기반` 이슈 B-3) | 9개 테이블, 제약, 인덱스 (6.1~6.3) |
| `V2__…` | P0-나머지 | `inspect_result`(+ CHECK 2개), `reservation.status` CHECK에 `NO_SHOW`, `customer.version`·`vehicle.version`(`INT NOT NULL DEFAULT 0`). **4건을 한 파일로**, DB 담당자가 P0-나머지 착수 때(중간 점검 통과 후) 기능 이슈(12 백로그 19·24)보다 먼저 만든다 |
| 이후 | P1 | 연락 기록 등 |

마이그레이션은 `chagok-backend/src/main/resources/db/migration/`에만 두고 DB 담당자가 작성한다. 시연 데이터는 마이그레이션이 아니다(7장). 운영용 기본 기준표는 정비소를 만들 때 서버가 넣는다(P1, F-ADM-01).

### 6.1 V1 생성 순서와 이름 규칙

부모가 먼저 있어야 FK를 만들 수 있다. 복합 FK가 참조하는 UNIQUE(shop_id, id)는 부모의 `CREATE TABLE` 안에 둔다.

| 순서 | 테이블 | 먼저 있어야 하는 것 |
|---|---|---|
| 1 | platform_admin | — |
| 2 | shop | platform_admin |
| 3 | staff | shop |
| 4 | customer | shop |
| 5 | service_item | shop |
| 6 | vehicle | shop, customer (UNIQUE(shop_id, id)) |
| 7 | maintenance_record | shop, vehicle·service_item (UNIQUE(shop_id, id)), staff |
| 8 | reservation | shop, vehicle (UNIQUE(shop_id, id)), staff |
| 9 | reservation_item | shop, reservation·service_item (UNIQUE(shop_id, id)) |

- `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4` (콜레이션은 MySQL 8 기본 `utf8mb4_0900_ai_ci`).
- 제약에 이름을 붙인다 💡: `uk_{테이블}_{칼럼}`, `fk_{자식}_{부모}`, `ck_{테이블}_{칼럼}`, `idx_{테이블}_{칼럼}`. MySQL은 FK·CHECK 이름이 스키마 안에서 유일해야 하고, V2가 `ck_reservation_status`를 `DROP CHECK` 후 다시 만들어야 하므로 이름이 필요하다.
- FK 칼럼 순서는 부모 키와 같게 `(shop_id, 부모_id)`. 자식 쪽 인덱스는 같은 순서로 시작해야 한다(3장 표의 인덱스가 그 역할). 인덱스를 따로 적지 않으면 MySQL이 이름 없는 인덱스를 만들므로 3장대로 명시한다.
- `staff.shop_id`, `shop.created_by_admin_id`, `maintenance_record.staff_id`, `reservation.created_by_staff_id`의 단일 FK 인덱스도 명시한다.
- 시연 시드는 V1에 넣지 않는다(7장). 기본 기준표 6행도 시드가 정비소마다 넣는다.
- 타임스탬프 칼럼(`created_at`·`updated_at`)은 `DATETIME NOT NULL`로만 만들고 `DEFAULT`를 붙이지 않는다(1장, 관문 1 확정). `version`·`consent`·`status` 등 타임스탬프가 아닌 칼럼의 기본값(3장)은 그대로 둔다.

### 6.2 JPA 매핑 확인 (`ddl-auto: validate`)

`validate`는 테이블·칼럼·타입을 비교하고 FK·인덱스·CHECK는 보지 않는다. 그래서 **복합 FK는 Flyway에만 두고 Entity에 옮기지 않는다.**

| 대상 | 매핑 |
|---|---|
| `shop_id`, 다른 도메인 id (`vehicle_id`, `service_item_id`, `staff_id` 등) | `Long` 기본 칼럼 (CONVENTIONS: 다른 도메인은 ID로만) |
| vehicle → customer (같은 도메인) | `Long customerId` 기본 칼럼. `@ManyToOne`을 쓰려면 `@JoinColumn(name = "customer_id", insertable = false, updatable = false)` 읽기 전용으로. `shop_id`가 두 매핑에 겹치므로 `@JoinColumns` 복합 매핑은 쓰지 않는다 |
| `SMALLINT` (model_year, cycle_months, sort_order) | `Short` (`Integer`면 validate가 타입 불일치로 실패) |
| `INT` (version, mileage, latest_mileage, cycle_km) | `Integer` |
| `CHAR(36)` visit_key | `String` + `@JdbcTypeCode(SqlTypes.CHAR)` 또는 `columnDefinition = "char(36)"` |
| enum (`VARCHAR` + CHECK) | `@Enumerated(EnumType.STRING)`. validate가 MySQL `enum` 타입을 기대해 실패하면 `@JdbcTypeCode(SqlTypes.VARCHAR)`를 붙인다 (첫 dbTest에서 확인) |
| `BOOLEAN` | `boolean`/`Boolean` (MySQL `TINYINT(1)`) |
| reservation.version | `@Version Integer version` |
| `created_at`·`updated_at` | `LocalDateTime` + `@CreatedDate`·`@LastModifiedDate` (`@EntityListeners(AuditingEntityListener.class)`), `@EnableJpaAuditing(dateTimeProviderRef = …)`로 `Clock` 기반 `DateTimeProvider` 지정. `created_at`은 `updatable = false`. `updated_at`이 없는 표(platform_admin·shop·staff·service_item·maintenance_record·reservation_item)는 `created_at`만 매핑 |

### 6.3 V1 검증 체크리스트 (DB 담당자, B-3 PR)

빈 MySQL 8에 Flyway를 적용한 뒤(`backend-ci` db-test) 확인한다. SQL 실행 결과를 PR 본문에 적고, 돌리지 못한 항목은 "미검증"으로 남긴다.

| ID | 확인 | 기대 |
|---|---|---|
| V1-1 | 빈 DB에 V1 적용, 앱 기동(`validate`) | 성공. 테이블 9개 |
| V1-2 | `information_schema`의 FK 목록 | 복합 FK 6개 + 단일 FK(`shop_id` 7개, staff 2개, admin 1개) |
| V1-3 | A 정비소 고객 id로 B 정비소 `vehicle` INSERT (`shop_id` = B) | 실패 (1452) |
| V1-4 | B 정비소 차량·항목으로 A 정비소 `maintenance_record`·`reservation` INSERT | 실패 (1452) |
| V1-5 | B 정비소 예약·항목을 가리키는 A 정비소 `reservation_item` INSERT | 실패 (1452) |
| V1-6 | `reserved_at` 10:15 / 10:30:15 INSERT | 실패 (CHECK) |
| V1-7 | `record_type = 'EXTERNAL'`, `source = 'SHOP'` INSERT | 실패 (CHECK) |
| V1-8 | `reservation.status = 'NO_SHOW'` INSERT | 실패 (V1에는 없음, V2에서 허용) |
| V1-9 | 같은 정비소 `service_item.code` 중복, 같은 예약에 같은 항목 두 번 | 실패 (UNIQUE) |
| V1-10 | 같은 정비소 같은 `plate_number` 차량 2대 | 성공 (중복 허용, POL-32) |
| V1-11 | 시연 시드(`run-demo-seed.sh`)를 V1 위에 적용 | 성공, 07 7.5 기대값 |
| V1-12 | V1에 P0-나머지·P1 칼럼·값(`inspect_result`, `NO_SHOW`, `customer.version`, `contact_log`)이 없음 | 없음 |
| V1-13 | `created_at`(·`updated_at`)을 빼고 INSERT / `SHOW CREATE TABLE`의 타임스탬프 칼럼 | 실패(1364, 기본값 없음) / `DEFAULT`·`ON UPDATE` 없음 |

V1-3~V1-10·V1-13은 SQL로 직접 확인하거나 `@Tag("db")` 테스트로 남긴다(TEST 명세서 6.1).

## 7. 시드 구성 (시연·테스트)

시연 데이터 정책 (D-43·D-44):

| 항목 | 규칙 |
|---|---|
| 위치 | `chagok-backend/db/seed/demo_seed.sql` (classpath 밖. 서버·Flyway가 읽지 않는다) |
| 넣는 곳 | 시연 전용 DB 💡 `chagok_demo`에만. 개발·운영 DB에는 넣지 않는다 |
| 실행 | `db/seed/run-demo-seed.sh`로만. DB 이름(`_demo`), Flyway 적용 여부, 빈 DB인지 확인하고 아니면 거부 |
| 다시 넣기 | 시드는 지우지 않는다(`DELETE`·`TRUNCATE`·`DROP`·`ALTER`·`CREATE`·`UPDATE` 금지). 시연 DB를 새로 만들고 Flyway 적용 → 시드 순서로 다시 한다 |
| 작성 | ERD 확정과 `V1__init.sql` 뒤 DB 담당자 |
| 날짜 | 모두 **오늘(D) 기준 상대값**. 경계에서 1주 이상 떨어뜨리고, 월말·윤년은 시드에 쓰지 않는다(T6·T7은 단위 테스트) |
| 생성·수정 시각 | 모든 행에 `created_at`(있으면 `updated_at`)을 직접 적는다. DB 기본값이 없으므로 빠뜨리면 INSERT가 실패한다(V1-13). 값은 그 행의 날짜 칼럼과 어긋나지 않게 💡 |

### 7.1 정비소·계정

| 정비소 | 이름 | 계정 |
|---|---|---|
| A | 차곡카센터 (02-0000-0001) | 사장 1, 정비사 1 |
| B | 바른카센터 (02-0000-0002) | 사장 1 |
| — | — | 서비스 관리자 1 (`platform_admin`) |

| 시연 계정 💡 | 역할 | 비밀번호 |
|---|---|---|
| `owner_a` | A 정비소 사장 | `1234` |
| `mech_a` | A 정비소 정비사 | `1234` |
| `owner_b` | B 정비소 사장 | `1234` |
| `admin` | 서비스 관리자 | `1234` |

시연 DB에만 있다. 비밀번호는 BCrypt 해시로 넣고, `password_change_required = false`(첫 로그인 변경 강제 안 함). 운영 환경에는 만들지 않는다 (D-44, 05 POL-17).

### 7.2 A 정비소 고객·차량과 기대 상태

"교체 D-6M-7d"는 오늘에서 6개월 전보다 7일 더 이전. 항목을 적지 않은 나머지 항목은 미확인.

| 고객 (동의) | 차량 | 기록 | 기대 (개월 기준) | 대상 목록 | 단계별 확인 |
|---|---|---|---|---|---|
| 김민수 010-0000-0001 (Y) | 12가0001 | 엔진오일 교체 D-6M-7d (40,000km), 엔진오일 점검 D-2M | 엔진오일 도래 | ○ | T12 (점검은 기준이 아님) |
| 이영희 010-0000-0002 (Y) | 34나0002 | 엔진오일 교체 D-6M-10d | 엔진오일 도래 | ○ 예약 있음 (D+2일 10:00) | D-13 |
| 박철수 010-0000-0003 (Y) | 56다0003 | 브레이크패드 교체 D-12M+20d | 브레이크패드 임박 (다음 정비일 D+20일) | ○ | |
| 최지은 010-0000-0004 (Y) | 78라0004 | 엔진오일 교체 D-2M (45,000km) | 엔진오일 여유 | × | 시나리오 B: 주행거리 55,000 입력 → 도래 |
| 정우성 010-0000-0005 (Y) | 90마0005 | 없음 | 전부 미확인 | × | T1 |
| 한가람 010-0000-0006 (Y) | 11바0006 | 엔진오일 교체 D-8M, 엔진오일 거절 D-1M | 엔진오일 도래 | ○ | P0-나머지부터 "지난 방문 거절" |
| 서민준 010-0000-0007 (Y) | 22사0007 | 에어컨필터 교체 D-13M, 에어컨필터 외부 D-1M (고객 진술) | 에어컨필터 여유 | × | 외부로 재시작 |
| 윤하늘 010-0000-0008 (Y) | 33아0008 | 타이어 교체 D-6M+20d, 타이어 점검 D-2M | 타이어 임박 | ○ | P0-나머지부터 점검 결과 "주의" + 메모 (V2 이후 시드에 반영) |
| 장미래 010-0000-0009 (**N**) | 44자0009 | 엔진오일 교체 D-7M | 엔진오일 도래 | × (미동의) | |
| 오세훈 010-0000-0010 (Y) | 55차0010 | 배터리 교체 D-36M+20d, 엔진오일 교체 D-1M, 에어클리너 교체 D-3M, 에어컨필터 교체 D-3M | 배터리 임박 | ○ | 이력 많은 차량 (방문 3회 이상) |
| 〃 | 66카0011 | 없음 | 전부 미확인 | × | 한 고객 여러 차량 |

차종·연식·최근 주행거리는 08 JSON 예시와 같게 넣는다: 78라0004 K5·2020·45,000km, 55차0010 쏘나타·2018·97,000km, 90마0005 아반떼·2019. 그 밖은 비워도 된다.

### 7.3 A 정비소 예약

| 차량 | 일시 | 상태 | 예약 목적 | 확인 |
|---|---|---|---|---|
| 78라0004 | 오늘 10:00 | 예약 | 엔진오일 | 오늘 예약, 시나리오 B 시작점 |
| 22사0007 | 오늘 14:30 | 예약 | 기타 + 메모 "에어컨 냄새" | 오늘 예약 |
| 34나0002 | D+2일 10:00 | 예약 | 엔진오일 | "예약 있음" |
| 55차0010 | 어제 15:00 | 예약 | 배터리 | **처리 필요** (D-23), "예약 있음"으로 세지 않음 |

### 7.4 B 정비소

| 고객 | 차량 | 기록 | 확인 |
|---|---|---|---|
| 강동원 010-0000-0101 (Y) | **12가0001** (A의 김민수와 같은 번호) | 엔진오일 교체 D-7M | A에서 검색해도 안 보임 (X7), A 토큰으로 id 조회 시 404 (X1·X2) |

### 7.5 시드 기대값 (매일 마감 전 확인용)

| 항목 | 기대값 |
|---|---|
| 홈 "오늘 예약" | 2건 |
| 홈 "오늘 연락할 고객" | 5명 (김민수·박철수·한가람·윤하늘·오세훈) |
| 재점검 대상 목록 | 6대 (위 5명의 차량 + 이영희 34나0002 "예약 있음") |
| A 정비소 고객 수 | 10명, 차량 11대 |

시드는 `chagok-seed-data` 스킬로 만들고(`demo_seed.sql`), 기대값이 바뀌면 이 절과 08 JSON 예시를 같이 고친다.
