# CodeRabbit 리뷰 기록

> 릴리스 PR과 `review-me` PR의 CodeRabbit 지적과 처리 결과. 분류 기준은 CONTRIBUTING.md 6장.

상태: 작성 중 — 2026-11-28 첫 정리(chagok-docs#210). 새 릴리스 리뷰가 끝나면 그 PR의 줄을 더한다.
근거: 각 PR의 CodeRabbit 인라인 지적과 작성자 답글, 후속 PR 본문(아래 「처리 PR」). 리뷰 전문은 옮기지 않는다. `chagok-docs`는 CodeRabbit 대상이 아니다(CONTRIBUTING 6장).

## 1. PR별 요약

| 레포 | 리뷰한 PR (리뷰 날짜) | 인라인 지적 | 처리 PR | 수정 | 미룸 | 반영 안 함 | 미해결 |
|---|---|---|---|---|---|---|---|
| backend | #66 릴리스 (2026-11-25) | 7 (Major 1) | #87 · #88 | 7 | 0 | 0 | 0 |
| frontend | #44 공통 UI (2026-11-25) | 5 | #47 | 4 | 0 | 1 | 0 |
| frontend | #45 `review-me` 앱 골격 (2026-11-25) | 3 | — | 0 | 0 | 0 | **3** (분류 답글·후속 PR 없음) |
| frontend | #72 `review-me` 패널 접수·정정 (2026-11-27) | 3 | #91 · #107 | 2 | 0 | 0 | **1** |
| backend | #114 릴리스 (2026-11-27) | 3 | #122 | 3 | 0 | 0 | 0 |
| frontend | #81 릴리스 (2026-11-27) | 9 | #91 (1건은 #88로 이미 반영) | 9 | 0 | 0 | 0 |
| frontend | #97 릴리스 (2026-11-27, 열림) | 11 (Major 1) | #105 (4건은 #91로 이미 반영) | 9 | 2 | 0 | 0 (미룸 2건은 후속 대기) |
| backend | #128 릴리스 (열림) | 리뷰 없음 (요약 댓글만, 자동 리뷰 SKIPPED) | — | — | — | — | 릴리스 점검 때 확인 (D-66 ④) |

- 「미해결」 = 분류 답글도 후속 PR도 없는 지적. CONTRIBUTING 6장 판단 순서(형상관리 1차 분류 → 담당자)로 정리한다.
- 「미룸」 2건은 해결 처리 대기가 아니라 다른 이슈의 흐름에서 처리한다(아래 표 사유 칸).

## 2. 지적별 기록

| 레포 | 릴리스·PR | 파일 | 지적 요약 | 분류 (수정 / 미룸 / 반영 안 함) | 사유 | 수정 PR |
|---|---|---|---|---|---|---|
| backend | #66 | `CustomerService` (방문 저장) | **Major** 같은 차량의 방문 저장이 동시에 돌면 최근 주행거리가 낮아질 수 있음(잠금·버전 없음) | 수정 | 데이터 손상 위험. 같은 차량 행을 첫 조회에서 잠금(`findForUpdateByIdAndShopId`) | #87, 잠금 방식 통일 #88 |
| backend | #66 | `CustomerService` | 차량 소속 조회를 한 구현으로 통합, 방문 저장도 연식 상한 헬퍼 재사용 (2건) | 수정 | 같은 규칙 중복 (CONVENTIONS 11장) | #87 |
| backend | #66 | `ReservationService.findByDate` | 하루 예약 건수에서 취소 예약 제외 | 수정 | 08 04·D-63 B05와 다름 | #87 |
| backend | #66 | DB 테스트 2개 | `LAST_INSERT_ID()`를 다른 JDBC 호출로 읽어 연결이 바뀔 수 있음 (2건) | 수정 | 테스트가 우연히 통과할 수 있음 | #87 |
| backend | #66 | `pr-check.yml` | HTML 주석 안의 `Refs #n`으로 이슈 연결 검사가 통과 | 수정 | 검사 구멍 | #87 (세 레포는 chagok-docs#162·#169) |
| frontend | #44 | `FormField` (2건) | 오류 칸 초점이 오류 상태와 구별되지 않음, `id` 생략 시 접근성 연결 보장 | 수정 | 접근성 | #47 |
| frontend | #44 | `Modal` (2건) | 숨긴 요소를 초점 후보에서 제외, 위 모달이 남아 있으면 배경으로 초점 복원하지 않기 | 수정 | 접근성·겹친 모달 | #47 |
| frontend | #44 | `ItemStatusList.css` | 표에서 강조 항목만 굵게 | 반영 안 함 | v3 확정 디자인은 모든 행의 항목 이름이 굵음(#18 결정, CodeRabbit도 답글에서 제안 철회) | — |
| frontend | #45 | `AppLayout.css` | 접힌 사이드바에서도 계정 정보를 보조 기술에 제공 | **미분류** | 분류 답글·후속 PR 없음, 파일은 #45 이후 그대로 | — |
| frontend | #45 | `AppMenu.jsx` | 아이콘 없는 메뉴도 접힌 상태에서 표시 | **미분류** | 위와 같음 | — |
| frontend | #45 | `routeCollect.ts` | 라우터가 같은 URL로 처리하는 경로도 중복으로 거부 | **미분류** | 위와 같음 | — |
| frontend | #72 | `useReservationPanel`·`HomePage` | 패널을 닫은 뒤 성공한 방문 접수도 목록·요약 갱신 (dyk816 사후 리뷰 M1과 같은 지적) | 수정 | 서버 성공이 화면에 반영되지 않음 | #91 |
| frontend | #72 | `mocks` (39) | Mock에서도 연식·주행거리 범위 검사 | 수정 | Mock이 08 계약과 다름 | #107 (frontend#106) |
| frontend | #72 | `CorrectDialog.jsx` | 정정 400 `fieldErrors`를 해당 입력 아래에 표시 | **미분류** | 분류 답글·후속 PR 없음. 입력에 `maxLength` 200이 있어 영향 작음(dyk816 사후 리뷰 m1) | — |
| backend | #114 | `issue-close.yml` | 코드 블록 뒤의 정상 이슈 참조 보존(코드 펜스 안 `<!--`) | 수정 | 검사 오동작 | #122 (frontend #91) |
| backend | #114 | `build.gradle` | 모든 Test 작업의 `user.timezone`이 시간대 검증 테스트를 무력화 | 수정 | 회귀를 못 잡음 — `tzTest`(UTC JVM) 분리 | #122 |
| backend | #114 | `ReservationService` | 정정 대상 상태 판정을 한 곳에서 | 수정 | 규칙 중복 — `Reservation.isCorrectTarget()` | #122 |
| frontend | #81 | `issue-close.yml`·`pr-check.yml` (2건) | 코드 블록 뒤 참조 보존, 인라인 코드의 주석 표기를 주석으로 보지 않기 | 수정 | 검사 오동작 | #91 |
| frontend | #81 | `.claude/settings.json` | 이슈 삭제 명령이 막혀 있지 않음 | 수정 | 보안 설정 — `gh issue -* delete` deny 추가 | #91 |
| frontend | #81 | `editFlow.ts` | 쉼표만 입력한 값이 주행거리·연식 비움 검사를 통과 | 수정 | 입력 검증 | #91 |
| frontend | #81 | `useEditForm`·`CustomerDetailPage` (2건) | 이전 저장 완료가 새 편집 폼을 닫음, 재조회 실패 시 입력이 사라짐 | 수정 | 입력 유지(05 POL-122) | #91 |
| frontend | #81 | `useReservationPanel`·`HomePage` (2건) | 요청 중 패널을 닫으면 성공한 변경이 목록에 안 보임, 갱신이 이전 달을 다시 부름 | 수정 | 화면 상태 불일치 | #91 |
| frontend | #81 | `mocks` (15) | `mockGetReservations`가 `assigneeId` 조건을 적용하지 않음 | 수정 | Mock 계약 | #88 (이미 develop에 있음) |
| frontend | #97 | `VehicleDetailPage.jsx` | **Major** 차량이 바뀌어도 M-03·수정 이력 패널이 남음 | 수정 | 다른 차량 기록을 고칠 위험 — 회귀 테스트 추가 | #105 |
| frontend | #97 | `StartVisitDialog.jsx` | 이전 예약의 접수 응답이 현재 대화상자를 닫음 | 수정 | 늦은 응답 처리 — 회귀 테스트 추가 | #105 |
| frontend | #97 | `panelFlow.ts` | 취소 안내가 실제 정정 범위(노쇼·완료만)와 다름 | 수정 | 안내 문구 정정 | #105 |
| frontend | #97 | `DatePickerPopover.css` (2건) | 낮은 화면에서 팝오버 스크롤, 키보드 초점 윤곽선 대비(WCAG 1.4.11) | 수정 | 접근성 | #105 |
| frontend | #97 | `CustomerDetailPage` (2건)·`VehicleDetailPage` 취소 버튼·`pr-check.yml` 코드 펜스 | #81 리뷰와 같은 지적 | 수정 | 이미 반영 | #91 |
| frontend | #97 | `.claude/settings.json` | `gh api -X=DELETE` 형태가 막혀 있지 않음 | 미룸 | 설정 변경은 chagok-docs#190·frontend#102(사후 리뷰 반영) 흐름에서 처리 | 진행 중 |
| frontend | #97 | `index.html` | 공유 이미지(`og:image`)에 절대 URL | 미룸 | 운영 도메인 미정. 도메인이 정해질 때 frontend#93 후속 | — |
