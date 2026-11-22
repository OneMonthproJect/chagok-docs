# 08 API 명세서

> 엔드포인트·요청·응답·에러 코드·격리 테스트 — **API 번호, 요청·응답, 에러 코드, X-xx, JSON 예시의 원본**

상태: 작성됨 (2026-11-22 · @하다) — 관문 1에서 확정. 확정 후 바꾸려면 `결정` 이슈 → 이 문서(표 + JSON 예시) + 13 changelog → 코드 PR
근거: 04 기능 명세, 07 ERD, 06 권한. 💡 = 제안값. ❓ = 결정 필요(문서 끝 목록)

---

## 0. 공통

### 0.1 기본

| 항목 | 규칙 |
|---|---|
| 주소 | 정비소 API `/api/**`, 관리자 API `/api/admin/**` |
| 형식 | JSON, UTF-8. 필드 이름은 camelCase |
| 인증 | `Authorization: Bearer {accessToken}`. 로그인 API(01·02)만 토큰 없이 |
| 날짜 | `"2026-11-24"` (DATE) |
| 일시 | `"2026-11-24T10:00:00"` (Asia/Seoul, 시간대 표기 없음) 💡 |
| 목록 쪽 나누기 | `?page=0&size=20`. size 최대 50 (`PageLimit`) 💡 |
| 정비소 | 요청에 `shopId`를 받지 않는다. 토큰의 `shop_id`만 쓴다 (I-3) |
| 예시 값 | 07 시드 구성의 값. 오늘(D)은 예시에서 `2026-11-24`로 둔다 |

### 0.2 공통 응답

성공:

```json
{
  "success": true,
  "data": { },
  "error": null
}
```

