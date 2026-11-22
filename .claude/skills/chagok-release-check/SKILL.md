---
name: chagok-release-check
description: 차곡 형상관리자가 세 레포(chagok-docs·chagok-backend·chagok-frontend)의 develop → main 릴리스 PR을 만들기 전에 쓰는 점검 스킬. 이번 릴리스에 들어가는 PR·이슈, 열린 P0·P1 이슈, 완료 정의 누락, 범위 위반(단계 순서·P2 선진입·Non-goal·동결 후 기능), 문서·코드 어긋남, CodeRabbit 미해결 지적, 빈 DB 실행 순서를 확인해 머지 가능 여부 보고서와 릴리스 PR 본문·태그 명령을 만든다. "릴리스 점검", "main 머지 전", "중간 점검 준비", "MVP 점검", "관문 2", "발표 전 확인", "v0.5", "v0.8", "v0.9"이면 이 스킬을 사용한다.
---

# 차곡 릴리스 점검

> 경로 표기: `docs/…`·`CONVENTIONS.md`·`CONTRIBUTING.md`는 `chagok-docs` 기준(코드 레포에서는 `../chagok-docs/…`), `chagok-backend/…`·`chagok-frontend/…`는 각 레포 루트 기준이다(`.claude/rules/ai-rules.md`「작업 폴더와 경로」). 필요한 레포가 작업 폴더에 없으면 지어내지 말고 읽지 못한 것으로 보고한다.

CodeRabbit은 코드 품질을 본다. 이 스킬은 **"이 상태로 main에 올려도 되는가"**를 프로젝트 규칙 기준으로 본다. 판단은 형상관리자가 하고, 이 스킬은 근거를 모은다.

**세 레포를 한 릴리스로 본다.** 같은 날 세 레포에 같은 태그를 달기 때문에, 한 레포라도 막는 항목이 있으면 릴리스 전체가 보류다. 작업 폴더에 세 레포가 모두 있어야 한다(없으면 그 레포는 "점검 못 함"으로 표시하고 판정을 조건부 이하로).

## 0. 어떤 릴리스인지 확인

| 릴리스 | 태그 | 기준 |
|---|---|---|
| 중간 점검 | `v0.5-midcheck` | P0-핵심 순환이 끝까지 도는가 |
| MVP 점검 | `v0.8-mvp` | P0·P1 전부 완료 정의 충족, T·X 테스트 통과, 시나리오 A·B·격리 시연. 통과해야 P2 착수 |
| 관문 2 (기능 동결) | `v0.9-freeze` | 완료 정의를 충족한 기능만 남았는가 (P2 포함) |
| 발표 | `v1.0-demo` | 동결 이후 `fix/`·`docs/`만 들어왔는가 |

관문 1 태그 `v0.1-gate1`(CONTRIBUTING 9장)은 릴리스 PR이 없는 문서 확정 태그다. 이 스킬로 점검하라는 요청이면 2장 대신 `chagok-spec-sync` 모드 B를 문서끼리 대조(00·04·07·08 ID 일치)로만 돌리고, 태그 명령만 준다.

## 1. 이번 릴리스에 들어가는 것

```bash
# 작업 폴더(chagok/)에서, 레포마다
for r in chagok-docs chagok-backend chagok-frontend; do
  git -C $r fetch origin && git -C $r log --oneline origin/main..origin/develop
  gh pr list --repo OneMonthproJect/$r --base develop --state merged --limit 100 \
    --json number,title,labels,mergedAt,headRefName,body
done
# 열린 단계 이슈 (코드 레포 각각)
gh issue list --repo OneMonthproJect/chagok-backend --state open --label "P0-핵심" --json number,title,assignees
gh issue list --repo OneMonthproJect/chagok-backend --state open --label "P1" --json number,title,assignees
```

이전 태그가 있으면 그 이후 머지된 PR만 본다(`mergedAt`). 세 레포의 이전 태그가 같은지도 확인한다(다르면 지난 릴리스가 한 레포에서 빠진 것).

## 2. 점검 항목

**A. 완료 정의** — 머지된 기능 PR마다 PR 본문의 완료 정의 체크박스를 읽는다. 체크 안 된 항목이 있는 PR을 표로 모은다. 백엔드 이슈와 프론트 「짝 이슈」가 둘 다 머지돼야 그 기능이 완료다. 한쪽만 머지된 기능을 모은다. 코드 PR의 「문서 PR」 링크가 가리키는 `chagok-docs` PR이 머지됐는지도 본다.

**A-2. 이슈 닫힘 (D-49)** — 기본 브랜치가 `main`이라 이슈는 develop 머지 때 `issue-close`가 닫는다. 이번 릴리스에 포함된 PR마다 본문 `Closes #번호`의 같은 레포 이슈가 닫혔는지 본다(`gh issue view <번호> --repo OneMonthproJect/<레포> --json state`). 열려 있으면 PR에 `done-verified` 라벨이 없는지, 검사가 실패했는지 확인해 표로 모은다. 완료가 맞으면 원래 PR에 `done-verified`를 붙여 develop 기준으로 닫으라고 안내하고, 미완이면 "확인 필요"에 적는다. 다른 레포 이슈를 가리킨 `Closes`는 자동으로 닫히지 않으므로 그 레포에서 닫혔는지 따로 본다. 포함 커밋 메시지(`git log origin/main..origin/develop`)에 `Closes`·`Fixes`·`Resolves #번호`가 있으면 릴리스 PR의 pr-check가 열린 이슈에 대해 ❌를 내므로 미리 표시한다.

