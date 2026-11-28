# 차곡 협업 규칙 (세 레포 공통)

> 형상관리 담당이 관리합니다. 바꾸려면 `chagok-docs`에 `결정` 이슈로 제안하고 팀 합의 후 이 문서를 고칩니다.
> 문서 역할: **이 문서 = 사람이 협업하는 규칙(Git·이슈·PR·릴리스)**, `CONVENTIONS.md` = 코드 구조 규칙, 각 레포 `CLAUDE.md` + `.claude/rules/ai-rules.md` = AI용 안내. 같은 규칙을 두 문서에 쓰지 않습니다.
> 이 문서는 `chagok-docs`에만 있고, `chagok-backend`·`chagok-frontend`에도 똑같이 적용됩니다.

## 0. 레포 3개

| 레포 | 담는 것 | 이슈로 만드는 것 |
|---|---|---|
| `chagok-docs` | 기획 문서 00~13, 이 문서, `CONVENTIONS.md`, 공용 AI 설정(`.claude/rules·skills·agents`) | 문서, `결정`(명세 변경·범위 추가·규칙 변경) |
| `chagok-backend` | Spring Boot API, Flyway 마이그레이션, 시연 시드(`db/seed/`) | 백엔드 기능(도메인 패키지 하나), 백엔드 버그, 백엔드 `기반` |
| `chagok-frontend` | React 화면 | 프론트 기능(화면 하나), 프론트 버그, 프론트 `기반` |

- **원본은 한 곳에만.** 기준 문서·협업 규칙·코드 규칙·공용 AI 설정은 `chagok-docs`에만 둡니다. 코드 레포에 복사해 커밋하지 않습니다.
- 세 레포는 작업 폴더 `chagok/` 안에 나란히 clone합니다(`scripts/setup-workspace.sh`). 코드 레포의 AI 설정은 `scripts/sync-claude.sh`로 복사해 쓰고, 복사본은 커밋되지 않습니다.
- 다른 레포의 이슈·PR은 `OneMonthproJect/chagok-docs#12`처럼 레포 이름을 붙여 적습니다. 진행 상태는 Organization의 Projects 보드 하나로 세 레포를 함께 봅니다.

## 1. 한눈에 보기

```
이슈 생성(해당 레포) → develop에서 브랜치 → 커밋 → develop으로 PR (최종 PR은 Closes #n, 일부 완료는 Refs #n, 명세가 바뀌면 문서 PR 링크)
→ 자동 검사(❌면 머지하지 않음) + 팀원 확인 → (Closes 최종 PR만) `done-verified` 라벨 → Squash merge → 이슈 자동 클로즈(issue-close)
                         ↓ (M2 통합 검증 · M3 MVP 검증 · M4 기능 동결 · M5 최종 시연)
     형상관리자: 세 레포 각각 develop → main 릴리스 PR(이슈는 Refs #n으로 연결만) → (코드 레포) CodeRabbit 점검 → Merge commit + 같은 태그
```

GitHub 기본 브랜치는 `main`, 팀원 PR이 모이는 통합 브랜치는 `develop`이다(D-49). 그래서 develop 머지에서는 GitHub의 `Closes #` 자동 클로즈가 동작하지 않고, 대신 `issue-close` 워크플로가 이슈를 닫는다(5장).

## 2. 브랜치 (세 레포 같음)

| 브랜치 | 용도 | 누가 머지 | 머지 방식 |
|---|---|---|---|
| `main` | **GitHub 기본 브랜치**. M2 통합 검증·M3 MVP 검증·M4 기능 동결·M5 최종 시연 시점의 안정 버전 | 형상관리자 | Merge commit |
| `develop` | **통합 브랜치** (팀원 PR의 대상) | PR을 확인한 팀원 | Squash (커밋 메시지 = PR 제목) |
| `feature/#번호-이름` | 기능 | | |
| `fix/#번호-이름` | 버그 수정 | | |
| `docs/#번호-이름` | 문서만 | | |
| `chore/#번호-이름` | 설정·빌드·CI·AI 설정 | | |

- 이름은 영문 소문자·숫자·하이픈. 예: `feature/#12-cycle-calc`. 번호는 **그 레포의** 이슈 번호.
- 작업 브랜치는 항상 최신 `develop`에서 만든다. clone 직후에는 기본 브랜치인 `main`에 있으므로 `git switch develop`부터 한다.
- **팀원 PR의 대상은 반드시 `develop`이다.** GitHub 화면과 `gh pr create`는 기본 브랜치(`main`)를 대상으로 잡으므로, 화면에서는 base를 `develop`으로 고르고 CLI는 `gh pr create --base develop`을 쓴다. `develop`이 아닌 브랜치에서 `main`으로 올린 PR은 pr-check가 ❌로 표시한다.
- 이슈 하나 = 브랜치 하나 = PR 하나가 기본이다. 하루 안에 머지할 크기로 쪼갠다. 이슈가 크면 **같은 이슈로 PR을 여러 개**(`Refs #n` 부분 PR → 마지막 `Closes #n` 최종 PR) 올릴 수 있다. PR마다 새 브랜치(예: `feature/#12-cycle-calc-part2`)를 쓰고, PR을 나누려고 이슈를 새로 쪼개지 않는다(D-71).
- **`main` ↔ `develop` 차이는 정상이다**(D-71). 병렬 개발 중 `develop`이 `main`보다 앞서 있는 것을 오류·미완료로 보지 않고, 단순 최신화·동기화 목적으로 develop 전체를 `main`에 머지하지 않는다. 기능 코드의 `main` 반영은 마일스톤 검증 후 형상관리자가 한다(6장). 확정 문서·협업 규칙·독립적으로 검증된 필수 변경은 **형상관리자가** 변경 범위·의존성을 확인한 뒤 예외적으로 먼저 반영할 수 있다. 이때 미완료 기능을 함께 넣지 않고(pr-check는 `main` PR의 head를 `develop`만 허용하므로, `develop`에 미완료 기능이 섞여 있으면 다음 릴리스까지 기다린다), 변경과 무관한 전체 재검증은 하지 않으며, 그 변경이 `develop`에도 들어 있게 관리한다.
- `main`·`develop`에 직접 push하지 않는다. GitHub Free 기준으로 설정이 막아 주지 않으므로 **팀원이 지키는 규칙**이다(아래 「GitHub Free 운영」).
- **브랜치 자동 삭제는 쓰지 않는다**(D-49). 켜 두면 릴리스 PR(develop → main) 머지 때 `develop`이 지워진다. **팀원 PR이 머지돼도 작업 브랜치는 바로 지우지 않는다**(D-66 ①). 마일스톤 점검(M2~M5) 또는 형상관리자 요청 때 브랜치를 점검해, 연결 이슈가 닫히고 검증 근거·사후 리뷰(5장)·후속 작업이 확인된 「정리 검토 가능」 브랜치 중 **형상관리자가 승인한 원격 브랜치만 사람이 지운다.** 내 PC의 로컬 브랜치는 각자 정리한다(PR에 반영되지 않은 커밋이 없는지 먼저 확인). **릴리스 PR에서는 Delete branch를 누르지 않는다.** 로컬을 지울 때는 `git pull --prune` 후 `git branch -D <브랜치>` (Squash merge라 `-d`는 거부됨). Squash merge 뒤 같은 브랜치에서 이어 작업하지 않는다.