실패 (모든 에러 응답은 이 모양 하나):

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_INPUT",
    "message": "입력값을 확인해 주세요.",
    "fieldErrors": [
      { "field": "reservedAt", "reason": "30분 단위로 입력해 주세요." }
    ],
    "details": null
  }
}
```

`fieldErrors`는 `INVALID_INPUT`일 때만 채우고, 그 밖에는 빈 배열. `details`는 화면이 다음 행동을 안내하는 데 필요한 값만 담는다(지금은 `RESERVATION_ACTIVE_EXISTS`의 `{ "reservationId": 3 }` 하나). 그 밖에는 `null`.

**오류 응답과 화면 처리 (05 POL-120~129)**

| 상황 | 응답 | 화면 |
|---|---|---|
| 입력 오류 | 400 `INVALID_INPUT` + `fieldErrors` | 필드 옆에 메시지, 입력값 유지 |
| 같은 차량 진행 중 예약 | 409 `RESERVATION_ACTIVE_EXISTS` + `details.reservationId` | 기존 예약 상세 패널을 열어 확인·변경 안내 |
| 다른 직원이 먼저 수정 | 409 `CONCURRENT_MODIFICATION` | 덮어쓰지 않음. 최신 내용을 다시 불러와 보여주고 다시 수정하게 함 |
| 인증 만료 | 401 `AUTH_REQUIRED` | 로그인 안내 → 로그인 화면 |
| 권한 없음 | 403 `FORBIDDEN` | 권한 안내 |
| 없음·남의 데이터 | 404 `NOT_FOUND` | "찾을 수 없습니다" (있는지 여부를 드러내지 않음) |
| 서버 오류 | 500 `INTERNAL_ERROR` | 공통 오류 안내, 입력값 유지. 서버는 그 요청의 변경을 모두 되돌린다(트랜잭션) |
| 네트워크 오류·응답 없음 | (응답 없음) | 입력값 유지. 저장됐는지 목록·이력에서 확인한 뒤 사람이 다시 저장. **자동으로 다시 보내지 않는다** |

목록 응답의 `data`:

```json
{
  "items": [ ],
  "page": 0,
  "size": 20,
  "totalElements": 10,
  "totalPages": 1
}
```

### 0.3 에러 코드 (`ErrorCode`와 1:1)

| 코드 | HTTP | 언제 | 단계 |
|---|---|---|---|
| `AUTH_REQUIRED` | 401 | 토큰 없음·만료·위조 | P0-핵심 |
| `LOGIN_FAILED` | 401 | 아이디 없음·비밀번호 틀림 (같은 응답) | P0-핵심 |
| `FORBIDDEN` | 403 | 역할이 맞지 않음 (관리자 → 정비소 API, 정비사 → 사장 전용 API) | P0-핵심 |
| `NOT_FOUND` | 404 | 없거나 다른 정비소 것 (D-12) | P0-핵심 |
| `INVALID_INPUT` | 400 | 검증 실패, 잘못된 JSON, 타입 불일치, 30분 단위 아님 | P0-핵심 |
| `RESERVATION_PAST_DATE` | 400 | 예약 날짜가 어제 이전 (D-23) | P0-핵심 |
| `RESERVATION_ACTIVE_EXISTS` | 409 | 같은 차량에 진행 중 예약이 있음 (D-22) | P0-핵심 |
| `INVALID_STATUS_TRANSITION` | 409 | 허용되지 않은 예약 상태 변경 | P0-핵심 |
| `CONFLICT` | 409 | 유일 제약 위반 (아이디 중복 등) | P0-핵심 |
| `CONCURRENT_MODIFICATION` | 409 | 읽은 뒤 다른 직원이 먼저 바꿈 (`version` 불일치, D-42) | P0-핵심 |
| `INTERNAL_ERROR` | 500 | 그 밖 | P0-핵심 |
| `SHOP_SUSPENDED` | 403 | 정지된 정비소 계정 로그인 | P1 |
| `PASSWORD_CHANGE_REQUIRED` | 403 | 임시 비밀번호 상태에서 다른 API 호출 | P1 |

`message`는 화면에 그대로 보여 줄 수 있는 한국어 문장. 405·415 같은 표준 예외도 `INVALID_INPUT`으로 감싼다.

### 0.4 값 목록 (enum)

| 이름 | 값 |
|---|---|
| 역할 `role` | `OWNER` 사장 · `MECHANIC` 정비사 · `ADMIN` 서비스 관리자 |
| 점검 주기 상태 `status` | `UNKNOWN` 미확인 · `AHEAD` 여유 · `SOON` 임박 · `DUE` 도래 |
| 도래 근거 `dueReason` | `DATE` 날짜 · `KM` 주행거리 · `null` |
| 정비 구분 `type` | `REPLACE` 교체 · `INSPECT` 점검 · `EXTERNAL` 외부 · `DECLINE` 거절 |
| 출처 `source` | `SHOP` 우리 정비소 · `CUSTOMER_STATEMENT` 고객 진술 |
| 점검 결과 `inspectResult` (P0-나머지) | `GOOD` 양호 · `CAUTION` 주의 |
| 예약 상태 `status` | `RESERVED` 예약 · `COMPLETED` 방문 완료 · `CANCELED` 취소 · `NO_SHOW` 노쇼(P0-나머지) |
| 항목 `code` | `ENGINE_OIL` · `AIR_CLEANER` · `AC_FILTER` · `BRAKE_PAD` · `TIRE` · `BATTERY` |

### 0.5 연락처 표시

목록 응답(04·05·14·15)의 `phone`은 P0-나머지부터 서버가 마스킹한 값(`010-****-0001`, F-CUS-07). 상세 응답(07·09·17)과 문자 초안(28)의 `phone`은 전체 번호(D-40). 아래 목록 예시는 P0-핵심 기준(마스킹 전).

## 1. API 목록

| 번호 | 메서드 | 경로 | 기능 | 단계 | 권한 |
|---|---|---|---|---|---|
| 01 | POST | `/api/auth/login` | F-AUTH-01 | P0-핵심 | 없음 |
| 02 | POST | `/api/admin/auth/login` | F-AUTH-02 | P0-핵심 | 없음 |
| 03 | GET | `/api/me` | F-AUTH-01 | P0-핵심 | 사장·정비사 |
| 04 | GET | `/api/home` | F-HOME-01 | P0-핵심 | 사장·정비사 |
| 05 | GET | `/api/customers` | F-CUS-01 | P0-핵심 | 사장·정비사 |
| 06 | POST | `/api/customers` | F-CUS-02 | P0-핵심 | 사장·정비사 |
| 07 | GET | `/api/customers/{customerId}` | F-CUS-04 | P0-핵심 | 사장·정비사 |
| 08 | POST | `/api/customers/{customerId}/vehicles` | F-CUS-03 | P0-핵심 | 사장·정비사 |
| 09 | GET | `/api/vehicles/{vehicleId}` | F-CUS-05 | P0-핵심 | 사장·정비사 |
| 10 | GET | `/api/vehicles/{vehicleId}/item-status` | F-CYC-01, F-VIS-01 | P0-핵심 | 사장·정비사 |
| 11 | GET | `/api/vehicles/{vehicleId}/visits` | F-CUS-05 | P0-핵심 | 사장·정비사 |
| 12 | POST | `/api/vehicles/{vehicleId}/visits` | F-MNT-01·02·03 | P0-핵심 | 사장·정비사 |
| 13 | GET | `/api/items` | F-MNT-01, F-RSV-01 | P0-핵심 | 사장·정비사 |
| 14 | GET | `/api/targets` | F-TGT-01 | P0-핵심 | 사장·정비사 |
| 15 | GET | `/api/reservations` | F-RSV-02·05 | P0-핵심 | 사장·정비사 |
| 16 | POST | `/api/reservations` | F-RSV-01 | P0-핵심 | 사장·정비사 |
| 17 | GET | `/api/reservations/{reservationId}/panel` | F-RSV-03 | P0-핵심 | 사장·정비사 |
| 18 | POST | `/api/reservations/{reservationId}/complete` | F-RSV-04 | P0-핵심 | 사장·정비사 |
| 19 | PATCH | `/api/reservations/{reservationId}` | F-RSV-06 | P0-핵심 | 사장·정비사 |
| 20 | POST | `/api/reservations/{reservationId}/cancel` | F-RSV-07 | P0-나머지 | 사장·정비사 |
| 21 | POST | `/api/reservations/{reservationId}/no-show` | F-RSV-08 | P0-나머지 | 사장·정비사 |
| 22 | PATCH | `/api/customers/{customerId}` | F-CUS-06 | P0-나머지 | 사장·정비사 |
| 23 | PATCH | `/api/vehicles/{vehicleId}` | F-CUS-06 | P0-나머지 | 사장·정비사 |
| 24 | POST | `/api/me/password` | F-AUTH-03 | P1 | 사장·정비사 |
| 25 | GET | `/api/staff` | F-STF-01 | P1 | 사장 |
| 26 | POST | `/api/staff` | F-STF-01 | P1 | 사장 |
| 27 | PATCH | `/api/items/{itemId}` | F-ITEM-01 | P1 | 사장 |
| 28 | GET | `/api/targets/{customerId}/message-draft` | F-CON-01 | P1 | 사장·정비사 |
| 29 | POST | `/api/contacts` | F-CON-02 | P1 | 사장·정비사 |
| 30 | GET | `/api/stats/customers` | F-STAT-01 | P1 | 사장·정비사 |
| 31 | GET | `/api/admin/shops` | F-ADM-01 | P1 | 관리자 |
| 32 | POST | `/api/admin/shops` | F-ADM-01 | P1 | 관리자 |
| 33 | POST | `/api/admin/shops/{shopId}/suspend` | F-ADM-02 | P1 | 관리자 |
| 34 | POST | `/api/admin/shops/{shopId}/resume` | F-ADM-02 | P1 | 관리자 |
| 35 | POST | `/api/admin/shops/{shopId}/owner-password-reset` | F-ADM-02 | P1 | 관리자 |

F-NTF-01(아침 알림)은 저장 위치에 따라 API가 없을 수 있다(P1 착수 때).

---

## 2. 인증

### 01 POST `/api/auth/login` — 사장·정비사 로그인

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| loginId | string | ○ | 1~50자 |
| password | string | ○ | 1~100자 |

```json
{ "loginId": "owner_a", "password": "********" }
```

| 응답 data | 타입 | 설명 |
|---|---|---|
| accessToken | string | JWT |
| tokenType | string | `"Bearer"` |
| expiresIn | number | 초. 💡 43200 (12시간) |
| staff | object | 03 응답과 같은 모양 |

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9.example.signature",
    "tokenType": "Bearer",
    "expiresIn": 43200,
    "staff": { "staffId": 1, "name": "박사장", "role": "OWNER", "shopId": 1, "shopName": "차곡카센터" }
  },
  "error": null
}
```