**B. 범위**
- 중간 점검: 열린 `P0-핵심` 이슈가 있으면 미달. P1·P2 라벨 PR이 이미 머지돼 있으면 규칙 위반으로 표시.
- MVP 점검: 열린 `P0-핵심`·`P0-나머지`·`P1` 이슈가 있으면 미달. P2 라벨 PR이 이미 머지돼 있으면 규칙 위반으로 표시.
- 관문 2: 완료 정의 미충족 기능은 "시연 제외" 후보로 표시(진행 중이던 P2 포함). P2 PR마다 `chagok-docs` 결정 이슈 링크가 있는지 본다. Non-goal 기능, 미리 만든 빈 화면·API·테이블이 있으면 표시.
- 발표: 동결 이후 머지된 `feature/` 브랜치가 있으면 표시.

**C. 자동 검사 상태** — 릴리스 PR이 이미 있으면 레포마다 `gh pr checks <번호> --repo OneMonthproJect/<레포>`. 없으면 develop 최신 커밋의 CI 결과를 본다(backend-ci·frontend-ci·pr-check). `ArchitectureTest`·`EndpointGuardTest`가 빌드에 포함돼 통과했는지 따로 확인한다(구조 규칙을 사람 대신 지키는 장치라 꺼져 있으면 막는 항목).

**C-2. 구조 건강** — 이번 릴리스의 PR 중 pr-check가 "도메인 3개 이상" 경고를 낸 PR을 모은다. 각각 `api`만 추가했는지, 다른 도메인 내부를 고쳤는지 확인해 표로 보고한다. 내부를 고친 PR이 있으면 다음 개발 전에 정리할 항목으로 남긴다.

**D. 문서·코드** — `chagok-spec-sync` 모드 B를 이번 릴리스에서 바뀐 기능 범위로 실행한다. 문서끼리 다른 곳은 `.claude/rules/source-of-truth.md` 순서로 판단하고, 13 changelog의 결정이 본문에 반영되지 않은 곳도 막는 항목 후보로 모은다. 프론트·백엔드가 함께 바뀐 기능은 모드 C(API 계약 점검)도 돌린다. Claude Code면 모드 C는 `chagok-contract-checker` 에이전트에게 맡긴다. 시연 상태가 시드에 기대는 릴리스(중간 점검·발표)는 `chagok-seed-data`의 기대 상태표와 대상 목록이 맞는지 본다. 최소한 07 ↔ Flyway 마이그레이션, 08 ↔ Controller·프론트 `types.ts`, T-xx·X-xx 테스트 존재 여부는 확인한다. 시드에 기대는 릴리스에 MVP 점검도 포함한다.

**E. CodeRabbit 미해결 지적** — 릴리스 PR이 생긴 뒤 다시 실행한다.
```bash
gh api graphql -F owner=OWNER -F repo=REPO -F n=PR_NUMBER -f query='
query($owner:String!,$repo:String!,$n:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$n){
      reviewThreads(first:100){
        nodes{ isResolved path comments(first:1){ nodes{ author{login} body } } }
      }
    }
  }
}'
```
`isResolved: false`이고 작성자가 coderabbitai인 것만 모은다. 각 지적에 분류를 제안한다(CONTRIBUTING.md 6장).
- 수정: 정비소 격리(shop_id) 누락, cycle 규칙 위반, 실행 오류, 보안, 08 명세와 불일치
- 미룸: 이름 짓기, 리팩터링, 작은 성능 개선 등 시연에 영향 없는 것
- 반영 안 함: 기획 결정과 충돌하는 제안 (근거 문서 절을 함께 적는다)
CodeRabbit은 코드 레포에만 있으므로 `chagok-backend`·`chagok-frontend` 릴리스 PR 각각에 실행한다. 분류 결과를 chagok-docs `docs/etc/DEV_REVIEW_CodeRabbit.md` 표(레포 칸 포함)에 붙일 수 있는 줄로도 준다. CodeRabbit 리뷰는 머지 차단 조건이 아니다(D-47). 지적마다 수정·미룸·반영 안 함 분류와 답글이 있는지 보고, 실제 오류·보안·데이터 손상·정비소 격리 위반이 남아 있으면 막는 항목으로 올린다. 최종 판단은 형상관리자.

**E-2. 테스트 기록** — 세 레포 develop의 최신 CI 결과(`gh run list --branch develop`)를 확인한다. ❌가 있으면 판정은 보류다. 작업 요약의 "건너뜀(검증 안 됨)" 수도 그대로 옮긴다(통과로 세지 않음). 이번 릴리스 기준 T-xx·R-xx·X-xx 통과 여부를 chagok-docs `docs/etc/TEST_테스트명세서.md`의 결과 칸에 붙일 수 있는 줄로 준다(실행하지 못했으면 "미실행").

