# 04 Claude 스킬·에이전트 사용안내

> 기준: 2026-11-24, chagok-docs develop `cf9ef3f`의 `.claude/` 트리. 규칙의 원본은 `.claude/rules/ai-rules.md`(작업 등급 L0~L3, 작업 절차)이고 이 문서는 요약이다. 스킬·에이전트를 쓰기 전 해당 `SKILL.md`·에이전트 파일을 읽는다.

## 1. 스킬과 에이전트의 차이

| | 스킬 (`.claude/skills/<이름>/SKILL.md`) | 에이전트 (`.claude/agents/<이름>.md`) |
|---|---|---|
| 무엇 | "어떻게 하는가" 절차 원본 | 스킬을 싣고 **별도 맥락·최소 권한**으로 일을 맡아 결과만 돌려주는 담당자 |
| 쓰기 | 메인 대화가 직접 파일을 고칠 수 있음 | `chagok-seed-builder`(시드 파일만) 외에는 **읽기 전용** |
| 부르는 법 | "chagok-issue-coder로 #17 구현해줘" | "chagok-pr-reviewer 에이전트로 이 브랜치 점검해줘" |

## 2. 설치된 스킬 8개 (docs develop에 실제 있음)

| 스킬 | 목적 · 언제 | 주로 쓰는 사람 | 레포 |
|---|---|---|---|
| `chagok-scope-guard` | 새 기능·범위 추가 의견 판정 (진행/쪼개기/결정/보류/거절) | PM 김예린 | docs |
| `chagok-issue-writer` | 기능 ID로 이슈 제목·본문·라벨·마일스톤 만들기 | 형상관리 김동윤·PM | docs |
| `chagok-issue-coder` | 이슈 구현 (CONVENTIONS·완료 정의, 브랜치·커밋·PR 본문) | 각 구현자 | backend·frontend |
| `chagok-bug-fix` | 명세와 다른 동작 재현·최소 수정·재발 방지 테스트 | 각 구현자 | backend·frontend |
| `chagok-pr-review` | develop 대상 PR 리뷰, 작성자 자가 점검 | 확인하는 팀원·작성자 | 세 레포 |
| `chagok-spec-sync` | 명세 변경 영향(A), 문서·코드 대조(B), API 계약 점검(C) | 도메인 최은정·담당 | 세 레포 |
| `chagok-seed-data` | 시연 시드(`db/seed/demo_seed.sql`) 작성·수정 | DB관리 이영주·이재성 | backend |
| `chagok-release-check` | develop → main 릴리스 전 세 레포 점검 | 형상관리 김동윤 | 세 레포 |

흐름: scope-guard → issue-writer → issue-coder / bug-fix → pr-review → (spec-sync C · seed-data) → release-check

## 3. 설치된 에이전트 4개

| 에이전트 | 맡기는 때 | 싣는 스킬 | 쓰기 |
|---|---|---|---|
| `chagok-contract-checker` | diff에 Controller·DTO·ErrorCode·`api.ts`·`types.ts`·`mocks/`가 있을 때, FE·BE 연결 직후 | spec-sync (C) | 없음 |
| `chagok-pr-reviewer` | **L2·L3 PR을 올리기 직전 필수**, L1 선택 | pr-review | 없음 |
| `chagok-scope-keeper` | 12 백로그에 없는 기능, 지금 단계 밖 이슈를 만들기 전 | scope-guard | 없음 |
| `chagok-seed-builder` | 시드 작성·수정, M2·M3·M5 검증 전 | seed-data | `db/seed/demo_seed.sql`만 |

## 4. 없는 것 (사용 가능하다고 안내하지 않음)

- **`chagok-branch-audit`**: 스킬 파일이 없다. chagok-docs#72(`결정`)에서 판정 기준을 정한 뒤 만든다. 지금은 부르지 않는다.
- **`.claude/settings.json` ask 보강**(브랜치 삭제·`gh issue close`·`gh api` 쓰기 등): chagok-docs#73 미완료. 현재 확인을 묻는 것은 `git commit·push·reset --hard·clean·rebase·tag`, `gh pr create·merge·review·comment`, `gh issue create·comment`, `gh release create`뿐이다. 나머지는 지시문으로만 막혀 있다.

## 5. 동기화 (코드 레포)

```bash
cd chagok-docs && git switch develop && git pull --ff-only origin develop && cd ..
cd chagok-backend  && bash ../chagok-docs/scripts/sync-claude.sh   # frontend도 같음
cat .claude/.synced-from                                          # 예: cf9ef3f (develop)
```
- 코드 레포의 `.claude/rules·skills·agents`는 복사본(Git 제외). **복사본을 고치지 말고 docs에서 고친다.**
- `.claude/settings.json`은 레포마다 커밋된 파일이다(동기화 대상 아님).
- 스킬·규칙이 바뀌었다는 공지를 받으면 다시 동기화한다.

## 6. 작업 등급별로 무엇을 부르나 (ai-rules 요약)

| 등급 | 예 | 스킬 | 에이전트 |
|---|---|---|---|
| L0 | 오타·주석 | 없음 | 없음 |
| L1 | 화면 문구, README | `issue-coder`·`bug-fix` (해당 시) | `pr-reviewer` 선택 |
| L2 | Controller·DTO·ErrorCode·`api.ts`·`types.ts`·`mocks/`·`cycle`·Entity·Service 업무 규칙 | `issue-coder` (+ 명세 변경 시 `spec-sync`) | `contract-checker`(API 건드리면), `pr-reviewer` **필수** |
| L3 | `db/migration`·`db/seed`, `global/auth`·`SecurityConfig`, `getOwned`·`shopId` 조건, ErrorCode, `.github/` | L2 + 시드면 `seed-data` | L2 + 담당 리뷰(DB는 DB관리, CI·settings는 형상관리) |

P0-핵심 기능 이슈는 대부분 **L2**, 2번(account, `SecurityConfig` 공개 경로)·격리 조건이 있는 BE 이슈는 **L3**다.

## 7. 부르는 예 (자연어)

```text
chagok-backend#<번호> 이슈를 chagok-issue-coder로 구현해줘. 먼저 계획(범위·파일·테스트·위험)을 보여 주고 내가 승인하면 구현해. 커밋·push는 내가 확인한 뒤에.
```
```text
PR 올리기 전에 chagok-contract-checker로 08과 내 DTO·api.ts를 대조하고, chagok-pr-reviewer로 이 브랜치를 점검해줘. 실행한 테스트와 미검증을 나눠서.
```
```text
chagok-spec-sync 모드 B로 S-06 차량 추가(F-CUS-03)가 04·08·09·12에서 어떻게 적혀 있는지 대조해줘. 문서는 고치지 말고 차이만.
```

## 8. 주의

- AI의 "완료·통과"는 실제 빌드·테스트 결과가 있을 때만 인정한다(D-48). SKIPPED는 통과가 아니다.
- 커밋·PR에 AI 공동 작성자 표기(`Co-authored-by: Claude`, `noreply@anthropic.com`, "Generated with Claude Code")를 넣지 않는다 — pr-check가 막는다.
- AI 사용은 PR 본문 「AI 사용」 칸에 한 줄로 남기고, docs `AI_USAGE`에는 통합 담당이 하루 단위로 모은다(chagok-docs#60). PR이 없는 AI 작업의 기록 위치는 #74에서 결정 중.
- `.env`·`secrets/`·키 파일은 AI가 읽지 않는다(settings deny).
- 에이전트 결과는 제안이다. 고칠지·머지할지는 사람이 정한다.