## 3. 이슈

- 작업은 이슈부터. 이슈는 0장 표의 레포에 만든다. 템플릿: `chagok-docs`는 문서 / 결정, 코드 레포는 기능 / 버그.
- 기능 이슈 제목: `[F-기능ID] 무엇을` — 기능 ID는 04 기능명세서 그대로.
- 기능 하나가 API와 화면을 모두 가지면 **백엔드 이슈와 프론트 이슈로 나누고** 서로 「짝 이슈」 칸에 링크한다.
- 라벨: 단계(`P0-핵심` / `P0-나머지` / `P1` / `P2` / `기반`) 하나는 반드시.
- 마일스톤(레포마다 같은 이름): M1 설계 확정 / M2 통합 검증 / M3 MVP 검증 / M4 기능 동결 / M5 최종 시연 중 하나.
- 이슈에는 담당자(Assignee)를 지정한다. 진행 상태는 Projects 보드가 자동으로 옮긴다. (PR Assignee는 5장)
- **단계 순서를 지킨다.** MVP = P0 + P1이다.
  - P1 이슈는 M2 통합 검증 통과 전에 열지 않는다.
  - P2·Non-goal 이슈는 이번 프로젝트에서 열지 않는다(D-70, M3 MVP 검증 통과 후에도 같다).
  - Non-goal 기능은 이슈를 만들지 않는다.
- **개발 시작 후 범위 추가는 `결정` 이슈 + 전원 합의가 먼저다.** 합의 전에 브랜치를 열지 않는다. (놀이방: 합의 전 추가 9건이 부실공사의 원인) 추가 의견이 나오면 PM이 `chagok-scope-guard`로 먼저 판정하고, 결정 이슈 초안도 거기서 만든다.
- 백엔드 기능 이슈는 **도메인 패키지 하나** 단위, 프론트 기능 이슈는 **화면 하나** 단위로 쪼갠다. 이슈 본문에 "건드리는 패키지"를 적는다. 도메인 3개 이상이면 쪼갠다.
- 범위를 줄이면 **기능을 통째로** 뺀다. 같은 날 `chagok-docs`에서 00·04·08에 "보류"로 표시한다(문서에 살아 있는 유령 API 방지).

## 4. 커밋

```
타입: 무엇을 했는지 (#이슈번호)
```

| 타입 | 언제 |
|---|---|
| `feat` | 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 |
| `test` | 테스트 |
| `refactor` | 동작 변화 없는 정리 |
| `chore` | 설정·빌드·의존성·CI·AI 설정 |

- 제목은 한국어 50자 이내, 마침표 없음.
- 비밀번호·DB 접속 정보·`.env`는 커밋하지 않는다.
- **AI를 공동 작성자로 올리지 않는다.** 커밋·PR 본문에 `Co-authored-by: Claude`, `noreply@anthropic.com`, "Generated with Claude Code"를 넣지 않는다. 커밋 작성자는 항상 본인 계정이다. AI 사용 사실은 PR 템플릿 「AI 사용」에 사람이 적고, `chagok-docs/docs/etc/AI_USAGE`에는 하루 단위로 모아 올린다(5장 「AI 사용 기록」). (pr-check가 막음)
- Squash merge라 develop에는 PR 제목만 커밋으로 남는다(레포 설정: Squash 커밋 메시지 = PR 제목, 본문 없음. D-49). 작업 중 커밋은 자유롭게 하되 PR 제목은 규칙대로.
- 커밋 메시지에 `Closes #`·`Fixes #`·`Resolves #`를 쓰지 않는다. 기본 브랜치가 `main`이라 릴리스 때 이 키워드가 이슈를 닫을 수 있다. 이슈 번호는 `(#12)`처럼만 적는다.

## 5. PR (팀원 → develop)

- 대상(base): **`develop`** (2장).
- 제목: `[#이슈번호] 이슈 제목`. 제목에는 `Closes #` 같은 닫는 키워드를 쓰지 않는다(Squash 커밋 제목이 되어 릴리스 때 이슈를 닫을 수 있음. pr-check가 막음).
- **PR 유형 세 가지**(D-71). 본문 첫 줄로 이슈를 연결한다(pr-check가 `Closes #n` 또는 `Refs #n` 중 하나를 요구).

  | 유형 | 언제 | 본문 첫 줄 | 머지 후 이슈 | `done-verified` |
  |---|---|---|---|---|
  | 최종 PR | 이슈 **전체** 완료 조건을 채움(앞선 `Refs` PR 반영분 포함) | `Closes #n` | `issue-close`가 닫음(아래 조건) | 붙임 |
  | 부분 PR | 이슈 **일부**를 끝냈고, 그 변경만으로 독립적으로 검토·머지할 수 있음 | `Refs #n` | 열린 채 유지, 남은 일은 같은 이슈에서 | 붙이지 않음 |
  | Draft PR | PR **자체**가 미완, 리뷰 준비 전, 필수 의존성이 없어 안전하게 머지할 수 없음 | 준비되면 쓸 `Closes`·`Refs` | — | — |

  이슈 전체가 미완이라는 이유만으로 Draft로 두지 않는다. 혼자 머지할 수 있으면 `Refs` 일반 PR로 올린다. 전체 완료 조건이 채워지지 않았으면 `Closes`를 쓰지 않는다.