**F. 빈 DB 실행 확인 순서** (형상관리자가 직접)
1. 세 레포 develop을 새로 clone(또는 `git clean -xfd` 후) → 빈 MySQL DB
2. 시연 DB를 새로 만들고 백엔드를 그 DB로 실행 → Flyway 적용 → `db/seed/run-demo-seed.sh`로 시드 (오류 없음)
3. 프론트 실행
4. 시나리오 A: 재점검 대상 목록 → 예약 등록 → 예약 목록(P0-나머지 이후는 캘린더) → 방문 완료 → 정비 기록 → 목록에서 빠짐
5. 시나리오 B: 방문 접수 → 주행거리 입력 → km 초과 항목 "도래" 표시
6. 격리: A 정비소 계정으로 B 정비소 고객 접근 → 거부 / 관리자 계정으로 고객 목록 → 거부
7. (MVP 점검부터) P1 기능: 월평균 추정이 대상 목록에 반영, 문자 초안 복사, 연락 결과 기록, 관리자 정비소 개설·정지

## 3. 출력

```markdown
# 릴리스 점검: v0.5-midcheck (YYYY-MM-DD) — 세 레포

## 판정: 머지 가능 / 조건부 / 보류
한 줄 이유

## 포함 내용
| 레포 | PR | 제목 | 기능 ID | 단계 | 완료 정의 | 문서 PR |
|---|---|---|---|---|---|---|

## 한쪽만 머지된 기능 (짝 이슈 미완)
- …

## 막는 것 (머지 전 해결)
- …

## 확인 필요 (형상관리자 판단)
- …

## 범위
- 열린 P0·P1 이슈 (레포별):
- 규칙 위반 (단계 선진입·결정 이슈 없는 P2·Non-goal·동결 후 feature):

## 문서·코드
spec-sync 결과 요약

## CodeRabbit 미해결
| 레포 | 파일 | 지적 요약 | 분류 제안 |

## 빈 DB 실행
체크리스트 (형상관리자가 채움)

## AI 사용 기록 (chagok-docs `docs/etc/AI_USAGE_AI활용기록.md`에 추가할 줄)
| 날짜 | 릴리스 v0.x | chagok-release-check (+ 쓴 에이전트) | 릴리스 점검: 판정 | 사람이 바꾼 것: (사람이 채움) |
```

판정 기준: A·B·C(C-2 제외) 중 하나라도 막는 항목이 있으면 **보류**. D·E에 사람 판단이 필요한 항목만 있으면 **조건부**. 모두 깨끗하면 **머지 가능**.

## 4. 릴리스 PR과 태그 (사용자가 실행)

```bash
# 순서: chagok-docs → chagok-backend → chagok-frontend (CONTRIBUTING 6장)
gh pr create --repo OneMonthproJect/chagok-backend --base main --head develop \
  --title "[release] v0.5-midcheck" --body-file release-v0.5-backend.md
# 머지는 Merge commit으로. 세 레포 모두 머지한 뒤, 레포마다:
git -C chagok-backend switch main && git -C chagok-backend pull
git -C chagok-backend tag -a v0.5-midcheck -m "중간 점검"
git -C chagok-backend push origin v0.5-midcheck
gh release create v0.5-midcheck --repo OneMonthproJect/chagok-backend --generate-notes --title "v0.5 중간 점검"
```

릴리스 PR 본문에는 판정, 포함 PR 목록, 포함 이슈(`Refs #12`처럼. **`Closes`·`Fixes`·`Resolves`는 쓰지 않는다** — 기본 브랜치가 `main`이라 머지 때 이슈가 닫히고, pr-check가 ❌로 막는다. D-49), 해결한 막는 항목, 미룬 CodeRabbit 지적과 사유, 다른 두 레포의 릴리스 PR 링크를 넣는다. 제목에도 닫는 키워드를 넣지 않는다. 릴리스 PR을 머지한 뒤 화면의 Delete branch는 누르지 않는다(`develop` 유지). 코드 레포는 `release` 라벨이 자동으로 붙고 CodeRabbit이 리뷰를 시작한다(`chagok-docs`는 CodeRabbit 없음). 시작하지 않으면 `@coderabbitai full review` 댓글을 안내한다.

명령은 모두 사람이 실행한다. `gh pr create`·`git tag`·`git push`·`gh release create`는 `.claude/settings.json`이 확인을 묻고, `main`으로의 직접 push는 막혀 있다.

MVP 점검 릴리스가 "머지 가능"이면 P2를 `chagok-scope-guard`로 하나씩 고를 수 있다고 알린다. 관문 2 릴리스 뒤에는 `FEATURE_FREEZE=true`(Organization 변수, 또는 세 레포 각각)로 바꾸라고 알린다.

발표(`v1.0-demo`) 점검이면 "시연에서 하지 말 것" 메모 초안도 만든다: 시드 재실행 순서, 시연 계정, 두 번 누르면 안 되는 버튼, 시연 범위 밖 메뉴, 오래 걸리는 동작, 빈 DB에서 처음 띄울 때 순서.
