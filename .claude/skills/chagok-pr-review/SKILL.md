---
name: chagok-pr-review
description: 차곡 develop 대상 PR을 확인하는 팀원이 리뷰할 때, 또는 작성자가 PR을 올리기 직전 자기 브랜치를 스스로 점검할 때 쓴다. PR diff와 본문을 이슈 완료 정의, 범위(00), CONVENTIONS 7개 규칙, 정비소 격리, cycle 규칙, 08 API 일치, 문서 동기화, AI 표기 기준으로 검토해 심각도별 지적과 리뷰 코멘트 초안, 직접 실행해 볼 확인 순서를 만든다. 승인·머지는 하지 않는다. "PR 리뷰", "#n 봐줘", "승인해도 돼?", "리뷰 코멘트 써줘", "PR 올리기 전에 봐줘", "이 브랜치 점검"이면 이 스킬을 사용한다. 릴리스 PR(develop → main)은 chagok-release-check를 쓴다.
---

# 차곡 PR 리뷰 (확인하는 팀원용)

> 경로 표기: `docs/…`·`CONVENTIONS.md`·`CONTRIBUTING.md`는 `chagok-docs` 기준(코드 레포에서는 `../chagok-docs/…`), `chagok-backend/…`·`chagok-frontend/…`는 각 레포 루트 기준이다(`.claude/rules/ai-rules.md`「작업 폴더와 경로」). 필요한 레포가 작업 폴더에 없으면 지어내지 말고 읽지 못한 것으로 보고한다.

CodeRabbit은 릴리스 PR(`release` 라벨)만 자동으로 본다. develop PR은 확인하는 팀원이 지킨다(GitHub Free 운영: 승인 인원 강제 없음, ❌인 PR은 머지하지 않음). 이 스킬은 확인하는 팀원이 **놓치기 쉬운 것을 순서대로** 확인하게 돕는다. 코드 스타일 취향보다 결함 위험이 먼저다. 코드는 고치지 않고, 승인·머지도 하지 않는다.

## 1. 가져오기

**PR이 있을 때 (확인하는 팀원)**
```bash
gh pr view <번호> --json title,body,headRefName,files,commits,labels
gh pr diff <번호>
gh pr checks <번호>
gh issue view <연결된 이슈 번호>
```

**PR을 올리기 전 (작성자 자가 점검)**: PR이 없으니 브랜치로 본다. 브랜치 이름의 `#번호`로 이슈를 찾는다.
```bash
git fetch origin
git diff origin/develop...HEAD --stat
git diff origin/develop...HEAD
git log --format='%h %s%n%b' origin/develop..HEAD   # AI 표기 확인용
```
자가 점검이면 결론을 "올려도 됨 / 고친 뒤 올림"으로 쓰고, 리뷰 코멘트 초안 대신 PR 본문(템플릿)에서 빠진 칸을 알려 준다.

## 2. 검토 순서