- `Closes #n` 최종 PR: develop은 기본 브랜치가 아니라 GitHub이 이 키워드로 이슈를 닫지 않으므로, 아래 조건을 모두 만족하면 **`issue-close` 워크플로가 이슈를 닫는다**(D-49). `Refs #n`은 닫지 않는다.
  - develop 대상 PR이 실제로 **머지**됨 (머지 없이 닫힌 PR은 대상 아님)
  - PR에 **`done-verified`** 라벨이 있음
  - PR 마지막 커밋의 자동 검사가 모두 ✅ (실패·진행 중이면 닫지 않음)
  - `Closes #번호` 중 **같은 레포** 이슈만. 다른 레포 이슈(`Closes OneMonthproJect/chagok-docs#12`)는 연결만 되고 닫히지 않으므로 그 레포에서 직접 닫는다
- 본문은 PR 템플릿대로. 기능 `Closes` 최종 PR은 완료 정의를 모두 체크하고, `Refs` 부분 PR은 그 PR 범위에 해당하는 항목만 체크한다.
- **PR Assignee는 기본 비워 둔다**(D-71). 작성자 본인을 Assignee로 다시 지정하지 않는다. 인수인계·담당 변경·작성자 외 처리 책임자가 있을 때만 지정한다. Reviewer·CODEOWNERS 리뷰 요청은 그대로이고, Assignee가 없다는 이유로 PR 생성·검증을 막지 않는다.
- **확인한 팀원이 완료 정의 체크리스트를 확인한 뒤 `done-verified` 라벨을 붙이고 머지한다**(`Closes` 최종 PR만. `Refs` 부분 PR은 라벨 없이 머지한다). 라벨 없이 머지했으면 머지 후에 라벨을 붙여도 그때 닫힌다. 이슈가 닫히지 않았으면 Actions의 `issue-close` 실행 기록(요약)에서 이유를 본다. 보드의 Done 이동은 Projects 기본 워크플로(이슈 닫힘 → Done)가 처리한다.
- **검증 근거와 사후 리뷰**(D-66 ②·③): `done-verified`는 라벨을 붙인 사람 또는 리뷰어가 작성자가 아닐 때 검증 근거로 인정한다. 작성자가 스스로 검증했으면 PR 댓글에 실행 명령·결과를 남기고, 이것을 「자기 검증」 근거로 인정한다. 단 자기 검증인 L2·L3 PR은 사후 리뷰까지 끝나야 브랜치가 「정리 검토 가능」이다. 작성자 외 확인 없이 머지된 PR 중 `review-me` 라벨, `.claude/rules/ai-rules.md` L3 대상 경로, 또는 PR 댓글이나 AI 사용 기록에 「사후 리뷰 필요」로 표시된 PR은 **사후 리뷰 대상**이다. 사후 리뷰 완료는 해당 경로 CODEOWNER(작성자 아님)의 GitHub PR 리뷰(Approve·Comment), 또는 작성자가 아닌 사람의 PR 댓글 「사후 리뷰: 결과 …」로만 인정한다(구두·메신저는 「확인 필요」). `issue-close` 동작은 그대로다.
- **검증 재사용**(D-71): 부분 PR은 그 변경 범위와 영향받는 의존성을 검증한다. 최종 PR은 앞선 부분 PR의 검증 근거(PR 링크·CI·실행 기록)를 함께 적어 이슈 전체 완료 조건을 확인하고, 그 뒤 바뀐 코드·정책·계약·의존성만 다시 검증한다. 앞선 근거가 무효가 되면(같은 곳을 다시 고침, 계약 변경) 그 영향 범위만 재검증한다. L0~L3 등급·필수 CI·마일스톤 통합 검증 기준은 그대로이고, 변경과 무관한 전체 재검증은 요구하지 않는다.
- **코드 레포 PR은 「문서 PR」 칸을 채운다.** 명세(07·08·09)가 바뀌는 변경이면 `chagok-docs` 문서 PR 링크, 아니면 「문서 변경 없음」 체크(7장).
- push 전 `git pull origin develop`. 충돌은 PR 올린 사람이 해결한다.
- 승인 인원을 강제하지 않는다. 다만 머지 전에 팀원 1명이 확인하는 것을 기본으로 한다(작은 문서·오타 수정은 생략 가능). 확인하는 사람은 브랜치를 받아 **다른 코드 레포의 develop과 함께 띄워** 실제로 실행해 본다. 점검 순서와 코멘트 초안은 `chagok-pr-review` 스킬이나 `chagok-pr-reviewer` 에이전트로 만들 수 있다(승인·코멘트 게시는 사람이). 작성자도 PR을 올리기 전에 같은 에이전트로 스스로 점검한다 — L2·L3는 필수, L1은 선택, L0(오타·주석)은 생략(`.claude/rules/ai-rules.md` 「작업 등급」).
- 자동 검사(`pr-check`, 코드 레포는 빌드 CI도)가 실패(❌)한 PR은 **머지하지 않는다.** GitHub가 자동으로 막지 않으므로, 머지하는 사람이 ✅를 확인한다. ❌인데 머지된 것을 발견하면 형상관리자가 되돌리거나(`git revert`) 고치는 PR을 바로 요청한다.

### AI 사용 기록 (chagok-docs#60)

