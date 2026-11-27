# 08 API 명세서

> 엔드포인트·요청·응답·에러 코드·격리 테스트 — **API 번호, 요청·응답, 에러 코드, X-xx, JSON 예시의 원본**

상태: 작성됨 (2026-11-22 · 최은정(eunjung01230)) — M1 설계 확정(2026-11-23, chagok-docs#46), 2026-11-23 D-60~D-63 반영(chagok-docs#65·#66). 확정 후 바꾸려면 `결정` 이슈 → 이 문서(표 + JSON 예시) + 13 changelog → 코드 PR
근거: 04 기능 명세, 07 ERD, 06 권한, M1 결정 A~D (13 changelog, chagok-docs#12), D-51~D-59 (13 changelog, 결정 이슈 `chagok-docs#20·#21·#22`), D-60~D-63 (계정·온보딩·약관·비활성 정비사 토큰·세부 정책, `chagok-docs#65`). 💡 = 제안값(M1 설계 확정 chagok-docs#46에서 P0-핵심 15건 확정, 💡 해제). ❓ = 결정 필요(문서 끝 목록)
계약 수준 (M1 결정 D): **P0-핵심(01~19)** 은 요청·응답·오류까지 구현 가능한 수준으로 확정. **P0-나머지(20~23, 36~42, 기존 API의 P0-나머지 확장)** 는 경로·메서드·책임·역할·격리·상태 전환·선행 DB 변경까지 확정하고 세부 JSON은 그 기능 착수 PR에서 확정(7장 첫 표). **P1(43~52 포함)** 은 8장 큰 모양만. 단 계정·온보딩(03의 P1 필드, 24·26·32·35·51·52)과 계정 상태 확인(0.6)은 D-60~D-62로 요청·응답·오류·JSON까지 정했다(8.1).
담당 정비사(D-51) 단계 구분: **P0-핵심**은 DB 스키마(`reservation.assignee_staff_id`)만 있고 요청에 담당 필드가 없다. 서버가 토큰의 계정을 담당으로 채운다. **P0-나머지**부터 16·19 요청의 `assigneeId`, 12 요청의 `mechanicId`, API 36, 409 `MECHANIC_SLOT_CONFLICT`, X13이 생긴다. 응답의 `assignee`도 P0-나머지부터다(아래 예시 중 `assignee`가 있는 것은 P0-나머지 응답 기준). **P0-핵심 구현과 프론트 Mock은 04·15·17 예시에서 `assignee`를 뺀 모양을 쓴다**(`phone`은 0.5대로 P0-핵심 기준, 마스킹 전). 담당 정비사 입력(12·16·19·37)과 36의 "활성 사장·정비사" 중 **비활성 제외는 `staff.active`가 생기는 P1(V3)부터**다(07 4장·5.1, D-57). P0-나머지에서는 그 정비소의 사장·정비사이면 된다(X13).

---

## 0. 공통

### 0.1 기본

| 항목 | 규칙 |
|---|---|
| 주소 | 정비소 API `/api/**`, 서비스 관리자 API `/api/admin/**` |
| 형식 | JSON, UTF-8. 필드 이름은 camelCase |
| 인증 | `Authorization: Bearer {accessToken}`. 로그인 API(01·02)만 토큰 없이. **01·02는 요청에 붙은 `Authorization` 헤더를 읽지 않는다** — 만료·위조 토큰이 붙어 있어도 헤더는 결과에 영향을 주지 않는다(화면에 남은 만료 토큰 때문에 로그인이 401로 막히지 않게, D-72). P1부터 첫 비밀번호 변경 전·약관 동의 전·비활성 계정은 0.6의 계정 상태 확인을 거친다 |
| 로그인 아이디 (01·02, D-72) | `loginId`는 **대소문자를 구분하지 않고** 찾는다(`OWNER_A` = `owner_a`). 비교는 DB 콜레이션 `utf8mb4_0900_ai_ci`(07 6.1)를 따르고 `login_id` UNIQUE도 같은 기준이다(악센트·전각 차이도 같게 볼 수 있다). 서버는 받은 값을 바꾸지 않는다(**앞뒤 공백 자르기**·소문자 변환 없음, `" owner_a "`는 401 `LOGIN_FAILED`). 아이디 앞뒤 공백은 화면(S-01)이 보내기 전에 자른다. 비밀번호는 대소문자를 구분하고 자르지 않는다. 신규 아이디 규칙(P1, 05 11장)은 따로다 |
| 날짜 | `"2026-11-24"` (DATE) |
| 일시 | `"2026-11-24T10:00:00"` (Asia/Seoul, 시간대 표기 없음) |
| 목록 쪽 나누기 | `?page=0&size=20` (M1 설계 확정). 생략하면 page 0·size 20. size 최대 50 — 50을 넘으면 서버가 50으로 줄인다(`PageLimit`, 응답 `size`도 50). page 음수, size 0 이하, 숫자가 아닌 값은 400 `INVALID_INPUT`. 쪽 나누기를 쓰는 API는 05·11과 (P1) 48뿐 (14는 전부, 15는 기간, 13·36은 배열) |
| 정비소 | 요청에 `shopId`를 받지 않는다. 토큰의 `shop_id`만 쓴다 (I-3) |
| 공통 오류 | 정비소 API(03~23, 36~52, 그 밖의 P1 정비소 API)는 모두 401 `AUTH_REQUIRED`(토큰 없음·만료)·403 `FORBIDDEN`(서비스 관리자 토큰)·500 `INTERNAL_ERROR`가 날 수 있다. P1부터 403 `PASSWORD_CHANGE_REQUIRED`·`TERMS_AGREEMENT_REQUIRED`·`ACCOUNT_INACTIVE`(0.6)도 날 수 있다. 서비스 관리자 API(31~35)는 사장·정비사 토큰이면 403 `FORBIDDEN`(X18). 각 API의 "에러" 줄에는 그 밖의 것만 적는다 |
| 요청 본문 안의 id | 경로 id와 본문 `vehicleId`(16)는 그 정비소 것이 아니면 404 `NOT_FOUND`. 본문의 정비 항목 id(`records[].itemId`, `purpose.itemIds`)는 없음·남의 것·쓰지 않는 항목 모두 400 `INVALID_INPUT` + `fieldErrors` (같은 응답이라 남의 것인지 드러나지 않음, X11). **담당 정비사 id(`assigneeId`, `mechanicId`, P0-나머지)도 없음·남의 것·비활성 모두 400 `INVALID_INPUT` + `fieldErrors`** (X13) |
| 주행거리·연식 (D-63 B03·B04) | 주행거리(`mileage`·`latestMileage`·`externalMileage`, 10의 쿼리 `mileage` 포함)는 **정수 0~2,000,000**(km). 연식(`modelYear`)은 **1980 ~ 현재 연도 + 1**이고 현재 연도는 서버 `Clock`(Asia/Seoul)으로 계산한다. 범위 밖·정수가 아닌 값은 400 `INVALID_INPUT` + 그 필드의 `fieldErrors`. 둘 다 선택 입력이며 차량에 비어 있으면 정비 시작 때 필수(D-58)인 것은 그대로 |
| 예시 값 | 07 시드 구성의 값. 오늘(D)은 예시에서 `2026-11-24`로 둔다. 담당 정비사 이름은 시드 계정 이름(사장 `owner_a` 박사장, 정비사 `mech_a` 김정비) |

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

`fieldErrors`는 `INVALID_INPUT`일 때만 채우고, 그 밖에는 빈 배열. 요청 본문을 읽을 수 없을 때(JSON 형식이 깨졌거나 값의 타입이 맞지 않음. 예: `reservedAt` 형식 오류, `version`이 숫자가 아님)는 400 `INVALID_INPUT`이고 어느 필드인지 알려 주지 않으므로 `fieldErrors`도 빈 배열이다. `details`는 화면이 다음 행동을 안내하는 데 필요한 값만 담는다(`RESERVATION_ACTIVE_EXISTS`·`MECHANIC_SLOT_CONFLICT`의 `{ "reservationId": 3 }`). 그 밖에는 `null`.

**오류 응답과 화면 처리 (05 POL-120~129)**

| 상황 | 응답 | 화면 |
|---|---|---|
| 입력 오류 | 400 `INVALID_INPUT` + `fieldErrors` | 필드 옆에 메시지, 입력값 유지 |
| 같은 차량 유효 예약 | 409 `RESERVATION_ACTIVE_EXISTS` + `details.reservationId` | 기존 예약 상세 패널을 열어 확인·변경 안내 |
| 담당 중복 (P0-나머지) | 409 `MECHANIC_SLOT_CONFLICT` + `details.reservationId` | 겹친 예약을 보여 주고 다른 시각·다른 담당 선택 안내 |
| 다른 직원이 먼저 수정 | 409 `CONCURRENT_MODIFICATION` | 덮어쓰지 않음. 최신 내용을 다시 불러와 보여주고 다시 수정하게 함 |
| 인증 만료 | 401 `AUTH_REQUIRED` | 로그인 안내 → 로그인 화면 |
| 권한 없음 | 403 `FORBIDDEN` | 권한 안내 |
| 첫 비밀번호 변경·약관 동의 전 (P1, 0.6) | 403 `PASSWORD_CHANGE_REQUIRED`·`TERMS_AGREEMENT_REQUIRED` | 권한 안내가 아니라 03을 다시 불러 S-01의 해당 단계로 보냄 (09 S-01) |
| 비활성 계정 (P1, 0.6) | 403 `ACCOUNT_INACTIVE` | 토큰을 지우고 로그인 화면으로, 사용할 수 없는 계정 안내 |
| 없음·남의 데이터 | 404 `NOT_FOUND` | "찾을 수 없습니다" (있는지 여부를 드러내지 않음) |
| 서버 오류 | 500 `INTERNAL_ERROR` | 공통 오류 안내, 입력값 유지. 서버는 그 요청의 변경을 모두 되돌린다(트랜잭션) |
| 네트워크 오류·응답 없음 | (응답 없음). 요청 시작부터 응답 본문 읽기 완료까지 **10초**를 넘긴 시간 초과, 응답 본문을 읽지 못한 경우도 같다. 프론트는 `status 0`·`NETWORK_ERROR`로 처리한다(서버 `ErrorCode` 아님) | 입력값 유지. 저장됐는지 목록·이력에서 확인한 뒤 사람이 다시 저장. **자동으로 다시 보내지 않는다** |

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
| `FORBIDDEN` | 403 | 역할이 맞지 않음 (서비스 관리자 → 정비소 API, 사장·정비사 → 서비스 관리자 API(X18, D-63 B10), 정비사 → 사장 전용 API) | P0-핵심 |
| `NOT_FOUND` | 404 | 없거나 다른 정비소 것 (D-12) | P0-핵심 |
| `INVALID_INPUT` | 400 | 검증 실패, 잘못된 JSON, 타입 불일치, 30분 단위 아님 | P0-핵심 |
| `RESERVATION_PAST_DATE` | 400 | 예약 날짜가 어제 이전 (D-23) | P0-핵심 |
| `RESERVATION_ACTIVE_EXISTS` | 409 | 같은 차량에 유효 예약(예약 + 예약 날짜 ≥ 오늘, 또는 진행중)이 있음 (D-22, D-52) | P0-핵심 |
| `INVALID_STATUS_TRANSITION` | 409 | 허용되지 않은 예약 상태 변경 | P0-핵심 |
| `CONFLICT` | 409 | 유일 제약 위반 (P1 계정 발급 26·32의 아이디 중복 등) | P0-핵심 |
| `CONCURRENT_MODIFICATION` | 409 | 읽은 뒤 다른 직원이 먼저 바꿈 (`version` 불일치, D-42) | P0-핵심 |
| `INTERNAL_ERROR` | 500 | 그 밖 | P0-핵심 |
| `MECHANIC_SLOT_CONFLICT` | 409 | 같은 담당 + 같은 시작 시각에 유효 예약이 있음 (D-51). `details`에 `{ "reservationId": n }` | P0-나머지 |
| `ASSIGNEE_CHANGE_CLOSED` | 409 | 담당 재배정 마감(예약 날짜 전날까지)이 지났거나 지난 날짜 예약 (D-53). 진행중 예약은 `INVALID_STATUS_TRANSITION` | P0-나머지 |
| `EDIT_PERIOD_EXPIRED` | 403 | 정비사의 수정·정정 기간(3일) 초과 (D-53·D-55) | P0-나머지 |
| `SHOP_SUSPENDED` | 403 | 정지된 정비소 계정 로그인 | P1 |
| `PASSWORD_CHANGE_REQUIRED` | 403 | 임시 비밀번호 상태(`password_change_required = true`, 사장·정비사)에서 0.6 허용 API 밖 호출 (D-60) | P1 |
| `TERMS_AGREEMENT_REQUIRED` | 403 | 현재 버전 서비스 이용약관에 동의하지 않은 정비소의 사장이 0.6 허용 API 밖 호출 (D-61) | P1 |
| `HAS_ACTIVE_RESERVATION` | 409 | 유효 예약이 있어 비활성화·익명화·정비사 비활성화 불가 (D-56·D-57) | P1 |
| `HAS_HISTORY` | 409 | 이력이 있어 고객 삭제 불가 (D-56) | P1 |
| `RETENTION_NOT_REACHED` | 409 | 보관 5년이 지나지 않음 (D-56) | P1 |
| `ACCOUNT_INACTIVE` | 403 | 비활성 정비사 계정 로그인(D-57), 비활성화 전에 받은 토큰으로 정비소 API 호출(D-62) | P1 |

`message`는 화면에 그대로 보여 줄 수 있는 한국어 문장. 405·415 같은 표준 예외도 `INVALID_INPUT`으로 감싼다.

DB 제약 위반의 처리 (M1 결정 A): `CONFLICT`는 사용자가 고칠 수 있는 유일 제약 위반(P1 아이디 중복 등)에만 쓴다. 복합 FK·CHECK 위반은 서버 검증이 먼저 막아야 하는 것이므로, 실제로 나면 서버 버그로 보고 500 `INTERNAL_ERROR`(트랜잭션 롤백, 내부 정보 미노출)로 응답한다. `DataIntegrityViolationException`을 모두 `CONFLICT`로 바꾸지 않는다. JPA `@Version` 충돌(`OptimisticLockException`)은 `CONCURRENT_MODIFICATION`이다.

### 0.4 값 목록 (enum)

| 이름 | 값 |
|---|---|
| 역할 `role` | `OWNER` 사장 · `MECHANIC` 정비사 · `ADMIN` 서비스 관리자 |
| 점검 주기 상태 `status` | `UNKNOWN` 미확인 · `AHEAD` 여유 · `SOON` 임박 · `DUE` 도래 |
| 도래 근거 `dueReason` | `DATE` 날짜 · `KM` 주행거리 · `null` |
| 정비 구분 `type` | `REPLACE` 교체 · `INSPECT` 점검 · `EXTERNAL` 외부 · `DECLINE` 거절. 입력(12)은 P0-핵심 `REPLACE`·`INSPECT`, P0-나머지부터 `EXTERNAL`·`DECLINE`(13 2026-11-22). 조회 응답(10 `baseRecord.type`, 11·17 `records[].type`)에는 시드·기존 기록 때문에 P0-핵심에서도 4개가 모두 나올 수 있다(07 3.7·7.2) |
| 출처 `source` | `SHOP` 우리 정비소 · `CUSTOMER_STATEMENT` 고객 진술 |
| 점검 결과 `inspectResult` (P0-나머지) | `GOOD` 양호 · `CAUTION` 주의 |
| 예약 상태 `status` | `RESERVED` 예약 · `IN_PROGRESS` 진행중(P0-나머지, D-52) · `COMPLETED` 방문 완료 · `CANCELED` 취소 · `NO_SHOW` 노쇼(P0-나머지) |
| 예약 이력 종류 `kind` (P0-나머지, `reservation_revision`) | `STATUS` 상태 정정 · `MEMO` 메모 정정 · `ASSIGNEE` 담당 재배정 |
| 항목 `code` | `ENGINE_OIL` · `AIR_CLEANER` · `AC_FILTER` · `BRAKE_PAD` · `TIRE` · `BATTERY` |
| 정비소 상태 `status` (P1, 31·33·34) | `ACTIVE` 이용 중 · `SUSPENDED` 정지 (07 3.2 CHECK와 같음) |

### 0.5 연락처 표시

목록 응답(04·05·14·15)의 `phone`은 P0-나머지부터 서버가 마스킹한 값(`010-****-0001`, F-CUS-07). 상세 응답(07·09·17)과 문자 초안(28)의 `phone`은 전체 번호(D-40). 아래 목록 예시는 P0-핵심 기준(마스킹 전).

마스킹 규칙 (D-63 B07, 서버 한 곳): 저장된 값에서 숫자만 센다(하이픈 무시). 숫자를 n자리라 하면

| n | 표시 | 예 |
|---|---|---|
| 9 이상 | 앞 머리(`02`로 시작하면 2자리, 아니면 3자리) + `-` + 가운데 숫자 수만큼 `*` + `-` + 뒤 4자리 | `010-0000-0001` → `010-****-0001`, `02-123-4567` → `02-***-4567`, `0311234567` → `031-***-4567` |
| 5~8 | 앞 숫자 수만큼 `*` + `-` + 뒤 4자리 | `1588-1234` → `****-1234` |
| 4 이하 | 숫자 수만큼 `*` | — |

- 가운데 자리는 항상 가린다. 원래 하이픈 위치는 따르지 않는다(입력 형식이 달라도 같은 번호면 같은 표시).
- 빈 값(익명화 고객 등, P1)은 빈 값 그대로.

### 0.6 계정 상태 확인 (P1, D-60~D-62)

보호된 정비소 API(`/api/**` 중 `/api/admin/**`를 뺀 것) 요청마다 서버가 토큰의 `staffId`로 `staff`를 읽어 아래 순서로 확인한다. 이 확인은 **역할·경로 확인(사장 전용 경로 등)보다 먼저** 한다. 그래서 비활성·임시 비밀번호 상태의 정비사가 사장 전용 API를 불러도 `FORBIDDEN`이 아니라 아래 상태 코드가 나간다(06 2.1, 11 3.3.1). 토큰에 상태를 넣지 않으므로 비밀번호를 바꾸거나 약관에 동의한 뒤 **같은 토큰**으로 바로 다음 단계로 간다(재로그인 불필요, 새로 고침해도 서버 상태 기준).

| 순서 | 조건 | 응답 | 허용 API |
|---|---|---|---|
| 1 | 토큰의 `staffId`에 해당하는 `staff` 행이 없음 (서명·만료가 유효해도) | 401 `AUTH_REQUIRED` | — |
| 2 | `staff.active = false` (정비사, V3부터) | 403 `ACCOUNT_INACTIVE` | 없음 (화면은 토큰을 지우고 로그인으로) |
| 3 | `password_change_required = true` (사장·정비사) | 403 `PASSWORD_CHANGE_REQUIRED` | 03 `GET /api/me`, 24 `POST /api/me/password` |
| 4 | 역할 사장이고 그 정비소에 현재 약관 버전 동의 기록이 없음 | 403 `TERMS_AGREEMENT_REQUIRED` | 03, 24, 52 `POST /api/me/terms-agreement` |
| — | 모두 통과 | 정상 처리 | 역할·경로 규칙대로 |

- 정비사에게는 4번(약관)을 적용하지 않는다(D-61).
- `/api/admin/**`는 이 확인 대상이 아니다. 서비스 관리자 토큰은 `platform_admin` 계정이라 `staff` 상태가 없고, 사장·정비사 토큰으로 `/api/admin/**`를 부르면 계정 상태와 관계없이 403 `FORBIDDEN`이다(X18).
- 정비소 정지(`SHOP_SUSPENDED`)는 로그인만 막는다. 이미 발급된 토큰 즉시 차단은 P2 그대로(05 POL-15).
- 1~3·4의 판정은 서버가 하고 화면 라우팅은 03 응답으로 같은 단계를 보여 줄 뿐이다. 화면에서 단계를 건너뛰어도 서버가 막는다(X19~X21).
- P0(시드 시연 계정)은 `password_change_required = false`라 3번에 걸리지 않는다. 4번은 P1 구현 때 시연 정비소의 동의 기록을 시드에 넣을지 DB 담당자가 정한다(07 4.4).

## 1. API 목록

| 번호 | 메서드 | 경로 | 기능 | 단계 | 권한 |
|---|---|---|---|---|---|
| 01 | POST | `/api/auth/login` | F-AUTH-01 | P0-핵심 | 없음 |
| 02 | POST | `/api/admin/auth/login` | F-AUTH-02 | P0-핵심 | 없음 |
| 03 | GET | `/api/me` | F-AUTH-01 | P0-핵심 | 사장·정비사 |
| 04 | GET | `/api/home` | F-HOME-01 | P0-핵심 (`assignee`는 P0-나머지부터) | 사장·정비사 |
| 05 | GET | `/api/customers` | F-CUS-01 | P0-핵심 | 사장·정비사 |
| 06 | POST | `/api/customers` | F-CUS-02 | P0-핵심 | 사장·정비사 |
| 07 | GET | `/api/customers/{customerId}` | F-CUS-04 | P0-핵심 | 사장·정비사 |
| 08 | POST | `/api/customers/{customerId}/vehicles` | F-CUS-03 | P0-핵심 | 사장·정비사 |
| 09 | GET | `/api/vehicles/{vehicleId}` | F-CUS-05 | P0-핵심 | 사장·정비사 |
| 10 | GET | `/api/vehicles/{vehicleId}/item-status` | F-CYC-01, F-VIS-01 | P0-핵심 | 사장·정비사 |
| 11 | GET | `/api/vehicles/{vehicleId}/visits` | F-CUS-05 | P0-핵심 | 사장·정비사 |
| 12 | POST | `/api/vehicles/{vehicleId}/visits` | F-MNT-01·02·03 | P0-핵심 (`mechanicId`는 P0-나머지부터) | 사장·정비사 |
| 13 | GET | `/api/items` | F-MNT-01, F-RSV-01 | P0-핵심 | 사장·정비사 |
| 14 | GET | `/api/targets` | F-TGT-01 | P0-핵심 | 사장·정비사 |
| 15 | GET | `/api/reservations` | F-RSV-02·05 | P0-핵심 (`assignee`·`assigneeId` 쿼리는 P0-나머지부터) | 사장·정비사 |
| 16 | POST | `/api/reservations` | F-RSV-01 | P0-핵심 (`assigneeId`는 P0-나머지부터) | 사장·정비사 |
| 17 | GET | `/api/reservations/{reservationId}/panel` | F-RSV-03 | P0-핵심 (`assignee`는 P0-나머지부터) | 사장·정비사 |
| 18 | POST | `/api/reservations/{reservationId}/complete` | F-RSV-04 | P0-핵심 (진행중에서 완료는 P0-나머지) | 사장·정비사 |
| 19 | PATCH | `/api/reservations/{reservationId}` | F-RSV-06 | P0-핵심 (`assigneeId` 재배정은 P0-나머지부터) | 사장·정비사 |
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
| 31 | GET | `/api/admin/shops` | F-ADM-01 | P1 | 서비스 관리자 |
| 32 | POST | `/api/admin/shops` | F-ADM-01 | P1 | 서비스 관리자 |
| 33 | POST | `/api/admin/shops/{shopId}/suspend` | F-ADM-02 | P1 | 서비스 관리자 |
| 34 | POST | `/api/admin/shops/{shopId}/resume` | F-ADM-02 | P1 | 서비스 관리자 |
| 35 | POST | `/api/admin/shops/{shopId}/owner-password-reset` | F-ADM-02 | P1 | 서비스 관리자 |
| 36 | GET | `/api/staff/assignees` | F-RSV-01·06 (담당 후보: id·이름·역할·`colorIndex`, 활성만) | P0-나머지 | 사장·정비사 |
| 37 | PATCH | `/api/records/{recordId}` | F-MNT-04 | P0-나머지 | 사장·정비사(조건) |
| 38 | GET | `/api/records/{recordId}/revisions` | F-MNT-04 | P0-나머지 | 사장·정비사 |
| 39 | POST | `/api/reservations/{reservationId}/start` | F-RSV-09 | P0-나머지 | 사장·정비사 |
| 40 | POST | `/api/reservations/{reservationId}/correct` | F-RSV-10 | P0-나머지 | 사장·정비사(조건) |
| 41 | GET | `/api/reservations/{reservationId}/revisions` | F-RSV-06·10 | P0-나머지 | 사장·정비사 |
| 42 | GET | `/api/reservations/summary?from=&to=` | F-RSV-05 (월 보기 날짜별 건수·상태별 건수) | P0-나머지 | 사장·정비사 |
| 43 | POST | `/api/customers/{customerId}/deactivate` | F-CUS-10 | P1 | 사장 |
| 44 | POST | `/api/customers/{customerId}/activate` | F-CUS-10 | P1 | 사장 |
| 45 | DELETE | `/api/customers/{customerId}` | F-CUS-10 (이력 없을 때만) | P1 | 사장 |
| 46 | POST | `/api/vehicles/{vehicleId}/deactivate` | F-CUS-10 | P1 | 사장 |
| 47 | POST | `/api/vehicles/{vehicleId}/activate` | F-CUS-10 | P1 | 사장 |
| 48 | GET | `/api/customers/retention-due` | F-CUS-11 | P1 | 사장 |
| 49 | POST | `/api/customers/{customerId}/anonymize` | F-CUS-11 | P1 | 사장 |
| 50 | POST | `/api/staff/{staffId}/deactivate` | F-STF-01 | P1 | 사장 |
| 51 | POST | `/api/staff/{staffId}/password-reset` | F-STF-01 (정비사 임시 비밀번호 재발급, D-60 A09) | P1 | 사장 |
| 52 | POST | `/api/me/terms-agreement` | F-AUTH-04 (서비스 이용약관 동의, D-61) | P1 | 사장 |

F-NTF-01(아침 알림)은 알림 시간·허용 여부를 브라우저에 저장하므로(04 F-NTF-01, D-59) API가 없다. 36~42는 P0-나머지, 43~52는 P1이다. **43~49(D-56)는 05 POL-46(법적 근거 확인, 담당 PM) 확인 후 구현 착수**(문서는 확정, 구현 이슈는 확인 뒤에 연다).

---

## 2. 인증

### 01 POST `/api/auth/login` — 사장·정비사 로그인

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| loginId | string | ○ | 1~50자 |
| password | string | ○ | 1~100자 |

로그인은 이미 있는 계정을 받으므로 신규 아이디 규칙(6~20자)·비밀번호 조합 규칙(8~20자, 05 11장)을 적용하지 않는다. 시연 계정 `1234`도 그대로 로그인한다(D-44, D-60). 임시 비밀번호 계정·약관 동의 전 사장도 로그인은 성공하고(200), 응답 `staff`의 상태 필드(03, P1)로 남은 단계를 안다.

```json
{ "loginId": "owner_a", "password": "********" }
```

| 응답 data | 타입 | 설명 |
|---|---|---|
| accessToken | string | JWT |
| tokenType | string | `"Bearer"` |
| expiresIn | number | 초. 43200 (12시간) |
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

에러: `LOGIN_FAILED`, `INVALID_INPUT`, (P1) `SHOP_SUSPENDED`·`ACCOUNT_INACTIVE`

### 02 POST `/api/admin/auth/login` — 서비스 관리자 로그인

요청은 01과 같다. 토큰에 `shop_id`가 없다. 응답 `admin`은 `{ adminId, name, role }`이고 `role`은 항상 `"ADMIN"`이다.

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

에러: `LOGIN_FAILED`, `INVALID_INPUT` (요청 검증이 01과 같고, `LOGIN_FAILED`는 0.3 정의대로 아이디 없음·비밀번호 틀림을 같은 응답으로)

### 03 GET `/api/me` — 내 계정

```json
{
  "success": true,
  "data": { "staffId": 1, "name": "박사장", "role": "OWNER", "shopId": 1, "shopName": "차곡카센터" },
  "error": null
}
```

P1부터(D-60·D-61) 01 응답의 `staff`와 이 응답에 계정 상태 필드를 더한다. 03은 임시 비밀번호·약관 동의 전 상태에서도 부를 수 있다(0.6). 화면은 다시 로그인하거나 새로 고침할 때 이 값으로 남은 단계부터 보여 준다.

| 응답 data (P1 추가) | 타입 | 설명 |
|---|---|---|
| passwordChangeRequired | boolean | `staff.password_change_required`. true면 비밀번호 변경(24) 단계 |
| termsAgreementRequired | boolean | 사장이고 그 정비소에 현재 약관 버전 동의 기록이 없으면 true. 정비사는 항상 false |
| termsVersion | string/null | `termsAgreementRequired`가 true일 때 동의할 약관 버전(화면 표시·52 요청 값). 아니면 null |

```json
{
  "success": true,
  "data": {
    "staffId": 1, "name": "박사장", "role": "OWNER", "shopId": 1, "shopName": "차곡카센터",
    "passwordChangeRequired": false,
    "termsAgreementRequired": true,
    "termsVersion": "2026-11-23"
  },
  "error": null
}
```

예시는 약관 동의 전 사장의 상태다. `termsVersion` 값 형식(예시의 날짜 문자열)과 현재 버전을 두는 곳(서버 설정)은 약관 전문이 확정될 때 함께 정한다(04 F-AUTH-04). 에러: (P1) `ACCOUNT_INACTIVE`

## 3. 홈

### 04 GET `/api/home`

| 응답 data | 타입 | 설명 |
|---|---|---|
| date | date | 오늘 |
| todayReservationCount | number | 오늘 예약 중 취소 제외 |
| todayContactCount | number | 오늘 연락할 고객 수 (04 F-HOME-01) |
| todayReservations | array | 15의 항목과 같은 모양(P0-나머지부터 `assignee { staffId, name, colorIndex }` 포함, 상태에 `IN_PROGRESS` 가능), 시각 순, **취소 포함**(상태 라벨로 구분. `todayReservationCount`는 취소 제외 그대로, D-63 B05). P0-핵심은 이 오늘 목록이 홈의 예약 목록이고, P0-나머지부터 홈 캘린더가 15·42로 날짜별 예약을 불러온다 |

```json
{
  "success": true,
  "data": {
    "date": "2026-11-24",
    "todayReservationCount": 3,
    "todayContactCount": 5,
    "todayReservations": [
      {
        "reservationId": 5,
        "reservedAt": "2026-11-24T09:00:00",
        "status": "IN_PROGRESS",
        "needsAction": false,
        "version": 0,
        "vehicleId": 5,
        "plateNumber": "90마0005",
        "customerId": 5,
        "customerName": "정우성",
        "phone": "010-0000-0005",
        "purposeSummary": "엔진오일"
      },
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

P0-나머지부터는 `todayReservations[]`의 각 항목에 `assignee`가 더해진다(위 표). 예: `"assignee": { "staffId": 1, "name": "박사장", "colorIndex": 0 }`

## 4. 고객·차량

### 05 GET `/api/customers?q=&page=&size=` — 검색·목록

`q`는 고객명·연락처·차량번호 일부(공백·하이픈 무시). 비우면 전체(최근 등록순).

P1부터: 쿼리 `includeInactive`(기본 false. true면 비활성 고객도 포함, D-56), 항목에 `status`(고객 상태)·`lastVisitDate`·`visitCount`·`hasUpcomingCheck`(F-CUS-09). 차량번호 중복을 막지 않는 것은 그대로.

| 응답 data | 타입 | 설명 |
|---|---|---|
| items[].customerId, name, phone, consent | number, string, string, boolean | 모두 값 있음. phone은 P0-나머지부터 마스킹(0.5) |
| items[].vehicles[] | array | `{ vehicleId, plateNumber }`. 차량이 없으면 `[]` |
| page, size, totalElements, totalPages | number | 쪽 나누기(0.1). 결과가 없으면 `items: []`, `totalElements: 0` (화면 문구는 09 S-05) |

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
| phone | string | ○ | 숫자·하이픈, 9~20자 |
| consent | boolean | ○ | 기본 false를 화면이 보냄 |
| vehicle.plateNumber | string | ○ | 1~20자, 공백 제거 |
| vehicle.model | string | ○ | 1~50자 (D-58) |
| vehicle.modelYear | number | | 1980 ~ 현재 연도 + 1 (0.1). 비어 있으면 정비 시작(방문 접수 39) 또는 정비 기록 첫 저장(12) 때 필수 |
| vehicle.mileage | number | | 정수 0~2,000,000 (0.1). 비어 있으면 `modelYear`와 같이 정비 시작 또는 정비 기록 첫 저장 때 필수. 칼럼은 `vehicle.latest_mileage`(07 3.5), 응답(07·09·17)에서는 `latestMileage` |

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

차량번호 중복은 막지 않는다(에러 없음). 고객과 첫 차량은 한 트랜잭션(둘 중 하나가 실패하면 둘 다 저장 안 됨). 에러: `INVALID_INPUT`

### 07 GET `/api/customers/{customerId}` — 고객 상세

| 응답 data | 타입 | 설명 |
|---|---|---|
| customerId, name, phone, consent | number, string, string, boolean | phone 전체(D-40) |
| version | number | 동시 수정 확인용 번호(0부터). 고객 수정(22) 요청에 그대로 보낸다 (POL-124). `vehicles[]`에는 없다 |
| vehicles[].vehicleId, plateNumber, model | number, string, string | `model`은 서버 검증으로 필수(D-58)라 값이 있다 |
| vehicles[].modelYear, latestMileage | number/null | 비어 있을 수 있음(07 3.5) |
| vehicles[].dueCount, soonCount | number | 오늘(서버 `Clock`) 기준, 그 차량의 **사용하는(`active`) 정비 항목** 중 상태가 `DUE`인 항목 수·`SOON`인 항목 수. 10을 주행거리 없이 부른 결과와 같은 기준(날짜 기준, P1부터 월평균 반영 F-CYC-03도 그대로 따름). P0는 6개 항목 모두 사용 (D-63 B01) |

```json
{
  "success": true,
  "data": {
    "customerId": 10,
    "name": "오세훈",
    "phone": "010-0000-0010",
    "consent": true,
    "version": 0,
    "vehicles": [
      { "vehicleId": 10, "plateNumber": "55차0010", "model": "쏘나타", "modelYear": 2018, "latestMileage": 97000, "dueCount": 0, "soonCount": 1 },
      { "vehicleId": 11, "plateNumber": "66카0011", "model": "K3", "modelYear": null, "latestMileage": null, "dueCount": 0, "soonCount": 0 }
    ]
  },
  "error": null
}
```

P1부터 응답에 고객 `status`, 차량마다 `active`가 붙는다. 익명화한 고객(F-CUS-11)은 이름이 "(삭제된 고객)", `phone`이 빈 값이다. 에러: `NOT_FOUND` (X1)

### 08 POST `/api/customers/{customerId}/vehicles` — 차량 추가

요청은 06의 `vehicle`과 같다(`model` 필수, `modelYear`·`mileage` 선택).

```json
{ "plateNumber": "66카0011", "model": "K3", "modelYear": null, "mileage": null }
```

```json
{ "success": true, "data": { "customerId": 10, "vehicleId": 11 }, "error": null }
```

에러: `NOT_FOUND`(없는 고객·다른 정비소 고객 — 차량을 저장하지 않음, X17, D-63 B11), `INVALID_INPUT` (`model` 누락, 주행거리·연식 범위(0.1), P1 비활성 고객에 차량 추가)

### 09 GET `/api/vehicles/{vehicleId}` — 차량 정보

| 응답 data | 타입 | 설명 |
|---|---|---|
| vehicleId, plateNumber, model | number, string, string | `model`은 값이 있다(D-58) |
| modelYear, latestMileage | number/null | 비어 있을 수 있음(07 3.5) |
| version | number | 동시 수정 확인용 번호(0부터). 차량 수정(23) 요청에 그대로 보낸다 (POL-124). 고객의 `version`과 별개다 |
| customer | object | `{ customerId, name, phone, consent }`, phone 전체(D-40) |

```json
{
  "success": true,
  "data": {
    "vehicleId": 4,
    "plateNumber": "78라0004",
    "model": "K5",
    "modelYear": 2020,
    "latestMileage": 45000,
    "version": 0,
    "customer": { "customerId": 4, "name": "최지은", "phone": "010-0000-0004", "consent": true }
  },
  "error": null
}
```

P1부터 응답에 `active`가 붙는다. 고객이 익명화되었으면 `customer.phone`은 빈 값이다. 에러: `NOT_FOUND` (X2)

### 10 GET `/api/vehicles/{vehicleId}/item-status?mileage=` — 항목 상태 · 저장 전 미리보기

`mileage`를 주면 방문 중 안내(F-VIS-01, km 판정 포함), 안 주면 날짜 기준만. 기록을 남기지 않는다. `mileage`는 정수 0~2,000,000(0.1), 벗어나면 400 `INVALID_INPUT`.

| 응답 data | 타입 | 설명 |
|---|---|---|
| vehicleId | number | 경로의 차량 |
| asOf | date | 판정 기준일(오늘) |
| inputMileage | number/null | 요청의 `mileage` 그대로. 안 주면 null(날짜 기준만) |
| items | array | 아래 |

| 응답 items[] | 타입 | 설명 |
|---|---|---|
| itemId, code, name | | 항목 |
| status | enum | `UNKNOWN`·`AHEAD`·`SOON`·`DUE` |
| dueReason | enum/null | 도래면 `DATE` 또는 `KM` (둘 다면 `DATE`) |
| baseRecord | object/null | 기준 기록 `{ date, mileage, type }` |
| nextDueDate | date/null | 다음 정비일 (P1부터 월평균 반영) |
| nextDueMileage | number/null | 기준 km + 주기 km (기준 기록 km 없으면 null) |
| lastDecline | object/null | P0-나머지부터. 지난 방문 거절 `{ date, memo }`(F-CYC-02). `date`(date)는 그 거절 기록의 날짜, `memo`(string/null)는 그 기록의 메모. 조건(그 항목의 가장 최근 기록이 거절이고 기준 기록보다 늦음)이 아니면 null |
| lastCaution | object/null | P0-나머지부터. 지난 점검 주의 `{ date, memo }`(F-CYC-02). `date`(date)는 그 점검 기록의 날짜, `memo`(string/null)는 그 기록의 메모. 조건(그 항목의 가장 최근 기록이 점검이고 결과가 `CAUTION`)이 아니면 null |

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

P0-나머지부터 `items[]`마다 `lastDecline`·`lastCaution`이 붙는다(해당 없으면 `null`). 두 값은 상태를 바꾸지 않는다(F-CYC-02). 둘 다 "그 항목의 가장 최근 기록" 하나에서 나오므로 **한 항목에 동시에 붙지 않는다**. `lastDecline`은 기준 기록(교체·외부)이 아직 없어도(거절만 있어도) 붙는다(`baseRecord`는 `null`, `status`는 `UNKNOWN`). 예: 07 7.2 시드 11바0006(차량 6)의 엔진오일 — 기준은 교체 D-8M이라 도래이고, 그 뒤 거절 D-1M이 있어 `lastDecline`이 붙는다(오늘 D = 2026-11-24 기준 값).

```json
{
  "itemId": 1, "code": "ENGINE_OIL", "name": "엔진오일",
  "status": "DUE", "dueReason": "DATE",
  "baseRecord": { "date": "2026-03-24", "mileage": null, "type": "REPLACE" },
  "nextDueDate": "2026-09-24", "nextDueMileage": null,
  "lastDecline": { "date": "2026-10-24", "memo": null },
  "lastCaution": null
}
```

### 11 GET `/api/vehicles/{vehicleId}/visits?page=&size=` — 방문 단위 정비 이력

`visit_key`로 묶어 최신순(`visitDate` 내림차순, 같으면 나중에 저장한 방문 먼저). 쪽 나누기와 `totalElements`는 **방문 묶음 수** 기준이다(기록 행 수가 아님). 기록마다 자기 날짜가 있다(외부는 고객이 말한 날짜). 에러: `NOT_FOUND` (X2)

| 응답 items[] | 타입 | 설명 |
|---|---|---|
| visitKey | string | UUID 36자 (07 3.7) |
| visitDate | date | 아래 설명 |
| mileage | number/null | 방문 주행거리. 비어 있을 수 있음(07 3.7) |
| staffName | string | 기록 담당 정비사 이름 |
| records[] | array | `{ recordId, itemId, itemName, type, date, memo }`. `type`은 0.4의 4개 값, `memo`는 null 가능 |
| records[].source | enum | P0-나머지부터. `SHOP`·`CUSTOMER_STATEMENT`(0.4). 외부(`EXTERNAL`)면 `CUSTOMER_STATEMENT`, 그 밖은 `SHOP`(07 3.7 CHECK) |
| records[].inspectResult | enum/null | P0-나머지부터. 점검(`INSPECT`)이고 결과를 남겼을 때만 `GOOD`·`CAUTION`, 그 밖은 null(07 3.7 CHECK) |

페이지 필드(`page`·`size`·`totalElements`·`totalPages`)는 05와 같다. 차량에 기록이 없으면 `items: []`.

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "visitKey": "5eed0000-0000-4000-8000-000000000015",
        "visitDate": "2026-10-24",
        "mileage": null,
        "staffName": "김정비",
        "records": [
          { "recordId": 16, "itemId": 1, "itemName": "엔진오일", "type": "REPLACE", "date": "2026-10-24", "memo": null }
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

P0-나머지부터 `records[]`에 아래 필드가 붙는다. `source`·`inspectResult`는 위 표와 같다(F-MNT-02·03). 아래 세 필드는 F-MNT-04(정비 기록 수정, 37·38)가 쓰고, **모든 기록에 항상** 붙는다(수정한 적이 없어도). 17 `recentVisits[].records[]`도 같은 모양이다. `visitDate`는 그 묶음에서 외부가 아닌 기록의 날짜(외부만 있으면 그 날짜). 묶음의 `staffName`은 바꾸지 않는다.

| 응답 records[] | 타입 | 설명 |
|---|---|---|
| version | number | 수정 확인용 번호. 기록을 저장할 때(12) 0이고 수정(37)마다 +1(07 3.7). 화면은 수정 요청에 이 값을 그대로 보낸다 |
| edited | boolean | 수정 이력(38)이 한 건이라도 있으면 `true`. 이력 내용은 38에서 받는다 |
| staff | object | 그 기록의 담당 정비사 `{ staffId, name }`. `name`은 그 계정의 현재 이름(38·41과 같음). 37로 담당을 바꾸면 이 값이 바뀐다 |

P0-나머지 `records[]` 예 1: 07 7.2 시드 22사0007(차량 7)의 외부 기록(고객 진술, D-1M). 수정한 적이 없어 `version`은 0, `edited`는 `false`다. 담당 `staff` 값은 예시 값이다.

```json
{
  "recordId": 9, "itemId": 3, "itemName": "에어컨필터", "type": "EXTERNAL", "date": "2026-10-24", "memo": null,
  "source": "CUSTOMER_STATEMENT", "inspectResult": null,
  "version": 0, "edited": false, "staff": { "staffId": 2, "name": "김정비" }
}
```

예 2: 37·38 예시의 기록 16을 두 번 수정한 뒤의 모양이다(`version` 2, `edited` `true`, 수정한 내용은 38 예시와 같다).

```json
{
  "recordId": 16, "itemId": 1, "itemName": "엔진오일", "type": "INSPECT", "date": "2026-10-24", "memo": "합성유 사용",
  "source": "SHOP", "inspectResult": "CAUTION",
  "version": 2, "edited": true, "staff": { "staffId": 2, "name": "김정비" }
}
```

### 12 POST `/api/vehicles/{vehicleId}/visits` — 방문·정비 기록 저장

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| visitDate | date | ○ | 오늘 이전·오늘 |
| mileage | number | 조건부 ○ | 정수 0~2,000,000 (0.1). 차량의 최근 주행거리가 비어 있고 요청에 교체·점검 항목이 있으면 필수 (D-58) |
| vehicle.modelYear | number | 조건부 ○ | 1980 ~ 현재 연도 + 1 (0.1). 차량의 연식이 비어 있고 요청에 교체·점검 항목이 있으면 필수 (D-58). 같은 트랜잭션에서 차량에 반영 |
| mechanicId | number | | P0-나머지. 담당 정비사 id. 그 정비소의 활성 사장·정비사 (X13) |
| records[] | array | ○ | 1개 이상, 같은 itemId 중복 불가 |
| records[].itemId | number | ○ | 그 정비소의 쓰는 항목 |
| records[].type | enum | ○ | P0-핵심 `REPLACE`·`INSPECT` / P0-나머지 `EXTERNAL`·`DECLINE` |
| records[].memo | string | | ~200자 |
| records[].externalDate | date | 외부면 ○ | P0-나머지. 오늘 이전 |
| records[].externalMileage | number | | P0-나머지. 정수 0~2,000,000 (0.1) |
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
  "mechanicId": 2,
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

담당 정비사는 P0-핵심에서는 저장한 계정이다. P0-나머지부터 `mechanicId`로 고르고(정비사도 다른 정비사를 지정할 수 있음), 화면의 기본값은 예약 완료 뒤 이동이면 그 예약의 담당, 아니면 로그인 계정이다(04 F-MNT-01). 차량의 연식·최근 주행거리가 비어 있고 요청에 교체·점검 항목이 있으면 `vehicle.modelYear`와 `mileage`를 반드시 보내야 하고(없으면 400 `INVALID_INPUT`) 같은 트랜잭션에서 차량에 반영한다. 주행거리가 차량의 최근 주행거리보다 크면 갱신. 저장한 기록의 수정은 12가 아니라 37이다(삭제는 없음). P1부터 비활성 고객·차량이면 400 `INVALID_INPUT`. `visitKey`는 서버가 이 요청 하나마다 새로 만든다(요청으로 받지 않음, 07 3.7). 기록 행 저장과 최근 주행거리 갱신은 한 트랜잭션 — 하나라도 실패하면 아무것도 저장하지 않는다. 예약과는 데이터로 잇지 않는다(방문 완료 18과 별도 요청, 05 POL-95). 에러: `NOT_FOUND` (X5), `INVALID_INPUT` (방문일 미래, 기록 0개, 같은 항목 중복, `itemId`가 그 정비소의 쓰는 항목이 아님 X11, P0-핵심에서 `EXTERNAL`·`DECLINE`·`inspectResult`·`mechanicId`, 차량에 비어 있는 연식·주행거리를 보내지 않음, P0-나머지부터 `mechanicId`가 없음·남의 것·비활성 X13)

### 13 GET `/api/items` — 정비 항목·주기

`data`는 배열(쪽 나누기 없음, 0.1). 로그인한 정비소의 항목만(I-3). 다른 정비소 항목이 섞이지 않는지 X7에서 확인한다(D-63 B06).

| 응답 data[] | 타입 | 설명 |
|---|---|---|
| itemId, code, name | number, string, string | `code`는 0.4 항목 값 |
| cycleMonths, cycleKm | number | 07 3.6 (0보다 큼) |
| active, sortOrder | boolean, number | |

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

쪽 나누기 없이 전부(`// LIMIT: 정비소당 대상 수백 건 이하 가정`). 정렬: 도래가 있는 차량 먼저, 그다음 가장 이른 다음 정비일 순.

| 응답 data | 설명 |
|---|---|
| asOf | 판정 기준일(오늘) |
| items | 아래. 대상이 없으면 `[]` |

| 응답 items[] | 설명 |
|---|---|
| customerId, customerName, phone | phone은 P0-나머지부터 마스킹 |
| vehicleId, plateNumber | |
| targetItems[] | 도래·임박 항목만 `{ itemId, name, status, nextDueDate, baseDate }`. P0-나머지부터 `lastDecline`·`lastCaution`(10과 같은 모양·조건) |
| activeReservation | 유효 예약 `{ reservationId, reservedAt }` 또는 null ("예약 있음"). 유효 예약 = `RESERVED` + 예약 날짜 ≥ 오늘, 또는 `IN_PROGRESS`(P0-나머지) (D-22, D-52, 16의 R3과 같은 기준) |

`targetItems[]`의 `status`·`nextDueDate`는 10을 주행거리 없이 부른 결과와 같고(`baseDate` = 10의 `baseRecord.date`), 대상 판정은 날짜 기준이다(F-CYC-01: P0에서 km만 넘은 차량은 뜨지 않음).

```json
{
  "success": true,
  "data": {
    "asOf": "2026-11-24",
    "items": [
      {
        "customerId": 2, "customerName": "이영희", "phone": "010-0000-0002",
        "vehicleId": 2, "plateNumber": "34나0002",
        "targetItems": [
          { "itemId": 1, "name": "엔진오일", "status": "DUE", "nextDueDate": "2026-11-14", "baseDate": "2026-05-14" }
        ],
        "activeReservation": { "reservationId": 3, "reservedAt": "2026-11-26T10:00:00" }
      },
      {
        "customerId": 1, "customerName": "김민수", "phone": "010-0000-0001",
        "vehicleId": 1, "plateNumber": "12가0001",
        "targetItems": [
          { "itemId": 1, "name": "엔진오일", "status": "DUE", "nextDueDate": "2026-11-17", "baseDate": "2026-05-17" }
        ],
        "activeReservation": null
      }
    ]
  },
  "error": null
}
```

시드 기준 실제 응답은 6대(07 7.5). 예시는 그중 2대를 정렬 순서대로 적었다(앞에 11바0006이 더 있다). 안내 수신 미동의 고객은 나오지 않는다.

## 6. 예약

### 15 GET `/api/reservations?from=&to=` — 기간 조회 (날짜별 목록·캘린더)

`from`·`to`는 날짜(둘 다 포함). 최대 42일(월 보기 6주). 취소·노쇼 포함, 시각 순. P0-핵심은 홈의 날짜별 예약 목록(앞뒤 날짜 이동)이, P0-나머지부터는 홈 캘린더의 주 보기와 월 보기의 날짜 목록 패널이 이 API를 쓴다(일 보기는 없음, D-54). 월 보기의 날짜별 건수·상태별 건수는 요약 API 42를 쓴다(15는 쪽 나누기 없이 기간 전체를 돌려준다, 0.1).

| 응답 data | 설명 |
|---|---|
| from, to | 요청 기간 그대로 (date) |
| items | 아래. 기간에 예약이 없으면 `[]` |

| 쿼리 | 타입 | 필수 | 설명 |
|---|---|---|---|
| from, to | date | ○ | 기간 (둘 다 포함) |
| assigneeId | number | | P0-나머지. 그 담당의 예약만("내 담당만" 보기, 화면 필터일 뿐 데이터 권한이 아님). 없는 id나 다른 정비소 직원의 id는 오류가 아니라 200과 빈 `items`이고(정비소 조건은 그대로라 다른 정비소 예약은 나오지 않음, 본문 안의 담당 id가 400인 X13과 다름), 숫자가 아니면 400 `INVALID_INPUT` |

| 응답 items[] | 설명 |
|---|---|
| reservationId, reservedAt, status | `status`는 P0-나머지부터 `IN_PROGRESS` 가능 |
| needsAction | `status = RESERVED`이고 `reservedAt`이 현재 시각보다 이전 → "처리 필요" (D-23). 오늘 시각이 지난 예약은 "처리 필요"이면서 유효 예약(14·16 기준)이기도 하다. `IN_PROGRESS`는 "처리 필요"가 아니다 |
| version | 동시 수정 확인용 번호. 변경(19)·방문 완료(18)·취소(20)·노쇼(21)·방문 접수(39)·정정(40) 요청에 그대로 보낸다 (D-42, M1 결정 B) |
| vehicleId, plateNumber, customerId, customerName, phone | phone은 P0-나머지부터 마스킹 |
| purposeSummary | 고른 항목 이름을 `·`로 잇고, 기타면 "기타". 없으면 null |
| assignee | P0-나머지부터. 담당 정비사 `{ staffId, name, colorIndex }`. `colorIndex`는 36과 같은 값(화면은 색과 함께 이름 라벨을 보인다) |

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

P0-나머지부터는 `items[]`의 각 항목에 `assignee`가 더해진다(위 표). 예: `"assignee": { "staffId": 1, "name": "박사장", "colorIndex": 0 }`

에러: `INVALID_INPUT` (`from`·`to` 누락, `from` > `to`, 42일 초과)

### 16 POST `/api/reservations` — 예약 등록

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| vehicleId | number | ○ | 그 정비소 차량 |
| reservedAt | datetime | ○ | 분이 00·30, 초 00 (R1). 날짜 ≥ 오늘 (R2) |
| purpose.itemIds | number[] | | 그 정비소의 쓰는 항목, 중복 없음 |
| purpose.other | boolean | | 기본 false |
| purpose.memo | string | | ~200자 |
| assigneeId | number | P0-나머지 ○ | 담당 정비사 id. 그 정비소의 활성 사장·정비사 (X13). P0-핵심은 요청에 이 필드가 없고 서버가 토큰의 계정을 담당으로 채운다 (D-51) |

P0-핵심 요청 예시:

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

P0-나머지 요청·응답 예시(`assigneeId` 추가, 응답에 `assignee`):

```json
{
  "vehicleId": 1,
  "reservedAt": "2026-11-27T11:30:00",
  "assigneeId": 2,
  "purpose": { "itemIds": [1], "other": false, "memo": null }
}
```

```json
{
  "success": true,
  "data": {
    "reservationId": 5, "status": "RESERVED", "reservedAt": "2026-11-27T11:30:00", "vehicleId": 1, "version": 0,
    "assignee": { "staffId": 2, "name": "김정비", "colorIndex": 1 }
  },
  "error": null
}
```

서버가 확인하는 순서: 차량 소유(`getOwned`, 아니면 404) → 입력 검증(30분 단위·항목, P0-나머지부터 `assigneeId` 포함, 400) → 날짜 ≥ 오늘(400) → 같은 차량 유효 예약 1건(`RESERVED` + 날짜 ≥ 오늘, 또는 `IN_PROGRESS`, 409) → (P0-나머지) 담당 중복(같은 담당 + 같은 시작 시각의 유효 예약, 409). 소요 시간이 없어 10:00 예약은 10:30 예약을 막지 않는다(시작 시각만 비교). 같은 시각 다른 담당은 허용한다. 예약 행과 예약 목적 행은 한 트랜잭션으로 저장하고 `version`은 0에서 시작한다.

에러: `NOT_FOUND` (X4), `INVALID_INPUT` (R1, 항목 X11, P0-나머지부터 `assigneeId` 누락·없음·남의 것·비활성 X13), `RESERVATION_PAST_DATE` (R2), `RESERVATION_ACTIVE_EXISTS` (R3), `MECHANIC_SLOT_CONFLICT` (P0-나머지, R15)

`RESERVATION_ACTIVE_EXISTS`는 기존 예약 번호를 함께 준다. 화면은 그 예약의 상세 패널을 열어 확인·변경하게 한다(전화 예약 중 기존 예약 발견, 02 2.2):

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "RESERVATION_ACTIVE_EXISTS",
    "message": "이 차량에는 이미 유효한 예약이 있습니다.",
    "fieldErrors": [],
    "details": { "reservationId": 3 }
  }
}
```

`MECHANIC_SLOT_CONFLICT`(P0-나머지)도 겹친 예약 번호를 준다. 화면은 겹친 예약을 열 수 있게 하고 다른 시각·다른 담당을 고르게 한다(09 M-02). 예: 담당 김정비(`assigneeId` 2)로 2026-11-24T10:00에 등록하면 시드 예약 1과 겹친다:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "MECHANIC_SLOT_CONFLICT",
    "message": "이 정비사는 해당 시각에 이미 예약이 있습니다. 다른 시각이나 다른 담당을 선택해 주세요.",
    "fieldErrors": [],
    "details": { "reservationId": 1 }
  }
}
```

