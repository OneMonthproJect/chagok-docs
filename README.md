# 차곡 · chagok-docs

정비 이력을 차곡차곡 쌓아, 정비할 때를 알려주는 정비소용 예약 CRM.

차곡은 소규모 정비소를 위한 예약 CRM으로, 예약 일정과 고객·차량·정비 이력을 통합 관리하고, 축적된 정비 기록을 활용해 재점검 시기가 된 고객의 재예약을 지원하는 서비스입니다. 예약 관리가 기본 기능이고, 정비 이력 기반 재방문 관리가 차별화 기능입니다. 고객은 아무것도 설치하거나 입력하지 않습니다.

부트캠프 팀 프로젝트 · **MVP = P0 + P1** · 우선순위는 **기능 수보다 완성도**

## 레포 3개

| 레포 | 담는 것 | 원본인 것 |
|---|---|---|
| **`chagok-docs`** (이 레포) | 기획 문서 00~13, 협업 규칙, 코드 구조 규칙, 공용 AI 설정(규칙·스킬·에이전트) | 기준 문서 · `CONTRIBUTING.md` · `CONVENTIONS.md` · `.claude/rules·skills·agents` |
| `chagok-backend` | Spring Boot API, Flyway 마이그레이션·시드 | 백엔드 코드 |
| `chagok-frontend` | React 화면, 디자인 자료(`design/` — v3.0 화면·프로토타입·디자인 변경 기록) | 프론트 코드 · 디자인 자료 (기획·정책·API는 이 레포가 원본) |

**원본은 한 곳에만 둡니다.** 두 코드 레포는 이 레포의 문서와 규칙을 가리키기만 하고 복사해 커밋하지 않습니다. 코드 레포에서 쓰는 AI 스킬·에이전트·규칙은 `scripts/sync-claude.sh`로 복사해 쓰고, 그 복사본은 커밋되지 않습니다.

## 작업 폴더

세 레포를 한 폴더 안에 나란히 clone합니다. 코드 레포의 설정과 스크립트가 `../chagok-docs`를 기준으로 동작합니다.

```text
chagok/                  ← 내 PC의 작업 폴더 (레포 아님)
├── chagok-docs/
├── chagok-backend/
└── chagok-frontend/
```

```bash
mkdir chagok && cd chagok
git clone https://github.com/OneMonthproJect/chagok-docs.git
bash chagok-docs/scripts/setup-workspace.sh OneMonthproJect   # 나머지 두 레포 clone + develop 전환 + AI 설정 복사
```

## 지금 단계

