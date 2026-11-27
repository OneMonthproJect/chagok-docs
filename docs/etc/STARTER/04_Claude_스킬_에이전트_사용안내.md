# 04 Claude 스킬·에이전트 사용안내

> 기준: 2026-11-24, chagok-docs develop `c81e120`(공용 `.claude/` 원본 `cf9ef3f`, 그 뒤 변경 없음). 규칙의 원본은 `.claude/rules/ai-rules.md`·`CONTRIBUTING.md`·각 `SKILL.md`·에이전트 파일이고, 이 문서는 개발 착수용 **빠른 사용 설명서**다. 세부 정책·전체 명령어는 **[GUIDE 총정리본](../GUIDE_레포구조_협업규칙_AI스킬안내.md)**(이하 GUIDE)에 있다. 두 문서가 다르면 원본 → GUIDE 순으로 확인한다.
> 이후 현황(2026-11-27): 이 문서가 다룬 P0 작업(12 4·5장 이슈)은 모두 끝났다 — M2 통합 검증 통과(2026-11-26, `v0.5-m2-integration`), P0-나머지 구현 이슈 모두 닫힘. 아래는 2026-11-24 착수 당시 기록이다. 지금 단계는 [README](../../../README.md)·[GUIDE](../GUIDE_레포구조_협업규칙_AI스킬안내.md) 「지금 단계」, 규칙은 원본(CONTRIBUTING·`.claude/rules/ai-rules.md`)을 따른다.
> 표기: **확정** / **결정 대기**(정책 아님) / **미구현**(사용 불가) / **미검증**(실행 근거 없음).

## 1. 시작 전 체크리스트

| | 준비 | 확인 |
|---|---|---|
| ☐ | GitHub Organization `OneMonthproJect` 초대 수락 | 세 레포가 보이는지 |
| ☐ | Git + Git Bash, `user.name`·`user.email` = 본인 GitHub | `git --version` |
| ☐ | GitHub CLI 인증 (스킬이 이슈·PR을 조회할 때 필요) | `gh auth status` |
| ☐ | JDK 21 · MySQL 8 (BE) / Node 22 LTS (FE) | [03](03_공통_클론_개발환경.md) |
| ☐ | **Claude Code 설치 + Claude 로그인** — 스크립트가 설치해 주지 않음 | `claude --version` |

GitHub 인증과 Claude 인증은 **별개**다(GUIDE 11장).

## 2. 처음 한 번: 클론 + 설정 (Git Bash, 작업 폴더를 만들 위치에서)

```bash
mkdir -p chagok && cd chagok
git clone https://github.com/OneMonthproJect/chagok-docs.git
bash chagok-docs/scripts/setup-workspace.sh OneMonthproJect
```

스크립트가 하는 일: 빠진 레포(backend·frontend) clone → 세 레포 `develop` 전환 → 두 코드 레포에 `.claude/rules·skills·agents` 복사 + `.claude/.synced-from` 기록. 내가 할 일: Claude Code 설치·로그인, `.env`·DB 준비([03](03_공통_클론_개발환경.md)), 5장 확인.

## 3. 이미 클론한 팀원: 최신화·동기화 — 한 명령 (chagok-docs#208)

작업 폴더(`chagok/`)에서. 작업 중인 레포(작업 브랜치·커밋 안 한 변경·갈라진 develop)는 건드리지 않고 건너뛰며 이유를 알려 준다. `stash`·`reset --hard`·`clean`·브랜치 전환·push·외부 도구 설치는 하지 않는다.

```bash
bash chagok-docs/scripts/update-workspace.sh --check   # 먼저 보기만(읽기 전용, fetch도 안 함)
bash chagok-docs/scripts/update-workspace.sh           # 적용: 안전한 최신화 → AI 설정 동기화 → 외부 도구 확인
```

- PowerShell: `& "C:\Program Files\Git\bin\bash.exe" chagok-docs/scripts/update-workspace.sh`
- 처음 한 번은 docs에 이 스크립트가 있어야 한다: `git -C chagok-docs switch develop && git -C chagok-docs pull --ff-only origin develop`
- **언제**: 형상관리자의 릴리스·배포 공지를 받은 뒤, 지금 작업을 커밋·push하고 Claude 세션을 끝낸 안전한 때. 진행 중인 세션은 기존 설정으로 마무리한다.
- 건너뛴 레포는 화면 안내대로 정리한 뒤 같은 명령을 다시 실행하면 그 레포만 처리된다. `--ff-only`가 안 되는(갈라진) develop은 강제로 맞추지 말고 형상관리자에게 문의한다.

