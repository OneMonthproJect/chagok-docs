# 이영주 — DB관리 · BE 개발가이드

> 기준: 2026-11-24 05:53 KST, backend develop `f562a7b`, docs develop `cf9ef3f`. 담당 기능은 **추천안**([01](../01_P0_핵심기능_담당배정.md)). 공통은 [03](../03_공통_클론_개발환경.md)·[05](../05_공통_협업_개발절차.md).
> 이후 현황(2026-11-27): 이 문서가 다룬 P0 작업(12 4·5장 이슈)은 모두 끝났다 — M2 통합 검증 통과(2026-11-26, `v0.5-m2-integration`), P0-나머지 구현 이슈 모두 닫힘. 아래는 2026-11-24 착수 당시 기록이다. 지금 단계는 [README](../../../../README.md)·[GUIDE](../../GUIDE_레포구조_협업규칙_AI스킬안내.md) 「지금 단계」, 규칙은 원본(CONTRIBUTING·`.claude/rules/ai-rules.md`)을 따른다.

## 0. AI 개발 환경 최신화 및 역할별 효율적 사용 (2026-11-28, chagok-docs#208)

> 이 절만 새로 더했다. 아래 1장부터의 P0 기록은 그대로다. 자세한 것은 [GUIDE](../../GUIDE_레포구조_협업규칙_AI스킬안내.md) 11.1(외부 도구)·13~15장(최신화·확인)·29장(복구), 규칙 원본은 `.claude/rules/ai-rules.md`.

**공통** — 순서·명령의 원본은 [STARTER 03](../03_공통_클론_개발환경.md) 3장과 GUIDE 13~15장이다.
- 형상관리자(김동윤)의 릴리스·배포 공지를 받은 뒤 적용한다. 공지 전에는 기존 환경 그대로 일한다.
- 작업을 커밋·push하고 세션을 끝낸 안전한 때, 작업 폴더에서 `bash chagok-docs/scripts/update-workspace.sh`(먼저 `--check`) → Claude Code **새 세션**.
- 필요한 스킬만 부르고 이미 돌린 결과는 재사용(GUIDE 24.1), 충돌은 내 작업 브랜치에서 `git merge origin/develop`([05](../05_공통_협업_개발절차.md) 6장), 외부 도구는 선택(GUIDE 11.1).

**역할별 — DB관리 · BE**
- **필수 DB 검증은 그대로(L3)**: 마이그레이션·시드는 빈 DB 새 설치 + 같은 DB 재실행(Flyway validate → up to date), 시드 기대값(07 7.5), V(n) 정합성 테스트.
- **DB 테스트 결과 재사용 조건**: 같은 커밋이고 그사이 `db/migration`·`db/seed`·Entity·Repository가 바뀌지 않았을 때만 앞선 `dbTest`·CI 결과를 근거로 쓴다. 하나라도 바뀌면 그 영향 범위를 다시 돌린다.
- **영향 범위 중심**: 바뀐 테이블·마이그레이션에 닿는 테스트부터. 관련 없는 고비용 검증을 일괄로 돌리지 않는다.
- **개발·테스트 DB 보호**: `dbTest`는 빈 테스트 DB에서만. 개발·시연·공용 DB를 직접 바꾸지 않고, AI에게 DB 실행·변경을 맡기지 않는다.
- **Context7·RTK(선택)**: Flyway·Spring Data 버전 차이가 불확실할 때만 Context7(레포 `build.gradle` 버전 우선). 긴 `git log`·`git diff`는 `rtk`로 요약 가능, 테스트 실패 판정은 원래 출력으로.

**Claude 요청 예시**
```text
이번 브랜치의 마이그레이션 변경이 어떤 테이블·Entity·테스트에 닿는지 영향 범위만 조회해 줘. 이미 통과한 dbTest 결과(커밋 <SHA>)를 재사용할 수 있는지도 판단해 줘. DB는 실행하지 마.
```
```text
chagok-seed-builder 에이전트로 demo_seed.sql을 07 시드표와 대조해 줘. 바뀐 마이그레이션 V<번호> 기준으로만.
```