### 17 GET `/api/reservations/{reservationId}/panel` — 예약 상세 패널

| 응답 data | 설명 |
|---|---|
| reservation | `{ reservationId, reservedAt, status, needsAction, version, purpose: { items: [{ itemId, name }], other, memo }, assignee }` — `version`은 18~21·39·40 요청에 보낸다. `assignee`는 P0-나머지부터 `{ staffId, name, colorIndex }`. `status`는 P0-나머지부터 `IN_PROGRESS` 가능 |
| customer | `{ customerId, name, phone, consent }` (phone 전체, D-40. P1 익명화 고객은 빈 값) |
| vehicle | `{ vehicleId, plateNumber, model, modelYear, latestMileage }` |
| recentVisits | 최근 방문 **최대 2회** (11의 항목 모양, D-54가 D-26의 3회를 대체) |
| totalVisitCount | 그 차량의 전체 방문 횟수(서로 다른 `visit_key` 수, 외부 기록만 있는 방문 제외, 05 POL-45). **3 이상이면 화면이 "상세 이동" 버튼(→ 차량 상세 S-07)을 활성**하고 그 미만은 비활성으로 보인다 |
| itemStatuses | 10의 `items` 모양 + `highlighted`(예약 목적으로 고른 항목). 값은 10을 **주행거리 없이** 부른 결과와 같다(날짜 기준, `dueReason`은 `DATE`·null만). 같은 차량의 14 `targetItems`와 상태·다음 정비일이 같아야 한다. **순서는 정비 항목 `sortOrder` 순**이고 `highlighted` 항목도 자리를 옮기지 않는다(화면이 굵게 등으로만 강조, D-63 B02) |