| 무엇 | 규칙 |
|---|---|
| 원본 기록 | **모든 PR 본문의 「AI 사용」 칸.** 「없음」/「있음」 중 하나를 반드시 체크하고, 있음이면 기록 한 줄(`\| 날짜 \| 레포#이슈 \| 스킬·에이전트 \| 한 일 \| 사람이 바꾼 것 \|`)을 본문에 적는다. **PR이 없는 AI 작업**(이슈만 만든 조사·설계, 결정 이슈 초안, 읽기 전용 점검·리뷰, 댓글만 남긴 작업)은 그 작업이 남긴 이슈 본문, 또는 작업 대상 이슈·PR의 댓글에 같은 형식의 한 줄을 남긴다(D-67) |
| docs 반영 | `docs/etc/AI_USAGE_AI활용기록.md`에는 **하루 단위로 통합**한다. 그날 머지된 세 레포 PR의 「있음」 줄을 모아 docs PR 하나로 올린다. 작업마다 AI_USAGE 전용 PR을 따로 만들지 않는다 |
| 통합 담당 | 최은정(eunjung01230) — 2026-11-23 eunjung01230 지정(chagok-docs#60). 각 PR 작성자는 자기 PR 본문에 기록하고, 통합 담당이 모아 올린다. 기존 AI_USAGE 줄은 지우거나 덮어쓰지 않는다 |
| 누락 방지 | ① 통합 담당이 세 레포에서 그날 머지된 PR을 모은다: `gh pr list -R OneMonthproJect/<레포> --state merged --search "merged:YYYY-MM-DD" --json number,title,body` ② 「있음」인 PR이 모두 들어갔는지, 「없음」·「있음」 둘 다 비어 있는 PR이 없는지 대조한다(비어 있으면 작성자에게 묻고 PR 본문을 고치게 함) ③ 통합 PR 본문에 대조한 PR 번호 목록을 남긴다 ④ 그날 통합하지 못하면 다음 통합 PR에 날짜별로 함께 넣는다 ⑤ 그날(KST) 만든·고친 이슈와 댓글 중 「AI 사용」 칸이 있는 것도 조회해 함께 옮긴다. KST 하루를 UTC 범위로 조회한다(예: `gh search issues --owner OneMonthproJect "AI 사용" --include-prs=false --updated "2026-11-23T15:00:00Z..2026-11-24T15:00:00Z"`, 본문 「AI 사용」 칸 유무로 거름) (D-67) |
| 중복 방지 | 후속 PR은 이미 통합된 이슈 단계 작업 줄을 다시 쓰지 않고 「AI 사용」 칸에 "이슈 단계 기록: chagok-docs#n으로 통합됨"처럼 참조만 남긴다. 후속 PR에서 새로 한 AI 작업만 새 줄로 적는다 (D-67) |

### GitHub Free 운영 — 무엇이 자동으로 막히고, 무엇을 사람이 지키나

| 구분 | 내용 |
|---|---|
| GitHub가 실제로 하는 것 | 검사를 돌려 PR에 ✅/❌ 표시, 라벨 자동 부착, 이슈 자동 클로즈(`issue-close`: develop 머지 + `done-verified` + 검사 ✅), CODEOWNERS 리뷰 요청. 머지된 브랜치는 자동 삭제하지 않는다(2장) |
| GitHub가 막지 **않는** 것 (사람이 지킴) | ❌인 PR 머지, `main`·`develop` 직접 push, 확인 없는 머지, `feature/` PR의 동결 후 머지 |
| 지키는 사람 | 머지하는 사람: ✅와 확인 여부를 보고 머지. 형상관리자: 매일 `develop` 커밋 목록과 Actions 결과를 보고, 규칙을 어긴 머지를 되돌리거나 수정 PR을 요청. `main`은 형상관리자만 머지 |
| 선택 사항 | 공개 레포라 Free에서도 브랜치 보호·필수 검사를 켤 수 있다. 켜면 위의 일부가 자동으로 막힌다. 켜지 않아도 이 문서의 규칙은 같다 |

### 자동으로 일어나는 일

| 무엇 | 레포 | 언제 |
|---|---|---|
| 브랜치명·PR 제목·본문 이슈 연결(`Closes #` 또는 `Refs #`, D-71) 검사, PR 제목의 닫는 키워드 금지 | 세 레포 | PR 생성·수정 |
| 릴리스 PR(develop → main): 제목·본문의 닫는 키워드 금지, 포함 커밋이 **열린 이슈**를 닫는 키워드를 담으면 차단 (D-49) | 세 레포 | 릴리스 PR 생성·수정 (❌) |
| 커밋·PR 본문의 AI 공동 작성자 표기 차단 | 세 레포 | PR 생성·수정 |
| M4 기능 동결 이후 `feature/` 차단 (`FEATURE_FREEZE`) | 세 레포 | PR 생성·수정 |
| **비밀값·민감 파일**(`.env`, 키 파일, 토큰 형태, 설정 파일의 평문 비밀번호) | 세 레포 | PR 생성·수정 (❌) |
| **DB·Flyway 규칙**: 이미 있는 마이그레이션 수정·삭제, 이름 규칙(`V{번호}__{설명}.sql`), `schema.sql`·`data.sql`, `src/main/resources`의 마이그레이션 밖 SQL, `ddl-auto`가 validate가 아님, `sql.init.mode` always | backend | PR 생성·수정 (❌) |
| 마이그레이션 변경인데 문서 PR 링크 없음 | backend | PR 생성·수정 (❌) |
| Controller·DTO·ErrorCode 변경인데 문서 PR 링크 없음, cycle 변경인데 테스트 없음, 도메인 3개 이상 → 경고 | backend | PR 생성·수정 |
| `features/*/api·types` 변경인데 문서 PR 링크 없음, 새 페이지, feature 3개 이상 → 경고 | frontend | PR 생성·수정 |
| 기준 문서 변경인데 13 changelog 없음, 공용 AI 설정·규칙 변경 → 경고 | docs | PR 생성·수정 |
| 패키지 주인에게 리뷰 요청 (CODEOWNERS) | 세 레포 | PR 생성 |
| Gradle Wrapper 확인·검증 → 빌드 + DB 없는 테스트(ArchitectureTest 등) → DB 테스트(빈 MySQL에 Flyway 적용·앱 기동). 결과는 작업 요약과 리포트 파일로 남김. 검사 대상이 아직 없는 규칙은 "건너뜀(검증 안 됨)"으로 따로 표시 | backend | 모든 PR, develop·main push (❌) |
| `npm ci`·lint(ESLint 경계 규칙)·테스트(Vitest, `npm test`)·빌드(타입 검사 포함) | frontend | 모든 PR, develop·main push (❌) |
| 영역 라벨(`backend`/`frontend`/`db`/`docs`/`ci`), 유형 라벨(`feature`/`fix`) | 세 레포 | PR 생성 |
| `review-me` 라벨 (표시용, 자동 리뷰 없음) | 코드 레포 | backend: cycle·global·마이그레이션, frontend: `src/app`·`src/shared/api` 변경 |
| `release` 라벨 → CodeRabbit 자동 리뷰 1회 | 코드 레포 | develop → main PR |
| 이슈 자동 클로즈(`issue-close`: develop 머지 + `done-verified` + 검사 ✅, 같은 레포 `Closes` 이슈만 — `Refs`는 닫지 않음) → 보드 Done(Projects 기본 워크플로) | 세 레포 | develop 머지, 또는 머지 후 `done-verified` 부착 |

(❌) = 실패로 표시되는 **차단 기준**. 나머지 경고는 리뷰 때 확인하는 **경고 기준**이다.

| 차단 기준 (❌, 머지하지 않음) | 경고·리뷰 기준 (확인 후 판단) |
|---|---|
| 컴파일·빌드 실패, 필수 테스트 실패, ArchitectureTest 실패, 비밀값·민감 파일, DB·Flyway 규칙 위반, 형식 검사(브랜치·제목·`Closes #`/`Refs #`·AI 표기·동결), 릴리스 PR의 닫는 키워드 | 08 명세 불일치 의심(문서 PR 링크 없음), 문서 갱신 누락, 테스트 부족, 네이밍·스타일, 중복 코드, 선택적 리팩터링 |

자동 검사로 찾을 수 있는 것만 차단한다. 검사가 통과해도 "보안 문제 없음", "명세와 일치"가 보장되지는 않는다(리뷰와 `chagok-contract-checker`로 확인).

## 6. 릴리스 (형상관리자: develop → main, 세 레포 함께)

| 시점 | 태그 | 범위 |
|---|---|---|
| M2 통합 검증 | `v0.5-m2-integration` | P0-핵심 |
| M3 MVP 검증 | `v0.8-m3-mvp` | P0 전체 + P1 (MVP 완성) |
| M4 기능 동결 | `v0.9-m4-freeze` | M3 MVP 검증 이후 변경분 (오류 수정·연결 보완·안정화) |
| M5 최종 시연 | `v1.0-m5-demo` | 동결 이후 수정분 |

**세 레포에 같은 날 같은 태그를 단다.** 태그 이름이 같으면 "이 시점의 문서·백엔드·프론트"를 한 번에 맞춰 받을 수 있다.

**`main` 머지는 형상관리자(dyk816)가 한다**(D-71). 관리자 권한이 있는 다른 계정(eunjung01230)도 권한은 그대로 두지만, 대상 레포·PR을 특정해 직접 판단한 경우가 아니면 `main`을 머지하지 않고 형상관리자에게 넘긴다. 릴리스 PR 준비·검토·점검은 누구나 할 수 있다. 릴리스·예외 선반영 요청은 대상 레포·포함 범위·검증 근거를 이슈·PR 댓글로 형상관리자에게 남긴다. AI의 `main` 머지 제한은 `.claude/rules/ai-rules.md` 「AI만의 규칙」.

**이슈는 develop 통합과 main 릴리스를 나눠 관리한다(D-49).**

| | develop 통합 (팀원 PR) | main 릴리스 (릴리스 PR) |
|---|---|---|
| 이슈 표기 | 본문 `Closes #번호`(최종) 또는 `Refs #번호`(부분, D-71) | 본문 `Refs #번호` 또는 링크. **`Closes`·`Fixes`·`Resolves` 금지** |
| 이슈 닫힘 | `Closes`만 `issue-close`가 닫음 (머지 + `done-verified` + 검사 ✅). `Refs`는 열린 채 | 닫지 않음. 연결(타임라인 표시)만 |
| 검사 | pr-check 형식 검사 | pr-check가 제목·본문 키워드와, 포함 커밋이 열린 이슈를 닫는지 확인 (❌) |

기본 브랜치가 `main`이라 릴리스 PR 제목·본문이나 포함 커밋에 닫는 키워드가 있으면 머지 때 GitHub이 이슈를 닫는다. `done-verified` 없이 열어 둔 이슈가 이렇게 닫히지 않도록 키워드를 쓰지 않고, pr-check가 확인한다.

순서:
1. `chagok-release-check` 스킬로 세 레포를 함께 점검한 보고서 작성 (완료 정의, 열린 P0·P1 이슈, 범위, 문서·코드 대조, 세 레포 develop을 함께 띄운 시연). **이번 릴리스에 포함된 PR의 `Closes` 이슈가 모두 닫혔는지** 확인하고(`Refs` 부분 PR만 머지된 이슈가 열려 있는 것은 정상), 열려 있으면 `done-verified` 누락인지 검사 실패인지 판단한다(완료면 원래 PR에 라벨을 붙여 develop 기준으로 닫고, 미완이면 릴리스 보고서에 미완으로 적는다)
2. `chagok-docs`부터 `develop → main` PR. 본문에 포함 이슈를 `Refs #번호`로 나열한다. 문서 릴리스 PR은 CodeRabbit 없이 형상관리자가 확인 후 머지
3. `chagok-backend`·`chagok-frontend` 릴리스 PR → `release` 라벨이 자동으로 붙고 CodeRabbit이 자동 리뷰 1회 (리뷰가 시작되지 않으면 PR에 `@coderabbitai full review` 댓글). 이후 push에는 자동 리뷰가 없다. 다시 보려면 `@coderabbitai review`
4. CodeRabbit 지적을 분류한다 (아래 표)
5. 수정할 것은 `fix/` 브랜치로 해당 레포 develop에 머지 → 릴리스 PR에 자동 반영
6. 모든 지적에 처리 결과(수정·미룸·반영 안 함)를 답글로 남기고 해결 처리. CodeRabbit 리뷰는 머지 차단 조건이 아니며, 최종 판단은 형상관리자가 한다
7. 세 레포 main을 함께 받아 빈 DB에서 시나리오 A·B와 격리 시연 확인 후 **Merge commit**으로 머지
8. 세 레포에 같은 태그 생성 → GitHub Release의 "Generate release notes"로 변경 목록 자동 작성

CodeRabbit은 지적만 하고 머지하지 않는다. 이슈 close는 팀원 PR이 develop에 머지될 때 `issue-close`가 하고, 릴리스 PR에서는 일어나지 않는다(`issue-close`는 develop 대상 PR만 보고, 릴리스 PR에는 닫는 키워드가 없다). 브랜치 자동 삭제를 꺼 두었으므로 릴리스 PR을 머지해도 `develop`은 남는다. 릴리스 PR 화면의 Delete branch는 누르지 않는다.

### CodeRabbit 운영 — 릴리스 PR 중심

| 대상 | 처리 |
|---|---|
| 일반 PR → develop | 자동 리뷰 없음 |
| 중요·복잡한 PR → develop (`review-me` 라벨 등) | 작성자·확인자가 필요할 때 PR 댓글 `@coderabbitai review` |
| develop → main | `release` 라벨로 자동 리뷰 1회 |
| 추가 push | 자동 증분 리뷰 없음 |

- 모든 제안을 필수 수정으로 다루지 않는다. 실제 오류·보안·데이터 손상 위험·정비소 격리 위반을 먼저 고친다.
- **CodeRabbit 필요 판정**(D-66 ④): 코드 레포의 `review-me` 또는 L3 경로 PR은 CodeRabbit 리뷰 「필요」로 본다. 완료는 그 PR의 CodeRabbit 리뷰, 또는 그 머지 커밋이 포함된 릴리스 PR의 CodeRabbit 리뷰 + 미해결 지적마다 분류 답글(아래 표)이다. 머지 차단 조건은 아니다(D-47). `chagok-docs`는 해당 없음.
- 설정: 코드 레포의 `.coderabbit.yaml`(공식 스키마 v2 `reviews.auto_review`).

### CodeRabbit 지적 분류

| 분류 | 기준 | 처리 |
|---|---|---|
| 수정 | 정비소 격리(shop_id) 누락, cycle 규칙 위반, 실행 오류, 보안, 08 명세와 불일치 | `fix/`로 develop에 고친 뒤 반영 |
| 미룸 | 이름 짓기, 리팩터링, 작은 성능 개선 등 시연에 영향 없는 것 | "M4 기능 동결 이후 검토" 답글 후 해결 처리 |
| 반영 안 함 | 기획 결정과 충돌 (차량번호 중복 차단, 쓰지 않는 기능 추가 등) | 근거 문서를 답글로 남기고 해결 처리 |

- 판단: 형상관리자 1차 분류, 주기 계산은 도메인관리, 마이그레이션·시드는 DB관리. 수정은 그 코드를 쓴 담당자.
- 기록: `chagok-docs/docs/etc/DEV_REVIEW_CodeRabbit.md`에 한 줄씩 (레포 이름 포함).
- 시간: 릴리스 당일 오전 리뷰 → 점심 전 분류 → 오후 수정·머지.
- 수동 리뷰(develop 단계)도 같은 분류를 쓰고, 판단은 작성자와 확인자가 한다.

M4 기능 동결 이후에는 `FEATURE_FREEZE=true`로 바꾼다(Organization 변수 하나, 안 되면 세 레포 각각). 그때부터 `feature/` 브랜치 PR은 pr-check가 실패(❌)한다. 형상관리자는 동결 후 `feature/` PR이 머지되지 않게 확인한다.

## 7. 문서와 코드 맞추기

**기획이 기준이고, 기획은 `chagok-docs`에만 있다.** M1 설계 확정 이후 명세를 바꾸려면:

1. `chagok-docs`에 `결정` 이슈 (무엇을 왜)
2. `chagok-docs`에 문서 PR: 문서 수정 + `13_changelog` 한 줄
3. 코드 레포에 코드 PR: 본문 「문서 PR」 칸에 2의 링크
4. **문서 PR을 먼저(또는 같은 날) 머지한다.** 코드가 먼저 develop에 들어가 문서와 다른 시간을 만들지 않는다.

| 문서 (chagok-docs) | 코드 | 규칙 |
|---|---|---|
| 07 ERD | backend `src/main/resources/db/migration/V*.sql`, `db/seed/demo_seed.sql`, Entity | 마이그레이션이 바뀌면 07 문서 PR 링크 필수 (pr-check ❌). 이미 있는 버전 파일은 고치지 않는다 |
| 08 API | backend Controller·DTO·ErrorCode, frontend `features/*/api.ts`·`types.ts` | 바뀌면 08 문서 PR (pr-check가 경고). **JSON 예시 블록도 같이**. 반대쪽 담당에게 PR 링크 공유 |
| 04 주기 규칙 | backend `domain/cycle`, 테스트 T1~T17(04) | 규칙을 바꾸면 테스트 기대값부터. 도메인관리 리뷰 필수 |
| 격리·인증 규칙 | backend 모든 정비소 데이터 조회, 인증·권한·계정 상태 | **08 9장의 X 테스트 전체**(현재 X1~X21: 격리 X1~X8·X11~X15·X17, 역할·인증 X9·X10·X16·X18, 계정 상태 X19~X21). 실패하면 머지 금지 |
| 09 화면 | frontend `src/pages` | 화면 ID와 페이지 1:1 |
| 00 범위 | 존재하는 기능 전체 | 차례가 오지 않은 단계·P2·Non-goal 기능은 빈 화면·버튼·API·테이블로도 만들지 않음 |

**08 API마다 JSON 예시 블록을 둔다.** 08이 API의 유일한 원본이라 예시도 08 안에만 둔다(별도 예시 파일 없음, 코드 레포에도 복사하지 않음).

- 요청 본문이 있는 API는 요청 예시, 모든 API는 성공 응답 예시(공통 응답으로 감싼 전체 모양)를 ```` ```json ```` 블록으로 둔다.
- 필드 이름·enum 값·날짜 형식은 예시와 표가 글자까지 같아야 한다. 표만 고치고 예시를 두고 가지 않는다.
- 값은 시드 데이터에서 가져온다(시연 때 실제로 보이는 값). 에러 응답 예시는 공통 절에 한 번만.
- 프론트 `types.ts`와 백엔드 연결 전 목업은 이 JSON을 기준으로 만든다.

영향 범위가 헷갈리면 `chagok-spec-sync` 스킬을 쓴다. 프론트와 백엔드가 처음 연결될 때·기능 묶음이 끝났을 때는 같은 스킬의 모드 C(API 계약 점검: 08 ↔ Controller·DTO ↔ `features/*/api.ts`·`types.ts`)를 돌린다. 세 레포가 작업 폴더에 함께 있어야 한다. 시드는 `chagok-seed-data`로 07 시드표에 맞춰 만든다. 코드 쪽 규칙(어느 패키지에 무엇을 두나)은 `CONVENTIONS.md`.

### 변경 유형별 문서 확인 (모든 PR, chagok-docs#214)

PR을 올릴 때 **바뀐 것의 종류만** 보고 아래 문서를 확인한다. 해당 없는 줄의 문서는 읽지 않고, 세 레포 문서 전체를 다시 보지 않는다. 문서 최신화 기준은 이 표 한 곳이고, PR 템플릿·GUIDE는 이 표를 가리키기만 한다.

| 바뀐 것 | 함께 확인할 문서 |
|---|---|
| 기능 추가·변경 | 04 기능명세 · 08 API · 09 화면 |
| 서비스 정책 | 05 정책 · 관련 04 · 13 changelog (M1 이후는 위 1~4 절차) |
| 인증·인가·권한 | 06 권한 · 08 0.1·9장(X) · CONVENTIONS 8장 |
| DB (마이그레이션·시드) | 07 ERD · backend `db/seed/README.md` |
| API 요청·응답·에러 코드 | 08 표·JSON 예시 · 09 해당 화면 · 10 연결표 |
| 기술 스택·실행 방법·환경변수 | 그 레포 README |
| 패키지·아키텍처 | 11 아키텍처 · CONVENTIONS · 그 레포 README |
| 디자인 | frontend `design/README.md`·`design/CHANGELOG.md` |
| 중요한 오류 해결 | `docs/etc/DEV_REVIEW_트러블슈팅.md` |
| CodeRabbit 지적 처리 | `docs/etc/DEV_REVIEW_CodeRabbit.md` (6장 「CodeRabbit 지적 분류」) |
| AI 설정·스킬·에이전트 | GUIDE · STARTER 04 · 영향받는 PERSONAL |
| 통합검증 | `docs/etc/TEST_테스트명세서.md` 7.1 |
| 마일스톤 통과 | 00 8장 · README 「지금 단계」 · TEST 7.1 |
| 확정된 결정 | 관련 기준 문서 · 13 changelog |
| AI 사용 | PR 본문 「AI 사용」 칸만 (5장 「AI 사용 기록」, docs 반영은 하루 단위 통합) |

- 고쳐야 할 문서가 있으면 docs 레포 PR은 같은 PR에서, 코드 레포 PR은 「문서 PR」 칸에 문서 PR 링크를 단다. 바로 고치지 못하면 후속 이슈 링크를 남긴다. 해당 없으면 PR 템플릿의 「관련 없음」에 체크한다.
- 문서 변경이 필요한데 링크·후속 이슈 없이 `Closes` 최종 PR을 완료 처리하지 않는다. 문서와 관계없는 PR에 문서 PR을 요구하지 않는다.
- 기록 문서(트러블슈팅·CodeRabbit·TEST)에는 오타·사소한 화면 수정·중요하지 않은 지적을 적지 않는다. 이슈·PR에 근거가 충분하면 핵심과 링크만 적는다.

## 8. 패키지 주인 (CODEOWNERS)

**도메인 패키지 하나 = 주인 1명.** 주인은 그 패키지의 `api` 계약을 관리하고, 다른 사람이 그 패키지를 건드리는 PR을 리뷰한다. 레포마다 `.github/CODEOWNERS`에 적어 두면 GitHub이 자동으로 주인에게 리뷰를 요청한다.

| 레포 | 경로 | 주인 |
|---|---|---|
| backend | `global/`, `build.gradle`, `application.yaml` | 백엔드 기반 담당 |
| backend | `src/main/resources/db/` (마이그레이션), `db/seed/` (시연 시드) | DB관리 |
| backend | `domain/cycle` | 구현 담당 + 도메인관리 리뷰 |
| backend | `domain/<그 밖의 도메인>`, `screen/` | 도메인별 구현 담당 |
| frontend | `src/app`, `src/shared`, `eslint.config.js` | 프론트 기반 담당 |
| frontend | `src/features/<도메인>`, `src/pages` | 도메인별 구현 담당 |
| docs | `docs/` (07은 DB관리, 04는 도메인관리 함께) | PM |
| 세 레포 | `.github/`, `.claude/`, `CLAUDE.md`, (docs) `CONTRIBUTING.md`·`CONVENTIONS.md`·`scripts/` | 형상관리 |

이름은 결정 14(구현 담당) 후 CODEOWNERS에 채운다. 사람 팀원 계정만 쓴다(AI 계정 금지). 남의 패키지 `api`에 메서드가 필요하면 주인에게 이슈로 요청하거나, 직접 추가하고 주인 리뷰를 받는다.

## 9. 단계별 규칙

| 시점 | 규칙 |
|---|---|
| 기획·설계 | `chagok-docs` 작업 중심. 결정은 `결정` 이슈로 |
| M1 설계 확정 | 세 레포 태그 `v0.1-m1-design`. 초기 구성(B-0)은 완료 상태. `기반` 이슈 3개(백엔드 공통 기반·프론트 공통 기반·V1 마이그레이션/시연 시드)로 코드 시작 |
| 구현 시작 직후 | 로그인 → 고객 등록 → 정비 기록 → 대상 목록 → 예약이 이어진 뼈대를 두 코드 레포 develop에 |
| 매일 마감 전 | 두 코드 레포 develop을 받아 함께 띄우고 빈 DB에서 실행 확인 (대상 목록이 시드의 기대 상태표와 같은지) |
| M2 통합 검증 | 첫 릴리스. 미달이면 P0-핵심 보강 먼저, P0-나머지·P1 이슈 열지 않음 |
| M3 MVP 검증 | P0·P1 완료 정의 + T·X 테스트 + 시연. 릴리스 `v0.8-m3-mvp`. 통과해도 P2는 착수하지 않음(D-70) |
| P2 | 이번 프로젝트에서 착수하지 않음(D-70). 이후 별도 프로젝트용 참고 자료 |
| M4 기능 동결 | 기능 동결. `FEATURE_FREEZE=true`. 이후 `fix/`·`docs/`만. 완료 정의를 못 채운 기능은 빼고 시연 |
| M5 최종 시연 직전 | 기능 추가 금지. 통합 시연·버그 수정만. "시연에서 하지 말 것" 메모 작성 |
| M5 최종 시연 | 세 레포 `main`(`v1.0-m5-demo`)으로 다른 팀원 PC에서 시연 |

## 10. 라벨

| 종류 | 라벨 | 붙이는 쪽 |
|---|---|---|
| 단계 | `P0-핵심` `P0-나머지` `P1` `P2` `기반` | 이슈 작성자 |
| 이슈 유형 | `bug` `결정필요` `docs` | 템플릿 |
| PR 영역 | `backend` `frontend` `db` `docs` `ci` | 자동 |
| PR 유형 | `feature` `fix` | 자동 (브랜치 이름) |
| 리뷰 | `review-me` (중요 변경 표시, 필요하면 `@coderabbitai review`), `release` (릴리스 PR, CodeRabbit 자동 리뷰) | 자동, `review-me`는 손으로도 가능 |
| 완료 확인 | `done-verified` (이슈 전체 완료 정의 확인됨 → develop 머지 시 `issue-close`가 이슈를 닫음, D-49). `Closes` 최종 PR에만, `Refs` 부분 PR에는 붙이지 않음(D-71) | PR을 확인한 팀원이 손으로 |

`bash scripts/setup-labels.sh OneMonthproJect`로 세 레포에 한 번에 만든다.

---

## 부록: 초기 설정 체크리스트

레포 생성·첫 커밋은 최은정(eunjung01230)이, 이후 관리는 형상관리자가 맡는다. Organization 안의 레포라 소유권을 옮길 필요 없이 **형상관리자에게 세 레포 Admin 권한**을 주면 된다.

**Organization (한 번)**
- [ ] 레포를 만들 계정에 레포 생성 권한(Owner 또는 Member privileges의 레포 생성 허용)
- [ ] 팀원 초대. 형상관리자는 Owner 또는 세 레포 Admin
- [x] 레포 공개 범위: **공개 레포**로 확정 (Organization `OneMonthproJect`). GitHub Free 기준으로 운영한다(브랜치 보호는 선택). 공개이므로 비밀값(`.env`, DB 비밀번호, JWT 키)은 절대 커밋하지 않는다
- [ ] Actions 변수 `FEATURE_FREEZE=false` (Organization 변수로 세 레포에 공유)
- [ ] Projects 보드 1개(Organization 소유)에 세 레포 연결, 기본 워크플로(이슈 추가 → Todo, PR 연결 → In Progress, 닫힘 → Done) 켬
- [ ] CodeRabbit GitHub App 설치, `chagok-backend`·`chagok-frontend`만 허용

**레포마다 (세 개 모두)**
- [x] `develop` 브랜치 생성. **기본 브랜치는 `main` 유지** (D-49)
- [ ] Pull Requests: Squash merge와 Merge commit만 허용, Rebase 끔
- [x] Squash merge 커밋 메시지: **Pull request title** (`squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=BLANK`, D-49)
- [ ] "Always suggest updating pull request branches" 켬
- [x] "Automatically delete head branches" **끔** (D-49: 켜면 릴리스 PR 머지 때 `develop`이 지워짐)
- [ ] `issue-close` 워크플로가 있는지 (`.github/workflows/issue-close.yml`, 세 레포 같은 내용)
- [ ] (선택) 브랜치 보호·필수 상태 검사(`pr-check`, `backend-ci`, `frontend-ci`). 켜지 않아도 운영 규칙은 같다(5장 「GitHub Free 운영」)
- [ ] `main` 머지는 형상관리자만 한다 (팀 규칙)
- [ ] backend: Gradle Wrapper가 커밋돼 있는지 (`backend-ci`의 wrapper 작업이 확인)
- [ ] 마일스톤 5개: M1 설계 확정 / M2 통합 검증 / M3 MVP 검증 / M4 기능 동결 / M5 최종 시연
- [ ] 결정 14 후 `.github/CODEOWNERS` 채우고 주석 해제 (리뷰 요청이 자동으로 간다. 승인 강제는 하지 않음)

**그 밖**
- [x] `bash scripts/setup-labels.sh OneMonthproJect` (세 레포 라벨, `done-verified` 포함)
- [ ] 코드 레포에 `.claude/settings.json`·`CLAUDE.md`가 커밋돼 있고, `.claude/rules·skills·agents`는 `.gitignore`로 빠져 있는지
