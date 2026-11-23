# 이재성 — DB관리 · FE 개발가이드

> 기준: 2026-11-24 05:53 KST, frontend develop `bf2ab08`, docs develop `cf9ef3f`. 담당 기능은 **추천안**([01](../01_P0_핵심기능_담당배정.md)). 공통은 [03](../03_공통_클론_개발환경.md)·[05](../05_공통_협업_개발절차.md).

## 1. 내 역할과 책임

| 구분 | 내용 |
|---|---|
| 운영 역할 (확정 D-14) | DB관리(이영주와 공동) — 07·시드 리뷰(CODEOWNERS `/docs/07_*`), DB 모델 검토 |
| 개발 역할 (추천) | FE: S-01 로그인(3), S-02 오늘 예약 목록·M-02 등록·변경(14), 예약 상세 패널(15), S-02 홈(17) |
| 추가 검증 | FE↔BE 예약 계약(409 두 종류), 예약 UX, 401 흐름 |
| 주 협업 | 김동윤(01·03·04 API), 김예린(15~19 API), 최은정(S-04에서 예약, 홈 집계 검토) |

## 2. 현재 상태

- 있음: `shared/api/client.ts`(08 공통 응답, `ApiError`, 401 → 토큰 삭제·`onUnauthorized`, Mock 판정), `shared/lib/tokenStore.ts`(localStorage ❓), `submitGuard.ts`, `shared/ui/Button`·`Layout`·`StatusBadge`·`theme.css`(**임시 디자인**, D-19 전), `app/App.jsx`·`RequireAuth`(`state.from`)·`UnauthorizedRedirect`(`state.reason='expired'`)·`ServerCheck`(지금 `/login`).
- 없음: `pages/`·`features/` 전부.
- 미검증: `state.from` 실제 이동(보호 화면 없음), Button 렌더링(jsdom 없음).
- 착수 가능: **3번 바로 가능**(선행 B-2 완료, 08 01·03 예시로 Mock).

## 3. 내 P0-핵심 담당 (추천)

| 순번 | 기능 ID | 기능 | API (08) | 화면 (09) | GitHub | 상태 | 선행 | 협업 |
|---:|---|---|---|---|---|---|---|---|
| 3 | F-AUTH-01 | 로그인 화면 | 01 `POST /api/auth/login`, 03 `GET /api/me` | S-01 | 미생성 | 추천 | B-2 ✅ | 김동윤 (BE 2) |
| 14 | F-RSV-01·02·06 | 오늘 예약 목록(앞뒤 날짜) + 등록·변경 | 15·16·19 (+05 고객 검색·13 항목) | S-02 목록, M-02 | 미생성 | 추천 | 5 | 김예린 (BE 11) |
| 15 | F-RSV-03·04 | 예약 상세 패널 + 방문 완료 → S-08 | 17·18 | S-02 패널 → S-08 | 미생성 | 추천 | 14, 10 | 김예린 (BE 13·11) |
| 17 | F-HOME-01 | 홈 요약 숫자 + 오늘 예약 목록 | 04 `GET /api/home` | S-02 | 미생성 | 추천 | 15, 16 | 최은정 (BE 12 김동윤) |

FE는 DB를 직접 쓰지 않는다. 테이블은 BE 담당이 다룬다.

## 4. 첫 개발 순서

1. `develop` 최신화, `npm ci`, `npm run lint && npm test && npm run build` 통과 확인.
2. 09 S-01·08 01·03·05 POL-126 읽기. D-19 화면 세부 확정 여부를 최은정에게 확인(C05).
3. 3번 이슈 열기 → `feature/#<번호>-login-page`.
4. `features/auth/`: `types.ts`(08 그대로), `api.ts`(`client.request` 사용), `mocks/`(08 예시, `VITE_USE_MOCK=true`는 `.env.development.local`).
5. `pages/S01` + `App.jsx` 라우트 교체(`ServerCheck` 자리). 실패 문구 하나(`LOGIN_FAILED`), 비밀번호는 브라우저 저장소에 두지 않음(09).
6. 로그인 성공 → `tokenStore.setToken` → `state.from`이 있으면 그곳, 없으면 S-02. `reason='expired'`면 안내 문구. (FU-3 결정 전: 현재 계약대로 구현, from 누락은 기록)
7. `npm test`(Vitest, api 단위) + 수동 확인.
8. 김동윤 2번 머지 후 실제 백엔드로 401·403 확인 → PR.
9. 14번: 5번(고객 검색) Mock을 재사용해 M-02 → 409 `RESERVATION_ACTIVE_EXISTS`면 기존 예약 패널 열기 **자리만**(패널은 15).
10. 15 → 17 순.

## 5. 코드 경로 (`src/`)