## 1. 내 역할과 책임

| 구분 | 내용 |
|---|---|
| 운영 역할 (확정 D-14) | DB관리(이재성과 공동) — 07 ERD·Flyway·시드 주인(CODEOWNERS `/docs/07_*`), 마이그레이션·시드 승인, Entity↔V1 일치 검토 |
| 개발 역할 (추천) | BE: `domain/customer`(4-1 검색·등록, 4-2 상세·차량 추가), `domain/item`(7-1), `domain/maintenance`(7-2). 순서: 4-1 → 7-1 → 7-2 → 4-2 |
| 추가 검증 | FK·무결성·`shop_id` 격리(X1·X2·X5·X7·X17), 시나리오 데이터(07 7장) |
| 주 협업 | 최은정(S-05·06·07·08 FE), 김예린(reservation이 customer `api` 사용), 김동윤(cycle·visit이 정비 기록 사용), 이재성(DB 공동) |

## 2. 현재 상태

- 있음: `V1__init.sql`(07 9개 표: shop·staff·platform_admin·customer·vehicle·service_item·maintenance_record·reservation·reservation_item, 제약·인덱스), `db/seed/demo_seed.sql`·`run-demo-seed.sh`·`README.md`, `V1InitMigrationTest`·`DemoSeedTest`·`DemoSeedFileTest`(DB 테스트), `application.yaml`의 `ddl-auto: validate`.
- 없음: Entity 전부, `domain/customer`·`maintenance`·`item`.
- 미검증: **Entity ↔ 스키마 일치**(Entity가 없어 아직 검사할 대상이 없음) — 4·7번이 처음 검증한다.
- 착수 조건: 4-1은 **2(account) 선행**. 4-2는 4-1·**1(cycle)·7-2** 선행(`dueCount`·`soonCount`에 cycle과 정비 기록이 필요, 02 Q1). 7-1은 4-1 선행, 7-2는 4-1·7-1 선행.

## 3. 내 P0-핵심 담당 (추천)

| 순번 | 기능 ID | 기능 | API (08) | 화면 | 테이블 (읽기/쓰기) | GitHub | 상태 | 선행 | 협업 |
|---:|---|---|---|---|---|---|---|---|---|
| 4-1 | F-CUS-01·02 | 고객·차량 검색·등록 | 05 `GET /api/customers?q=&page=&size=`, 06 `POST /api/customers` | (S-05, M-01) | customer·vehicle / customer·vehicle | 미생성 | 추천 | 2 | 최은정 (5) |
| 4-2 | F-CUS-03·04·05 | 고객 상세·차량 추가·차량 상세 | 07 `GET /api/customers/{customerId}`, 08 `POST /api/customers/{customerId}/vehicles`, 09 `GET /api/vehicles/{vehicleId}` | (S-06·07) | customer·vehicle·maintenance_record·service_item / vehicle | 미생성 | 추천 | 4-1, 1, 7-2 | 최은정 (6·6-1·9) |
| 7-1 | F-MNT-01 | 항목 목록 | 13 `GET /api/items` | (S-08) | service_item / — | 미생성 | 추천 | 4-1 | 김예린 (11-1이 사용) |
| 7-2 | F-MNT-01 | 방문 기록 저장·이력 | 11 `GET /api/vehicles/{vehicleId}/visits`, 12 `POST /api/vehicles/{vehicleId}/visits` | (S-07·08) | vehicle·service_item·staff / maintenance_record·vehicle | 미생성 | 추천 | 4-1, 7-1 | 김동윤 (cycle·visit) · FE 짝 최은정 (9·10) |

## 4. 첫 개발 순서

