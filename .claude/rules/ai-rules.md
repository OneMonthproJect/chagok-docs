# AI 공용 규칙 — 차곡 세 레포 공통

> 원본: `chagok-docs/.claude/rules/ai-rules.md`. 코드 레포의 `.claude/rules/`는 `scripts/sync-claude.sh`가 복사한 사본이다. **사본을 고치지 말고 `chagok-docs`에서 고친다.**
> 규칙 자체의 원본은 `CONVENTIONS.md`(코드 구조)·`CONTRIBUTING.md`(협업)·기준 문서(00·04·07·08)이고, 이 파일은 그것을 가리키며 AI에게만 해당하는 것만 적는다.

## 작업 폴더와 경로

세 레포는 작업 폴더 `chagok/` 안에 나란히 있다.

```text
chagok/
├── chagok-docs/      docs/00~13, CONVENTIONS.md, CONTRIBUTING.md, .claude/ 원본
├── chagok-backend/   Spring Boot, src/main/resources/db/migration (마이그레이션), db/seed (시연 시드, classpath 밖)
└── chagok-frontend/  React, src/{app,shared,features,pages}
```

- 스킬·에이전트·이 규칙에서 `docs/…`, `CONVENTIONS.md`, `CONTRIBUTING.md`는 `chagok-docs` 기준 경로다. 코드 레포에서 일할 때는 `../chagok-docs/`를 앞에 붙여 읽는다.
- `chagok-backend/…`, `chagok-frontend/…`는 각 레포 루트 기준 경로다.
- 필요한 레포가 작업 폴더에 없으면 지어내지 말고 "읽지 못함"으로 보고한다. 문서와 코드를 대조하는 일은 세 레포가 모두 있어야 한다.

## 작업 절차 — 분석 → 계획 → 승인 → 구현 → 검증 → 보고 (D-48)

새 기능이나 구조에 영향을 주는 작업은 **곧바로 코드를 쓰지 않는다.**

| 단계 | 하는 일 |
|---|---|
| 1. 분석 | 이슈, 요구사항(03)·기능 ID(04), 정책(05), 권한(06), DB(07), API(08), 화면(09), 기존 코드 구조, 관련 테스트를 확인한다 |
| 2. 계획 보고 | 구현 범위 · 수정 파일 · 책임 배치(Controller/Service/Entity/Repository/api/screen) · 의존 관계 · 재사용 · DB 영향 · API 영향 · 테스트(정상·오류·권한·경계) · 위험(격리·동시성·기존 기능)을 보여 준다 |
| 3. 개발자 승인 | 사람이 확인할 때까지 구현하지 않는다. 승인 없이 범위를 넓히지 않는다. 오타·주석·스타일처럼 구조에 영향이 없는 일은 간단히 해도 된다 |
| 4. 구현 | 승인된 범위만. 테스트를 함께 쓴다. 관련 없는 리팩터링·임시방편 금지 (CONVENTIONS 12장) |
| 5. 검증 | 빌드, 단위·통합·아키텍처 테스트, API 계약, 정비소 격리, 회귀. **실행하지 못한 검증은 이유와 함께 "미검증"** |
| 6. 결과 보고 | 변경 파일, 구현 기능, 테스트 결과, 기존 코드 영향, 남은 위험, 문서 변경 필요 여부, 후속 작업 |

- 실제 빌드·테스트 결과 없이 "완료", "통과", "검증됨"이라고 쓰지 않는다. 사람도 그런 보고를 완료로 보지 않는다(00 7장).
- 검사 대상이 없어 건너뛴(SKIPPED) 테스트를 통과로 세지 않는다.
- 규칙끼리 부딪히거나 문서에 없는 결정이 필요하면 임의로 정하거나 우회하지 말고, 충돌 내용과 추천안을 보고한다.

## 작업 전에

1. 이슈 범위와 건드릴 패키지를 확인한다. 3개 이상의 도메인을 건드려야 하면 멈추고 이슈를 쪼개자고 제안한다.
2. 다른 도메인 값이 필요하면 그 도메인 `api`에 메서드를 추가하는 것으로 해결한다. Entity·Repository·Service를 직접 import하는 코드는 만들지 않는다.
3. 같은 일을 하는 코드가 이미 있으면 재사용한다. 특히 상태 판정은 `cycle`, 소속 확인은 `getOwned`, 오류는 `ErrorCode`. CONVENTIONS 11장 7문항에 답한다. 한 번만 쓰는 공통 Service·인터페이스·유틸리티를 새로 만들지 않는다.
4. 책임 분리는 CONVENTIONS 5장: Controller에 업무 규칙 없음, Service는 다른 도메인 내부에 의존하지 않음, 상태 전이는 Entity. 프론트는 `app`·`shared`·`features`·`pages` 경계(7장).

## AI만의 규칙