| 경로 | 상태 |
|---|---|
| `shared/api/client.ts` | **있음** — 모든 요청은 여기로만. 바꾸면 L2 + `review-me` |
| `shared/lib/tokenStore.ts`, `submitGuard.ts` | **있음** |
| `shared/ui/Button.jsx`·`Layout.jsx`·`StatusBadge.jsx` | **있음** (임시 디자인) |
| `app/App.jsx`, `RequireAuth.jsx`, `UnauthorizedRedirect.jsx`, `paths.js` | **있음** — S-01 연결 때 수정 |
| `features/auth/{api.ts,types.ts,mocks/,components/}` | 생성 예정 |
| `features/reservation/…` | 생성 예정 (14·15) |
| `pages/S01/`, `pages/S02/` | 생성 예정 |

`features/` 끼리 import 금지 — 홈(S-02)에서 reservation·target을 합칠 때는 `pages/S02`에서.

## 6. 협업과 연동 시점

| 기능 | BE | 계약 | Mock | 실제 연동 |
|---|---|---|---|---|
| 3 | 김동윤 2 | 01 실패 `LOGIN_FAILED`, `expiresIn` 43200, 03 내 계정 | ○ | 2 머지 후 |
| 14 | 김예린 11 | 15 목록(42일 상한), 16 등록, 19 변경(`version`), 409 두 종류 | ○ | 11 머지 후 |
| 15 | 김예린 13·11 | 17 패널, 18 완료(`version`) | ○ | 13 머지 후 |
| 17 | 김동윤 12 | 04 홈(건수는 취소 제외, 목록은 취소 포함) | ○ | 12 머지 후 |

Mock은 08의 사본이다. Mock과 08이 다르면 08이 맞다. 계약 변경은 BE 담당 + 최은정에게 알리고 docs 08 PR.

## 7. 구현 정책·주의

- 상태 배지는 서버 값 그대로(재계산 금지). 저장 버튼은 요청 중 비활성(`submitGuard`).
- 자동 재전송 금지(POL-125). 네트워크 오류·500에도 입력값 유지.
- 409 `RESERVATION_ACTIVE_EXISTS` → 기존 예약 패널 열기. 409 `CONCURRENT_MODIFICATION` → 다시 조회. 18·19 실패면 S-08로 이동하지 않음.
- 30분 단위 시간 선택, 과거 날짜 막기(서버도 `RESERVATION_PAST_DATE`).
- **만들지 않음**: 담당 정비사 선택·이름 표시(Q10), 취소·노쇼, 월·주 캘린더, S-01 비밀번호 변경·약관 단계, 관리자 로그인 전환(P1).
- 패널: 상세 이동 버튼은 항상 보이고 방문 3회 이상이면 활성.

## 8. 테스트·검증

| 이슈 | 테스트 |
|---|---|
| 3 | 로그인 성공·실패, 401 → 로그인 이동(`reason`), 토큰 삭제, 네트워크 실패 문구 (X10 화면 동작) |
| 14 | 409 두 종류, 중복 제출 방지, 날짜 앞뒤 이동, 입력 보존 |
| 15 | 18·19 409 → 재조회·이동 안 함, 3회 이상 활성 |
| 17 | 07 7.5 기대값(오늘 예약 2건, 오늘 연락할 고객 5명) — 시연 DB 또는 BE 테스트 데이터로 |

명령: `npm run lint && npm test && npm run build`. 화면 렌더링 테스트(jsdom)는 아직 없음 — 도입은 별도 판단.

## 9. PR·완료 기준

`api.ts`·`types.ts`·`mocks/`를 건드리면 `chagok-contract-checker` 필수, `chagok-pr-reviewer` 필수(L2). 백엔드 develop과 함께 띄워 확인한 결과를 PR에 → `done-verified`.

## 10. 착수 체크리스트

- [ ] Node 22, `npm ci`, lint·test·build 통과
- [ ] 백엔드 `bootRun` + `npm run dev` → `/login` "UP"
- [ ] `.env.development.local`에 Mock 설정 방법 확인
- [ ] D-19 화면 세부 확인 (최은정)
- [ ] 3번 브랜치 생성

## 11. DB관리 업무

- 07·시드 PR 공동 리뷰(이영주와). 시드 값(07 7장)을 FE Mock 값으로 재사용.
- 예약 데이터 모델(`reservation.version`, `reservation_item`)을 FE 상태 관리와 맞춰 검토.
- DB 변경이 필요해 보이면 직접 고치지 않고 `결정`·docs 이슈로.

## 12. 미결·확인

- 담당 확정 전 (추천안), 업무량 중간~높음(FE 4개)
- FU-3: 토큰 저장 위치, 401 이동 `from` 계약 (현재 `from` 누락)
- Q5(14·17 목록 중복), Q6(패널 순서), Q9(S-02 연락처 칸)
- D-19 확정 시점 (README에 2026-11-24 확정 예정으로 적혀 있음 — 결과 확인)