1. `develop` 최신화. **개발 DB와 빈 테스트 DB를 나눠** 만든다(README). `dbTest`로 V1·시드 테스트가 내 PC에서 도는지 먼저 확인.
2. DB관리: V1과 07을 다시 읽고 Entity 매핑 규칙(이름·타입·FK·`version`)을 정리 → 다른 BE(김동윤·김예린)에게 공유.
3. 4-1 이슈 열기 → 04 F-CUS-01·02, 08 05·06, X1·X2·X7·X17 중 해당분(+ Q7 X8).
4. `feature/#<번호>-customer`.
5. Entity `Customer`·`Vehicle`(setter 없음) → `ddl-auto: validate`로 `dbTest` 통과 확인 = **Entity↔스키마 첫 검증**.
6. Repository(`…AndShopId`), Service(`getOwned(shopId, id)` → 없거나 남의 것이면 404), `api/`(다른 도메인용 `CustomerReader` 등 — 김예린과 계약 합의).
7. 2번(account) 머지 후 실제 토큰으로 Controller 연결. 4-1은 05·06까지만. 07의 `dueCount`·`soonCount`는 cycle·정비 기록이 필요해서 4-2에서 만든다 → 1번·7-2 머지 시점을 PM과 확인.
8. 최은정과 05·06 응답·400 필드 오류 확인.
9. PR → `chagok-contract-checker` + `chagok-pr-reviewer` → 확인 → 머지. 4는 4-1(05·06)·4-2(07·08·09)로 이미 나눴다(02 6장).
10. 7-1(`domain/item`, 13) → 7-2(`domain/maintenance`, 11·12) 순. 그 뒤 4-2(07·08·09)로 돌아온다.

## 5. 코드 경로

| 경로 | 상태 |
|---|---|
| `src/main/resources/db/migration/V1__init.sql` | **있음** — 머지됨, **수정 금지**. 바꿔야 하면 새 V 번호 + 07 문서 PR (P0-핵심은 새 마이그레이션 없음이 기본) |
| `db/seed/demo_seed.sql`, `run-demo-seed.sh` | **있음** — 시연 전용 DB에서만, `chagok-seed-data` |
| `src/test/java/.../migration/V1InitMigrationTest.java`, `seed/DemoSeedTest.java` | **있음** |
| `domain/customer/{api,controller,dto,service,entity,repository}/` | 생성 예정 |
| `domain/item/…`, `domain/maintenance/…` | 생성 예정 |

## 6. 협업과 연동 시점

| 기능 | 상대 | 계약 | Mock | 연동 |
|---|---|---|---|---|
| 4-1 → 5 | 최은정 | 05 목록(쪽 기본 20·최대 50), 06 등록(차종 필수) | FE가 먼저 Mock | 4-1 머지 후 |
| 4-2 → 6·9, 6-1 | 최은정(6·9), 김동윤(6-1) | 07 상세, 08 차량 추가, 09 차량 상세 | 〃 | 4-2 머지 후 |
| 7-1·7-2 → 9·10 | 최은정 | 13 항목, 11 이력, 12 저장(`REPLACE`·`INSPECT`) | 〃 | 7-1·7-2 머지 후 |
| 4-1 → 11-1 | 김예린 | customer `api` 메서드 | — | 4-1 PR 전에 합의 |
| 7-1 → 11-1 | 김예린 | 항목 `api`(예약 목적 `itemIds` 검증, X11) | — | 7-1 PR 전에 합의 |
| 7-2 → 1·8 | 김동윤 | 정비 기록 → cycle 입력 모양 (maintenance `api`) | — | 7-2 PR 전에 합의 |

## 7. 구현 정책·주의

- **customer**: 주행거리 정수 0~2,000,000, 연식 1980~(Clock 현재 연도+1), 벗어나면 400. `model` 필수(D-58). 06은 한 트랜잭션. 차량번호 중복 허용(저장 버튼 중복 제출은 FE가 막음). 상세는 전체 연락처, 목록 마스킹은 P0-나머지(D-40) — **만들지 않음**. 💡 "공백만 제거"(F-CUS-02)는 착수 전 확인(Q11).
- **maintenance**: type은 `REPLACE`·`INSPECT`만, EXTERNAL·DECLINE·`inspectResult`·`mechanicId`는 400(P0-나머지). 방문일 미래 불가, 같은 항목 중복 불가, 차량 연식·주행거리가 비었으면 첫 저장 때 필수(D-58). 저장 전체가 한 트랜잭션. 담당 = 저장한 계정. 💡 "주행거리가 작으면 갱신하지 않음" 확인(Q11).
- 격리: shopId는 토큰에서만, 다른 정비소 → 404. `staff`·`reservation`의 복합 FK(D-51)는 V1에 이미 있다.
- DB 오류(제약 위반)는 500으로 떨어진다(08 0.3 M1 결정 A) → 서버 검증이 먼저 막아야 한다.