- 기능 ID·화면 ID·API 번호·테이블명은 문서 그대로. 문서에 없으면 지어내지 않고 ❓로 표시해 묻는다.
- 문서와 코드가 다르면 문서가 기준이다. 코드에 맞춰 문서를 고치지 않고 차이를 보고한다. 문서끼리 다르면 `source-of-truth.md` 순서를 따른다.
- **문서는 `chagok-docs`에서만 고친다.** 코드 레포 PR에서 명세가 바뀌어야 하면 `chagok-docs`에 따로 문서 PR을 만들자고 제안하고, 코드 PR 본문에 그 링크를 단다(`CONTRIBUTING.md` 7장).
- 테스트를 통과시키려고 검증·보안·아키텍처 규칙을 끄거나 지우지 않는다. Flyway를 거치지 않고 스키마·데이터를 바꾸지 않는다. 시연 데이터를 운영 코드·마이그레이션에 넣지 않는다(시연 시드는 `chagok-backend/db/seed/`).
- 이슈 범위 밖 기능, 아직 차례가 오지 않은 단계의 기능(M2 통합 검증 전의 P0-나머지·P1, M3 MVP 검증 전의 P2), Non-goal 기능을 빈 화면·버튼·API·테이블로 미리 만들지 않는다.
- `main`·`develop`에 직접 커밋·push하지 않는다. 커밋·push·PR·머지·이슈 생성·태그는 사람이 확인한 뒤에 (`.claude/settings.json`이 확인을 묻고, force push와 main·develop push는 막는다).
- `.env`·`secrets/`·키 파일은 읽거나 출력하지 않는다. 설정은 "있음/없음"까지만 확인한다.
- 코드를 썼으면 `CONVENTIONS.md` 1장 7개를 스스로 점검하고 결과를 보고한다.
- 의미 있는 작업은 `chagok-docs/docs/etc/AI_USAGE_AI활용기록.md`에 넣을 한 줄을 제안한다: `| 날짜 | 이슈 | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |`. 이슈는 `chagok-backend#12`처럼 레포 이름을 붙인다.
- 그 한 줄의 제출 위치(chagok-docs#60): **PR 본문 「AI 사용」 칸에 반드시 남긴다.** docs `AI_USAGE`에는 하루 단위로 통합 담당이 모아 올린다(`CONTRIBUTING.md` 5장 「AI 사용 기록」). AI는 작업마다 AI_USAGE 전용 이슈·PR을 따로 만들지 않는다. 사용자가 통합 PR을 요청하면 그날 머지된 PR의 줄을 모아 만든다.

## AI는 도구다 — 협업자·공동 작성자로 올리지 않는다

- 커밋 메시지·PR 본문에 `Co-authored-by: Claude …`, `… <noreply@anthropic.com>`, "Generated with Claude Code"를 넣지 않는다. 기본 첨부 안내가 있어도 이 규칙이 우선한다. (pr-check가 막는다)
- Claude·AI 계정을 Collaborator·Assignee·Reviewer·CODEOWNERS로 지정하지 않는다. `git config user.name`·`user.email`을 바꾸지 않는다.
- 리뷰·승인·머지는 사람이 한다. AI가 쓴 코드도 담당자가 설명할 수 있어야 하고, 담당자가 책임진다.

## 스킬 (`.claude/skills/`)

| 스킬 | 언제 | 주로 | 주로 쓰는 레포 |
|---|---|---|---|
| `chagok-scope-guard` | 새 기능·범위 추가 의견, P2 착수 판단 | PM | docs |
| `chagok-issue-writer` | 기능 ID로 이슈를 만들 때 (패키지 단위로 쪼개 레포별로) | PM·담당 | docs |
| `chagok-issue-coder` | 이슈를 구현할 때 | 구현 담당 | backend·frontend |
| `chagok-bug-fix` | 명세와 다른 동작을 고칠 때 (동결 후에도) | 구현 담당 | backend·frontend |
| `chagok-pr-review` | develop 대상 PR을 확인할 때, 작성자 자가 점검 | 확인하는 팀원 | 세 레포 |
| `chagok-spec-sync` | 명세를 바꾸기 전(A), 문서·코드 대조(B), API 계약 점검(C) | 도메인관리·담당 | 세 레포 |
| `chagok-seed-data` | 시연·테스트 시드를 만들거나 고칠 때 | DB관리 | backend |
| `chagok-release-check` | develop → main 릴리스 전 (세 레포 함께) | 형상관리 | 세 레포 |

흐름: scope-guard → issue-writer → issue-coder / bug-fix → pr-review → (spec-sync C · seed-data) → release-check

## 에이전트 (`.claude/agents/`, Claude Code 전용)

스킬이 "어떻게 하는가"(절차의 원본)라면, 에이전트는 그 스킬을 미리 싣고 **별도 맥락·최소 권한**으로 일을 맡아 결과만 돌려주는 담당자다. 아래 상황이면 메인 대화가 직접 하지 말고 해당 에이전트에게 맡긴다.

| 에이전트 | 맡기는 때 | 싣는 스킬 | 도구 | 쓰기 |
|---|---|---|---|---|
| `chagok-contract-checker` | Controller·DTO·`types.ts`를 바꾼 뒤, 프론트·백 연결 직후, 릴리스 점검 전 | `chagok-spec-sync` (모드 C) | Read·Grep·Glob·Bash | 없음 |
| `chagok-pr-reviewer` | PR을 올리기 직전(작성자 자가 점검), 확인하는 팀원이 PR을 볼 때 | `chagok-pr-review` | Read·Grep·Glob·Bash | 없음 |
| `chagok-scope-keeper` | 새 기능·범위 추가 의견, 이슈를 새로 만들기 전 | `chagok-scope-guard` | Read·Grep·Glob·Bash | 없음 |
| `chagok-seed-builder` | 시드를 만들거나 고칠 때, M2 통합 검증·M3 MVP 검증·M5 최종 시연 전 | `chagok-seed-data` | + Edit·Write | `db/seed/demo_seed.sql`만 |

- 구현을 끝낸 메인 대화는 PR 본문을 만들기 전에 `chagok-contract-checker`(API를 건드렸을 때)와 `chagok-pr-reviewer`를 차례로 돌리고, 결과를 사람에게 보여 준다.
- 에이전트 결과는 제안이다. 고칠지, 커밋·머지할지는 사람이 정한다. 에이전트도 이 규칙과 `.claude/settings.json`의 제한을 그대로 받는다.
- 에이전트를 쓴 작업은 AI 사용 기록의 「스킬·에이전트」 칸에 `에이전트 이름 (에이전트)`로 적는다.