**구현** — M1 설계 확정(2026-11-23, chagok-docs#46)과 M2 통합 검증(2026-11-26, 세 레포 태그 `v0.5-m2-integration`)을 통과했습니다. P0-나머지 구현 이슈는 2026-11-27 모두 닫혔고, P1 구현 이슈는 아직 없습니다. M2 이후 순서는 chagok-docs#192 (C)안으로 정했습니다. 지금은 마일스톤이 아닌 **V2 기준 P0 통합검증**(12 8장)을 하고, 그 통과 뒤 P1을 시작합니다. 이 검증을 M3라고 부르지 않으며, 아래 표의 통과 조건은 00 8장 그대로입니다(M3 = P0·P1 전부).

명세를 바꾸는 절차는 CONTRIBUTING 7장을 봅니다.

| 마일스톤 | 통과 조건 | 날짜 | 담당 |
|---|---|---|---|
| M1 설계 확정 | 정비 항목 6개 개월·km 주기표, ERD·API 명세 확정 | 2026-11-23 통과 | |
| M2 통합 검증 | P0-핵심 순환이 백엔드·프론트 `develop`에서 끝까지 시연됨 | 2026-11-26 통과 | |
| M3 MVP 검증 | P0·P1 전부 완료 정의 충족, 주기 계산·격리 테스트 통과, 빈 DB에서 시나리오 A·B·격리 시연. P2는 이번 프로젝트에서 착수하지 않음(D-70) | | |
| M4 기능 동결 | 기능 동결. 완료 정의를 충족한 기능만 시연 | | |
| M5 최종 시연 | 다른 팀원 환경에서 시나리오 A·B 시연 | | |

> 2026-11-23 단계 이름을 바꿨습니다(옛 이름: 관문 1 · 중간 점검 · MVP 점검 · 관문 2 · 발표). 통과 조건은 그대로이고, 릴리스 태그도 `v0.1-m1-design` · `v0.5-m2-integration` · `v0.8-m3-mvp` · `v0.9-m4-freeze` · `v1.0-m5-demo`로 정했습니다. 대응은 `docs/13_changelog` 2026-11-23 행.

## 이 레포의 구조

```text
chagok-docs/
├── docs/            기획·설계 문서 (00~13, etc/)
├── .github/         문서·결정 이슈 템플릿, PR 템플릿, 자동 검사, 라벨, CODEOWNERS
├── .claude/
│   ├── settings.json   이 레포에서 쓰는 AI 권한 설정
│   ├── rules/          AI 공용 규칙 (source-of-truth.md, ai-rules.md)  ← 세 레포 공용 원본
│   ├── skills/         스킬 8개                                       ← 세 레포 공용 원본
│   └── agents/         에이전트 4개                                    ← 세 레포 공용 원본
├── scripts/         라벨 생성, 작업 폴더 준비, AI 설정 복사
├── CONTRIBUTING.md  협업 규칙 (세 레포 공통: 브랜치·이슈·커밋·PR·릴리스·문서 동기화)
├── CONVENTIONS.md   코드 구조 규칙 (백엔드·프론트 공통)
└── CLAUDE.md        이 레포에서 AI로 작업할 때
```

## 문서

| 구분 | 문서 |
|---|---|
| 기준 문서 | 00 PRD · 04 기능명세서 · 07 ERD · 08 API |
| 계속 수정 | 12 백로그 · 13 변경 이력 |
| 나머지 | 01 문제 정의 · 02 흐름 · 03 요구사항 · 05 정책 · 06 권한 · 09 화면 · 10 연결표 · 11 아키텍처 · etc/ |
| 개발 기록 (etc/) | TEST 테스트명세서(실행 결과·통합검증) · DEV_REVIEW_CodeRabbit · DEV_REVIEW_트러블슈팅 · AI_USAGE(하루 단위 통합) |

문서 간 ID(기능 F-xx, 화면 S-xx, API 번호, 테이블명)는 00·04·07·08을 기준으로 맞춥니다. 처음 보는 팀원은 `docs/etc/GUIDE_레포구조_협업규칙_AI스킬안내.md`부터 읽습니다.

## 작업할 때마다

```bash
git switch develop
git pull
git switch -c docs/#이슈번호-short-name     # 설정·스킬은 chore/
# 작업 → 커밋 → push → GitHub에서 develop으로 PR (본문 첫 줄 Closes #이슈번호)
```

코드 레포 쪽 흐름은 `CONTRIBUTING.md`, 코드 구조는 `CONVENTIONS.md`, AI로 작업할 때는 각 레포의 `CLAUDE.md`와 `.claude/rules/ai-rules.md`를 봅니다.

## 팀

| 역할 | 이름 | 맡는 일 |
|---|---|---|
| PM | 김예린(paaaraaaeaaa) — 서브 도메인관리, 백엔드 | 범위·마일스톤 진행, M2 통합 검증·M3 MVP 검증 진행, M5 최종 시연 흐름 |
| 도메인관리 | 최은정(eunjung01230) — 서브 형상관리·서브 DB관리, 프론트 | 정비 항목·주기표, 주기 계산 규칙 검증 |
| DB관리 | 이재성(godgeul-glitch) — 프론트 | ERD, Flyway 마이그레이션, 시드 데이터 |
| DB관리 | 이영주(softy20) — 백엔드 | ERD, Flyway 마이그레이션, 시드 데이터 |
| 형상관리 | 김동윤(dyk816) — 백엔드 | Organization·레포 3개, 브랜치 전략, 커밋 규칙, PR 리뷰·머지 |