## 8. 테스트·검증

| 이슈 | 테스트 |
|---|---|
| 4-1 | X1·X2·X7·X17 중 05·06분, X8, 주행거리·연식 경계, 차종 누락 400, 쪽 상한 50, Entity validate |
| 4-2 | X1·X2·X7·X17 중 07·08·09분, `dueCount`·`soonCount`(D-63 B01·B03·B04) |
| 7-1 | X7(13) |
| 7-2 | X5·X11(12 `records[].itemId`)·X2(11 NOT_FOUND) (Q3), 미래 날짜·중복 항목 400, 트랜잭션 롤백 |

명령: `./gradlew build` + 빈 테스트 DB `dbTest`. 공용 DB는 쓰지 않는다.

## 9. PR·완료 기준

격리 조건이 있으므로 **L3 검증**(A 토큰으로 B id → 404, 목록 섞임 없음). `chagok-pr-reviewer` 필수. 최은정 FE와 함께 띄워 확인 → `done-verified`.

## 10. 착수 체크리스트

- [ ] 개발 DB `chagok`, 빈 테스트 DB `chagok_test` 분리
- [ ] `dbTest` 통과(V1·시드 테스트)
- [ ] Entity 매핑 규칙 공유
- [ ] customer `api` 계약 (김예린), maintenance `api` 계약 (김동윤)
- [ ] 💡 2건(Q11) 확인

## 11. DB관리 업무

- 모든 마이그레이션·시드 PR의 리뷰어(CODEOWNERS). 머지된 V 파일 수정·`flyway repair` 요청은 거절.
- 다른 BE의 Entity PR에서 V1과 일치 여부 확인.
- 시드 변경은 `chagok-seed-builder` 에이전트 + 07 7.5 기대값 확인. M2 검증 전 시연 DB 준비(승인된 경우만).
- docs#71 PR #75의 「DB 담당자: 상세 10장 검토안 2·8·9번」 확인 요청이 남아 있다(P1 약관 모델, 지금 구현 아님).

## 12. 미결·확인

- 담당 확정 전 (추천안)
- 4-2의 선행에 cycle(1)·7-2를 넣은 것(Q1)은 **❓ Q14(API 07 `dueCount` 조립 위치, CONVENTIONS 3장과 충돌) 결정 전 잠정** — [08](../08_구현_파일_소유_충돌방지.md) 6장. X8은 4-1에 반영(Q7) — PM 확인
- 도메인의 **첫 PR은 `api/`(계약)만**(4-1 `CustomerReader`·7-1 `ItemReader`·7-2 `MaintenanceReader`) — 김예린·김동윤이 이 계약으로 시작한다. 파일 소유는 08 4장
- 4·7번 분할(4-1·4-2, 7-1·7-2)은 추천안 — PM·담당 확정 (02 6장)

## 부록. 2026-11-24 일정 분리·P0-나머지 추천 (01 6장)

추천안이다. 담당 지정은 PM이 GitHub에서 한다. 시작 후 10~12일 목표라서 큰 이슈를 새 파일 중심으로 나눴다(02 10장, 08).

- **#42** backend — 방문 기록 저장(API 12). 7-2에서 분리. `domain/maintenance` 새 컨트롤러·dto, `MaintenanceService`에 메서드 추가.
- **#43** backend — 고객 상세(API 07). 4-2에서 분리. **마지막에 하는 이슈**. ❓ Q14(chagok-docs#96)가 (a)면 `screen/`으로 옮겨져 김동윤 담당.
- P0-나머지 추천: #31 Flyway V2, #32 외부·거절·점검 결과(maintenance만), #34 고객·차량 수정·마스킹, #39 정비 기록 수정·이력. 착수는 M2 통과 후.