에러: `LOGIN_FAILED`, `INVALID_INPUT`, (P1) `SHOP_SUSPENDED`

### 02 POST `/api/admin/auth/login` — 서비스 관리자 로그인

요청은 01과 같다. 토큰에 `shop_id`가 없다.

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9.admin.signature",
    "tokenType": "Bearer",
    "expiresIn": 43200,
    "admin": { "adminId": 1, "name": "운영관리자", "role": "ADMIN" }
  },
  "error": null
}
```

### 03 GET `/api/me` — 내 계정

```json
{
  "success": true,
  "data": { "staffId": 1, "name": "박사장", "role": "OWNER", "shopId": 1, "shopName": "차곡카센터" },
  "error": null
}
```

## 3. 홈

### 04 GET `/api/home`

| 응답 data | 타입 | 설명 |
|---|---|---|
| date | date | 오늘 |
| todayReservationCount | number | 오늘 예약 중 취소 제외 💡 |
| todayContactCount | number | 오늘 연락할 고객 수 (04 F-HOME-01) |
| todayReservations | array | 15의 항목과 같은 모양, 시각 순, 취소 포함 💡 |

```json
{
  "success": true,
  "data": {
    "date": "2026-11-24",
    "todayReservationCount": 2,
    "todayContactCount": 5,
    "todayReservations": [
      {
        "reservationId": 1,
        "reservedAt": "2026-11-24T10:00:00",
        "status": "RESERVED",
        "needsAction": false,
        "version": 0,
        "vehicleId": 4,
        "plateNumber": "78라0004",
        "customerId": 4,
        "customerName": "최지은",
        "phone": "010-0000-0004",
        "purposeSummary": "엔진오일"
      },
      {
        "reservationId": 2,
        "reservedAt": "2026-11-24T14:30:00",
        "status": "RESERVED",
        "needsAction": false,
        "version": 0,
        "vehicleId": 7,
        "plateNumber": "22사0007",
        "customerId": 7,
        "customerName": "서민준",
        "phone": "010-0000-0007",
        "purposeSummary": "기타"
      }
    ]
  },
  "error": null
}
```

## 4. 고객·차량

### 05 GET `/api/customers?q=&page=&size=` — 검색·목록

`q`는 고객명·연락처·차량번호 일부(공백·하이픈 무시) 💡. 비우면 전체(최근 등록순).

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "customerId": 1,
        "name": "김민수",
        "phone": "010-0000-0001",
        "consent": true,
        "vehicles": [ { "vehicleId": 1, "plateNumber": "12가0001" } ]
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  },
  "error": null
}
```

