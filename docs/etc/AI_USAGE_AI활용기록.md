# AI 활용 기록

> AI 사용 내용·범위

상태: 작성 예정
근거: 개발 중 채움. 칸: | 날짜 | 이슈(레포#번호) | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |

| 날짜 | 이슈(레포#번호) | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |
|---|---|---|---|---|
| 2026-11-22 | 없음 (초기 저장소 구성) | Claude Code (스킬·에이전트 없음) | 초기 ZIP 3개 검사(경로 이탈·민감정보·Git 추적 목록 = ZIP 목록), chagok-docs 한글 파일명 문서 19개 누락 발견·복원, 세 레포 Git 초기화·GitHub 저장소 생성·main/develop Push, 라벨 생성, CI 결과 확인 | 실행 계획 승인, 기본 브랜치 `main` 유지 결정, 라벨 생성 시 기존 라벨 덮어쓰기 금지(`--force` 미사용) 지시 |
| 2026-11-22 | chagok-docs#1, chagok-backend#1, chagok-frontend#1 | Claude Code (스킬·에이전트 없음) | D-49 문서 수정(CONTRIBUTING·GUIDE·00·13), `issue-close` 워크플로 작성, pr-check에 PR 제목·릴리스 PR 닫는 키워드 검사 추가, PR 템플릿 안내 주석 수정, 로컬 시뮬레이션 20건 검증, PR 3개 생성 | 기본 브랜치 `main` 유지와 PR 흐름·CodeRabbit 운영 유지 결정, develop 머지 시 `done-verified` 조건부 자동 Close 방식 지정, 자동 브랜치 삭제 끔, Squash 커밋 = PR 제목, 릴리스 PR은 `Refs #`만 쓰도록 규칙 추가 |
| 2026-11-22 | chagok-docs#1 | Claude Code (스킬·에이전트 없음) | `chagok-release-check`·`chagok-pr-review` 스킬 수정안을 패치 파일로 작성(`.claude` 폴더 편집 제한) | 패치를 직접 적용하고 적용 결과 확인 후 커밋하도록 지시 |
| 2026-11-22 | chagok-docs#1, chagok-backend#1, chagok-frontend#1 | Claude Code (스킬·에이전트 없음) | 초기 PR 템플릿의 AI 표기 체크 문구가 pr-check AI 검사에 오탐되는 문제 발견·수정, 실제 정규식으로 수정 전 1줄 → 수정 후 0줄, 실제 AI 표기 6/6 검출 확인 | 별도 이슈 대신 D-49 작업에 포함하도록 결정, AI 공동 작성자 표기 금지 정책 유지 지시 |
| 2026-11-22 | 없음 (팀 공지) | Claude Code (스킬·에이전트 없음) | GitHub 초기 설정·D-49 팀 공지 초안 작성 | 없음 (초안 그대로 사용) |
| 2026-11-22 | chagok-docs#1, chagok-backend#1, chagok-frontend#1 | Claude Code (스킬·에이전트 없음) | D-49 PR #2 3건 최종 점검(상태·CI·충돌·범위·워크플로 동일성·키워드), `done-verified` 부착·Squash 머지, issue-close 실제 동작 확인(세 레포 Issue #1 자동 종료), 성공 run 재실행으로 중복 실행 안전성 확인 | 세 PR 완료 정의를 직접 확인하고 머지 전 라벨 부착 결정, AI_USAGE PR #4 보류 결정, 재실행 검증 지시 |
| 2026-11-22 | chagok-docs#5 | Claude Code (스킬·에이전트 없음) | 초기 CI 기준 보고서 작성: Actions 실행·아티팩트(JUnit XML)·로컬 빌드(`./gradlew build`, `npm ci`·lint·tsc·build·audit) 결과 수집, 상태 표기 구분, 후속 조치 13건 정리, 이슈 #5·PR #6 생성 | 이슈·PR 생성 승인, PR #6 검토 후 머지 지시 |
| 2026-11-22 | 없음 (릴리스 PR chagok-docs#7, chagok-backend#3, chagok-frontend#3) | chagok-release-check (스킬) | 초기 협업 환경 기준판 릴리스 점검(main…develop 비교, 열린 이슈·키워드 확인), 릴리스 PR 3개 생성·교차 링크, main 머지, main CI·릴리스 경로 pr-check·issue-close 미실행 확인 | 머지 방식을 붙여 넣은 지시의 Squash 대신 CONTRIBUTING 기준 Merge commit으로 결정, main 머지 승인, 릴리스 태그 보류 결정 |
| 2026-11-22 | chagok-docs#8 | Claude Code (스킬·에이전트 없음) | CI 기준 보고서에 초기 릴리스 결과 반영(H장 신설, 릴리스 경로 검증 상태 갱신, CodeRabbit 미실행 기록), 이슈 #8·PR #9 생성 | 보고서 갱신 지시, PR #9 검토 후 머지 지시 |
| 2026-11-22 | chagok-docs#3, chagok-docs#10 | Claude Code (스킬·에이전트 없음) | AI_USAGE PR #4 머지 가능 여부 재확인·머지(issue-close로 #3 종료 확인), 이 세션 AI 사용 기록 작성, 이슈 #10·PR 생성 | PR #4 기록 직접 검토 후 머지 지시, 이 기록 추가 지시 (머지 전 담당자 확인) |