```json
{
  "success": true,
  "data": {
    "reservation": {
      "reservationId": 4,
      "reservedAt": "2026-11-23T15:00:00",
      "status": "RESERVED",
      "needsAction": true,
      "version": 0,
      "purpose": { "items": [ { "itemId": 6, "name": "배터리" } ], "other": false, "memo": null }
    },
    "customer": { "customerId": 10, "name": "오세훈", "phone": "010-0000-0010", "consent": true },
    "vehicle": { "vehicleId": 10, "plateNumber": "55차0010", "model": "쏘나타", "modelYear": 2018, "latestMileage": 97000 },
    "recentVisits": [
      {
        "visitKey": "5eed0000-0000-4000-8000-000000000015",
        "visitDate": "2026-10-24",
        "mileage": null,
        "staffName": "김정비",
        "records": [ { "recordId": 16, "itemId": 1, "itemName": "엔진오일", "type": "REPLACE", "date": "2026-10-24", "memo": null } ]
      },
      {
        "visitKey": "5eed0000-0000-4000-8000-000000000014",
        "visitDate": "2026-08-24",
        "mileage": null,
        "staffName": "김정비",
        "records": [
          { "recordId": 14, "itemId": 2, "itemName": "에어클리너", "type": "REPLACE", "date": "2026-08-24", "memo": null },
          { "recordId": 15, "itemId": 3, "itemName": "에어컨필터", "type": "REPLACE", "date": "2026-08-24", "memo": null }
        ]
      }
    ],
    "totalVisitCount": 3,
    "itemStatuses": [
      {
        "itemId": 1, "code": "ENGINE_OIL", "name": "엔진오일",
        "status": "AHEAD", "dueReason": null,
        "baseRecord": { "date": "2026-10-24", "mileage": null, "type": "REPLACE" },
        "nextDueDate": "2027-04-24", "nextDueMileage": null,
        "highlighted": false
      },
      {
        "itemId": 6, "code": "BATTERY", "name": "배터리",
        "status": "SOON", "dueReason": null,
        "baseRecord": { "date": "2023-12-14", "mileage": null, "type": "REPLACE" },
        "nextDueDate": "2026-12-14", "nextDueMileage": null,
        "highlighted": true
      }
    ]
  },
  "error": null
}
```

