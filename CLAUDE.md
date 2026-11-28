# CLAUDE.md — chagok-docs에서 AI로 작업할 때

공용 규칙은 `.claude/rules/ai-rules.md`(AI 규칙·스킬·에이전트)와 `.claude/rules/source-of-truth.md`(문서끼리 어긋날 때)에 있다. 이 파일은 **이 레포에만 해당하는 것**만 적는다.

| 무엇 | 원본 |
|---|---|
| 코드 구조·의존 방향·한 곳에만 둘 규칙 | `CONVENTIONS.md` |
| 브랜치·이슈·커밋·PR·릴리스·문서 동기화 (세 레포 공통) | `CONTRIBUTING.md` |
| 범위·기능 ID·ERD·API·화면 | `docs/00`, `docs/04`, `docs/07`, `docs/08`, `docs/09` |

## 이 레포는 원본이다

- 기준 문서, 협업·코드 규칙, 공용 AI 설정(`.claude/rules`·`skills`·`agents`)의 **유일한 원본**이다. 코드 레포에는 사본만 있다.
- 기준 문서(00·04·07·08)를 바꾸면 같은 PR에서 `docs/13_changelog`에 한 줄 남긴다. ID(F-xx, S-xx, API 번호, 테이블명)는 00·04·07·08과 글자까지 같게.
- 코드 레포의 PR 때문에 문서를 고치는 경우, 문서 PR 본문에 그 코드 PR(`chagok-backend#n`, `chagok-frontend#n`)을 적는다.
- 작업 폴더에 `../chagok-backend`, `../chagok-frontend`가 있으면 대조할 때 읽을 수 있다(`.claude/settings.json`의 `additionalDirectories`). 이 레포에서 코드 레포 파일을 고치지 않는다.

## `.claude/`를 고칠 때

- 세 레포의 AI 동작이 함께 바뀐다. `chore/#번호-…` 브랜치와 PR로 하고, 형상관리 리뷰를 받는다.
- 작업 등급(`ai-rules.md` 「작업 등급」)은 경로가 아니라 내용으로 정한다: 설명·문구·오타는 L0~L1, 스킬 호출 조건·작업 절차는 L2, `settings.json`(deny·ask·`additionalDirectories`)·훅·보안·Git 보호 규칙은 L3. 규칙끼리 부딪히거나 보안 우회 위험이 보이면 L3로 올린다.
- 팀원 사본은 docs `origin/main`(릴리스된 버전) 기준으로 동기화된다. develop 머지 뒤 릴리스되면 형상관리자가 "`bash chagok-docs/scripts/update-workspace.sh` → 새 세션"을 공지하고, 스킬 본문이 바뀌었으면 claude.ai용 `.skill`도 다시 배포한다(`docs/etc/GUIDE` 13·28장).
- 코드 레포의 `.claude/rules·skills·agents` 사본을 직접 고치지 않는다. 다음 동기화 때 덮어써진다.