### 06 POST `/api/customers` — 신규 고객 + 첫 차량

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| name | string | ○ | 1~50자 |
| phone | string | ○ | 숫자·하이픈, 9~20자 💡 |
| consent | boolean | ○ | 기본 false를 화면이 보냄 |
| vehicle.plateNumber | string | ○ | 1~20자, 공백 제거 |
| vehicle.model | string | | ~50자 |
| vehicle.modelYear | number | | 1980~올해+1 💡 |
| vehicle.mileage | number | | 0 이상 |

```json
{
  "name": "정우성",
  "phone": "010-0000-0005",
  "consent": true,
  "vehicle": { "plateNumber": "90마0005", "model": "아반떼", "modelYear": 2019, "mileage": null }
}
```

```json
{
  "success": true,
  "data": { "customerId": 5, "vehicleId": 5 },
  "error": null
}
```

차량번호 중복은 막지 않는다(에러 없음).

### 07 GET `/api/customers/{customerId}` — 고객 상세

```json
{
  "success": true,
  "data": {
    "customerId": 10,
    "name": "오세훈",
    "phone": "010-0000-0010",
    "consent": true,
    "vehicles": [
      { "vehicleId": 10, "plateNumber": "55차0010", "model": "쏘나타", "modelYear": 2018, "latestMileage": 97000, "dueCount": 0, "soonCount": 1 },
      { "vehicleId": 11, "plateNumber": "66카0011", "model": null, "modelYear": null, "latestMileage": null, "dueCount": 0, "soonCount": 0 }
    ]
  },
  "error": null
}
```

에러: `NOT_FOUND` (X1)

### 08 POST `/api/customers/{customerId}/vehicles` — 차량 추가

요청은 06의 `vehicle`과 같다.

```json
{ "plateNumber": "66카0011", "model": null, "modelYear": null, "mileage": null }
```

```json
{ "success": true, "data": { "customerId": 10, "vehicleId": 11 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT`

### 09 GET `/api/vehicles/{vehicleId}` — 차량 정보

```json
{
  "success": true,
  "data": {
    "vehicleId": 4,
    "plateNumber": "78라0004",
    "model": "K5",
    "modelYear": 2020,
    "latestMileage": 45000,
    "customer": { "customerId": 4, "name": "최지은", "phone": "010-0000-0004", "consent": true }
  },
  "error": null
}
```

에러: `NOT_FOUND` (X2)

### 10 GET `/api/vehicles/{vehicleId}/item-status?mileage=` — 항목 상태 · 저장 전 미리보기

`mileage`를 주면 방문 중 안내(F-VIS-01, km 판정 포함), 안 주면 날짜 기준만. 기록을 남기지 않는다.

| 응답 items[] | 타입 | 설명 |
|---|---|---|
| itemId, code, name | | 항목 |
| status | enum | `UNKNOWN`·`AHEAD`·`SOON`·`DUE` |
| dueReason | enum/null | 도래면 `DATE` 또는 `KM` (둘 다면 `DATE`) |
| baseRecord | object/null | 기준 기록 `{ date, mileage, type }` |
| nextDueDate | date/null | 다음 정비일 (P1부터 월평균 반영) |
| nextDueMileage | number/null | 기준 km + 주기 km (기준 기록 km 없으면 null) |
| lastDecline | object/null | P0-나머지부터. `{ date, memo }` |
| lastCaution | object/null | P0-나머지부터. `{ date, memo }` |

```json
{
  "success": true,
  "data": {
    "vehicleId": 4,
    "asOf": "2026-11-24",
    "inputMileage": 55000,
    "items": [
      {
        "itemId": 1, "code": "ENGINE_OIL", "name": "엔진오일",
        "status": "DUE", "dueReason": "KM",
        "baseRecord": { "date": "2026-09-24", "mileage": 45000, "type": "REPLACE" },
        "nextDueDate": "2027-03-24", "nextDueMileage": 55000
      },
      {
        "itemId": 2, "code": "AIR_CLEANER", "name": "에어클리너",
        "status": "UNKNOWN", "dueReason": null,
        "baseRecord": null, "nextDueDate": null, "nextDueMileage": null
      }
    ]
  },
  "error": null
}
```