`itemStatuses`는 예시에서 6개 중 2개만 적었다(실제는 쓰는 항목 전부, 순서는 `sortOrder` 순, D-63 B02). 강조(`highlighted`)된 배터리도 `sortOrder`대로 뒤에 있다. P0-나머지부터는 `reservation`에 `assignee`가 더해진다(위 표). 예: `"assignee": { "staffId": 1, "name": "박사장", "colorIndex": 0 }`. 예시 값은 07 7.2 시드(기록 id·`visitKey`, 55차0010 기록은 주행거리 없음)와 같다. 에러: `NOT_FOUND` (X3)

### 18 POST `/api/reservations/{reservationId}/complete` — 방문 완료

`RESERVED`(시각 전·후 모두) 또는 `IN_PROGRESS`(P0-나머지, D-52)에서 가능. 화면이 읽은 예약의 `version`을 함께 보낸다(M1 결정 B 확정). 진행중에서 완료해도 화면은 S-08로 이동한다.

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| version | number | ○ | 화면이 읽은 예약의 `version` (04·15·17 응답). 누락이거나 숫자가 아니면 400 `INVALID_INPUT`. 숫자이면(음수 포함) 서버 값과 다를 때 409 `CONCURRENT_MODIFICATION` |

```json
{ "version": 0 }
```

| 응답 data | 타입 | 설명 |
|---|---|---|
| reservationId | number | |
| status | enum | `COMPLETED` |
| vehicleId | number | 화면이 방문·정비 기록(S-08)을 열 때 쓴다 |
| version | number | 바뀐 `version` (요청 값 + 1) |

