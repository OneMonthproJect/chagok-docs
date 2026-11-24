# 김예린 — PM · BE 개발가이드

> 기준: 2026-11-24 05:53 KST, backend develop `f562a7b`, docs develop `cf9ef3f`. 담당 기능은 **추천안**([01](../01_P0_핵심기능_담당배정.md)). 공통은 [03](../03_공통_클론_개발환경.md)·[05](../05_공통_협업_개발절차.md).

## 1. 내 역할과 책임

| 구분 | 내용 |
|---|---|
| 운영 역할 (확정 D-14) | PM — 범위·우선순위, D-15 일정·담당 결정 책임, 담당 확정 회의, 범위 추가 판정(`chagok-scope-guard`), docs `/docs/`·04·08 CODEOWNER |
| 개발 역할 (추천) | BE: `domain/reservation`(11), `screen/booking`(13) |
| 추가 검증 | 예약 R 테스트(중복·상태 전이·동시 수정 409), cycle(1)·account(2)·target(12) 검증 협업 |
| 주 협업 | 이재성(S-02·M-02·패널 FE), 이영주(customer `api`·item), 김동윤(cycle·visit) |

## 2. 현재 상태

- 있음: `V1__init.sql`의 `reservation`(`version` 포함, `assignee_staff_id` 복합 FK)·`reservation_item`, ErrorCode의 409 계열·`OptimisticLockingFailureException` → 409 `CONCURRENT_MODIFICATION` 처리(GlobalExceptionHandler), `PageLimit`.
- 없음: `domain/reservation`, `screen/booking` 전부.
- 착수 조건: 11번은 **4(customer) 선행**, 13번은 **8·11 선행**. 지금은 PM 업무와 명세·테스트 설계부터.

## 3. 내 P0-핵심 담당 (추천)

| 순번 | 기능 ID | 기능 | API (08) | 화면 | 테이블 (읽기/쓰기) | GitHub | 상태 | 선행 | 협업 |
|---:|---|---|---|---|---|---|---|---|---|
| 11 | F-RSV-01·02·04·06 | 예약 등록·기간 조회·방문 완료·변경 | 15 `GET /api/reservations?from=&to=`, 16 `POST /api/reservations`, 18 `POST /api/reservations/{reservationId}/complete`, 19 `PATCH /api/reservations/{reservationId}` | (S-02, M-02) | vehicle·service_item·reservation / reservation·reservation_item | 미생성 | 추천 | 4 (❓ X11은 7도 필요) | 이재성 |
| 13 | F-RSV-03 | 예약 상세 패널 | 17 `GET /api/reservations/{reservationId}/panel` | (S-02 패널) | reservation·reservation_item·customer·vehicle·maintenance_record·service_item·staff / — | 미생성 | 추천 | 8, 11 | 이재성 |

## 4. 첫 개발 순서

1. **PM 먼저 (착수 전 결정)**: [01](../01_P0_핵심기능_담당배정.md) 5장 질문 1~5 결정 → 담당 확정 → 김동윤에게 이슈 생성 요청. D-15 일정(C06). #72·#74·#79는 결정됨(D-66~D-68) — 남은 PM 일은 PR #82·#87 사후 리뷰.
2. `develop` 최신화, 환경 준비.
3. 04 F-RSV-01·02·04·06 + R1~R5·R7~R14, 08 15·16·18·19와 X4·X7·X11·X12 읽기 → 테스트 목록 먼저 작성.
4. 4번(customer) 이슈 진행 상황 확인. 머지 전에는 `CustomerReader` 같은 `api` 계약 모양을 이영주와 합의.
5. 11번 이슈 열기 → `feature/#<번호>-reservation`.
6. Entity(`Reservation`, `version`, 이름 있는 상태 메서드) → Repository(`shopId` 조건) → Service(`getOwned`) → Controller.
7. R 테스트 + X4·X11·X12 격리 테스트(`dbTest`).
8. 이재성과 15·16·19 응답·409 처리 확인(Mock → 실제).
9. PR → `chagok-pr-reviewer` → 확인 → 머지. 크면 15·16 / 18·19로 분할(02 6장).
10. 8(김동윤)·11 머지 후 13번 패널.

## 5. 코드 경로