예시는 6개 중 2개만 적었다. 실제 응답은 쓰는 항목 전부(`sortOrder` 순). 에러: `NOT_FOUND` (X6), `INVALID_INPUT`(음수)

### 11 GET `/api/vehicles/{vehicleId}/visits?page=&size=` — 방문 단위 정비 이력

`visit_key`로 묶어 최신순. 기록마다 자기 날짜가 있다(외부는 고객이 말한 날짜).

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "visitKey": "3f1c2b9e-0000-4000-8000-000000000003",
        "visitDate": "2026-10-24",
        "mileage": 97000,
        "staffName": "이정비",
        "records": [
          { "recordId": 31, "itemId": 1, "itemName": "엔진오일", "type": "REPLACE", "date": "2026-10-24", "memo": null }
        ]
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 3,
    "totalPages": 1
  },
  "error": null
}
```

P0-나머지부터 `records[]`에 `source`, `inspectResult`가 붙는다. `visitDate`는 그 묶음에서 외부가 아닌 기록의 날짜(외부만 있으면 그 날짜).

### 12 POST `/api/vehicles/{vehicleId}/visits` — 방문·정비 기록 저장

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| visitDate | date | ○ | 오늘 이전·오늘 💡 |
| mileage | number | | 0 이상 |
| records[] | array | ○ | 1개 이상, 같은 itemId 중복 불가 |
| records[].itemId | number | ○ | 그 정비소의 쓰는 항목 |
| records[].type | enum | ○ | P0-핵심 `REPLACE`·`INSPECT` / P0-나머지 `EXTERNAL`·`DECLINE` |
| records[].memo | string | | ~200자 |
| records[].externalDate | date | 외부면 ○ | P0-나머지. 오늘 이전 |
| records[].externalMileage | number | | P0-나머지. 0 이상 |
| records[].inspectResult | enum | | P0-나머지. `INSPECT`일 때만 `GOOD`·`CAUTION` |

P0-핵심 요청 예시:

```json
{
  "visitDate": "2026-11-24",
  "mileage": 55000,
  "records": [
    { "itemId": 1, "type": "REPLACE", "memo": null },
    { "itemId": 5, "type": "INSPECT", "memo": "앞 타이어 마모 확인" }
  ]
}
```

P0-나머지 요청 예시:

```json
{
  "visitDate": "2026-11-24",
  "mileage": 55000,
  "records": [
    { "itemId": 1, "type": "REPLACE", "memo": null },
    { "itemId": 4, "type": "DECLINE", "memo": "다음 방문 때 하기로 함" },
    { "itemId": 3, "type": "EXTERNAL", "externalDate": "2026-10-01", "externalMileage": null, "memo": "다른 곳에서 교체했다고 함" },
    { "itemId": 5, "type": "INSPECT", "inspectResult": "CAUTION", "memo": "앞 타이어 마모" }
  ]
}
```

```json
{
  "success": true,
  "data": { "vehicleId": 4, "visitKey": "3f1c2b9e-0000-4000-8000-000000000012", "savedCount": 2 },
  "error": null
}
```

저장한 계정이 담당 정비사가 된다 💡. 주행거리가 차량의 최근 주행거리보다 크면 갱신. 에러: `NOT_FOUND` (X5), `INVALID_INPUT`

### 13 GET `/api/items` — 정비 항목·주기

```json
{
  "success": true,
  "data": [
    { "itemId": 1, "code": "ENGINE_OIL", "name": "엔진오일", "cycleMonths": 6, "cycleKm": 10000, "active": true, "sortOrder": 1 },
    { "itemId": 2, "code": "AIR_CLEANER", "name": "에어클리너", "cycleMonths": 12, "cycleKm": 15000, "active": true, "sortOrder": 2 },
    { "itemId": 3, "code": "AC_FILTER", "name": "에어컨필터", "cycleMonths": 6, "cycleKm": 10000, "active": true, "sortOrder": 3 },
    { "itemId": 4, "code": "BRAKE_PAD", "name": "브레이크패드", "cycleMonths": 12, "cycleKm": 20000, "active": true, "sortOrder": 4 },
    { "itemId": 5, "code": "TIRE", "name": "타이어 상태 점검", "cycleMonths": 6, "cycleKm": 10000, "active": true, "sortOrder": 5 },
    { "itemId": 6, "code": "BATTERY", "name": "배터리", "cycleMonths": 36, "cycleKm": 60000, "active": true, "sortOrder": 6 }
  ],
  "error": null
}
```

## 5. 재점검 대상

### 14 GET `/api/targets` — 재점검 대상 목록

쪽 나누기 없이 전부 💡(`// LIMIT: 정비소당 대상 수백 건 이하 가정`). 정렬: 도래가 있는 차량 먼저, 그다음 가장 이른 다음 정비일 순.

