# 차곡 코드 구조 규칙 (CONVENTIONS)

> **목표: 하나를 고칠 때 한 곳만 고친다. 기능을 더할 때 새 파일을 더하고, 기존 파일은 거의 건드리지 않는다.**
> 놀이방에서는 동작은 단단했지만 도메인끼리 서로 직접 불러서 하나를 고치면 여러 곳이 무너졌다. 이 문서는 그걸 첫날부터 막는 규칙이다.
>
> - 코드 규칙의 **원본은 이 문서 하나**다(`chagok-docs`에만 있음). 각 레포 `CLAUDE.md`, 스킬, 안내 문서는 여기를 가리키기만 한다.
> - 적용 레포: `chagok-backend`는 1~6장·8·9장, `chagok-frontend`는 7장과 4장의 프론트 줄. 경로는 각 레포 루트 기준이다.
> - 사람이 기억할 규칙은 1장의 7개뿐이다. 나머지는 테스트·설정·자동 검사가 지킨다(8장).
> - 💡 = 제안값. 2·3장(패키지 구조·의존 방향)은 M1 설계 확정(D-20, chagok-docs#46)에서 현행안 그대로 확정했다. 남은 💡(6장 DB, 7장 프론트 구조)는 아직 제안값이다. 바꾸려면 `결정` 이슈로.
> - 적용 시점: M1 설계 확정 이후 `기반` 이슈에서 이 구조로 프로젝트를 만든다.

---

## 1. 꼭 기억할 7개

| # | 규칙 | 왜 (놀이방에서 일어난 일) | 누가 지키나 |
|---|---|---|---|
| 1 | **다른 도메인은 그 도메인의 `api` 패키지로만 부른다.** Entity·Repository·Service를 직접 import하지 않는다 | 13개 도메인 중 9개가 Service 직접 주입으로 얽힘 → 하나 고치면 와르르 | ArchUnit 테스트 |
| 2 | **의존 방향은 한쪽으로만.** 외래키 방향 = 코드 방향(3장 표). 거꾸로 부르거나 순환하면 빌드 실패 | 서로 import하는 순환이 생기면 어느 쪽도 혼자 못 고침 | ArchUnit 테스트 |
| 3 | **같은 규칙은 한 곳에.** 주기 상태는 `cycle`, 정비소 소속 확인은 각 도메인의 `getOwned`, 상태 전이는 Entity 메서드 | "공개 작품" 규칙 사본이 5~6곳, 이미 서로 어긋나 있었음 | 리뷰 + CodeRabbit |
| 4 | **여러 도메인을 읽는 화면은 `screen` 패키지에서 조립**하고, 아무도 `screen`을 import하지 않는다 | 마이페이지·관리자 화면을 업무 패키지 안에서 조립하다 순환 발생 | ArchUnit 테스트 |
| 5 | **오류는 `BusinessException(ErrorCode)`로 던지고 전역 처리기 한 곳에서 응답.** Controller에 try/catch 금지 | Controller 38개 중 13개가 오류를 각자 처리 → 화면마다 다른 오류 | 리뷰 + CodeRabbit |
| 6 | **상태는 저장하지 않고 조회 때 계산한다.** 미확인/여유/임박/도래는 DB 칼럼이 아니다 | (예방) 주기 규칙을 바꿀 때 데이터 마이그레이션이 필요 없게 | 07 ERD |
| 7 | **DB 구조는 Flyway 버전 파일이 기준**, Entity는 거기에 맞춘다(`ddl-auto: validate`). `develop`에 들어간 버전 파일은 고치지 않고 새 번호를 더한다 | 테스트 420개 중 172개가 로컬 DB 스키마 차이로 계속 실패 | Flyway + 빈 DB CI + pr-check |

---

## 2. 백엔드 패키지 구조

기본 패키지 `com.wanted.chagok`

```
com.wanted.chagok
├── ChagokApplication
├── global/                  모든 도메인이 쓰는 기반. 업무 규칙 없음
│   ├── config/              SecurityConfig(기본 거부), WebConfig, ClockConfig
│   ├── auth/                LoginStaff(staffId·shopId·role), LoginAdmin, @CurrentStaff 주입
│   ├── error/               ErrorCode(enum), BusinessException, GlobalExceptionHandler
│   ├── response/            ApiResponse (08 공통 응답)
│   └── web/                 RequestIdFilter(요청 ID 로그), PageLimit(쪽 크기 상한)
│
├── domain/                  업무 도메인. 표를 가진다
│   ├── shop/                shop
│   ├── account/             staff, platform_admin, 로그인
│   ├── customer/            customer + vehicle (고객 1:N 차량, 한 덩어리)
│   ├── item/                service_item (정비 항목·주기)
│   ├── maintenance/         maintenance_record
│   ├── reservation/         reservation
│   └── cycle/               주기 상태 계산만. 표 없음, Spring·JPA 없음
│
└── screen/                  화면 조립 전용. 표 없음. 아무도 import하지 않음
    ├── target/              재점검 대상 목록 (시나리오 A)
    ├── visit/               방문 접수 시 항목 상태·추가 점검 안내 (시나리오 B), 차량 상세의 항목 상태
    └── booking/             예약 상세 패널: 예약 + 고객·차량 + 최근 정비 이력 + 점검 주기 요약 (기획안 v9)
```

### 도메인 하나의 안쪽

```
domain/customer/
├── api/          ← 다른 패키지가 import할 수 있는 유일한 곳
│   ├── CustomerReader.java        interface: 다른 도메인에 주는 계약 메서드
│   └── VehicleRef.java            record: 계약이 돌려주는 값 (Entity 아님)
├── controller/   CustomerController  (요청 받기·@Valid·응답. 업무 판단 없음)
├── dto/          요청·응답 record (이 도메인 화면 전용)
├── service/      CustomerService (implements CustomerReader), 트랜잭션
├── entity/       Customer, Vehicle  (setter 없음, 상태 변경은 이름 있는 메서드)
└── repository/   CustomerRepository, VehicleRepository
```

- `api` 안에는 **interface, record, enum만** 둔다. 구현은 `service`가 한다.
- 다른 도메인에 값이 필요해지면 `api`에 메서드를 **추가**한다(기존 메서드 시그니처는 바꾸지 않는다).
- `controller/dto`의 응답 record는 그 화면 전용이다. 다른 도메인이 계산 재료로 쓰지 않는다(그럴 땐 `api`).

> **회고와 다른 선택 (이유 표시):** 회고 3-1은 계약 인터페이스를 "쓰는 쪽"에 두라고 했다. 여기서는 "주는 쪽의 `api` 패키지"에 둔다. 쓰는 쪽에 두면 주는 쪽이 쓰는 쪽 패키지를 import해야 해서 2번 규칙(방향 = 외래키 방향)이 뒤집히고, 짧은 기간에 팀이 익히기도 어렵다. 1팀이 겪은 "경계가 덜 끊김"은 계약 안에 Entity가 섞여서였으므로, `api`에 record·enum만 두는 규칙으로 막는다.

---

## 3. 의존 방향

화살표 = "import해도 된다". 표에 없는 방향은 금지(ArchUnit이 막는다).

```
screen/target ──┬──▶ customer.api
screen/visit  ──┤──▶ item.api
screen/booking ─┤   (booking: reservation.api·customer.api·maintenance.api·item.api·cycle)
                ├──▶ maintenance.api
                ├──▶ reservation.api   (target만: "예약 있음" 표시)
                └──▶ cycle

maintenance ────┬──▶ customer.api     (차량이 우리 정비소 것인지)
                ├──▶ item.api         (항목이 있는지)
                └──▶ account.api        (담당 정비사가 우리 정비소 사람인지, D-55)
reservation ────┬──▶ customer.api
                ├──▶ item.api         (예약 목적 항목, D-38)
                └──▶ account.api        (담당 정비사가 우리 정비소 사람인지, D-51)
account ────────────▶ shop.api
customer, item, shop, cycle ──▶ (다른 도메인 없음)

모두 ──▶ global
```

| 규칙 | 내용 |
|---|---|
| 외래키 방향 = 코드 방향 | `maintenance_record → vehicle`이므로 maintenance가 customer를 부른다. 거꾸로는 안 된다 |
| 담당 정비사 검증은 `account.api`로 | `reservation → account.api`, `maintenance → account.api`(허용 의존). 담당은 요청 값이라(`assigneeId`·`mechanicId`, 08 0.1·X13) 그 정비소의 활성 사장·정비사인지 확인한다. staff 표는 `account` 도메인에 있으므로 이 `api`는 `account`의 `api` 패키지에 둔다. 담당 검증은 P0-나머지부터 필요하다(P0-핵심은 토큰의 계정이 담당이다). staff 쪽은 reservation·maintenance를 부르지 않는다 |
| `cycle`은 아무것도 모른다 | 입력은 값(record), 출력도 값. `java.time`만 쓴다. 그래서 테스트에 DB가 필요 없다 |
| "방문 완료 → 정비 기록 등록" 연결은 **화면 이동**이다 | reservation이 maintenance를 부르지 않는다. 프론트가 방문 완료 응답을 받고 정비 기록 화면으로 보낸다 |
| shop_id는 `global/auth`의 로그인 정보에서 | 도메인들이 shop 도메인을 부를 필요가 없다 |

---

## 4. 한 곳에만 있는 규칙

| 규칙 | 있는 곳 | 다른 곳에서는 |
|---|---|---|
| 항목 상태(미확인/여유/임박/도래), 임박 기준, 도래 경계(≥), km 판정, "지난 방문 거절"·"지난 점검 주의" 표시 판정 | `domain/cycle` | 부르기만 한다. 날짜·km 비교를 직접 쓰지 않는다 |
| 정비소 소속 확인 | 각 도메인 service의 `getOwned(shopId, id)` 한 메서드 | 조회는 모두 이 메서드나 `findBy…AndShopId`로. 없거나 남의 것이면 같은 `NOT_FOUND`(404) |
| 역할 확인(사장만 가능한 일) | `SecurityConfig` URL 규칙 | 서비스 안에서 역할 `if` 분기를 만들지 않는다 |
| 예약 상태 전이(예약 → 진행중 → 방문 완료/취소, 예약 → 노쇼)와 변경 가능 여부 | `Reservation` Entity 메서드 `start()`, `complete()`, `cancel()`, `markNoShow(now)`, `reschedule(…)` | 끝난 예약을 바꾸려 하면 Entity가 거절한다. 동시 수정은 `@Version`이 막는다 |
| 정비 구분(교체/점검/외부/거절)이 주기를 다시 시작하는지 | `RecordType` enum의 `resetsCycle()` | `if (type == REPLACE || …)`를 여기저기 쓰지 않는다 |
| 현재 시각 | `Clock` 빈 하나 | `LocalDate.now()` 직접 호출 금지. Entity·cycle은 시각을 인자로 받는다 |
| 상태 표시 문구·색 | 프론트 `shared/ui/StatusBadge` | 화면마다 색·문구를 따로 정하지 않는다. 프론트는 상태를 계산하지 않는다 |
| 오류 응답 모양 | `GlobalExceptionHandler` | Controller·Service에서 응답을 직접 만들지 않는다 |

---

## 5. 계층별로 하는 일 / 하지 않는 일

| 계층 | 한다 | 하지 않는다 |
|---|---|---|
| controller | 요청 받기, `@Valid`, `@CurrentStaff`로 로그인 정보 받기, service 호출, 응답 변환 | 업무 판단, try/catch, Repository 주입(ArchitectureTest), Entity 반환 |
| service | 유스케이스 흐름 조립, `@Transactional`(요청 하나 = 트랜잭션 하나, 실패하면 전부 롤백), 소속 확인(`getOwned`), DTO 변환 | 응답 모양 만들기, 다른 도메인 Repository·Entity·Service 사용, 같은 규칙을 다른 service에 복사 |
| entity | 칼럼 매핑, 상태 전이와 도메인 불변식(자기 상태로 판단하는 규칙과 거절), `@Version` | public setter, 다른 도메인 Entity 참조(ID로만), 양방향 연관, cascade |
| repository | 조회 메서드 (정비소 데이터는 shopId 조건 포함) | 업무 판단 |
| api | interface·record·enum | 구현, Entity 노출 |
| screen | 여러 `api`를 읽어 화면 하나의 응답 조립, cycle 호출 | 저장·상태 변경, 표 소유 |
| global | 인증·오류·공통 응답·시각 같은 기술 기반 | 업무 규칙, domain·screen import(ArchitectureTest) |

규칙끼리 부딪혀서 지키기 어려운 경우(예: 3장 표에 없는 방향이 꼭 필요함), 우회 코드를 만들지 말고 멈추고 설계 검토(`결정` 이슈)로 올린다.

권한 판정 한 곳(06 7.5): 사장 전용·담당·기간(예: 정비사는 본인 담당 + 3일) 판정은 서비스에 `if (role == …)`를 흩뜨리지 않고 도메인의 `…Policy`/`EditRule` 하나에서 한다(4장 "역할 확인" 행과 함께, 11장 7문항으로 확인).

Entity 연관: 같은 도메인 안(customer–vehicle)만 `@ManyToOne(fetch = LAZY)` 허용. 다른 도메인은 `Long vehicleId`처럼 ID로만.

---

## 6. 오류·입력·설정

- **ErrorCode = 08 에러 코드 표**, 개수는 10개 안팎으로 유지(화면이 전부 처리할 수 있게). 새 코드는 08과 같은 PR에서.
- 전역 처리기는 업무 예외 + **표준 예외**(검증 실패·잘못된 JSON·405·415·타입 불일치 → 400대, 유일 제약 위반 → 409)를 처음부터 함께 매핑한다. 감쌀 때는 원인을 넘긴다: `new BusinessException(code, e)`.
- 모든 요청 DTO에 `@Valid` + 범위(길이·최솟값). 주행거리는 0 이상. 화면 검사는 편의일 뿐이다.
- 목록은 쪽 크기 상한을 `global/web/PageLimit` 한 곳에서 자른다.
- `spring.jpa.open-in-view: false`. 화면에 필요한 값은 service가 DTO로 다 만들어 넘긴다.
- 요청 ID 필터: 모든 로그 줄에 요청 ID·URL·상태·처리 시간.
- DB 접속 기본값은 로컬 개발용에만. 배포 프로필은 기본값 없이 환경변수(없으면 기동 실패).
- 세션 만료·미로그인은 401, 권한 없음은 403, 남의 데이터·없는 데이터는 404.

### DB (Flyway) 💡

- 구조: `src/main/resources/db/migration/V{번호}__{설명}.sql` (예: `V1__init.sql`, `V2__add_contact_log.sql`). 07 ERD와 같은 표·칼럼·제약. Spring Boot 4이므로 `spring-boot-starter-flyway`와 `flyway-mysql`이 함께 필요하다. `ddl-auto: validate`, `spring.sql.init.mode: never`.
- 번호는 develop에 머지되는 순서. 두 PR이 같은 번호를 쓰면 나중에 머지하는 PR이 번호를 올린다.
- `develop`에 들어간 버전 파일은 고치지 않는다(pr-check가 막는다). 잘못 만들었으면 바로잡는 새 버전을 더한다. 아직 develop에 없는 내 PR의 버전 파일은 고쳐도 된다.
- 시연 시드: 레포 루트 `db/seed/demo_seed.sql`(classpath 밖, 서버·Flyway가 읽지 않음). 시연 전용 DB(`chagok_demo` 💡)에만 `db/seed/run-demo-seed.sh`로 넣는다. 삭제·구조 변경 문장 금지, 날짜는 `CURDATE() - INTERVAL …` 상대값, 시연 계정 비밀번호 1234는 BCrypt 해시(D-43·D-44). `src/main/resources`에는 마이그레이션 밖 SQL을 두지 않는다(pr-check ❌).
- 상태(미확인/여유/임박/도래)는 칼럼으로 만들지 않는다(1장 6번).

---

## 7. 프론트 구조 💡

```
src/
├── app/          라우팅, 로그인 가드(401이면 로그인 화면)
├── shared/       아무것도 import하지 않음
│   ├── api/client.ts      공통 응답·오류 처리 (유일한 fetch 위치)
│   ├── ui/                StatusBadge, Layout, Table, Button(제출 중 비활성)
│   └── lib/               날짜 표시 등
├── features/     도메인별. shared만 import
│   ├── auth/  customer/  maintenance/  reservation/  target/
│   │   └── api.ts · types.ts(08 그대로) · components/ · mocks/(개발용, 아래)
└── pages/        화면 조립 (09 화면 ID와 1:1). 여러 feature를 합치는 유일한 곳
```

- feature끼리 import하지 않는다. 두 feature가 한 화면에 필요하면 `pages`에서 합친다(백엔드 `screen`과 같은 생각).
- 상태(미확인/여유/임박/도래)는 서버가 준 값을 그대로 보여 준다. 프론트에서 날짜로 다시 계산하지 않는다.
- 저장 버튼은 요청 중 비활성(두 번 누르기 방지 — 차량번호 중복을 막지 않는 기획이라 특히 필요).

### Mock (프론트 개발용, 2026-11-23 chagok-docs#58)

백엔드를 띄우지 않고 화면을 만들기 위한 것이다. **계약의 기준은 08이고, Mock은 08을 따라가는 사본이다.** Mock에 맞춰 08·07·DB를 바꾸지 않는다.

| 항목 | 규칙 |
|---|---|
| 위치 | `features/<도메인>/mocks/` — `*.json` fixture + 간단한 응답 함수 `index.ts` 하나. 그 화면 이슈가 자기 feature에 만든다 |
| 모양 | 08 0.2 공통 응답 그대로(`{ success, data, error }`). 필드 이름·타입·nullable·enum·일시 형식(오프셋 없음)이 08과 글자까지 같다. P0-핵심은 08 머리말대로 `assignee`를 뺀다 |
| 값 | 07 7장 시드와 08 JSON 예시의 값(가상의 이름·번호·차량번호)을 쓴다. 실제 개인정보를 넣지 않는다. 시드에 없는 값을 만들면 08 규칙에 맞는지 확인한다 |
| 사례 | 정상, 빈 목록(`items: []`), 오류(08 0.3 코드: 400·401·403·404·409)를 08 0.2 모양으로. 로그인은 A 정비소 기준이고, B 정비소 id(07 7.4: 고객 11·차량 12)를 요청하면 404 `NOT_FOUND`(격리). 서비스 관리자로 정비소 API를 부르면 403 |
| 전환 | API 호출 계층에서만 한다. `features/<도메인>/api.ts`가 실제 요청과 Mock 응답 중 하나를 고르고, 둘 다 `shared/api/client.ts`의 같은 응답 해석·오류 처리(05 POL-120~129)를 거친다. 화면 컴포넌트·`pages`는 `mocks/`를 import하지 않는다(아래 ESLint) |
| 켜는 방법 | 개발 환경에서만 명시적으로: `.env.development.local`(Git 제외)에 `VITE_USE_MOCK=true`. 판정은 `import.meta.env.DEV && import.meta.env.VITE_USE_MOCK === 'true'` 한 곳(`shared/api/client.ts`) |
| 운영 빌드 | Mock을 쓰지 않는다. `vite build`에서는 `DEV`가 false라 꺼지고, `mocks/`는 `api.ts`에서 동적 `import()`로만 불러 운영 번들에 들어가지 않게 한다 |
| 08이 바뀔 때 | 같은 PR에서 그 API의 `types.ts`와 `mocks/`를 함께 고친다. API 계약 점검(`chagok-contract-checker`) 대상에 `mocks/`도 넣는다 |
| 하지 않는 것 | Mock 서버, Mock 라이브러리(MSW 등), 프론트 DB·브라우저 저장소에 데이터 쌓기, 범용 Mock 프레임워크, 08에 없는 API의 Mock |

전환 장치(`client.ts`의 판정과 응답 해석)는 B-2(chagok-frontend#10), 도메인별 `mocks/`는 각 화면 이슈가 만든다.

ESLint로 고정 (`eslint.config.js`에 추가, `@/` = `src/` 별칭 전제):

```js
{
  files: ['src/shared/**'],
  rules: { 'no-restricted-imports': ['error', { patterns: [
    { group: ['@/features/*', '@/pages/*'], message: 'shared는 features·pages를 import하지 않습니다' },
  ]}]},
},
{
  files: ['src/features/**'],
  rules: { 'no-restricted-imports': ['error', { patterns: [
    { group: ['@/pages/*'], message: 'features는 pages를 import하지 않습니다' },
    { group: ['@/features/*'], message: '다른 feature가 필요하면 pages에서 조합하세요 (같은 feature 안은 상대 경로)' },
  ]}]},
},
{
  files: ['src/pages/**', 'src/features/*/components/**'],
  rules: { 'no-restricted-imports': ['error', { patterns: [
    { group: ['**/mocks/**', '**/mocks'], message: 'Mock은 api.ts에서만 고릅니다 (CONVENTIONS 7장 Mock)' },
  ]}]},
},
```

`api.ts`의 동적 `import()`는 이 규칙에 걸리지 않는다(정적 import만 막음). 위 규칙은 화면 쪽의 정적 import를 막는 장치다.

---

## 8. 사람 대신 지키는 장치

| 장치 | 무엇을 막나 | 만드는 때 |
|---|---|---|
| `ArchitectureTest` (ArchUnit, 아래) | 규칙 1·2·4, 3장 의존 방향, global → domain·screen, Controller의 Repository 주입, Entity setter | **B-0에서 만듦** (`chagok-backend/src/test/java/…/architecture/ArchitectureTest.java`). 대상 클래스가 없는 규칙은 SKIPPED |
| `EndpointGuardTest` | 등록 안 된 경로 거부, 토큰 없이 `/api/**` 401, 서비스 관리자 토큰으로 `/api/**` 403, 정비소 토큰으로 `/api/admin/**` 403, `/actuator/health`만 공개 (SecurityConfig는 `anyRequest().denyAll()`로 끝) | `기반` 이슈 B-1 (설계: 12 백로그 9장). 보호할 API가 없는 지금은 만들지 않는다 |
| pr-check 비밀값 검사 | `.env`·키 파일, 토큰 형태, 설정 파일의 평문 비밀번호 | 이미 있음 (❌) |
| pr-check DB·Flyway 규칙 | 공유된 마이그레이션 수정, 이름 규칙, `schema.sql`·`data.sql`, classpath 안 시드, `ddl-auto` ≠ validate | 이미 있음 (❌) |
| cycle 테스트 T1~T17(04) | 주기 규칙 | cycle 이슈 |
| 예약 규칙 테스트 R1~R29 | 예약 시각·중복·지난 날짜·상태 변경 (04) | 예약 이슈 |
| 격리 테스트 X1~X16 | 남의 정비소 데이터 → 404 | 각 도메인 이슈 |
| Flyway + 빈 MySQL CI(`backend-ci`), 기존 버전 파일 수정 차단(`pr-check`) | 스키마 차이 | `기반` 이슈 |
| ESLint 경계 규칙 | 프론트 feature 간 import | 프론트 `기반` 이슈 |
| pr-check | 한 PR이 도메인 3개(프론트는 feature 3개) 이상을 건드리면 경고, 명세 변경인데 `chagok-docs` 문서 PR 링크가 없으면 경고·차단 | 이미 있음 |
| CODEOWNERS | 패키지 주인에게 자동 리뷰 요청 | 결정 14 후 이름 기입 |

### ArchitectureTest

실제 파일: `chagok-backend/src/test/java/com/wanted/chagok/architecture/ArchitectureTest.java` (ArchUnit 1.3.0). `./gradlew build`(DB 없이)에서 돈다.

| 테스트 | 검사 |
|---|---|
| `global은_domain과_screen을_모른다` | global → domain·screen 의존 금지 |
| `screen은_아무도_import하지_않는다` | screen 밖에서 screen 의존 금지 (domain → screen 포함) |
| `다른_도메인은_api로만` (도메인별) | 다른 도메인의 `api` 밖(Entity·Repository·Service·DTO) 의존 금지 |
| `도메인_의존_방향` (도메인별) | 3장 표에 없는 도메인 간 의존 금지 (`reservation → account.api`, `maintenance → account.api` 허용 포함) |
| `도메인_사이_순환_없음` | 도메인 사이 순환 금지 |
| `cycle은_순수_계산이다` | cycle → 다른 도메인·Spring·JPA 금지 |
| `Controller는_Repository를_직접_쓰지_않는다` | |
| `Entity에는_public_setter가_없다` | |

- **검사할 클래스가 아직 없는 규칙은 PASSED가 아니라 SKIPPED**로 남는다(JUnit Assumption). CI 작업 요약에 "건너뜀(검증 안 됨)"으로 따로 보인다. 패키지가 생기면 같은 테스트가 자동으로 실제 검사를 시작한다.
- 규칙을 끄거나 느슨하게 바꾸려면 먼저 이 문서를 고치는 `결정` 이슈가 필요하다. 테스트를 통과시키려고 규칙을 지우지 않는다.

---

## 9. 바꾸거나 더할 때 건드리는 곳 (이 구조의 검증표)

설계가 맞는지는 "자주 생길 변경이 몇 곳을 건드리나"로 확인한다. 이 표보다 많이 건드리게 되면 구조가 새고 있다는 신호다.

| 변경 | 건드리는 곳 | 기존 코드 수정 |
|---|---|---|
| 정비 항목 주기값 변경 | 시드(`db/seed/`), 07 시드표 | 없음 |
| 임박 기준 변경 (1개월 → 2주) | `cycle` 상수 1개 + T 테스트 기대값 | cycle만 |
| 상태 표시 문구·색 | `shared/ui/StatusBadge` | 1파일 |
| 예약 상세 패널에 항목 추가 | `screen/booking` + 필요한 `api` 메서드 + 08 + 프론트 패널 | booking만, 추가 위주 |
| API 응답에 필드 추가 | 해당 도메인 `dto` + 08 + `features/x/types.ts` | 그 도메인만 |
| P0-나머지 외부 정비·거절 입력 | maintenance 입력 화면·검증 (enum 값과 cycle 처리는 이미 있음, 결정 6) | maintenance만 |
| P0-나머지 점검 결과(양호/주의) | maintenance 결과 칸(마이그레이션 V파일) + cycle의 "지난 점검 주의" 판정 + 화면 표시 | maintenance·cycle, 추가 위주 |
| P1 차량 약식 도면 | 프론트 차량 상세 페이지에 도면 컴포넌트 (상태는 기존 응답 그대로, 색은 StatusBadge 기준) | 프론트 1곳 |
| P0-나머지 정비 기록 수정 | maintenance 내부(+ revision 표, V파일) + account.api 조회 메서드 | maintenance + 추가 1개 |
| P1 월평균 주행거리 추정 | `cycle` + `maintenance.api`에 주행거리 이력 메서드 추가 + `screen/target` | 3곳, 추가 위주 |
| P1 연락 결과 기록 | 새 `domain/contact`(표 1개, 새 마이그레이션 V파일) + `screen/target`에 표시 한 줄 | 새 패키지 + 1줄 |
| P1 신규·재방문 집계 | 새 `screen/stats` + 필요한 `api` 메서드 추가 | 새 패키지 |
| P1 정비소 개설·정지 | 새 `screen/admin` 또는 `domain/shop` 내부 + `shop.api` + SecurityConfig 규칙 1줄 | shop + 1줄 |
| P1 정비소별 항목 설정 화면 | `item` 내부 + 화면 1개 | item만 |
| P1 고객 비활성화·삭제·익명화 | customer 내부 + reservation.api·maintenance.api 조회 메서드 2개 | customer + 추가 2개 |
| P2 (M3 MVP 검증 후, 결정 이슈로 하나씩) | 상세 기획안 13장 「추가할 것」 기준. 새 패키지·새 마이그레이션 위주 | 이 표보다 많이 건드리면 결정 이슈에서 다시 판단 |

---

## 10. 코드에 남기는 주석

- 단순하게 만든 곳: `// LIMIT: <한계> / <바꿀 시점>` 예) `// LIMIT: 정비소당 고객 1,000명 이하 가정, 넘으면 대상 목록 쿼리를 페이징으로`. 영향 범위·변경 위험까지 설명이 필요하면 PR 본문 「단순화 기록」에 이유·영향 범위·알려진 제약·변경 시 위험·개선 시점을 적는다(12장)
- 기획 근거가 있는 규칙: `// 근거: 04 §x, D-xx`
- 일부러 하지 않은 것: `// 범위 밖: 00 Non-goal (고객 직접 문자 발송)`

---

## 11. 바꾸기 전에 확인할 것 (변경 영향 최소화)

사람이든 AI든 코드를 고치기 전에 확인한다. AI는 구현 계획 보고(`.claude/rules/ai-rules.md` 2단계)에 답을 적는다.

1. 같은 역할을 하는 코드가 이미 있는가? (4장 "한 곳에만 있는 규칙"부터 본다)
2. 기존 코드를 고치는 것만으로 해결되는가?
3. 새 클래스·인터페이스가 정말 필요한가? (구현이 하나뿐인 인터페이스, 한 곳에서만 쓰는 공통 유틸은 만들지 않는다)
4. 이 변경이 여러 도메인으로 퍼지는가? (3개 이상이면 멈추고 이슈를 쪼갠다)
5. 같은 규칙이 여러 곳에 생기는가?
6. 아키텍처 규칙을 임시로 어기는가? (어기는 코드는 만들지 않고 설계 검토로 올린다)
7. 이번 이슈와 관계없는 코드를 고치는가? (관계없는 리팩터링은 별도 이슈)

프론트도 같다: 같은 API 요청·타입·검증을 여러 화면에 따로 만들지 않는다(`features/*/api.ts`·`types.ts` 한 곳), 다른 feature의 내부 파일을 import하지 않는다(ESLint).

## 12. 임시방편 금지와 단순화 기록

기간이 짧다는 이유로 아래는 하지 않는다.

| 금지 | 대신 |
|---|---|
| 테스트를 통과시키려고 검증 코드·테스트·규칙 삭제, 보안 검사·인증 비활성화 | 원인을 고치거나, 규칙 변경을 `결정` 이슈로 |
| Flyway를 거치지 않은 스키마 변경, DB 데이터 직접 수정 | 새 마이그레이션 파일, DB 담당자에게 요청 |
| 여러 Service에 같은 업무 로직 복사, Controller에 업무 로직 | 4장의 "한 곳"에 두고 부른다 |
| 프론트에서 서버 권한 검사를 대신함 | 서버가 판단, 화면은 표시만 |
| 오류를 숨기려고 예외를 모두 잡아 성공처럼 응답 | `ErrorCode`로 정확한 실패 응답 |
| 시연 데이터를 운영 코드·마이그레이션에 넣음 | `db/seed/demo_seed.sql` |
| 기능과 무관한 대규모 리팩터링 | 별도 이슈 |

단순한 구현이 곧 기술 부채는 아니다. 지금 요구사항에 충분하고 책임이 분명하면 단순한 쪽을 고른다. 다만 알려진 한계가 있으면 `// LIMIT:` 주석과 PR 본문 「단순화 기록」(이유 · 영향 범위 · 알려진 제약 · 변경 시 위험 · 개선이 필요한 시점)을 남긴다.