## 4. 동기화가 하는 일

- 코드 레포의 `.claude/rules·skills·agents`는 **복사본**(커밋 안 됨). 고치지 말고 `chagok-docs`에서 고친다. 손으로 고친 사본이 있으면 그 레포를 건너뛰고 알려 준다.
- 배포 기준은 **형상관리자가 승인·릴리스한 docs `origin/main`**. develop에만 있는 변경, 내 docs 브랜치·미커밋 내용은 복사되지 않는다.
- 내용이 같으면 다시 복사하지 않는다. 복사본 폴더의 관리 대상이 아닌 파일과 `~/.claude/` 개인 설정·스킬은 건드리지 않는다.
- `.claude/settings.json`은 레포마다 커밋된 파일이고 **동기화 대상이 아니다**.
- 승인 버전 지정·되돌리기는 `--ref <커밋>`(형상관리자가 공지한 커밋). 옵션·실패 문구·복구는 GUIDE 14장·29장.

## 5. 적용 확인

```bash
bash chagok-docs/scripts/update-workspace.sh --check
```

기대값: 세 레포 `최신`(작업 브랜치면 그 안내), 공용 AI 설정 두 레포 `최신 … (origin/main)`, 개인 폴더 `chagok-*` 경고 없음(있으면 지운다 — 옛 버전이 우선된다). 외부 도구는 없어도 정상(선택).

Claude Code에서: 열려 있던 세션은 끝내고 **새 세션**으로 코드 레포 루트에서 `claude` → 신뢰 확인 수락 → `/chagok` 입력 시 스킬 8개, `/agents`에 에이전트 4개.

결과는 GUIDE 28.3 회신 양식으로 형상관리자에게 보낸다.

## 6. 스킬 8개 · 에이전트 4개 (2026-11-24 실제 원본)

| 스킬 | 언제 | 주로 | 레포 |
|---|---|---|---|
| `chagok-scope-guard` | 새 기능·범위 추가·축소, P1 착수 의견(P2 착수 의견은 거절, D-70) → 진행/쪼개기/결정 이슈/보류/거절 | PM | docs |
| `chagok-issue-writer` | 기능 ID → BE·FE 짝 이슈 초안(생성은 사람) | 형상관리·PM, 도메인(분할 추천) | docs |
| `chagok-issue-coder` | 이슈 구현: 등급·계획 → **승인** → 구현·검증 → PR 본문 | 구현 담당 | backend·frontend |
| `chagok-bug-fix` | 명세와 다른 동작: 재현 → 원인 한 곳 → 최소 수정 + 재발 방지 테스트 | 구현 담당 | backend·frontend |
| `chagok-pr-review` | develop PR 리뷰, 작성자 자가 점검(승인·머지 안 함) | 확인하는 팀원·작성자 | 해당 레포 |
| `chagok-spec-sync` | A 명세 변경 영향 · B 문서·코드 대조 · C API 계약 점검 (보고만) | 도메인관리·담당 | 세 레포 |
| `chagok-seed-data` | 시연 시드 `db/seed/demo_seed.sql` (DB 실행 안 함) | DB관리 | backend |
| `chagok-release-check` | 세 레포 develop → main 릴리스 전 점검 | 형상관리 | 작업 폴더 |

| 에이전트 | 맡기는 때 | 싣는 스킬 | 쓰기 |
|---|---|---|---|
| `chagok-contract-checker` | diff에 Controller·DTO·ErrorCode·`api.ts`·`types.ts`·`mocks/` (PR 전), FE·BE 연결 직후, 릴리스 전 | spec-sync C | 없음 |
| `chagok-pr-reviewer` | **L2·L3 PR 올리기 직전 필수**, L1 선택, L0 안 씀 | pr-review | 없음 (승인·코멘트·머지 안 함) |
| `chagok-scope-keeper` | 12 백로그에 없는 기능, 지금 단계 밖 이슈를 만들기 전 | scope-guard | 없음 |
| `chagok-seed-builder` | 시드 작성·수정, M2·M3·M5 검증 전 | seed-data | `demo_seed.sql`만 (**지시문 제한**, 설정 강제 아님) |