| 응답 items[] | 설명 |
|---|---|
| customerId, customerName, phone | phone은 P0-나머지부터 마스킹 |
| vehicleId, plateNumber | |
| targetItems[] | 도래·임박 항목만 `{ itemId, name, status, nextDueDate, baseDate }`. P0-나머지부터 `lastDecline`·`lastCaution` |
| activeReservation | 진행 중 예약 `{ reservationId, reservedAt }` 또는 null ("예약 있음") |

```json
{
  "success": true,
  "data": {
    "asOf": "2026-11-24",
    "items": [
      {
        "customerId": 1, "customerName": "김민수", "phone": "010-0000-0001",
        "vehicleId": 1, "plateNumber": "12가0001",
        "targetItems": [
          { "itemId": 1, "name": "엔진오일", "status": "DUE", "nextDueDate": "2026-11-17", "baseDate": "2026-05-17" }
        ],
        "activeReservation": null
      },
      {
        "customerId": 2, "customerName": "이영희", "phone": "010-0000-0002",
        "vehicleId": 2, "plateNumber": "34나0002",
        "targetItems": [
          { "itemId": 1, "name": "엔진오일", "status": "DUE", "nextDueDate": "2026-11-14", "baseDate": "2026-05-14" }
        ],
        "activeReservation": { "reservationId": 3, "reservedAt": "2026-11-26T10:00:00" }
      }
    ]
  },
  "error": null
}
```

시드 기준 실제 응답은 6대(07 7.5). 안내 수신 미동의 고객은 나오지 않는다.

## 6. 예약

### 15 GET `/api/reservations?from=&to=` — 기간 조회 (날짜별 목록·캘린더)

`from`·`to`는 날짜(둘 다 포함). 최대 42일 💡(월 보기 6주). 취소·노쇼 포함, 시각 순. 월 보기의 날짜별 건수는 화면이 이 목록으로 센다 💡.

| 응답 items[] | 설명 |
|---|---|
| reservationId, reservedAt, status | |
| needsAction | `status = RESERVED`이고 시각이 지남 → "처리 필요" (D-23) |
| version | 동시 수정 확인용 번호. 변경(19) 요청에 그대로 보낸다 (D-42) |
| vehicleId, plateNumber, customerId, customerName, phone | phone은 P0-나머지부터 마스킹 |
| purposeSummary | 고른 항목 이름을 `·`로 잇고, 기타면 "기타". 없으면 null |

```json
{
  "success": true,
  "data": {
    "from": "2026-11-23",
    "to": "2026-11-23",
    "items": [
      {
        "reservationId": 4,
        "reservedAt": "2026-11-23T15:00:00",
        "status": "RESERVED",
        "needsAction": true,
        "version": 0,
        "vehicleId": 10, "plateNumber": "55차0010",
        "customerId": 10, "customerName": "오세훈", "phone": "010-0000-0010",
        "purposeSummary": "배터리"
      }
    ]
  },
  "error": null
}
```

### 16 POST `/api/reservations` — 예약 등록

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| vehicleId | number | ○ | 그 정비소 차량 |
| reservedAt | datetime | ○ | 분이 00·30, 초 00 (R1). 날짜 ≥ 오늘 (R2) |
| purpose.itemIds | number[] | | 그 정비소의 쓰는 항목, 중복 없음 |
| purpose.other | boolean | | 기본 false |
| purpose.memo | string | | ~200자 |

```json
{
  "vehicleId": 1,
  "reservedAt": "2026-11-27T11:30:00",
  "purpose": { "itemIds": [1], "other": false, "memo": null }
}
```

```json
{
  "success": true,
  "data": { "reservationId": 5, "status": "RESERVED", "reservedAt": "2026-11-27T11:30:00", "vehicleId": 1, "version": 0 },
  "error": null
}
```

에러: `NOT_FOUND` (X4), `INVALID_INPUT`, `RESERVATION_PAST_DATE`, `RESERVATION_ACTIVE_EXISTS` (R3)