```json
{ "success": true, "data": { "reservationId": 1, "status": "COMPLETED", "vehicleId": 4, "version": 1 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락·숫자 아님, R13), `INVALID_STATUS_TRANSITION` (R5·R10), `CONCURRENT_MODIFICATION` (R10·R12)

서버 처리 (상태 변경 18·20·21 공통, 19와 같은 순서): 정비소 소유(`getOwned`, 아니면 404) → 지금 상태가 허용 상태인지(18·20은 `RESERVED`, P0-나머지부터 `IN_PROGRESS`도. 21은 `RESERVED`만. 아니면 409 `INVALID_STATUS_TRANSITION`) → 요청 `version` = DB `version`인지 서버가 직접 비교(아니면 409 `CONCURRENT_MODIFICATION`) → (21만) 시각이 지났는지(아니면 409 `INVALID_STATUS_TRANSITION`) → Entity 상태 전이 → `@Version` 조건으로 저장(`… WHERE id = ? AND version = ?`, 비교한 뒤 저장 전에 다른 요청이 먼저 바꿨으면 409 `CONCURRENT_MODIFICATION`). 성공하면 `version`을 1 올리고 응답에 준다. 하나라도 어긋나면 상태·일시·예약 목적·`version` 모두 그대로다.

- 다른 직원이 이미 끝낸 예약 → `INVALID_STATUS_TRANSITION` (상태 확인이 먼저).
- 다른 직원이 일시·목적을 먼저 바꾼 예약(아직 `RESERVED`) → `CONCURRENT_MODIFICATION`. 바뀐 예약을 다시 보고 처리하게 한다.
- **화면 처리**: 두 409 모두 예약 상세 패널을 다시 조회(17)해 최신 상태·`version`을 보여 주고, S-08로 이동하지 않는다. 자동으로 다시 보내지 않는다(05 POL-104·125).

응답의 `vehicleId`로 화면이 방문·정비 기록(S-08)을 연다. 정비 기록 저장(12)은 별도 요청이며 이 예약과 데이터로 잇지 않는다. 기록 저장이 실패하거나 하지 않아도 예약은 `COMPLETED`로 남는다(05 POL-95).

### 19 PATCH `/api/reservations/{reservationId}` — 변경 (P0-핵심, D-42)

`RESERVED`만(진행중·끝난 예약은 변경 불가, 409 `INVALID_STATUS_TRANSITION`). 보낸 필드만 바꾼다. 고객·차량은 바꿀 수 없다(바꾸려면 취소 후 새로 등록). 담당 정비사는 P0-나머지부터 `assigneeId`로 재배정한다.

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| version | number | ○ | 화면이 읽은 예약의 `version` (04·15·16·17 응답). 누락이거나 숫자가 아니면 400 `INVALID_INPUT`. 숫자이면(음수 포함) 서버 값과 다를 때 409 `CONCURRENT_MODIFICATION` |
| reservedAt | datetime | | 16과 같음: 30분 단위, 날짜 ≥ 오늘 |
| purpose.itemIds | number[] | | 보내면 예약 목적 항목 전체를 이 목록으로 바꾼다. 빈 목록 `[]`이면 항목을 모두 지운다. 목록 안에 null이 있으면 400 `INVALID_INPUT`(`purpose.itemIds`) |
| purpose.other | boolean | | |
| purpose.memo | string | | ~200자. 보내지 않거나 null이면 그대로, 빈 문자열 `""`이면 비운다 |
| assigneeId | number | | P0-나머지. 담당 재배정. 그 정비소의 활성 사장·정비사 (X13). 재배정 규칙은 아래 |
| reassignReason | string | 당일 사장 재배정이면 ○ | P0-나머지. 재배정 사유, ~200자 💡. 없으면 400 `INVALID_INPUT` |

`version` 밖에 바꿀 필드(`reservedAt`, `purpose.itemIds`·`other`·`memo`, P0-나머지부터 `assigneeId`)가 하나도 없으면 400 `INVALID_INPUT`(`fieldErrors`는 `reservedAt`)이고, 예약과 `version`을 바꾸지 않는다(R14, M1 설계 확정). 이 검사는 요청 형식 검증이라 소유 확인보다 먼저 한다.

서버가 확인하는 것: 정비소 소유(`getOwned`, 아니면 404) → 상태가 `RESERVED`인지 → `version` 일치 → 입력 검증(30분 단위 → 항목, 16과 같은 순서) → 날짜 규칙 → (P0-나머지) 담당 재배정 마감 → 같은 차량 유효 예약 1건(자기 자신 제외, **`reservedAt`을 보낼 때만**) → (P0-나머지) 담당 중복(같은 담당 + 같은 시작 시각의 다른 유효 예약, 자기 자신 제외). 하나라도 어긋나면 아무것도 바꾸지 않는다.

날짜 규칙(`RESERVATION_PAST_DATE`)과 같은 차량 유효 예약 확인은 일시를 바꿀 때(`reservedAt`을 보낼 때)만 적용한다. 유효 예약이 둘이 되는 길은 일시를 바꿔 지난 예약을 오늘 이후로 옮기는 것뿐이기 때문이다. 그래서 날짜가 어제 이전인 `RESERVED` 예약("처리 필요")도 일시를 바꾸지 않는 변경(예약 목적·메모)은 할 수 있고, 같은 차량에 다른 유효 예약이 있어도 막히지 않는다. 지난 예약의 정정은 P0-나머지에서 별도(40번).

**담당 재배정 규칙 (P0-나머지, D-53)**: 마감 기준 날짜는 **변경 전 예약 날짜**다(일시와 담당을 한 요청에 같이 보내도 변경 전 날짜로 판정).
- 사장·정비사 모두: 오늘 < 예약 날짜(= 예약 날짜 전날까지)일 때만. 아니면 409 `ASSIGNEE_CHANGE_CLOSED`.
- **사장만** 예약 날짜 = 오늘도 재배정할 수 있고, 이때 `reassignReason`이 필수다. 지난 날짜(예약 날짜 < 오늘)는 사장도 409 `ASSIGNEE_CHANGE_CLOSED`, 진행중은 상태 확인에서 409 `INVALID_STATUS_TRANSITION`이다.
- 재배정은 `reservation_revision`(`kind = ASSIGNEE`)에 새 담당·이전 담당·사유·수정자·시각을 남긴다(조회는 41).
- **지금 담당과 같은 `assigneeId`는 재배정이 아니다.** 마감 판정도 이력도 없이 넘긴다. 일시·예약 목적 변경을 함께 보냈으면 그 변경만 적용하고, 바뀌는 것이 하나도 없으면 R14처럼 400 `INVALID_INPUT`(`fieldErrors`는 `assigneeId`)이다.
- `reassignReason`은 당일 사장 재배정에서만 필수다. 그 밖의 재배정에서 보내면 이력의 사유로 남기고, 공백뿐인 값은 사유 없음으로 본다.
- 입력 검증 안의 순서는 16과 같다: 30분 단위 → 항목 → `assigneeId`(X13) → 날짜. 담당 중복(R18)은 재배정이면 **새 담당**과 새 시각(안 바꾼 쪽은 지금 값)으로 본다.

- `version` 일치는 요청의 `version`과 DB에서 읽은 값을 서버가 직접 비교한다(JPA `@Version`은 읽은 뒤 저장 사이의 충돌만 잡으므로 둘 다 필요). 상태 확인이 먼저라, 다른 직원이 이미 끝낸 예약에 낡은 `version`으로 보내면 `INVALID_STATUS_TRANSITION`이 난다.
- 성공하면 바꾼 필드와 상관없이 `version`을 1 올린다. **예약 목적 항목(`purpose.itemIds`)만 바뀌어 `reservation` 행의 칼럼이 그대로여도 올린다**(`OPTIMISTIC_FORCE_INCREMENT` 또는 `updated_at` 갱신). 그렇지 않으면 목적만 바꾼 두 요청이 서로를 덮어쓴다.
- 예약 목적 항목은 기존 행을 지운 뒤 다시 넣는다(07 3.9). 항목 id는 16과 같은 검증(X11).

P0-핵심 요청·응답 예시:

```json
{ "version": 0, "reservedAt": "2026-11-28T09:00:00", "purpose": { "itemIds": [1, 4], "other": false, "memo": null } }
```

```json
{ "success": true, "data": { "reservationId": 3, "status": "RESERVED", "reservedAt": "2026-11-28T09:00:00", "vehicleId": 2, "version": 1 }, "error": null }
```

P0-나머지 담당 재배정 예시(예약 3의 담당을 김정비에서 박사장으로, 오늘 11-24 < 예약 날짜 11-26이라 전날까지 규칙 통과):

```json
{ "version": 0, "assigneeId": 1 }
```

```json
{
  "success": true,
  "data": {
    "reservationId": 3, "status": "RESERVED", "reservedAt": "2026-11-26T10:00:00", "vehicleId": 2, "version": 1,
    "assignee": { "staffId": 1, "name": "박사장", "colorIndex": 0 }
  },
  "error": null
}
```

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락, 바꿀 필드 없음 R14, 30분 단위 아님, P0-나머지부터 `assigneeId`가 없음·남의 것·비활성 X13, 당일 사장 재배정에 `reassignReason` 없음), `RESERVATION_PAST_DATE` (R7), `RESERVATION_ACTIVE_EXISTS`, `MECHANIC_SLOT_CONFLICT` (P0-나머지, R18), `ASSIGNEE_CHANGE_CLOSED` (P0-나머지, R24), `INVALID_STATUS_TRANSITION` (R9, 진행중 R21), `CONCURRENT_MODIFICATION` (R8·R11). 화면은 409 `CONCURRENT_MODIFICATION`이면 최신 예약을 다시 불러와 보여 주고 다시 수정하게 한다(09 M-02).

### 20 POST `/api/reservations/{reservationId}/cancel` — 취소 (P0-나머지)

`RESERVED` 또는 `IN_PROGRESS`에서, 시각 전·후 모두. 요청 본문은 `version`만(취소 사유 없음, POL-100). 요청·서버 처리·실패 처리·화면 처리는 18과 같다. 선행 DB 변경 없음(`CANCELED`는 V1에 있음. `IN_PROGRESS`는 39와 같이 V2).

```json
{ "version": 0 }
```

```json
{ "success": true, "data": { "reservationId": 3, "status": "CANCELED", "vehicleId": 2, "version": 1 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락), `INVALID_STATUS_TRANSITION` (끝난 예약), `CONCURRENT_MODIFICATION` (R12). 취소하면 그 차량은 바로 다시 "유효 예약 없음"이 된다(재점검 대상의 "예약 있음"이 사라짐).

### 21 POST `/api/reservations/{reservationId}/no-show` — 노쇼 (P0-나머지)

`RESERVED`이고 `reservedAt`이 현재 시각보다 이전인 예약만 (R6). 요청 본문은 `version`만. 요청·서버 처리·실패 처리·화면 처리는 18과 같고, 시각 확인은 `version` 비교 다음에 `Clock`으로 한다(`markNoShow(now)`). 선행 DB 변경: `V2`의 `reservation.status` CHECK에 `NO_SHOW` (07 6장).

```json
{ "version": 0 }
```

```json
{ "success": true, "data": { "reservationId": 4, "status": "NO_SHOW", "vehicleId": 10, "version": 1 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락), `INVALID_STATUS_TRANSITION` (R6: 시각 전, 끝난 예약), `CONCURRENT_MODIFICATION` (R12)

### 예약 상태 변경 요약

| 현재 → | 방문 접수 (39, P0-나머지) | 방문 완료 (18) | 일시·목적·담당 변경 (19) | 취소 (20) | 노쇼 (21) |
|---|---|---|---|---|---|
| RESERVED, 시각 전 | ○ | ○ | ○ | ○ | × |
| RESERVED, 시각 지남 (처리 필요) | ○ | ○ | ○ (오늘 이후로) | ○ | ○ |
| IN_PROGRESS (P0-나머지) | × | ○ | × | ○ | × |
| COMPLETED · CANCELED · NO_SHOW | × | × | × | × | × |

× = `INVALID_STATUS_TRANSITION`. P0-핵심에는 `IN_PROGRESS`와 39가 없다. 18~21·39 모두 화면이 읽은 `version`을 보내고, 다른 직원이 같은 예약을 먼저 바꿨으면 `CONCURRENT_MODIFICATION`이나 `INVALID_STATUS_TRANSITION`으로 실패하며 덮어쓰지 않는다. 끝난 예약(`COMPLETED`·`CANCELED`·`NO_SHOW`)의 상태·메모 정정은 이 표가 아니라 40의 허용표를 따른다(7장). "처리 필요"인 `RESERVED` 예약의 정리는 정정이 아니라 18·20·21이다.

| | 변경 (19) | 방문 완료·취소·노쇼 (18·20·21) |
|---|---|---|
| 요청 본문 | `version`(필수) + 바꿀 필드(하나 이상, 없으면 400) | `{ "version": n }` (필수) |
| 확인 순서 | 형식 → 소유 → 상태 → 요청 `version` = DB `version` → 시각·날짜 → (P0-나머지) 담당 재배정 마감 → 같은 차량 유효 예약 1건 → (P0-나머지) 담당 중복 → `@Version` 저장 | 형식 → 소유 → 상태 → 요청 `version` = DB `version` → (21만) 시각 지남 → `@Version` 저장 |
| 다른 직원이 먼저 끝냄 | `INVALID_STATUS_TRANSITION` | `INVALID_STATUS_TRANSITION` |
| 다른 직원이 먼저 일시·목적 변경 | `CONCURRENT_MODIFICATION` | `CONCURRENT_MODIFICATION` |
| 거의 동시 (비교 뒤 저장 전) | `CONCURRENT_MODIFICATION` (`@Version`) | `CONCURRENT_MODIFICATION` (`@Version`) |
| 실패 시 | 예약·예약 목적·`version` 그대로 | 예약·`version` 그대로 |
| 성공 시 응답 `version` | 요청 값 + 1 (목적·담당만 바뀌어도) | 요청 값 + 1 |
| 화면 (409) | 최신 예약을 다시 불러와 다시 수정 | 예약 상세 패널 다시 조회, S-08 이동 없음 |
| 단계 | P0-핵심 | 18 P0-핵심, 20·21 P0-나머지 |

## 7. P0-나머지 확정 범위와 고객·차량 수정

### 7.0 P0-나머지 확정 범위 (M1 결정 D)

여기까지 확정한다. **요청·응답 표와 JSON 예시는 그 기능의 착수 PR에서 이 문서에 확정**한다(아래 22·23 예시는 착수 전 초안. 22·23은 chagok-docs#148에서 `version`을 확정). 20·21의 요청·응답은 18과 같은 모양으로 M1 설계 확정 때 확정했다(6장). 36~42(D-51~D-55)는 이 표와 7.1의 요약까지 확정하고 상세 JSON은 착수 PR에서 정한다. 착수 전에 이 표와 다른 것이 필요하면 `결정` 이슈부터.

| API | 메서드·경로 | 책임 | 역할·격리 | 상태 전환·동시 수정 | 선행 DB 변경 |
|---|---|---|---|---|---|
| 20 | POST `/api/reservations/{reservationId}/cancel` | 예약 취소 (F-RSV-07). 본문 `{ version }` | 사장·정비사. 남의 예약 404 (X12) | `RESERVED`·`IN_PROGRESS` → `CANCELED`, 시각 전·후. 6장 상태 변경 공통 | `IN_PROGRESS`는 V2 (39와 같음) |
| 21 | POST `/api/reservations/{reservationId}/no-show` | 노쇼 (F-RSV-08). 본문 `{ version }` | 사장·정비사. 남의 예약 404 (X12) | `RESERVED` + 시각 지남 → `NO_SHOW` (R6). 6장 공통 | V2: status CHECK `NO_SHOW` |
| 22 | PATCH `/api/customers/{customerId}` | 고객명·연락처·동의 수정 (F-CUS-06). 보낸 필드만 | 사장·정비사. 남의 고객 404 (X12) | 요청에 `version` 필수, 다르면 409 `CONCURRENT_MODIFICATION` (POL-124) | V2: `customer.version` |
| 23 | PATCH `/api/vehicles/{vehicleId}` | 차량번호·차종·연식·최근 주행거리 수정 (F-CUS-06). 고객은 바꾸지 않음 | 사장·정비사. 남의 차량 404 (X12) | 22와 같음 | V2: `vehicle.version` |
| 12 확장 | POST `/api/vehicles/{vehicleId}/visits` | 외부·거절·점검 결과 입력 (F-MNT-02·03), 담당 `mechanicId` (D-51) | 같음. 남의 정비사 id 400 (X13) | — (기록은 추가만) | V2: `inspect_result` |
| 10·11·14·17 확장 | 기존 경로 | `lastDecline`·`lastCaution`(10·14·17), `source`·`inspectResult`·`version`·`edited`·`staff`(11·17 `recentVisits`) (F-CYC-02, F-MNT-04) | 같음 | — | V2: `inspect_result`, `maintenance_record.version` |
| 04·05·14·15 확장 | 기존 경로 | 목록 `phone` 마스킹 (F-CUS-07) | 같음 | — | 없음 |
| 04·15·17 확장 | 기존 경로 | `assignee`(담당 이름·색), 15 쿼리 `assigneeId`, 상태 `IN_PROGRESS` (D-51·D-52) | 같음 | — | V2: `IN_PROGRESS` |
| 15 (캘린더) | 기존 경로 | 홈 캘린더 월·주 보기는 같은 기간 조회(일 보기 없음, D-54). 월 보기 건수는 42 (F-RSV-05) | 같음 | — | 없음 |
| 16·19 확장 | 기존 경로 | 16 `assigneeId`(필수)·`MECHANIC_SLOT_CONFLICT`, 19 `assigneeId` 재배정·`reassignReason`·`ASSIGNEE_CHANGE_CLOSED` (D-51·D-53) | 같음. 남의 정비사 id 400 (X13) | 19는 `RESERVED`만 (재배정 마감 규칙은 19) | V2: `reservation_revision` (재배정 이력) |
| 36 | GET `/api/staff/assignees` | 담당 후보 목록 (F-RSV-01·06): 활성 사장·정비사 | 사장·정비사. 그 정비소 직원만 | — | 없음 (`staff` UNIQUE(shop_id, id)는 V1) |
| 37 | PATCH `/api/records/{recordId}` | 정비 기록 수정 (F-MNT-04). 보낸 필드만. 삭제 없음 | 사장은 전체, 정비사는 본인 담당·방문일 기준 3일 이내. 남의 기록 404 (X14) | 요청에 `version` 필수, 다르면 409 `CONCURRENT_MODIFICATION` | V2: `maintenance_record.updated_at·version`, `maintenance_record_revision` |
| 38 | GET `/api/records/{recordId}/revisions` | 정비 기록 수정 이력 (F-MNT-04) | 사장·정비사. 남의 기록 404 (X14) | — | V2: 37과 같음 |
| 39 | POST `/api/reservations/{reservationId}/start` | 방문 접수 (F-RSV-09). 차량 도착 | 사장·정비사. 남의 예약 404 (X14) | `RESERVED` → `IN_PROGRESS`, 시각 전·후. 요청에 `version` 필수. 6장 공통 | V2: status CHECK `IN_PROGRESS` |
| 40 | POST `/api/reservations/{reservationId}/correct` | 지난 예약 정정 (F-RSV-10): 상태·메모 | 상태 정정은 사장, 메모는 사장·담당 정비사(예약 날짜 + 3일 이내). 남의 예약 404 (X14) | 허용표 밖 409 `INVALID_STATUS_TRANSITION`. 요청에 `version` 필수 | V2: `reservation_revision` |
| 41 | GET `/api/reservations/{reservationId}/revisions` | 예약 재배정·정정 이력 (F-RSV-06·10) | 사장·정비사. 남의 예약 404 (X14) | — | V2: 40과 같음 |
| 42 | GET `/api/reservations/summary?from=&to=` | 월 보기의 날짜별 건수·상태별 건수 (F-RSV-05) | 사장·정비사. 토큰의 정비소만 | — | 없음 |

### 22 PATCH `/api/customers/{customerId}`

보낸 필드만. `name`·`phone`·`consent` (검증은 06과 같음). 화면은 고객 상세(07)에서 읽은 `version`을 함께 보낸다.

| 요청 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| version | number | ○ | 화면이 읽은 고객의 `version` (07 응답). 누락이거나 숫자가 아니면 400 `INVALID_INPUT`. 숫자이면(음수 포함) 서버 값과 다를 때 409 `CONCURRENT_MODIFICATION` |
| name, phone, consent | string, string, boolean | 선택 | 보낸 것만 바꾼다 |

| 응답 data | 타입 | 설명 |
|---|---|---|
| customerId, name, phone, consent | number, string, string, boolean | 바뀐 뒤의 값 |
| version | number | 바뀐 `version` (요청 값 + 1). 화면은 이 값을 다음 수정에 쓴다 |

```json
{ "version": 0, "consent": false }
```

```json
{ "success": true, "data": { "customerId": 1, "name": "김민수", "phone": "010-0000-0001", "consent": false, "version": 1 }, "error": null }
```

서버가 확인하는 순서: ① 요청 본문 형식(`version` 누락·숫자 아님, 값 형식, 400) → ② 정비소 소유(`getOwned`, 아니면 404) → ③ `version` 일치(409). ①은 요청 값만 보고 가를 수 있어 DB를 읽기 전에 거르는 것이 효율적이고(6장 표와 같음), 남의 정비소 데이터가 있는지 알려 주지 않으려고 ②를 ③보다 먼저 한다. 하나라도 어긋나면 아무것도 바꾸지 않는다. 요청 `version`과 DB에서 읽은 값은 서버가 직접 비교한다(18·19와 같음).

- 성공하면 바꾼 필드가 무엇이든 `version`을 1 올린다.
- **보낸 값이 지금 값과 모두 같으면** 200으로 지금 값을 돌려주고 `version`은 올리지 않는다. (chagok-docs#148에서 확정, 13 changelog)
- **화면 처리**: 409 `CONCURRENT_MODIFICATION`이면 고객 상세(07)를 다시 조회해 최신 값·`version`을 보여 주고, 입력한 값은 지우지 않는다. 자동으로 다시 보내지 않는다(05 POL-124).

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락·숫자 아님, 형식 오류), `CONCURRENT_MODIFICATION`

동의를 해제하면 재점검 대상·홈 숫자에서 바로 빠진다.

### 23 PATCH `/api/vehicles/{vehicleId}`

`plateNumber`·`model`·`modelYear`·`latestMileage`(최근 주행거리). 고객은 바꾸지 않는다. `model`은 비울 수 없고, `modelYear`·`latestMileage`도 값이 있으면 비울 수 없다(F-CUS-06). 요청에 차량 정보(09)에서 읽은 `version`(필수)을 함께 보낸다. 요청·서버 처리·실패 처리·화면 처리는 22와 같다(화면은 09를 다시 조회). 단 `modelYear`가 현재 연도 + 1보다 크면(시각이 필요해 서비스가 확인) ②와 ③ 사이에서 400 `INVALID_INPUT`(`fieldErrors`는 `modelYear`)이다.

최근 주행거리는 방문 기록(12)으로도 바뀐다(수정값이 기존보다 클 때 갱신). **그때 `vehicle.version`도 1 올라간다.** 수정 폼을 연 사이에 방문 기록이 저장되면 차량 수정은 409 `CONCURRENT_MODIFICATION`이 되고, 화면은 09를 다시 조회해 최신 주행거리를 보여 준다. 의도된 동작이다.

```json
{ "version": 0, "model": "K5 하이브리드" }
```

```json
{ "success": true, "data": { "vehicleId": 4, "plateNumber": "78라0004", "model": "K5 하이브리드", "modelYear": 2020, "latestMileage": 45000, "version": 1 }, "error": null }
```

에러: `NOT_FOUND`, `INVALID_INPUT` (`version` 누락·숫자 아님, 형식 오류), `CONCURRENT_MODIFICATION`

### 7.1 신규 API 36~42 요약 (D-51~D-55, 상세 JSON은 각 기능 착수 PR)

공통: 정비소 API라 토큰의 `shop_id`만 쓰고, 서비스 관리자 토큰은 403(X16). 남의 정비소 id는 404(X14).

- **36** `GET /api/staff/assignees` (담당 후보). 응답 `items: [ { staffId, name, role, colorIndex } ]`, 활성 사장·정비사만(비활성 제외는 `staff.active`가 생기는 P1(V3)부터이고, P0-나머지는 그 정비소의 사장·정비사 전원). `items`는 `staffId` 오름차순(= `colorIndex` 순번 순서)이고 직원이 없으면 빈 배열이다. `colorIndex`는 그 정비소 사장·정비사 계정 id 순서(비활성 포함)를 8로 나눈 나머지(8색 순환, 첫 계정이 0)이며 15·17·04의 `assignee.colorIndex`와 같은 값이다. 쪽 나누기 없음(정비소 직원 수 상한이 작음, `// LIMIT:`). 요청 파라미터 없음(정비소는 토큰의 `shop_id`로만 정한다).

  ```json
  {
    "success": true,
    "data": {
      "items": [
        { "staffId": 1, "name": "박사장", "role": "OWNER", "colorIndex": 0 },
        { "staffId": 2, "name": "김정비", "role": "MECHANIC", "colorIndex": 1 }
      ]
    },
    "error": null
  }
  ```
- **37** `PATCH /api/records/{recordId}` (정비 기록 수정, D-55, F-MNT-04). **기록 1행**의 방문일·주행거리·구분·항목·점검 결과·메모·담당 정비사를 고친다. 보낸 필드만 바꾼다. 차량은 바꿀 수 없고 삭제는 없다. 사장·정비사가 호출할 수 있고 정비사는 아래 권한 규칙을 따른다.

  | 요청 | 타입 | 필수 | 검증 |
  |---|---|---|---|
  | version | number | ○ | 화면이 읽은 기록의 `version`(11 `records[].version`). 누락이거나 숫자가 아니면 400 `INVALID_INPUT`, 서버 값과 다르면 409 `CONCURRENT_MODIFICATION` |
  | recordDate | date | | 바꿀 방문일. 오늘 이전·오늘(미래는 400). 외부 기록(`EXTERNAL`)이면 고객이 말한 정비일 |
  | mileage | number | | 바꿀 주행거리. 정수 0~2,000,000 (0.1) |
  | type | enum | | 바꿀 구분 `REPLACE`·`INSPECT`·`EXTERNAL`·`DECLINE` (0.4). 출처(`source`)는 서버가 맞춘다(`EXTERNAL`이면 `CUSTOMER_STATEMENT`, 그 밖은 `SHOP`, 07 3.7 CHECK) |
  | itemId | number | | 바꿀 항목. 그 정비소의 쓰는 항목(X11), 아니면 400 |
  | inspectResult | enum | | `GOOD`·`CAUTION`. 수정 뒤 구분이 `INSPECT`일 때만 보낼 수 있고 아니면 400 |
  | memo | string | | ~200자. 빈 문자열 `""`이면 메모를 비운다(19·40과 같음) |
  | mechanicId | number | | 바꿀 담당 정비사. 그 정비소의 사장·정비사(X13), 아니면 400. 정비사도 다른 정비사를 지정할 수 있다(12와 같음) |
  | reason | string | | 수정 사유, ~200자. 공백뿐이면 사유 없음으로 본다 |

  - 같은 값으로 두는 필드(`mileage`·`itemId` 등)는 바꾸는 것이 아니다. 바뀌는 필드가 하나도 없으면(`version`만 보냈거나 모두 지금과 같음) 400 `INVALID_INPUT`이고 `fieldErrors`는 보낸 필드 중 요청 표 순서로 첫째, 하나도 없으면 `recordDate`이다. 이때 이력은 남지 않는다.
  - **권한(수정 전 기록 기준)**: 사장은 모든 기록·기간 제한 없음. 정비사는 **수정 전 담당이 본인인 기록**만이고 아니면 403 `FORBIDDEN`(H3), **수정 전 방문일 + 3일 이내**(오늘 ≤ 방문일 + 3일)여야 하고 넘으면 403 `EDIT_PERIOD_EXPIRED`(H10). 외부 기록은 방문일이 고객이 말한 정비일이므로 **저장일(`created_at`의 서울 날짜)** 로 센다. 담당을 다른 정비사로 바꾸는 것도 이 기준으로 한 번 확인할 뿐 바뀐 담당에게는 제한이 없다.
  - **구분·점검 결과**: 구분을 `INSPECT`가 아닌 것으로 바꾸면 기존 점검 결과는 비워진다. `INSPECT`로 바꾸면서 `inspectResult`를 보내지 않으면 `null`(결과 없음)이다. 같은 방문(`visit_key`)에 같은 항목이 둘이 되면 400 `INVALID_INPUT`이고 `fieldErrors`는 `itemId`(H7). 수정 뒤 값으로 검사한다.
  - **주행거리**: 수정한 `mileage`가 차량 최근 주행거리보다 크면 차량 값을 갱신하고 작거나 같으면 갱신하지 않는다(05 POL-60). 오류가 아니다.
  - **서버가 확인하는 순서**: 형식(타입·길이·범위·미래 방문일, 400) → 정비소 소유(`getOwned`, 아니면 404, X14) → `version` 일치(409) → 권한(403 `FORBIDDEN` → `EDIT_PERIOD_EXPIRED`) → `itemId`·`mechanicId`(400, X11·X13) → 구분·점검 결과 짝(400) → 지금 값과 같은 필드를 뺀 뒤 바뀐 것이 있는지(400) → 같은 방문 항목 중복(400) → 저장. 하나라도 어긋나면 기록·`version`·이력이 모두 그대로다.
  - **응답**: `{ recordId, vehicleId, version }`(`version` +1). 수정된 기록 전체는 싣지 않는다. 화면은 수정 뒤 11을 다시 조회해 최신 값과 `edited`를 보여 준다. 주기 상태는 저장하지 않고 조회 때 계산하므로 수정 즉시 다음 정비일·상태·재점검 대상에 반영된다(H2).
  - 수정할 때마다 `maintenance_record_revision`에 **1행**(수정자·수정 시각·수정 전 값 전체·사유)을 같은 트랜잭션으로 남긴다. 조회는 38.
  - 에러: `NOT_FOUND`(X14), `INVALID_INPUT`(`version` 누락, 미래 방문일, 값 범위·길이, `itemId`·`mechanicId` 오류, `inspectResult`와 구분 불일치, 같은 방문 항목 중복, 바뀐 것 없음), `FORBIDDEN`(정비사가 남이 담당한 기록), `EDIT_PERIOD_EXPIRED`(정비사 기간 초과), `CONCURRENT_MODIFICATION`.

  요청·응답 예시(사장이 11 예시의 기록 16에 주행거리·메모를 보완):

  ```json
  { "version": 0, "mileage": 52000, "memo": "합성유 사용", "reason": "입력 누락 보완" }
  ```

  ```json
  { "success": true, "data": { "recordId": 16, "vehicleId": 4, "version": 1 }, "error": null }
  ```

  구분 정정 요청 예시(교체 → 점검, 이때 점검 결과를 함께 보낼 수 있다):

  ```json
  { "version": 1, "type": "INSPECT", "inspectResult": "CAUTION" }
  ```
- **38** `GET /api/records/{recordId}/revisions` (정비 기록 수정 이력 조회, D-55). 사장·정비사 모두 볼 수 있다. 남의 정비소 기록은 404(X14, H5). 이력은 쓰기만 하고 고치거나 지우지 않는다.

  | 응답 data | 설명 |
  |---|---|
  | items | 아래 목록. 수정 이력이 없으면 `[]` |

  | 응답 items[] | 설명 |
  |---|---|
  | revisionNo | 그 기록의 수정 번호. 1부터(07 4.1) |
  | changedAt | 수정한 일시 (datetime) |
  | changedBy | 수정한 사람 `{ staffId, name }` |
  | reason | 수정 사유. 없으면 `null` |
  | changes | `[ { field, before, after } ]`. 그 수정에서 바뀐 필드마다 한 항목, 아래 `field` 순서로 |

  | changes[].field | before·after |
  |---|---|
  | recordDate | date |
  | mileage | number 또는 `null` |
  | type | enum (`REPLACE`·`INSPECT`·`EXTERNAL`·`DECLINE`) |
  | item | `{ itemId, name }` (37 요청의 `itemId`) |
  | inspectResult | `GOOD`·`CAUTION` 또는 `null` |
  | memo | string 또는 `null` |
  | mechanic | `{ staffId, name }` (37 요청의 `mechanicId`, 담당 정비사) |

  서버는 한 수정의 수정 전 값(`prev_*`)과 **다음 수정의 수정 전 값**(마지막 수정은 지금 기록)을 비교해 `changes`를 만든다. 순서는 `revisionNo` 오름차순(오래된 것부터)이고 쪽 나누기는 없다. 구분을 바꿔 점검 결과가 비워진 것은 `inspectResult`의 `changes` 항목으로 나온다. `name`은 그 항목·계정의 현재 이름이다. 화면은 수정 날짜·수정자·`항목명: 전 → 후`를 보여 준다(F-MNT-04).

  ```json
  {
    "success": true,
    "data": {
      "items": [
        {
          "revisionNo": 1,
          "changedAt": "2026-11-25T10:05:00",
          "changedBy": { "staffId": 1, "name": "박사장" },
          "reason": "입력 누락 보완",
          "changes": [
            { "field": "mileage", "before": null, "after": 52000 },
            { "field": "memo", "before": null, "after": "합성유 사용" }
          ]
        },
        {
          "revisionNo": 2,
          "changedAt": "2026-11-26T09:30:00",
          "changedBy": { "staffId": 1, "name": "박사장" },
          "reason": null,
          "changes": [
            { "field": "type", "before": "REPLACE", "after": "INSPECT" },
            { "field": "inspectResult", "before": null, "after": "CAUTION" }
          ]
        }
      ]
    },
    "error": null
  }
  ```
- **39** `POST /api/reservations/{reservationId}/start` (방문 접수, D-52, F-RSV-09). 상태 `RESERVED`인 예약을 `IN_PROGRESS`로 바꾼다(차량 도착). 시각 전·후 모두 가능하다. 사장·정비사가 호출할 수 있고 담당 정비사가 아니어도 된다.

  | 요청 | 타입 | 필수 | 검증 |
  |---|---|---|---|
  | version | number | ○ | 18~21·40과 같음. 누락이거나 숫자가 아니면 400 `INVALID_INPUT`, 서버 값과 다르면 409 `CONCURRENT_MODIFICATION` |
  | modelYear | number | 조건부 ○ | 차량의 연식이 비어 있으면 필수(D-58, 없으면 400). 1980 ~ 현재 연도 + 1 (0.1) |
  | mileage | number | 조건부 ○ | 차량의 최근 주행거리가 비어 있으면 필수(D-58, 없으면 400). 정수 0~2,000,000 (0.1) |

  - **차량 반영**(같은 트랜잭션): `modelYear`는 차량 연식이 비어 있을 때만 채우고 이미 있으면 바꾸지 않는다. `mileage`는 차량 최근 주행거리가 비어 있거나 보낸 값이 더 클 때만 갱신하고, 같거나 작으면 바꾸지 않으며 오류가 아니다(05 POL-60). 차량에 값이 이미 있으면 보내지 않아도 된다. 보낸 값은 범위를 확인한다.
  - **서버가 확인하는 순서**: 형식(400) → 정비소 소유(`getOwned`, 아니면 404, X14) → 지금 상태가 `RESERVED`인지(아니면 409 `INVALID_STATUS_TRANSITION`, 진행중·끝난 예약 포함) → `version` 일치(409) → 차량의 비어 있는 연식·주행거리가 요청에 있는지(400, `fieldErrors`는 `modelYear`·`mileage` 중 빠진 것을 모두) → 보낸 값의 범위(400) → 저장. 하나라도 어긋나면 예약·차량·`version`이 모두 그대로다.
  - **응답**: 18·20·21·40과 같은 `{ reservationId, status, vehicleId, version }`(`status`는 `IN_PROGRESS`, `version` +1). 화면은 접수 뒤 17을 다시 조회해 최신 값을 보여 준다.
  - 진행중이 되면 변경(19)·재배정은 되지 않고 완료(18)·취소(20)만 되며, 담당의 시작 시각을 계속 점유한다(R22). 접수 뒤 정비 기록(12)은 별도 요청이다(05 POL-95).
  - 에러: `NOT_FOUND`(X14), `INVALID_INPUT`(`version` 누락, 비어 있는 연식·주행거리 미입력, 범위 밖), `INVALID_STATUS_TRANSITION`(`RESERVED`가 아님), `CONCURRENT_MODIFICATION`.

  요청·응답 예시(차량 연식·주행거리가 비어 있어 함께 보냄, 예약 3):

  ```json
  { "version": 1, "modelYear": 2018, "mileage": 55000 }
  ```

  ```json
  { "success": true, "data": { "reservationId": 3, "status": "IN_PROGRESS", "vehicleId": 2, "version": 2 }, "error": null }
  ```

  차량에 이미 값이 있을 때의 요청 예시:

  ```json
  { "version": 0 }
  ```
- **40** `POST /api/reservations/{reservationId}/correct` (지난 예약 정정, D-53, F-RSV-10). **끝난 예약(`COMPLETED`·`CANCELED`·`NO_SHOW`)의 상태·예약 메모**를 사후에 고친다. `RESERVED`·`IN_PROGRESS`는 정정 대상이 아니라 409 `INVALID_STATUS_TRANSITION`이다("처리 필요"인 예약의 정리는 정정이 아니라 18·20·21). 사장·정비사가 호출할 수 있고 할 수 있는 일은 아래처럼 갈린다.

  | 요청 | 타입 | 필수 | 검증 |
  |---|---|---|---|
  | version | number | ○ | 18~21과 같음. 누락이거나 숫자가 아니면 400 `INVALID_INPUT`, 서버 값과 다르면 409 `CONCURRENT_MODIFICATION` |
  | status | enum | | 바꿀 상태: `COMPLETED`·`CANCELED`·`NO_SHOW` 중 하나. 그 밖의 값은 400 `INVALID_INPUT` |
  | purposeMemo | string | | 바꿀 예약 메모, ~200자. 빈 문자열 `""`이면 메모를 비운다(19와 같음) |
  | reason | string | | 정정 사유, ~200자. 공백뿐이면 사유 없음으로 본다 |

  - **상태 정정 허용표**: 취소→노쇼, 노쇼→취소, 취소→완료, 노쇼→완료. 모두 **사장만**이고 정비사가 `status`를 보내면 403 `FORBIDDEN`(R27). 완료→취소·노쇼를 포함한 그 밖의 전이는 409 `INVALID_STATUS_TRANSITION`(R26). 완료로 정정해도 정비 기록은 자동으로 만들지 않는다.
  - **메모 정정**: 사장은 기간 제한이 없다. 정비사는 **그 예약의 담당**일 때만 가능하고 **예약 날짜 + 3일 이내**(오늘 ≤ 예약 날짜 + 3일)여야 한다. 담당이 아니면 403 `FORBIDDEN`(R29), 기간이 지났으면 403 `EDIT_PERIOD_EXPIRED`(R28)이며 담당 여부를 먼저 본다.
  - 지금 값과 같은 `status`·`purposeMemo`는 바꾸는 것이 아니다. 바뀌는 필드가 하나도 없으면(둘 다 없거나 모두 지금과 같음) 400 `INVALID_INPUT`이고 `fieldErrors`는 `status`를 보냈으면 `status`, 아니면 `purposeMemo`이다.
  - `status`와 `purposeMemo`를 함께 보내면 둘 다 허용될 때만 적용하고, 하나라도 안 되면 아무것도 바꾸지 않는다. 정비사가 메모만 고치려고 `status`를 함께 보내면 `status` 때문에 403이다.
  - **서버가 확인하는 순서**: 형식(400) → 정비소 소유(`getOwned`, 아니면 404, X14) → 지금 상태가 끝난 예약인지(409) → `version` 일치(409) → 권한(403) → 지금 값과 같은 필드를 뺀 뒤 바뀐 것이 있는지(400) → 상태 허용표(409) → `@Version` 조건으로 저장. 하나라도 어긋나면 상태·메모·`version`·이력 모두 그대로다.
  - **응답**: 18·20·21과 같은 `{ reservationId, status, vehicleId, version }`(`version` +1, `status`는 정정 뒤 상태. 메모만 고쳤으면 지금 상태 그대로). 화면은 정정 뒤 17을 다시 조회해 최신 값을 보여 준다.
  - 모든 정정은 `reservation_revision`에 남긴다. 상태를 고치면 `kind = STATUS`(이전·이후 상태), 메모를 고치면 `kind = MEMO`(이전·이후 메모) 한 행씩이고, 둘 다 고치면 같은 `reason`·수정자·시각으로 두 행을 같은 트랜잭션에 남긴다.
  - 에러: `NOT_FOUND`(X14), `INVALID_INPUT`(`version` 누락, `status` 값 오류, 바뀐 것 없음, 사유·메모 길이), `INVALID_STATUS_TRANSITION`(끝난 예약이 아님, 허용표 밖), `FORBIDDEN`(정비사의 상태 정정, 담당이 아닌 정비사의 메모 정정), `EDIT_PERIOD_EXPIRED`(담당 정비사가 예약 날짜 + 3일 초과), `CONCURRENT_MODIFICATION`.

  요청·응답 예시(예약 4 노쇼를 사장이 취소로 정정, 시드 예약 4와 같은 값):

  ```json
  { "version": 1, "status": "CANCELED", "reason": "고객이 전날 전화로 취소함" }
  ```

  ```json
  { "success": true, "data": { "reservationId": 4, "status": "CANCELED", "vehicleId": 10, "version": 2 }, "error": null }
  ```

  메모 정정 요청 예시(담당 정비사, 예약 날짜 + 3일 이내):

  ```json
  { "version": 2, "purposeMemo": "배터리 교체, 단자 청소 요청", "reason": "통화 내용 반영" }
  ```
- **41** `GET /api/reservations/{reservationId}/revisions` (예약 이력 조회, D-53). 사장·정비사 모두 볼 수 있다. 남의 예약은 404(X14). 이력은 쓰기만 하고 고치거나 지우지 않는다.

  | 응답 data | 설명 |
  |---|---|
  | items | 아래 목록. 이력이 없으면 `[]` |

  | 응답 items[] | 설명 |
  |---|---|
  | kind | `STATUS`(상태 정정, 40) · `MEMO`(메모 정정, 40) · `ASSIGNEE`(담당 재배정, 19) |
  | changedAt | 이력이 남은 일시 (datetime) |
  | changedBy | 바꾼 사람 `{ staffId, name }` |
  | reason | 사유. 없으면 `null` |
  | changes | `[ { field, before, after } ]`. 한 이력에 한 항목: `STATUS`는 `status`(이전·이후 상태 enum), `MEMO`는 `purposeMemo`(이전·이후 메모, 없으면 `null`), `ASSIGNEE`는 `assignee`(이전·이후 담당 `{ staffId, name }`) |

  순서는 `changedAt` 오름차순(오래된 것부터)이고 같으면 이력 번호 순이다(07 4.2). 번호 필드는 응답에 주지 않는다. 쪽 나누기는 없다. 바꾼 사람과 담당의 `name`은 그 계정의 현재 이름이고, 비활성 계정(P1)이어도 이름은 보인다.

  ```json
  {
    "success": true,
    "data": {
      "items": [
        {
          "kind": "ASSIGNEE",
          "changedAt": "2026-11-21T16:20:00",
          "changedBy": { "staffId": 1, "name": "박사장" },
          "reason": null,
          "changes": [
            { "field": "assignee", "before": { "staffId": 2, "name": "김정비" }, "after": { "staffId": 1, "name": "박사장" } }
          ]
        },
        {
          "kind": "STATUS",
          "changedAt": "2026-11-25T09:10:00",
          "changedBy": { "staffId": 1, "name": "박사장" },
          "reason": "고객이 전날 전화로 취소함",
          "changes": [
            { "field": "status", "before": "NO_SHOW", "after": "CANCELED" }
          ]
        },
        {
          "kind": "MEMO",
          "changedAt": "2026-11-25T09:10:00",
          "changedBy": { "staffId": 1, "name": "박사장" },
          "reason": "고객이 전날 전화로 취소함",
          "changes": [
            { "field": "purposeMemo", "before": null, "after": "배터리 교체, 단자 청소 요청" }
          ]
        }
      ]
    },
    "error": null
  }
  ```
- **42** `GET /api/reservations/summary?from=&to=`. 응답 `data: { from, to, items: [ { date, total, reserved, inProgress, completed, canceled, noShow } ] }`(15와 같은 규칙: `from`·`to`는 요청 그대로). `total`은 취소만 제외(진행중·노쇼 포함)이고 나머지 다섯 값은 그 날짜의 상태별 건수다. **예약이 한 건도 없는 날짜는 `items`에 없다**(없는 날은 0건으로 본다). 취소만 있는 날은 예약이 있는 날이라 `items`에 들어가고 `total`은 0, `canceled`는 그 건수다(화면이 `total` 0인 칸을 어떻게 보일지는 화면이 정한다). `items`는 `date` 오름차순이다. `from`·`to` 규칙은 15와 같다(둘 다 필수·포함, 최대 42일). 위반은 400 `INVALID_INPUT`이고 `fieldErrors`의 필드는 누락·형식 오류가 그 파라미터(`from`·`to`), `from` > `to`가 `from`, 42일 초과가 `to`다. 요청에 `assigneeId`는 없다(담당 필터는 15만). 정비소는 토큰의 `shop_id`로만 정한다.

  ```json
  {
    "success": true,
    "data": {
      "from": "2026-11-01",
      "to": "2026-11-30",
      "items": [
        { "date": "2026-11-23", "total": 3, "reserved": 2, "inProgress": 0, "completed": 1, "canceled": 1, "noShow": 0 },
        { "date": "2026-11-24", "total": 1, "reserved": 0, "inProgress": 1, "completed": 0, "canceled": 0, "noShow": 0 }
      ]
    },
    "error": null
  }
  ```

## 8. P1 API

요청·응답의 큰 모양만 정한다. **표와 JSON 예시는 그 기능의 P1 착수 PR에서 이 문서에 채운다**(CONTRIBUTING 7장, D-63 C07). D-59 항목의 ❓는 없음(51의 ❓1건은 10장). 계정·온보딩 API(24·26·32·35·51·52, 03의 P1 필드)는 D-60~D-62로 8.1에 요청·응답·오류·JSON까지 정했다. **43~49(D-56)는 05 POL-46(법적 근거 확인, 담당 PM) 확인 후 구현 착수**.

| 번호 | 요청 | 응답 data | 메모 |
|---|---|---|---|
| 24 | `{ currentPassword, newPassword }` | 없음 | 사장·정비사 (D-60 B09). 임시 비밀번호 상태에서도 호출 가능(0.6). 상세 8.1 |
| 25 | — | `[{ staffId, loginId, name, role }]` | 사장 |
| 26 | `{ loginId, name, temporaryPassword }` | `{ staffId }` | 사장. 역할 MECHANIC 고정. 신규 아이디 규칙·비밀번호 규칙, 아이디 중복 409 `CONFLICT`, 만든 계정은 `password_change_required = true`. 상세 8.1 |
| 27 | `{ cycleMonths?, cycleKm?, active? }` | 13의 항목 하나 | 사장. 새 항목은 추가하지 않는다(P2). 6개 항목의 켜기·끄기, 개월·km 수정만 (04 F-ITEM-01) |
| 28 | — | `{ customerId, phone(전체), text }` | 동의 고객만, 아니면 404 |
| 29 | `{ customerId, result, memo? }` | `{ contactId }` | `result`는 6개 값: 예약함 `RESERVED`·부재 `ABSENT`·이미 정비함 `ALREADY_DONE`·연락함 `CONTACTED`·번호 오류 `WRONG_NUMBER`·연락 거부 `REFUSED` (04 F-CON-02). "연락 거부"는 화면이 동의 해제 확인 대화상자를 띄우고 자동 해제하지 않는다 |
| 30 | `?from=&to=` | `{ newCustomers, returningCustomers }` | 재방문 정의는 04 F-STAT-01 한 곳(그 기간에 방문 기록이 있고 그 이전에도 방문 기록이 있는 고객). 화면은 홈(S-02) "고객 집계" 카드 |
| 31 | — | `[{ shopId, name, status, createdAt }]` | 정비소 안의 숫자는 주지 않음 |
| 32 | `{ name, phone, owner: { loginId, name, temporaryPassword } }` | `{ shopId, ownerStaffId }` | 기본 기준표 6행을 함께 생성. 사장 아이디·임시 비밀번호는 26과 같은 규칙, 아이디 중복이면 409 `CONFLICT`이고 정비소도 만들지 않음(한 트랜잭션). 사업자등록번호·정비소 주소 필드는 10장 ❓8. 상세 8.1 |
| 33·34 | — | `{ shopId, status }` | 정지·재개 |
| 35 | `{ temporaryPassword }` | 없음 | 사장 계정 `password_change_required = true`. 임시 비밀번호는 비밀번호 규칙(8.1) |
| 43·44 | — | (P1 착수 PR에서 확정) | 고객 비활성화·활성화 (F-CUS-10, 사장). 에러 `NOT_FOUND`, `HAS_ACTIVE_RESERVATION`(43), `FORBIDDEN`. POL-46 확인 후 구현 착수 |
| 45 | — | (P1 착수 PR에서 확정) | 고객 삭제 `DELETE` (F-CUS-10, 사장). 이력(정비 기록·예약)이 없을 때만, 이력 없는 차량도 함께 삭제. 에러 `NOT_FOUND`, `HAS_HISTORY`, `FORBIDDEN`. POL-46 확인 후 구현 착수 |
| 46·47 | — | (P1 착수 PR에서 확정) | 차량 비활성화·활성화 (F-CUS-10, 사장). 차량은 비활성화만(물리 삭제 없음). 에러 `NOT_FOUND`, `HAS_ACTIVE_RESERVATION`(46), `FORBIDDEN`. POL-46 확인 후 구현 착수 |
| 48 | `?page=&size=` | `items: [ { customerId, name(마스킹 없음), lastVisitDate, baseDate, vehicles } ]` | 보관 기간 경과 고객 목록 (F-CUS-11, 사장). 쪽 나누기 사용(0.1). POL-46 확인 후 구현 착수 |
| 49 | — | `{ customerId, anonymizedAt }` | 익명화 (F-CUS-11, 사장, 되돌릴 수 없음). 에러 `NOT_FOUND`, `RETENTION_NOT_REACHED`, `HAS_ACTIVE_RESERVATION`, `FORBIDDEN`. POL-46 확인 후 구현 착수 |
| 50 | — | (P1 착수 PR에서 확정) | 정비사 비활성화 (F-STF-01, 사장). 에러 `HAS_ACTIVE_RESERVATION`(그 정비사가 담당한 유효 예약이 있음), 사장 본인은 400 `INVALID_INPUT`, `FORBIDDEN`. 비활성 정비사는 로그인할 수 없고(`ACCOUNT_INACTIVE`) 36 담당 후보에서 빠진다. **비활성화 전에 받은 토큰으로 부르는 정비소 API도 403 `ACCOUNT_INACTIVE`**(0.6, D-62) |
| 51 | `{ temporaryPassword }` | 없음 | 정비사 임시 비밀번호 재발급 (F-STF-01, 사장, D-60 A09). 상세 8.1 |
| 52 | `{ termsVersion }` | `{ shopId, termsVersion, acceptedAt }` | 서비스 이용약관 동의 (F-AUTH-04, 사장, D-61). 상세 8.1 |

### 8.1 계정·온보딩 계약 (P1, D-60~D-62)

**공통 입력 규칙** (화면과 서버가 같은 규칙, 05 11장)

| 대상 | 규칙 | 어긋나면 |
|---|---|---|
| 신규 아이디 (26 `loginId`, 32 `owner.loginId`) | 6~20자, `a-z`·`0-9`·`_`만, 첫 글자는 영문 소문자 (`^[a-z][a-z0-9_]{5,19}$`). `staff.login_id`는 정비소를 넘어 전체에서 유일 | 형식 400 `INVALID_INPUT` + `fieldErrors`, 중복 409 `CONFLICT` |
| 새 비밀번호·임시 비밀번호 (24 `newPassword`, 26·32 `temporaryPassword`, 35·51 `temporaryPassword`) | 8~20자. 허용 문자는 공백을 뺀 ASCII 출력 문자(`!`~`~`, 코드 0x21~0x7E). 영문(`A-Z`·`a-z`) 1자 이상, 숫자 1자 이상, 특수문자(ASCII 문장부호 32자: `` !"#$%&'()*+,-./:;<=>?@[\]^_`{\|}~ ``) 1자 이상. 대·소문자를 따로 요구하지 않는다. 길이는 문자 수 | 400 `INVALID_INPUT` + `fieldErrors` |
| 현재 비밀번호 (24 `currentPassword`) | 1~100자(01과 같음). 조합 규칙을 적용하지 않는다 | 형식 400. 틀린 비밀번호는 아래 24 |
| 기존 계정 로그인 (01·02) | 1~50자 / 1~100자 그대로. 신규 규칙을 적용하지 않는다(시연 `1234`, D-44) | 01·02 |

- 비밀번호 원문은 응답·로그·오류 메시지·`fieldErrors`에 넣지 않는다. 저장은 BCrypt 해시(07 3.3). 아래 예시의 비밀번호는 모두 가린 값이다.
- 임시 비밀번호는 발급자가 직접 만들어 넣는다(자동 생성·이메일·SMS 없음, D-60 A02).

#### 24 POST `/api/me/password` — 내 비밀번호 변경 (사장·정비사)

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| currentPassword | string | ○ | 1~100자. 지금 비밀번호(임시 비밀번호 포함) |
| newPassword | string | ○ | 비밀번호 규칙(위 표) |

```json
{ "currentPassword": "********", "newPassword": "********" }
```

```json
{ "success": true, "data": null, "error": null }
```

- 성공하면 해시를 바꾸고 `password_change_required = false`. 토큰은 그대로 쓴다(0.6). 다음 단계는 03을 다시 불러 판단한다(사장이고 약관 동의 전이면 약관 단계).
- 에러: `INVALID_INPUT`(형식, 또는 현재 비밀번호가 맞지 않음 → `fieldErrors: [{ "field": "currentPassword", "reason": "현재 비밀번호가 맞지 않습니다." }]`. 401로 보내지 않는다 — 화면이 로그아웃되지 않게), (P1 공통) `ACCOUNT_INACTIVE`
- 새 비밀번호 확인 칸은 화면에만 있다(서버로 보내지 않음, 09 S-01).

#### 26 POST `/api/staff` — 정비사 계정 발급 (사장)

```json
{ "loginId": "mech_kim01", "name": "이정비", "temporaryPassword": "********" }
```

```json
{ "success": true, "data": { "staffId": 4 }, "error": null }
```

역할은 `MECHANIC` 고정, `shop_id`는 토큰의 정비소, `password_change_required = true`, `active = true`(V3). `name`은 1~50자. 에러: `INVALID_INPUT`, `CONFLICT`(아이디 중복), `FORBIDDEN`(정비사 토큰)

#### 32 POST `/api/admin/shops` — 정비소 개설 + 사장 계정 발급 (서비스 관리자)

```json
{
  "name": "새길카센터",
  "phone": "02-0000-0003",
  "owner": { "loginId": "owner_new01", "name": "정사장", "temporaryPassword": "********" }
}
```

```json
{ "success": true, "data": { "shopId": 3, "ownerStaffId": 5 }, "error": null }
```

정비소·사장 계정(`password_change_required = true`)·기본 기준표 6행을 한 트랜잭션으로 만든다. 에러: `INVALID_INPUT`, `CONFLICT`(사장 아이디 중복 — 정비소도 만들지 않음), `FORBIDDEN`(사장·정비사 토큰, X18)

- 정비소 정보로 사업자등록번호·정비소 주소도 받는다(D-73, 저장 칼럼 07 3.2 `shop.brn`·`shop.shop_address`). 요청 필드 이름·필수 여부·형식 검증·`INVALID_INPUT` 조건은 정하지 않았다(10장 ❓8). 정한 뒤 위 JSON 예시와 함께 채운다.

#### 35 POST `/api/admin/shops/{shopId}/owner-password-reset` — 사장 임시 비밀번호 재발급 (서비스 관리자)

```json
{ "temporaryPassword": "********" }
```

```json
{ "success": true, "data": null, "error": null }
```

- 대상은 경로 정비소의 사장 계정이다. 해시를 바꾸고 `password_change_required = true`. 서비스 관리자는 기존 비밀번호를 볼 수 없다(05 POL-16). 정비소 데이터·사장 계정은 그대로다.
- 그 사장이 이미 받은 토큰은 다음 요청부터 403 `PASSWORD_CHANGE_REQUIRED`(0.6). 그 정비소에 현재 약관 버전 동의 기록이 있으면 약관은 다시 묻지 않는다.
- 에러: `NOT_FOUND`(없는 정비소), `INVALID_INPUT`(비밀번호 규칙), `FORBIDDEN`(사장·정비사 토큰, X18)

#### 51 POST `/api/staff/{staffId}/password-reset` — 정비사 임시 비밀번호 재발급 (사장)

```json
{ "temporaryPassword": "********" }
```

```json
{ "success": true, "data": null, "error": null }
```

- 대상은 **그 정비소의 정비사**다. 해시를 바꾸고 `password_change_required = true`. 계정·정비 기록·담당 예약은 그대로다.
- 그 정비사가 이미 받은 토큰은 서명이 유효해도 다음 요청부터 403 `PASSWORD_CHANGE_REQUIRED`(0.6) — 새 비밀번호를 정할 때까지 CRM을 쓸 수 없다.
- 에러: `NOT_FOUND`(없는 계정·다른 정비소 계정, X15), `INVALID_INPUT`(비밀번호 규칙, 대상이 사장 계정 — 사장 본인은 24, 사장 재발급은 서비스 관리자 35), `FORBIDDEN`(정비사 토큰). ❓ 비활성 정비사를 대상으로 했을 때의 처리는 정하지 않았다(10장 ❓7, 착수 PR 전에 정함, D-63 C07).

#### 52 POST `/api/me/terms-agreement` — 서비스 이용약관 동의 (사장)

| 요청 | 타입 | 필수 | 검증 |
|---|---|---|---|
| termsVersion | string | ○ | 03이 준 `termsVersion`(서버의 현재 약관 버전)과 같아야 한다 |

```json
{ "termsVersion": "2026-11-23" }
```

```json
{
  "success": true,
  "data": { "shopId": 1, "termsVersion": "2026-11-23", "acceptedAt": "2026-11-24T09:10:00" },
  "error": null
}
```

- 서버가 정비소·동의한 사장(토큰)·약관 버전·동의 시각(`Clock`)을 기록한다(07 4.4). 체크박스 상태는 보내지 않는다 — 요청 자체가 동의이고, 화면은 체크 전에는 버튼을 비활성화한다(09 S-01).
- 같은 정비소가 같은 버전에 이미 동의했으면 새로 기록하지 않고 기존 기록을 200으로 돌려준다(두 번 눌러도 기록 하나).
- 에러: `INVALID_INPUT`(버전이 현재 버전과 다름 → 화면은 03을 다시 불러 최신 버전을 보여 줌), `PASSWORD_CHANGE_REQUIRED`(비밀번호 변경 전), `FORBIDDEN`(정비사 토큰 — 정비사에게는 필수 동의가 없다, D-61), (P1 공통) `ACCOUNT_INACTIVE`
- 약관 전문·개인정보 처리방침은 API로 내려주지 않는다. 화면이 버전별 전문(또는 링크)과 처리방침 링크를 보여 준다. 전문 작성·법률 검토는 별도 선행 과제다(04 F-AUTH-04, 05 POL-46).

## 9. 격리·인증 테스트 (X-xx)

시드: A 정비소 사장 토큰으로 B 정비소 데이터 요청 (07 7.4). **B 정비소 예약**(X3·X12·X14)은 시연 시드에 넣지 않고 테스트 픽스처로 그 테스트 안에서 만든다(D-63 B12, 07 7.4).

| ID | 요청 | 기대 |
|---|---|---|
| X1 | A 토큰으로 07 `GET /api/customers/{B 고객}` | 404 `NOT_FOUND` |
| X2 | A 토큰으로 09·10·11 `{B 차량}` | 404 |
| X3 | A 토큰으로 17 `{B 예약}` | 404 |
| X4 | A 토큰으로 16 `vehicleId = B 차량` | 404 |
| X5 | A 토큰으로 12 `{B 차량}` 기록 저장 | 404, 저장 안 됨 |
| X6 | A 토큰으로 10 미리보기 `{B 차량}?mileage=` | 404 |
| X7 | A 토큰으로 05 `q=12가0001`, 14, 04, 15, 13 | B 데이터가 섞이지 않음 (A의 김민수만, 13은 A 정비소 항목만 — D-63 B06) |
| X8 | A 토큰 요청 본문·쿼리에 `shopId=2`를 넣음 | 무시하고 A 기준으로 처리 |
| X9 | 서비스 관리자 토큰으로 05 고객 목록 | 403 `FORBIDDEN` |
| X10 | 토큰 없이 / 만료 토큰으로 04 | 401 `AUTH_REQUIRED` |
| X11 | A 토큰으로 12 `records[].itemId`, 16·19 `purpose.itemIds`, (P0-나머지) 37 `itemId`에 B 정비소 항목 id | 400 `INVALID_INPUT` (없는 id와 같은 응답), 저장·변경 안 됨 (P0-핵심) |
| X12 | A 토큰으로 18·19 `{B 예약}` (P0-핵심), 20·21 `{B 예약}`, 22 `{B 고객}`, 23 `{B 차량}` (P0-나머지) | 404, B 데이터 그대로 |
| X13 | 다른 정비소 정비사 id를 `assigneeId`·`mechanicId`로 보냄 (16·19·12·37) (P0-나머지) | 400 `INVALID_INPUT` (없는 id와 같은 응답), 저장·변경 안 됨 |
| X14 | 다른 정비소 기록 수정·이력 (37·38), 다른 정비소 예약 방문 접수·정정·이력 (39·40·41) (P0-나머지) | 404, B 데이터 그대로 |
| X15 | 다른 정비소 고객·차량 비활성화·활성화·삭제·익명화 (43~47·49), 정비사 비활성화 (50)·임시 비밀번호 재발급 (51) (P1). 48 목록과 25 정비사 목록은 X7처럼 B 데이터가 섞이지 않음 | 404, B 데이터 그대로 |
| X16 | 서비스 관리자 토큰으로 36~42 (P0-나머지), 43~52 (P1) | 403 `FORBIDDEN` |
| X17 | A 토큰으로 08 `POST /api/customers/{B 고객}/vehicles` (P0-핵심, D-63 B11) | 404 `NOT_FOUND`, B 고객에 차량이 생기지 않음 |
| X18 | 사장·정비사 토큰으로 `/api/admin/**` (P0-핵심 경로 규칙, P1의 31~35 포함, D-63 B10) | 403 `FORBIDDEN` |
| X19 | 비활성화(50) 전에 받은 정비사 토큰으로 정비소 API (03 포함) (P1, D-62) | 403 `ACCOUNT_INACTIVE`, 같은 정비소의 다른 계정은 영향 없음 |
| X20 | `password_change_required = true` 계정 토큰으로 03·24 밖의 정비소 API (P1, D-60) | 403 `PASSWORD_CHANGE_REQUIRED`. 03·24는 성공, 24 성공 뒤 같은 토큰으로 정상 이용 |
| X21 | 약관 동의 전 사장 토큰으로 03·24·52 밖의 정비소 API (P1, D-61) | 403 `TERMS_AGREEMENT_REQUIRED`. 52 성공 뒤 같은 토큰으로 정상 이용. 같은 정비소 정비사는 영향 없음 |

X4·X5·X11·X17의 DB 쪽 방어(복합 FK)는 07 6.3 V1-3~V1-5로 따로 확인한다. X17·X12·X14·X15는 경로 id로 B 행을 찾는 경우라 서버의 `getOwned`(07 I-4)로 막는다. X13의 DB 쪽 방어(담당 복합 FK)는 07 6.3 V1-4로 확인한다. X18은 B-1 `EndpointGuardTest` E4로 경로 규칙을 이미 확인한다(chagok-backend#11). X19~X21은 계정 상태 확인(0.6)이고 정비소 격리가 아니다. X와 07 I-xx는 1:1이 아니다(07 5장 I-xx 「지키는 곳」).

## 10. 결정 필요 (❓)

P1 착수 때 정하기로 했던 항목(연락 결과 값, "연락함" 유지 기간, 알림 저장 위치, 재방문 정의, 새 항목 추가)은 D-59로 확정했다(8장 27·29·30, F-NTF-01은 브라우저 저장이라 API 없음).

P0-핵심 API 계약 점검(chagok-docs#56)에서 남긴 ❓ 6건과 chagok-docs#50(API 24 역할, 사장·정비사 → 서비스 관리자 API 403, 격리 시험 범위·B 정비소 예약 데이터)은 **D-63(2026-11-23 팀 회의, chagok-docs#65)으로 확정**했다. 그 반영에서 새로 생긴 ❓는 아래 7번 하나였고, 8번은 D-73(chagok-docs#128)에서 남겼다.

| 옛 ❓ | 위치 | 확정 (D-63) | 반영 |
|---|---|---|---|
| 1 | 07 `dueCount`·`soonCount` | 오늘 기준 사용하는 항목 중 `DUE`·`SOON` 수 (B01) | 07 표 |
| 2 | 17 `itemStatuses` | `sortOrder` 순, `highlighted`는 강조만 (B02) | 17 표 |
| 3 | 주행거리 상한 | 정수 0~2,000,000 (B03) | 0.1 |
| 4 | `modelYear` | 1980 ~ 현재 연도 + 1 (B04) | 0.1 |
| 5 | 04 `todayReservations` | 취소 포함, 건수는 취소 제외 (B05) | 04 표 |
| 6 | API 13 격리 | X7에 13 추가 (B06) | 9장 |
| #50 1 | API 24 역할 | 사장·정비사 (B09 = D-60 A05) | 1장·8.1 |
| #50 2 | 서비스 관리자 API 역방향 403 | X18 (B10) | 0.1·0.3·9장 |
| #50 3a | API 08 격리 | X17 (B11) | 08·9장 |
| #50 3b | B 정비소 예약 | 테스트 픽스처 (B12) | 9장, 07 7.4 |

| ❓ | 위치 | 정할 것 | 막는 이슈 (12 백로그) |
|---|---|---|---|
| 7 | 8.1 51 | 비활성 정비사를 재발급 대상으로 했을 때 응답(허용 / 400 / 404 등). D-60·D-62는 정하지 않았다 | 정비사 계정 BE(32) |
| 8 | 8.1 32, 09 S-10 | 사업자등록번호·정비소 주소의 요청 필드 이름·필수 여부·형식 검증(`INVALID_INPUT` 조건), S-10 입력란의 blur 검사·오류 문구, 정비소 목록(31)에 두 값을 보여 줄지. 칼럼은 D-73으로 V2에 있다(07 3.2). DB관리 제안(chagok-docs#122): `brn` 숫자 10자리·하이픈 허용 — 확정 아님 | 정비소 개설 BE(30)·FE(31) |

D-19(화면 세부)는 그 후속(00 D-19)에서 정한다.