| # | 무엇 | 기준 | 위반이면 |
|---|---|---|---|
| 0 | 형식 | PR 대상(base)이 `develop`(기본 브랜치는 `main`이라 실수하기 쉬움), 브랜치 `feature/`·`fix/`·`docs/`·`chore/` + `#번호-영문`, 제목 `[#번호] …`(제목에 `Closes` 같은 닫는 키워드 없음), 본문 `Closes #번호`, PR 템플릿 체크, 완료 정의를 확인했으면 머지 전에 `done-verified` 라벨을 붙이라고 안내(라벨이 있어야 `issue-close`가 이슈를 닫음, D-49), 코드 레포면 「문서 PR」 칸(링크 또는 「문서 변경 없음」). 동결 중(`FEATURE_FREEZE=true`) `feature/` PR이면 머지하지 않는다. **`gh pr checks`에 ❌가 하나라도 있으면 결론은 "머지하지 않음"** (GitHub가 자동으로 막지 않는다) | blocker |
| 1 | 이슈 완료 정의 | 이슈 본문 「완료 정의」·「할 일」을 diff가 채우는가 | major |
| 2 | 범위 | 이슈 밖 기능, 차례가 오지 않은 단계(M2 통합 검증 전 P1, M3 MVP 검증 전·결정 이슈 없는 P2)·Non-goal 기능, 미리 만든 빈 화면·버튼·API·테이블 (00) | blocker |
| 3 | 정비소 격리 | 정비소 데이터 조회에 shop_id 조건, shop_id는 `@CurrentStaff`에서만, 남의 것은 404 (X-xx) | blocker |
| 4 | cycle 규칙 | 상태 판정이 cycle 밖에 없음, 상태를 저장하지 않음, `LocalDate.now()` 없음 | blocker |
| 5 | 08 일치 | 경로·메서드·요청·응답 필드·에러 코드가 08 표·JSON 예시와 같음, 프론트 types도 같음. API를 바꿨으면 JSON 예시도 고쳤는지 | major |
| 6 | 구조·책임 (CONVENTIONS 1·5·11장) | Controller에 업무 규칙, Service가 다른 도메인 내부에 의존, 상태 전이가 Entity 밖에 있음, 다른 도메인 내부 import, 3장 표 밖 의존, Controller try/catch, Entity setter. 같은 규칙의 복사, 한 번만 쓰는 공통 Service·인터페이스·유틸, 이슈와 무관한 리팩터링. 남의 패키지 `api`·공용 파일을 고쳤으면 CODEOWNERS 주인의 리뷰가 붙었는가. pr-check "도메인 3개 이상" 경고가 있으면 쪼갤 수 있었는지 | major (ArchUnit이 못 잡는 것 위주) |
| 7 | 문서 동기화 | 마이그레이션 ↔ 07, API ↔ 08, 화면 ↔ 09: 링크된 `chagok-docs` 문서 PR이 실제로 그 내용을 고치는지, 머지됐거나 같은 날 머지될지. 이미 있는 Flyway 버전 파일 수정 없음. 「문서 변경 없음」 체크가 사실인지. docs 레포 PR이면 기준 문서 ↔ 13 (pr-check 경고 확인). 문서 PR이면 ID가 00·04·07·08과 같은지, 문서끼리 다른 곳을 `.claude/rules/source-of-truth.md` 순서와 반대로 고치지 않았는지 | major |
| 8 | 테스트·검증 증거 | 이슈에 적힌 T-xx·R-xx·X-xx(04·08 표기 그대로)가 있는가, 정상·오류·권한·경계 사례가 있는가, 테스트를 지우거나 약화하지 않았는가, ArchitectureTest·보안 설정을 고쳐서 통과시키지 않았는가. PR 본문의 테스트 결과가 CI 결과와 맞는가(실행 결과 없이 "통과"라고 쓴 것은 미검증으로 본다, SKIPPED는 통과가 아님) | major (규칙을 꺼서 통과시켰으면 blocker) |
| 9 | 오류·입력 (05 POL-120~129) | `@Valid` 범위, ErrorCode 사용, 오류를 삼켜 성공처럼 응답하지 않음, 저장 버튼 중복 클릭 방지, 실패 시 입력값 유지, 자동 재전송 없음, 변경 API의 `version` 충돌 처리 | minor~major |
| 10 | AI 표기 | AI 공동 작성자 표기는 pr-check가 막으므로 `gh pr checks` 결과로 본다. AI를 썼으면 PR 템플릿 「AI 사용」에 스킬·에이전트 이름과 기록이 있는지(제출 위치는 `ai-rules.md` 「AI만의 규칙」) | major |
| 11 | 유지보수 | 이름, `// LIMIT:`·`// 근거:` 주석, 단순화했다면 PR 본문 「단순화 기록」(이유·영향·제약·위험·개선 시점) | minor |

각 지적은 근거 문서 절이나 CONVENTIONS 규칙 번호를 함께 적는다. 근거 없는 취향 지적은 하지 않는다. 문제가 없으면 억지로 만들지 않는다.

`review-me` 라벨이 붙은 중요 변경이면 필요할 때 `@coderabbitai review`를 요청하라고 안내할 수 있다(자동 리뷰는 없다). CodeRabbit 지적은 머지 차단 조건이 아니다.

## 3. 직접 실행 확인 (CONTRIBUTING 5장: 확인하는 팀원은 브랜치를 받아 실행한다)

PR의 「확인 방법」을 바탕으로 확인하는 팀원이 따라 할 순서를 만든다.

```bash
git fetch origin && git switch <브랜치>
# 다른 코드 레포는 develop 최신으로: git -C ../chagok-frontend switch develop && git -C ../chagok-frontend pull
# 빈 DB로 백엔드 실행(Flyway가 마이그레이션·시드 적용) → 프론트 실행
```
- 화면 이동 순서와 기대 결과
- 격리에 닿는 PR이면: B 정비소 계정으로 같은 화면 → 거부
- 주기에 닿는 PR이면: 시드의 어느 차량이 어떤 상태로 바뀌어야 하는지

## 4. 출력

```markdown
## 결론: 승인 가능 / 수정 후 승인 / 승인 비권장
한 줄 이유

## 지적
| 심각도 | 위치 | 문제 | 근거 | 최소 수정 제안 |
|---|---|---|---|---|

## 직접 실행 확인 순서
1. …

## 리뷰 코멘트 초안
(GitHub에 붙일 문장. 확인하는 팀원이 다듬어서 올림)
```

blocker가 하나라도 있으면 "승인 비권장". major만 있으면 "수정 후 승인".

승인(`gh pr review`)·코멘트 게시(`gh pr comment`)·머지는 실행하지 않는다. 확인하는 팀원이 브랜치를 직접 실행하고 ✅를 확인한 뒤 GitHub에서 한다.

```markdown
## AI 사용 기록 (형식·제출 위치는 `ai-rules.md` 「AI만의 규칙」)
| 날짜 | 레포 PR#번호 | chagok-pr-review | 리뷰: blocker n · major n | 사람이 바꾼 것: (사람이 채움) |
```

---

Claude Code에서는 에이전트 `chagok-pr-reviewer`(`.claude/agents/`)가 이 스킬을 미리 싣고 별도 맥락·제한된 도구로 같은 일을 한다. 절차와 출력 형식은 이 스킬이 원본이다.