`RESERVATION_ACTIVE_EXISTS`는 기존 예약 번호를 함께 준다. 화면은 그 예약의 상세 패널을 열어 확인·변경하게 한다(전화 예약 중 기존 예약 발견, 02 2.2):

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "RESERVATION_ACTIVE_EXISTS",
    "message": "이 차량에는 진행 중인 예약이 있습니다. 기존 예약을 확인하고 변경해 주세요.",
    "fieldErrors": [],
    "details": { "reservationId": 3 }
  }
}
```

### 17 GET `/api/reservations/{reservationId}/panel` — 예약 상세 패널

| 응답 data | 설명 |
|---|---|
| reservation | `{ reservationId, reservedAt, status, needsAction, purpose: { items: [{ itemId, name }], other, memo } }` |
| customer | `{ customerId, name, phone, consent }` (phone 전체, D-40) |
| vehicle | `{ vehicleId, plateNumber, model, modelYear, latestMileage }` |
| recentVisits | 최근 방문 최대 3회 (11의 항목 모양) |
| hasMoreVisits | 더 있으면 true → 차량 상세로 |
| itemStatuses | 10의 `items` 모양 + `highlighted`(예약 목적으로 고른 항목) |

```json
{
  "success": true,
  "data": {
    "reservation": {
      "reservationId": 1,
      "reservedAt": "2026-11-24T10:00:00",
      "status": "RESERVED",
      "needsAction": false,
      "version": 0,
      "purpose": { "items": [ { "itemId": 1, "name": "엔진오일" } ], "other": false, "memo": null }
    },
    "customer": { "customerId": 4, "name": "최지은", "phone": "010-0000-0004", "consent": true },
    "vehicle": { "vehicleId": 4, "plateNumber": "78라0004", "model": "K5", "modelYear": 2020, "latestMileage": 45000 },
    "recentVisits": [
      {
        "visitKey": "3f1c2b9e-0000-4000-8000-000000000004",
        "visitDate": "2026-09-24",
        "mileage": 45000,
        "staffName": "이정비",
        "records": [ { "recordId": 4, "itemId": 1, "itemName": "엔진오일", "type": "REPLACE", "date": "2026-09-24", "memo": null } ]
      }
    ],
    "hasMoreVisits": false,
    "itemStatuses": [
      {
        "itemId": 1, "code": "ENGINE_OIL", "name": "엔진오일",
        "status": "AHEAD", "dueReason": null,
        "baseRecord": { "date": "2026-09-24", "mileage": 45000, "type": "REPLACE" },
        "nextDueDate": "2027-03-24", "nextDueMileage": 55000,
        "highlighted": true
      }
    ]
  },
  "error": null
}
```

`itemStatuses`는 예시에서 1개만 적었다(실제는 쓰는 항목 전부). 에러: `NOT_FOUND` (X3)

### 18 POST `/api/reservations/{reservationId}/complete` — 방문 완료

요청 본문 없음. `RESERVED`만 가능(시각 전·후 모두).

```json
{ "success": true, "data": { "reservationId": 1, "status": "COMPLETED", "vehicleId": 4 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_STATUS_TRANSITION` (R5)

### 19 PATCH `/api/reservations/{reservationId}` — 변경 (P0-핵심, D-42)

`RESERVED`만. 보낸 필드만 바꾼다. 고객·차량은 바꿀 수 없다(바꾸려면 취소 후 새로 등록).

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| version | number | ○ | 화면이 읽은 예약의 `version` (15·16·17 응답). 서버 값과 다르면 409 `CONCURRENT_MODIFICATION` |
| reservedAt | datetime | | 16과 같음: 30분 단위, 날짜 ≥ 오늘 |
| purpose.itemIds | number[] | | 보내면 예약 목적 항목 전체를 이 목록으로 바꾼다 |
| purpose.other | boolean | | |
| purpose.memo | string | | ~200자 |

서버가 확인하는 것: 정비소 소유(`getOwned`, 아니면 404) → 상태가 `RESERVED`인지 → `version` 일치 → 시각·날짜 규칙 → 같은 차량 진행 중 1건(자기 자신 제외). 하나라도 어긋나면 아무것도 바꾸지 않는다.

```json
{ "version": 0, "reservedAt": "2026-11-28T09:00:00", "purpose": { "itemIds": [1, 4], "other": false, "memo": null } }
```

```json
{ "success": true, "data": { "reservationId": 3, "status": "RESERVED", "reservedAt": "2026-11-28T09:00:00", "vehicleId": 2, "version": 1 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT`, `RESERVATION_PAST_DATE` (R7), `RESERVATION_ACTIVE_EXISTS`, `INVALID_STATUS_TRANSITION`, `CONCURRENT_MODIFICATION` (R8)

### 20 POST `/api/reservations/{reservationId}/cancel` — 취소 (P0-나머지)

```json
{ "success": true, "data": { "reservationId": 3, "status": "CANCELED", "vehicleId": 2 }, "error": null }
```

### 21 POST `/api/reservations/{reservationId}/no-show` — 노쇼 (P0-나머지)

`RESERVED`이고 시각이 지난 예약만 (R6).

```json
{ "success": true, "data": { "reservationId": 4, "status": "NO_SHOW", "vehicleId": 10 }, "error": null }
```

### 예약 상태 변경 요약

| 현재 → | 방문 완료 (18) | 일시·목적 변경 (19) | 취소 (20) | 노쇼 (21) |
|---|---|---|---|---|
| RESERVED, 시각 전 | ○ | ○ | ○ | × |
| RESERVED, 시각 지남 (처리 필요) | ○ | ○ (오늘 이후로) | ○ | ○ |
| COMPLETED · CANCELED · NO_SHOW | × | × | × | × |

× = `INVALID_STATUS_TRANSITION`. 방문 완료·취소·노쇼도 다른 직원이 같은 예약을 먼저 바꿨으면 `CONCURRENT_MODIFICATION`(서버의 `version` 확인)이나 `INVALID_STATUS_TRANSITION`으로 실패하고, 상태를 덮어쓰지 않는다.

## 7. 고객·차량 수정 (P0-나머지)

### 22 PATCH `/api/customers/{customerId}`

보낸 필드만. `name`·`phone`·`consent` (검증은 06과 같음).

```json
{ "consent": false }
```

```json
{ "success": true, "data": { "customerId": 1, "name": "김민수", "phone": "010-0000-0001", "consent": false }, "error": null }
```

동의를 해제하면 재점검 대상·홈 숫자에서 바로 빠진다.

### 23 PATCH `/api/vehicles/{vehicleId}`

`plateNumber`·`model`·`modelYear`. 고객은 바꾸지 않는다.

```json
{ "model": "K5 하이브리드" }
```

```json
{ "success": true, "data": { "vehicleId": 4, "plateNumber": "78라0004", "model": "K5 하이브리드", "modelYear": 2020 }, "error": null }
```

## 8. P1 API

요청·응답의 큰 모양만 정한다. **표와 JSON 예시는 그 기능의 P1 착수 PR에서 이 문서에 채운다**(CONTRIBUTING 7장). ❓는 P1 착수 때 결정.

| 번호 | 요청 | 응답 data | 메모 |
|---|---|---|---|
| 24 | `{ currentPassword, newPassword }` | 없음 | 임시 비밀번호면 이것만 호출 가능 |
| 25 | — | `[{ staffId, loginId, name, role }]` | 사장 |
| 26 | `{ loginId, name, temporaryPassword }` | `{ staffId }` | 사장. 역할 MECHANIC 고정 |
| 27 | `{ cycleMonths?, cycleKm?, active? }` | 13의 항목 하나 | 사장. 새 항목 추가 ❓ |
| 28 | — | `{ customerId, phone(전체), text }` | 동의 고객만, 아니면 404 |
| 29 | `{ customerId, result, memo? }` | `{ contactId }` | result 값 ❓(예약함·부재·이미 정비함·연락함 + 번호 오류·연락 거부?) |
| 30 | `?from=&to=` | `{ newCustomers, returningCustomers }` | 재방문 정의 ❓ |
| 31 | — | `[{ shopId, name, status, createdAt }]` | 정비소 안의 숫자는 주지 않음 |
| 32 | `{ name, phone, owner: { loginId, name, temporaryPassword } }` | `{ shopId, ownerStaffId }` | 기본 기준표 6행을 함께 생성 |
| 33·34 | — | `{ shopId, status }` | 정지·재개 |
| 35 | `{ temporaryPassword }` | 없음 | 사장 계정 `password_change_required = true` |

## 9. 격리·인증 테스트 (X-xx)

시드: A 정비소 사장 토큰으로 B 정비소 데이터 요청 (07 7.4).

| ID | 요청 | 기대 |
|---|---|---|
| X1 | A 토큰으로 07 `GET /api/customers/{B 고객}` | 404 `NOT_FOUND` |
| X2 | A 토큰으로 09·10·11 `{B 차량}` | 404 |
| X3 | A 토큰으로 17 `{B 예약}` | 404 |
| X4 | A 토큰으로 16 `vehicleId = B 차량` | 404 |
| X5 | A 토큰으로 12 `{B 차량}` 기록 저장 | 404, 저장 안 됨 |
| X6 | A 토큰으로 10 미리보기 `{B 차량}?mileage=` | 404 |
| X7 | A 토큰으로 05 `q=12가0001`, 14, 04, 15 | B 데이터가 섞이지 않음 (A의 김민수만) |
| X8 | A 토큰 요청 본문·쿼리에 `shopId=2`를 넣음 | 무시하고 A 기준으로 처리 |
| X9 | 관리자 토큰으로 05 고객 목록 | 403 `FORBIDDEN` |
| X10 | 토큰 없이 / 만료 토큰으로 04 | 401 `AUTH_REQUIRED` |

19(P0-핵심)와 P0-나머지 이후 추가되는 API(20~23)도 같은 규칙으로 X1~X5에 사례를 더한다.

## 10. 결정 필요 (❓)

| 번호 | 내용 | 영향 |
|---|---|---|
| P1 착수 때 | 연락 결과 값, "연락함" 유지 기간, 알림 저장 위치, 재방문 정의, 새 항목 추가 | 8장 |