- 스킬 = 절차서(메인 대화), 에이전트 = 스킬을 싣고 별도 맥락·최소 도구로 맡는 보조 작업자(Claude Code 전용). 읽기 전용은 지시문·도구 목록으로 지켜지고, settings.json이 강제하는 것은 deny 패턴(Read 도구의 `.env`류·`secrets/`·`*.pem`, `git push origin main/develop…`·`git push --force/-f…` 형태, `gh issue delete`·`gh api` DELETE)과 커밋·push·PR·머지·리뷰·코멘트·이슈 생성·태그·Release, 브랜치·worktree·stash 삭제, 원격 ref prune, PR·이슈·라벨 상태 변경, `gh api` 쓰기의 확인 요청(ask)이다(#73). 패턴 밖의 push(예: upstream이 develop인 `git push`)는 ask만 받으므로 확인 창에서 대상 브랜치를 보고 거절한다(GUIDE 19.1).
- 에이전트 결과는 제안이다. 사람의 리뷰·승인·머지를 대신하지 않는다.
- claude.ai는 스킬만(형상관리자가 배포하는 `chagok-*.skill`). 에이전트 대신 spec-sync 모드 C·pr-review 스킬을 쓴다(GUIDE 16장).

### 6.1 필요한 것만 부르기 · 토큰 아끼기 (chagok-docs#208)

원본은 `ai-rules.md` 「검증 재사용」·「외부 도구」. 여기는 요약이다.

- **필수 호출은 그대로**: L2·L3 PR 직전 `pr-reviewer`, API·`types.ts`·`mocks/` diff면 `contract-checker`. 그 밖의 작은 일(문구·README·오타)에는 에이전트를 부르지 않는다.
- **검증은 한 번**: 빌드·테스트는 메인 대화가 한 번 돌리고, 에이전트에는 그 결과(커밋 SHA·명령·결과)를 넘겨 다시 돌리지 않게 한다. 같은 커밋의 결과·CI는 재사용하고, 고친 뒤에는 영향 범위만 다시 돌린다. docs 문서만 바꿨으면 앱 빌드·테스트를 돌리지 않는다.
- **요청은 좁게**: 이슈 번호·파일·범위를 처음에 준다. GUIDE·개인 가이드처럼 긴 문서는 "N장만 읽어" 한다. 끝나면 "변경·검증 근거·남은 일만" 보고받는다.
- **오류가 나면**: 같은 명령을 바로 되풀이하지 말고 원인부터. 승인된 범위의 일반 오류는 고치며 계속하고, 범위·정책·보안·데이터 위험이면 멈추고 묻는다.
- **외부 도구(선택)**: 설치하지 않아도 된다. 쓰면 아래 때만. 설치·버전·제거는 GUIDE 11.1(`bash chagok-docs/scripts/ai-tools.sh`).

| 도구 | 부르는 때 |
|---|---|
| RTK | 긴 `git log`·`git diff` 요약(lint·test에는 쓰지 않음, 상태 바꾸는 명령에 붙이지 않음) |
| Ponytail `/ponytail lite` | 일반 구현·재사용·국소 버그 수정에서 최소 변경 |
| Context7 | 라이브러리 버전 차이·새 API 확인(코드·개인정보를 질의에 넣지 않음) |
| Caveman `/caveman` | 진행·인계 보고를 짧게(정책·보안 근거·검증 결과는 줄이지 않음) |
| React Best Practices | React 구조·Hook·렌더링·성능(Next.js 전용 규칙 제외) |
| Playwright MCP | UI·사용자 흐름 변경의 브라우저 확인 |
| `/security-review` | L3 인증·권한·개인정보·격리의 추가 검토(필수 리뷰를 대신하지 않음) |

## 7. 역할별 추천 순서

| 역할 | 순서 |
|---|---|
| 공통 구현자 | `issue-coder`(계획 → 승인 → 구현) → API면 `contract-checker` → L2·L3면 `pr-reviewer` → PR |
| PM 김예린 | `scope-guard`/`scope-keeper` → `issue-writer` → 마일스톤 진행 확인 |
| 도메인관리 최은정 | `spec-sync` B → A → `issue-writer`(분할 추천) → `contract-checker`(PR 대조) |
| 백엔드 (김예린·이영주·김동윤) | `issue-coder` → `contract-checker` → `pr-reviewer`, 버그는 `bug-fix` |
| 프론트 (최은정·이재성) | `issue-coder` → `contract-checker`(`api.ts`·`types.ts`·`mocks/`) → `pr-reviewer` |
| 형상관리 김동윤 | `pr-review`/`pr-reviewer` → 마일스톤 때 `release-check`, AI 설정 변경 시 동기화 공지·`.skill` 재배포 |
| DB관리 이영주·이재성 | `spec-sync` B(07 ↔ 마이그레이션) → `seed-data`/`seed-builder` → `pr-reviewer` |
| 보조 형상·DB관리 최은정 | 대행 범위는 문서에 정의 없음(❓). PR 확인·`done-verified`·Squash merge 등 "확인한 팀원"의 일은 누구나(CONTRIBUTING 5장). 그 밖은 GUIDE 24.8 추천안(정책 아님). 과거 예외 재사용 금지 |

역할·소속은 **확정**(D-14), 기능별 개발 담당은 [01](01_P0_핵심기능_담당배정.md) **추천안**이다(Assignee는 확정 후).

## 8. 가장 자주 쓰는 명령 (Claude Code 대화창, `<번호>`만 바꾸기)

```text
chagok-backend#<번호> 이슈를 chagok-issue-coder로 구현해줘. 먼저 작업 등급과 계획(범위·파일·책임 배치·테스트·위험)을 보여 주고, 내가 승인하면 구현해. 커밋·push는 내가 확인한 뒤에.
```
```text
계획 승인합니다. 승인한 범위만 구현하고 테스트를 함께 써줘. 계획과 달라져야 하면 멈추고 다시 보고해. 끝나면 ./gradlew build 결과와, DB에 닿으면 빈 테스트 DB로 dbTest 결과를 PASS·FAIL·SKIPPED로 보여 줘.
```
```text
PR 올리기 전 점검을 해줘: 실행한 빌드·테스트 결과를 PASS·FAIL·SKIPPED·미실행으로 나누고, 조건에 맞으면 chagok-contract-checker와 chagok-pr-reviewer를 차례로 돌려 결과를 보여 줘. 커밋·push는 하지 마.
```
```text
chagok-bug-fix로 chagok-backend#<번호> 버그를 봐줘. 먼저 04·05·08 근거로 기대 동작을 정리하고, 재현 방법과 원인만 보고해. 고치는 범위가 원인 한 곳을 넘으면 계획을 먼저 보여 줘.
```
```text
chagok-pr-reviewer 에이전트에게 현재 브랜치를 읽기 전용으로 검토하도록 맡겨줘.
CI 결과, 심각도별 지적, 근거 문서, 직접 확인할 테스트를 보고해줘. 코드 수정·승인·댓글 게시·머지는 하지 마.
```
```text
chagok-spec-sync 모드 C로 API 05·06의 08 명세, 백엔드 DTO, 프론트 types.ts를 비교해줘. 일치·불일치·미검증을 구분하고 수정은 하지 마.
```
```text
지금까지의 작업을 인수인계 메모로 정리해줘: 이슈 번호와 브랜치, 승인받은 계획, 끝난 것, 남은 것, 실행한 검증과 결과(PASS·FAIL·SKIPPED·미실행), 미커밋 변경 파일 목록(git status), 다음에 할 첫 명령. 이 메모를 이슈 댓글로 올릴 수 있게 써 줘. 올리는 건 내가 할게.
```

역할별 명령(PM·도메인·BE·FE·형상관리·DB·보조·버그·리뷰)은 GUIDE 24장.

## 9. 작업 등급 L0~L3 (원본: ai-rules 「작업 등급」)

**건드린 대상으로 정한다(파일 수 아님). 애매하면 위 등급.**

| 등급 | 대상 (예) | 계획·승인 | 에이전트 | AI가 직접 돌리는 검증 |
|---|---|---|---|---|
| L0 | 오타·주석·링크 | 한 줄 알리고 진행 | 없음 | 바뀐 종류만 |
| L1 | 화면 문구·배치, README·가이드, 국소 코드 | 3~5줄 요약 → **승인** | `pr-reviewer` 선택 | BE `./gradlew build` / FE `npm run lint && npm test && npm run build` |
| L2 | Controller·DTO·ErrorCode·`api.ts`·`types.ts`·`mocks/`·`cycle`·Entity·Service 업무 규칙, 기준 문서 정책, 스킬 호출 조건·절차 | 전체 계획 → **승인** | `pr-reviewer` **필수**, API면 `contract-checker` | `build` + `dbTest`(DB에 닿으면) + 관련 T·R·X |
| L3 | `db/migration`·`db/seed`, 인증(`global/auth`·`SecurityConfig`·토큰), 권한(403), 개인정보(마스킹·로그), 정비소 격리(`getOwned`·`shopId`), CI·`scripts`·`.github/`, `settings.json` | L2 + 위험·되돌리기 → **승인** | L2와 같음 + 담당 리뷰(DB는 DB관리, CI·settings는 형상관리) | L2 + 대상별 고위험 검증(GUIDE 20.2) |

- ❓ **ErrorCode**: ai-rules는 L2, backend `CLAUDE.md`는 L3로 적었다(원본끼리 다름, 후속 정리 후보). 프론트 `client.ts`의 인증·오류 처리와 로그인 가드는 L3(frontend `CLAUDE.md`).
- CI(pr-check, backend-ci build+dbTest, frontend-ci lint·test·build)는 등급과 무관하게 모든 PR에서 돈다.
- 커밋·push·PR·머지·이슈 생성은 등급과 관계없이 사람이 확인한다.
- P0-핵심 기능 이슈는 대부분 L2이고, 12 4장 2번(account, `SecurityConfig` 공개 경로)과 격리 조건이 있는 BE 이슈는 L3다(대상 기준 판정 예시).

흐름: 분석 → 계획 보고 → **개발자 승인** → 구현 → 검증 → 결과 보고 → PR 준비 → **사람의 확인·머지**

## 10. 기능 개발 착수 순서

1. 배정된 이슈·완료 정의·테스트 ID 확인 → 2. 선행·짝 이슈 확인 → 3. 3장으로 develop 최신화 →
4. 브랜치:
   ```bash
   git switch develop && git pull --ff-only origin develop
   git switch -c feature/#<그 레포 이슈번호>-<영문-소문자-이름>
   ```
5. `issue-coder`로 분석 → 6. 등급 판정 → 7. 계획 보고 → 8. **승인** → 9. 승인 범위만 구현 → 10. 자체 검증 →
11. `contract-checker`(조건) → 12. `pr-reviewer`(L2·L3) → 13. 문서 변경 필요하면 chagok-docs 문서 PR 먼저 → 14. 결과 보고 →
15. **사람이 확인 후** 커밋·push·PR(base `develop`, 제목 `[#번호] …`, 본문 첫 줄 `Closes #번호`, 일부 완료면 `Refs #번호` — D-71) → 16. CI ✅ + 팀원 확인(두 레포 함께 실행) →
17. (`Closes` 최종 PR) 확인한 팀원이 `done-verified` → 18. **사람이** Squash merge → 19. PR 「AI 사용」 기록·인수인계

## 11. PR 전 필수 확인

- [ ] 실행한 검증만 적었다: BE `./gradlew build`(+ `dbTest`), FE `npm run lint && npm test && npm run build`. **SKIPPED·미실행은 통과가 아니다**
- [ ] 이슈의 테스트 ID(04의 T·R·H·K·L, 08 9장의 X — 번호는 원본에서 확인)를 구현·실행했다. 08 9장 X 실패면 머지 금지
- [ ] `contract-checker`(API 변경 시), `pr-reviewer`(L2·L3) 결과를 확인했다
- [ ] 「문서 PR」 칸: 링크 또는 「문서 변경 없음」
- [ ] 테스트를 통과시키려고 검증·보안·ArchitectureTest를 약하게 바꾸지 않았다
- [ ] AI 공동 작성자 표기(`Co-authored-by: Claude`, `noreply@anthropic.com`, "Generated with Claude Code")가 없다 — pr-check가 막는다
- [ ] CI ❌면 머지하지 않는다. CI·에이전트가 통과해도 머지는 사람이 확인 후

## 12. AI 사용 기록 (CONTRIBUTING 5장, chagok-docs#60 확정)

- **PR 본문 「AI 사용」 칸**에 「없음」/「있음」을 반드시 체크하고, 있음이면 한 줄: `| 날짜 | 레포#이슈 | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |` (에이전트는 `chagok-pr-reviewer (에이전트)`).
- docs `AI_USAGE`에는 **통합 담당(최은정)이 하루 단위로** 모은다. 팀원은 작업마다 AI_USAGE 전용 이슈·PR을 만들지 않는다.
- 코드 레포 PR 템플릿에는 아직 "AI_USAGE에 기록함" 문구가 남아 있다 → CONTRIBUTING 5장대로 PR 본문에 적는다.
- PR이 없는 AI 작업은 그 작업이 남긴 이슈 본문 또는 대상 이슈·PR 댓글에 같은 형식의 한 줄을 남기고, 후속 PR은 이미 통합된 줄을 참조만 한다(D-67 확정).

## 13. 하지 않는 것

- 코드 레포의 `.claude/rules·skills·agents` 복사본 수정, `.env`·`secrets/`·키 파일을 AI에게 읽히기(설정은 일부 패턴만 막는다)
- `main`·`develop` 직접 push, force push, 승인 없는 범위 확대, 차례가 오지 않은 단계·Non-goal 기능 미리 만들기
- AI에게 머지·승인을 맡기기. 이슈 닫기·라벨 변경·브랜치 삭제(`git branch -D`·`gh issue close`·`gh api` 쓰기)도 맡기지 않기를 권한다 — #73으로 확인(ask)이 걸리고 `gh issue delete`·`gh api` DELETE는 막히지만(deny), 패턴 밖 형태는 확인 없이 실행될 수 있다(GUIDE 19.1. 권장이며 원본 금지 조항은 아님)
- DB 직접 실행·변경, 머지된 Flyway 파일 수정, 문서를 코드 레포에서 고치기, 코드에 맞춰 문서 고치기

**브랜치 정리 (D-66 확정)**: 팀원 PR이 머지돼도 작업 브랜치는 바로 지우지 않는다. 마일스톤 점검 또는 형상관리자 요청 때 「정리 검토 가능」이면서 형상관리자가 승인한 원격 브랜치만 사람이 지운다(내 PC의 로컬 브랜치는 각자 정리). 릴리스 PR에서는 Delete branch를 누르지 않는다. 자세한 것은 GUIDE 6.1·CONTRIBUTING 2장.

## 14. 아직 없는 것 · 정해지지 않은 것

| 대상 | 상태 |
|---|---|
| `chagok-branch-audit` 스킬 | **미구현** — `SKILL.md` 없음. 판정 기준은 D-66으로 확정, 구현은 별도 PR 대기. 부르지 않는다 (브랜치 조회는 GUIDE 24.6의 읽기 전용 명령) |
| 브랜치 정리·사후 리뷰·검증 근거·CodeRabbit 판정 (#72) | **확정** (D-66) — CONTRIBUTING 2·5·6장, GUIDE 6.1·8장 |
| settings.json ask 보강 (#73) | **반영** (L3, 세 레포 같은 패턴. 패턴 밖 명령은 GUIDE 19.1) |
| PR 없는 AI 작업 기록 (#74) | **확정** (D-67) — 12장 |
| 프론트 인증 운영: 토큰 저장·401 이동·CORS (#79) | **확정** (D-68) — 코드 반영은 S-01 이슈에서 |
| 마일스톤 날짜 (D-15), 영역별 담당·코드 레포 CODEOWNERS | 미정 |
| CodeRabbit 실제 동작 | 미검증 (다음 코드 릴리스 PR에서 확인) |
| claude.ai `.skill` 최신 배포 (issue-coder·bug-fix, PR #76) | **미확인** — 형상관리자 확인 필요 |

## 15. 더 보기

- **[GUIDE 총정리본](../GUIDE_레포구조_협업규칙_AI스킬안내.md)**: 스킬·에이전트 상세(18·19장), 등급(20장), 착수~머지(21장), 검증 용어(22장), 역할별 명령(24장), 재배포·회신 양식(28장), FAQ(29장)
- [03 클론·환경](03_공통_클론_개발환경.md) · [05 협업 절차](05_공통_협업_개발절차.md) · [CONTRIBUTING](../../../CONTRIBUTING.md) · [ai-rules](../../../.claude/rules/ai-rules.md)