| 경로 | 상태 |
|---|---|
| `src/main/resources/db/migration/V1__init.sql` (reservation·reservation_item) | **있음** — 수정 금지, 읽기만 |
| `global/error/ErrorCode.java`, `GlobalExceptionHandler.java` | **있음** — `RESERVATION_ACTIVE_EXISTS` 등 08 코드 확인 |
| `domain/reservation/{api,controller,dto,service,entity,repository}/` | 생성 예정 |
| `screen/booking/` | 생성 예정 (reservation·customer·maintenance·item `api` + cycle만 import) |
| `domain/customer/api/` | 이영주가 4번에서 생성 예정 — 여기에 필요한 메서드를 **추가 요청** |

## 6. 협업과 연동 시점

| 기능 | 상대 | 계약 | Mock | 연동 |
|---|---|---|---|---|
| 11 → 14 | 이재성 | 15 목록, 16 등록, 19 변경(`version`), 409 두 종류 | FE가 08 예시로 먼저 | 11 머지 후 |
| 11 → 15 | 이재성 | 18 완료(`version`), 409면 패널 재조회·S-08 이동 안 함 | 〃 | 11 머지 후 |
| 13 → 15 | 이재성 | 17 `recentVisits` 최대 2, `totalVisitCount`, `itemStatuses` `sortOrder` 순 | 〃 | 13 머지 후 |
| 4 → 11 | 이영주 | 차량 소속 확인용 customer `api` | — | 4 머지 전 계약 합의 |

## 7. 구현 정책·주의

- **시간**: 30분 단위, 초 00. 날짜 ≥ 오늘(오늘의 지난 시각은 허용). 15 조회 기간 최대 42일.
- **중복**: 유효 예약이 있으면 409 `RESERVATION_ACTIVE_EXISTS` + `details.reservationId` (R3·R4).
- **동시 수정**: 18·19는 `version` 필수, 불일치 409 `CONCURRENT_MODIFICATION`. 목적만 바꿔도 version +1. 19에 바꿀 필드 없으면 400(R14).
- **담당**: P0-핵심은 서버가 등록자를 담당으로 자동 지정(D-51). `assigneeId` 입력·충돌 검사(R15~R20)는 **P0-나머지 — 만들지 않음**.
- **만들지 않음**: 취소·노쇼(20·21), 진행중·방문 접수(39), 월·주 캘린더(42), 정정·재배정(40·41).
- 격리: 다른 정비소 예약·차량 → 404. 요청의 shopId는 무시(X8 — 담당 ❓, 02 Q7).
- 방문 완료(18)와 정비 기록 저장(12)은 별도 요청(C03) — 중간 이탈 정합성은 미검증으로 남김.

## 8. 테스트·검증

| 이슈 | 테스트 |
|---|---|
| 11 | R1~R5·R7~R14, X4·X7(15)·X11·X12(18·19), 30분·초·과거 날짜 경계, 42일 상한, 동시 수정 두 요청 |
| 13 | X3(B 정비소 예약은 **테스트 픽스처**, B12), 최근 2회·`totalVisitCount`(외부 기록만 있는 방문 제외) |

명령: `./gradlew build` + 빈 테스트 DB `dbTest`. 실제 409 E2E는 FE 연결 후 이재성과 함께.

## 9. PR·완료 기준

L2(격리 조건은 L3). `chagok-contract-checker`(DTO·ErrorCode) + `chagok-pr-reviewer` 필수. 이재성 FE develop과 함께 띄워 409 흐름 확인 → 확인한 팀원 `done-verified`.

## 10. 착수 체크리스트

- [ ] 01 5장 질문 1~5 결정, 담당 확정 공지
- [ ] D-15 일정 초안
- [ ] R1~R14 목록 정리 (P0-나머지 R15~ 제외 확인)
- [ ] customer `api` 계약 합의 (이영주)
- [ ] 개발 DB·테스트 DB, `./gradlew build` 통과

## 11. PM 업무

- 업무량: 김동윤 부하(BE 4 + 형상관리) 조정 여부 결정.
- 선행 순서: 02 3장 Q1(4번에 cycle 필요)·Q4(11번에 item 필요) 반영 여부.
- 범위: 02 3장 Q8(시나리오 B의 P0-나머지 단계) `결정` 이슈 여부.
- 담당 확정 뒤 12 7장 기록 docs PR.
- 범위 추가 의견이 오면 `chagok-scope-guard` 먼저.

## 12. 미결·확인

- 담당 확정 전 (추천안), D-15 미정
- X8 담당(Q7), X7을 11번에 넣을지(Q4)
- S-02 목록 연락처 칸(Q9) — 이재성과 확인
