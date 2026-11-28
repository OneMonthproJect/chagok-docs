# 트러블슈팅 기록

> 개발 중 실제로 겪은 오류의 증상·원인·해결·검증·재발 방지. 이슈·PR에 근거가 남은 것만 적고, 미해결도 숨기지 않는다.

상태: 작성 중 — 2026-11-28 첫 정리(chagok-docs#210). 중요한 오류를 해결하면 그 PR에서 한 항목을 더한다(작은 오타·화면 문구는 적지 않음).
근거: 각 항목의 「근거」 칸 이슈·PR. 자세한 과정은 링크를 보고, 여기에는 핵심만 둔다.

| ID | 문제 | 영역 | 상태 |
|---|---|---|---|
| TS-01 | 릴리스 PR을 Squash로 머지해 다음 릴리스 PR이 충돌 | Git·릴리스 | 해결 |
| TS-02 | 같은 리뷰 지적을 두 PR이 다르게 고쳐 병합 뒤 develop 빌드 실패 | Git·리뷰 후속 | 해결 |
| TS-03 | JVM 시간대에 따라 DB 시각이 9시간 어긋나고, 그 회귀 테스트가 Gradle 설정 때문에 항상 통과 | 날짜·시간대·테스트 | 해결 |
| TS-04 | 같은 차량의 방문 저장이 겹치면 최근 주행거리가 낮아질 수 있음 | DB·동시성 | 해결 |
| TS-05 | 컨테이너가 `/error`로 넘긴 오류의 상태 코드가 403·500으로 바뀜 | 인증·오류 응답 | 일부 해결 (진행 중) |
| TS-06 | PR 검사·이슈 자동 닫기 정규식의 구멍과 오탐 | CI·협업 설정 | 해결 (후속 결정 대기) |
| TS-07 | Mock 응답이 08 계약과 달라 Mock으로는 통과하고 실서버에서 다르게 동작 | API 계약 | 진행 중 |
| TS-08 | 여러 세션·계정이 같은 작업을 동시에 해 중복 이슈·PR | 협업 | 운영 규칙으로 대응 |
| TS-09 | Windows에서 소문자 드라이브 경로로 `npm test`를 돌리면 모든 테스트 파일 실패 | 로컬 환경 | 우회 방법 확인 |
| TS-10 | 공용 AI 설정 복사 스크립트가 작업 트리를 그대로 복사·폴더를 통째로 덮어씀 | Claude 공통 설정 | 진행 중 |

## TS-01 릴리스 PR을 Squash로 머지해 다음 릴리스 PR이 충돌

| 항목 | 내용 |
|---|---|
| 증상 | frontend 릴리스 PR #97(develop → main)이 CONFLICTING. 22개 파일이 충돌로 잡혔지만 내용 차이는 없었다 |
| 원인 | 지난 릴리스 #81을 Merge commit이 아니라 Squash로 머지했다(CONTRIBUTING 6장은 Merge commit). develop 커밋이 main의 조상이 되지 않아 merge-base가 옛 커밋에 머물렀다 |
| 해결 | develop에서 `git merge -s ours origin/main`으로 main 이력만 연결(파일 변경 0) — frontend#99, PR #100을 Merge commit으로 머지 |
| 검증 | 머지 전 시뮬레이션과 머지 후 #97 MERGEABLE 확인. `origin/main` 트리 = develop `f1bb1fa` 트리 |
| 재발 방지 | 릴리스 PR은 Merge commit만(Squash 금지)을 형상관리자에게 재확인. main·develop 직접 push·force push 없이 develop 쪽 PR로만 고친다 |
| 근거 | chagok-frontend#99 · #100 · #97 |
| 상태 | 해결 (frontend#99 이슈는 열린 채 — 닫기만 남음) |

## TS-02 같은 리뷰 지적을 두 PR이 다르게 고쳐 병합 뒤 develop 빌드 실패

| 항목 | 내용 |
|---|---|
| 증상 | backend PR #87 머지 직후 develop `backend-ci` 컴파일 오류(`CustomerService is not abstract and does not override … getOwnedVehicleForVisit`) |
| 원인 | 릴리스 #66 CodeRabbit의 같은 지적(주행거리 경합)을 develop의 다른 커밋(`ecc95da`, 첫 조회에서 행 잠금)과 #87(`entityManager.refresh(…, PESSIMISTIC_WRITE)`)이 서로 다르게 고쳤다. 충돌을 풀면서 인터페이스는 한쪽, 구현은 다른 쪽이 남았다 |
| 해결 | 잠금 방식을 "첫 조회에서 잠금" 하나로 통일하고 중복된 `refresh`·생성자 인자 제거 — backend PR #88 |
| 검증 | 로컬 `./gradlew build` 통과, 새 동시 저장 시험(`CustomerWriterTransactionDbTest`)은 CI db-test로 확인 |
| 재발 방지 | 같은 지적은 한 PR이 맡는다. 충돌을 푼 뒤에는 develop을 합친 상태로 빌드한 다음 push한다 |
| 근거 | chagok-backend#66 · #87 · #88 |
| 상태 | 해결 |

## TS-03 JVM 시간대에 따라 DB 시각이 9시간 어긋나고, 그 회귀 테스트가 항상 통과

| 항목 | 내용 |
|---|---|
| 증상 | ① UTC 서버(CI 등)에서 시드가 SQL로 넣은 예약 10:00이 앱에서 01:00으로 읽힘. 한국 시간 PC에서는 드러나지 않음 ② 이후 CI db-test에서 저장한 날짜가 하루 밀리는 실패가 나 테스트 작업에 `user.timezone=Asia/Seoul`을 걸었더니, ①의 회귀 테스트가 어떤 코드에서도 통과하게 됨 |
| 원인 | ① 앱은 `Clock`·`jdbc.time_zone`·`serverTimezone`을 Asia/Seoul로 가정하는데 JVM 기본 시간대는 환경에 맡겨져 있었다 ② 테스트 JVM 자체를 Asia/Seoul로 띄우면 "UTC JVM에서도 맞는가"를 검사할 수 없다 |
| 해결 | ① 앱 시작 때 JVM 기본 시간대를 Asia/Seoul로 고정(backend#65) ② `JvmTimeZoneDbTest`만 UTC JVM에서 돌리는 `tzTest` 작업 분리, `dbTest` 뒤 자동 실행(릴리스 #114 CodeRabbit 지적 → PR #122) |
| 검증 | V2 기준 P0 통합검증에서 dbTest 227 + tzTest(UTC) 2 통과(TEST 7.1) |
| 재발 방지 | 시간대 관련 테스트를 통과시키려고 테스트 JVM 설정을 바꾸지 않는다(CONVENTIONS 12장). 시각은 `Clock` 주입 |
| 근거 | chagok-backend#65 · #114 · #122 · #115(본문 AI 기록) |
| 상태 | 해결 |

## TS-04 같은 차량의 방문 저장이 겹치면 최근 주행거리가 낮아질 수 있음

| 항목 | 내용 |
|---|---|
| 증상 | (코드 검토로 발견) 같은 차량에 두 방문 저장이 동시에 오면 60,000 다음에 50,000이 늦게 저장돼 최근 주행거리가 내려갈 수 있다 |
| 원인 | 방문 저장이 차량을 먼저 읽고 나중에 "더 클 때만 갱신"하는데, 그 사이 잠금·버전 검사가 없었다 |
| 해결 | 방문 저장에서 차량 행을 첫 조회부터 잠금(`findForUpdateByIdAndShopId`) — 스키마 변경 없음 |
| 검증 | 한 저장이 행을 잠그면 다른 저장이 기다리고, 끝난 뒤에도 주행거리가 내려가지 않는 DB 테스트. 실제 다중 스레드 부하 시험은 하지 않음 |
| 재발 방지 | 「더 클 때만 갱신」 같은 읽기-비교-쓰기는 잠금 또는 `@Version`으로 감싼다 |
| 근거 | chagok-backend#66 (CodeRabbit Major) · #87 · #88 |
| 상태 | 해결 |

## TS-05 컨테이너가 `/error`로 넘긴 오류의 상태 코드가 바뀜

| 항목 | 내용 |
|---|---|
| 증상 | 인증된 요청에 `Accept: application/xml` → 406이어야 할 응답이 403 `FORBIDDEN`. Controller·Service의 `AccessDeniedException`·`ResponseStatusException`은 500 |
| 원인 | 컨테이너가 오류를 `/error`로 다시 보내는데 `anyRequest().denyAll()`이 그 경로까지 막았다. 공통 처리기는 `Exception` 하나로 받아 500으로 만들었다 |
| 해결 | 406·`AccessDeniedException`·`ResponseStatusException` 상태 보존(backend PR #124, 08 0.3 문서 chagok-docs#186). `/error` 디스패치 허용과 실제 서블릿 컨테이너 테스트는 PR #130(L3, 리뷰 대기), 06·CONVENTIONS 예외 문구는 chagok-docs#191 |
| 검증 | #124 머지 분은 CI 통과. `/error` 부분은 #130 머지 후 `EndpointGuardTest` 회귀와 RANDOM_PORT 테스트로 확인 예정 |
| 재발 방지 | 기본 거부 원칙(06 5장)을 약하게 하지 않고 ERROR 디스패치만 허용하는 방식으로 연다 |
| 근거 | chagok-backend#17 · #124 · #130, chagok-docs#186 · #191 |
| 상태 | 일부 해결 — `/error` 디스패치는 진행 중 |

## TS-06 PR 검사·이슈 자동 닫기 정규식의 구멍과 오탐

| 항목 | 내용 |
|---|---|
| 증상 | ① HTML 주석 안의 `Refs #n`, 닫히지 않은 `<!--` 뒤의 참조로 이슈 연결 검사 통과 ② `Prefix #12`에서 `fix #12`를 키워드로 인식 ③ `done-verified` PR 본문의 `hotfix #12`로 issue-close가 이슈를 닫을 수 있음 ④ 코드 펜스·인라인 코드 안의 `<!--`를 주석으로 처리해 그 뒤 정상 참조를 놓침 |
| 원인 | 세 레포 `pr-check`·`issue-close`가 주석 제거와 키워드 정규식을 따로 가졌고, 단어 경계가 없었다 |
| 해결 | 주석 제거 통일(chagok-docs#162), 닫히지 않은 주석·키워드 경계(#169), `close_re` 경계(#173), 코드 펜스 처리(backend #122·frontend #91) — 세 레포 같은 식 |
| 검증 | #169: 입력 21건·PR 본문 205건 회귀, #173: 입력 23건·PR 214건·커밋 387건 회귀(옛 식과 결과가 달라진 것은 의도한 경우뿐) |
| 재발 방지 | 워크플로는 세 레포를 같은 PR 묶음으로 고치고, 옛 PR 본문·커밋으로 회귀를 돌린다(L3, 형상관리 리뷰) |
| 근거 | chagok-docs#162 · #169 · #173, chagok-backend#116 · #120 · #122, chagok-frontend#78 · #85 · #91 |
| 상태 | 해결. chagok-docs#173은 머지 후 형상관리 결정·`done-verified` 대기로 열려 있음 |

## TS-07 Mock 응답이 08 계약과 달라 Mock으로는 통과

| 항목 | 내용 |
|---|---|
| 증상 | 화면 테스트·Mock 확인은 통과했지만 실서버와 응답이 달랐다(목록 마스킹, 04 예시 모양, 22·23·16 확인 순서, 39 범위 검사, 12 구분 불일치 등 7건) |
| 원인 | Mock을 08 확정 전·백엔드 구현 전에 만들고, 08이 바뀐 뒤 따라가지 않았다 |
| 해결 | chagok-docs#195 계약 점검에서 찾아 frontend#106으로 모아 수정(PR #107 머지, 16 확인 순서는 PR #108) |
| 검증 | 08 ↔ backend Controller·DTO ↔ frontend `api.ts`·`types.ts`·`mocks/` 대조(chagok-contract-checker) |
| 재발 방지 | 08이 바뀌면 같은 날 Mock도 고친다(CONTRIBUTING 7장). 기능 묶음이 끝날 때 계약 점검(모드 C) |
| 근거 | chagok-frontend#106 · #107 · #108, chagok-docs#195 |
| 상태 | 진행 중 (#108 리뷰 대기) |

## TS-08 여러 세션·계정이 같은 작업을 동시에 함

| 항목 | 내용 |
|---|---|
| 증상 | 같은 문서 변경이 이슈 두 개로 만들어지고(chagok-docs#182·#185), 같은 폴더에서 여러 세션의 미커밋 변경이 한 브랜치에 섞였다 |
| 원인 | 몇 분 전에 읽은 원격 상태로 이슈·PR을 만들었고, 세션들이 한 작업 폴더를 같이 썼다 |
| 해결 | 중복 이슈는 닫고 먼저 머지된 쪽(#184)을 남김. 세션마다 별도 worktree에서 작업 |
| 검증 | — (운영 방식) |
| 재발 방지 | 이슈·브랜치·PR을 만들기 직전에 세 레포의 열린·방금 머지된 이슈·PR과 원격 브랜치 이름을 다시 조회한다. 다른 세션의 브랜치·worktree·미커밋 변경은 건드리지 않는다 |
| 근거 | chagok-docs#182 · #184 · #185 |
| 상태 | 운영 규칙으로 대응 |

## TS-09 Windows 소문자 드라이브 경로에서 `npm test` 전부 실패

| 항목 | 내용 |
|---|---|
| 증상 | `c:\pro_3\…`(VS Code가 여는 소문자 드라이브)에서 `npm test`를 돌리면 모든 테스트 파일이 `Cannot read properties of undefined (reading 'config')`, 테스트 0개 |
| 원인 | 정확한 원인은 확인하지 못함. 작업 경로의 드라이브 문자가 소문자일 때만 재현되고 대문자 경로에서는 통과하므로 코드 문제는 아니다. CI(ubuntu)는 통과 |
| 해결 | Git Bash에서 대문자 경로로 실행: `cd /C/pro_3/ChaGok/chagok-frontend && npm test` |
| 검증 | 2026-11-26 로컬 재현·우회 확인(32 files / 366 tests 통과). lint·build는 영향 없음 |
| 재발 방지 | 로컬 테스트가 전부 0개로 실패하면 코드보다 경로 대소문자를 먼저 본다 |
| 근거 | 로컬 재현 기록(이슈 없음). CI 결과는 각 PR의 frontend-ci |
| 상태 | 우회 방법 확인 (원인 미확인) |

## TS-10 공용 AI 설정 복사 스크립트의 위험

| 항목 | 내용 |
|---|---|
| 증상 | `scripts/sync-claude.sh`가 docs **작업 트리**를 복사해 미커밋·미머지 내용까지 코드 레포에 퍼지고, 사본 폴더를 통째로 지워 개인 파일이 사라질 수 있음 |
| 원인 | 처음 만들 때 한 사람·한 브랜치 사용을 가정했다 |
| 해결 | 승인된 기준(`origin/develop`·지정 커밋)으로만 복사, 읽기 전용 확인, 관리 파일만 교체 — chagok-docs#208 PR B(L3, 리뷰 대기) |
| 검증 | #208 완료 조건의 임시 폴더 시험(같은 버전 무변경·로컬 수정 감지·복구 등) |
| 재발 방지 | 공용 설정은 릴리스된 버전으로만 배포하고 GUIDE의 최신화 절차를 따른다 |
| 근거 | chagok-docs#208 |
| 상태 | 진행 중 |
