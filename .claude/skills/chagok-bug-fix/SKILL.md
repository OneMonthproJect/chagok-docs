---
name: chagok-bug-fix
description: 차곡에서 명세와 다르게 동작하는 버그를 재현하고 원인을 찾아 최소 수정과 재발 방지 테스트로 고친다. 기대 동작은 04·05·08 명세를 근거로 하고, CONVENTIONS 규칙(cycle 단일 모듈, getOwned 격리, ErrorCode)을 지키며 fix/ 브랜치·커밋·PR 본문까지 만든다. 동결 후에도 쓴다. "버그", "에러 나", "안 돼", "500", "대상 목록이 이상해", "다른 정비소 데이터가 보여", "#n 버그 고쳐줘"이면 이 스킬을 사용한다.
---

# 차곡 버그 수정

> 경로 표기: `docs/…`·`CONVENTIONS.md`·`CONTRIBUTING.md`는 `chagok-docs` 기준(코드 레포에서는 `../chagok-docs/…`), `chagok-backend/…`·`chagok-frontend/…`는 각 레포 루트 기준이다(`.claude/rules/ai-rules.md`「작업 폴더와 경로」). 필요한 레포가 작업 폴더에 없으면 지어내지 말고 읽지 못한 것으로 보고한다.

버그의 기준은 **명세**다. "이상해 보인다"가 아니라 04·05·08과 다른 동작이 버그다. 코드 규칙은 `CONVENTIONS.md`를 그대로 따르고, 여기에 복사하지 않는다.

## 1. 절차

1. **현상 정리**: 이슈(`gh issue view <번호>`, 지금 레포 기준. 다른 레포면 `--repo OneMonthproJect/chagok-…`) 또는 사용자 설명에서 어디서·재현 순서·실제 결과를 뽑는다.
2. **기대 동작의 근거 찾기**: 04(기능·주기 규칙·T-xx), 05(정책), 08(응답·에러 코드·X-xx)에서 해당 절을 찾는다. 이 동작에 관한 `13_changelog` 줄이나 닫힌 `결정` 이슈가 있으면 그것이 먼저다. 문서끼리 다르면 `.claude/rules/source-of-truth.md` 순서로 판단한다(05는 04·08에 맞춰 고칠 대상). 명세에 없거나 **기준 문서(00·04·07·08)끼리** 다르면 버그가 아니라 결정 문제다 → 멈추고 `chagok-spec-sync` 모드 A와 `결정` 이슈를 권한다.
3. **재현**: 가능하면 실패하는 테스트부터 쓴다. 테스트 ID는 04·08 표기 그대로(CONVENTIONS 8장 기준 T1~T17·R1~R8(04), X1~X10). 주기 문제는 `test/.../cycle`, 격리 문제는 `test/.../isolation`에 이름 앞에 ID를 붙인다. 테스트가 어려우면 재현 요청(curl)·화면 순서를 적는다. 앱을 띄우거나 요청을 보내기 전에 한 줄로 알린다.
4. **원인 찾기**: 증상이 아니라 원인. 고칠 메서드의 호출부를 모두 확인한다. 자주 나오는 원인:
   - 상태 판정이 cycle 밖에 복사됨 → 복사본을 지우고 cycle 호출로
   - shop_id 조건 빠짐, shop_id를 요청 값에서 받음 → `getOwned` · `@CurrentStaff`
   - `LocalDate.now()` 직접 호출 → `Clock`
   - Controller try/catch로 오류 모양이 다름 → `BusinessException(ErrorCode)`
   - 프론트가 상태를 다시 계산함 → 서버 값 그대로
   - 시드가 07·마이그레이션과 어긋남 → `chagok-seed-data`
5. **최소 수정**: 원인 한 곳만 고친다. 같은 패턴이 다른 곳에도 있으면 **고치지 말고** 목록으로 보고한다(별도 이슈 후보).
6. **점검**: 재현 테스트 통과, `./gradlew build`(ArchitectureTest 포함, DB가 있으면 `./gradlew dbTest`) 또는 `npm run lint && npm run build`. 못 돌렸으면 "미검증(이유)"으로 보고하고 완료라고 하지 않는다.

원인 한 곳만 고치는 수정이 아니라 여러 파일·도메인·구조에 걸치거나 API·DB를 바꿔야 하면, 고치기 전에 `ai-rules.md` 「작업 절차」 2단계(계획 보고)를 하고 개발자 승인을 받는다. 테스트를 통과시키려고 검증을 지우거나 예외를 삼키지 않는다(CONVENTIONS 12장).
7. **PR 전 점검**: Claude Code면 API를 건드렸을 때 `chagok-contract-checker`, 이어서 `chagok-pr-reviewer`에게 맡기고 결과를 사람에게 보여 준다. claude.ai면 `chagok-spec-sync` 모드 C·`chagok-pr-review`(작성자 자가 점검)로.
8. **보고**: 아래 형식. 커밋·push·PR은 사용자가 확인한 뒤에(`.claude/settings.json`이 확인을 묻는다).

## 2. 멈추고 물어볼 때

- 고치려면 08 응답·에러 코드나 07 구조(마이그레이션)를 바꿔야 한다 → 문서가 먼저(`chagok-docs`에 `결정` 이슈 → 문서 PR)
- 도메인 3개 이상의 내부를 고쳐야 한다 → 원인이 구조에 있을 가능성. 우회 코드 대신 보고
- 동결 후(`FEATURE_FREEZE=true`)인데 수정이 사실상 기능 추가다 → `chagok-scope-guard`. 동결 후에도 `fix/` 브랜치는 머지된다

## 3. 보고 형식

```markdown
## 버그
- 실제: …
- 기대: … (근거: 04 §… / 08 API n번 / X-xx)

## 원인
파일:줄 — 왜 이렇게 됐는지

## 수정
- 고친 파일
- 재발 방지 테스트: T-xx / X-xx / (새 테스트 이름)
- 빌드: 성공 / 미확인

## 같은 패턴이 남은 곳 (이번에 고치지 않음)
- …

## PR 전 점검
- contract-checker: ❌ n건 / 해당 없음 / 미실행
- pr-reviewer: blocker n · major n / 미실행

## 브랜치·커밋·PR
- 브랜치: fix/#번호-short-name (영문 소문자·숫자·하이픈)
- 커밋: fix: 무엇을 고쳤는지 (#번호)
- push 전: git pull origin develop
- PR 제목: [#번호] 이슈 제목
- PR 본문: (이 레포 `.github/PULL_REQUEST_TEMPLATE.md` 초안, 첫 줄 Closes #번호, 「문서 PR」 칸: 링크 또는 「문서 변경 없음」)

## 트러블슈팅 기록 후보 (chagok-docs `docs/etc/DEV_REVIEW_트러블슈팅.md`)
- 에러 / 원인 / 해결 각 한 줄 (팀에 남길 만한 버그일 때만)

## AI 사용 기록 (chagok-docs `docs/etc/AI_USAGE_AI활용기록.md`에 추가할 줄)
| 날짜 | 레포#번호 | chagok-bug-fix (+ 쓴 에이전트) | 한 일 | 사람이 바꾼 것: (사람이 채움) |
```

커밋 메시지·PR 본문에 AI 공동 작성자 표기를 넣지 않는다(CONTRIBUTING 4장).
