Closes #

<!-- 제목: [#이슈번호] 이슈 제목 (제목에는 Closes를 쓰지 않음). PR 대상은 develop. 위 줄은 PR 유형에 맞게 고칩니다 (D-71, CONTRIBUTING 5장):
  · 이슈 전체 완료 조건을 채운 최종 PR → Closes #번호 (develop 머지 + done-verified 라벨 + 검사 ✅이면 issue-close가 이 레포 이슈를 닫음, D-49)
  · 이슈 일부만 끝냈고 혼자 검토·머지할 수 있는 PR → Refs #번호 (머지돼도 이슈는 열림, done-verified를 붙이지 않음)
  · PR 자체가 미완·리뷰 준비 전·필수 의존성 미충족 → Draft PR (이슈 전체가 미완이라는 이유만으로 Draft로 하지 않음)
  PR Assignee는 비워 둡니다(인수인계·담당 변경 때만 지정). -->

## 바뀐 문서·설정
-

## 관련 코드 PR (있으면)
- OneMonthproJect/chagok-backend#
- OneMonthproJect/chagok-frontend#

## 확인
- [ ] 변경 유형별 관련 문서를 확인했다 (CONTRIBUTING 7장 「변경 유형별 문서 확인」) — 이 PR에서 고쳤다 / 관련 없음
- [ ] 기능 ID·화면 ID·API 번호·테이블명이 00·04·07·08과 같다
- [ ] 기준 문서(00·04·07·08)가 바뀌었다면 13 changelog에 한 줄 남겼다
- [ ] 08을 바꿨다면 표와 JSON 예시 블록을 함께 고쳤다
- [ ] 문서끼리 다른 곳을 `.claude/rules/source-of-truth.md` 순서와 반대로 고치지 않았다
- [ ] `.claude/`·`CONTRIBUTING.md`·`CONVENTIONS.md`를 바꿨다면: 머지 후 팀 공지(`sync-claude.sh` 다시 실행, `.skill` 재배포)

## AI 사용
- [ ] 없음
- [ ] 있음 → 아래에 기록 한 줄 (docs `AI_USAGE`에는 하루 단위로 통합, CONTRIBUTING 5장 「AI 사용 기록」)
  - `| 날짜 | 레포#이슈 | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |`
- [ ] 커밋·본문에 AI 공동 작성자 표기가 없다 (AI 이름을 넣은 Co-authored-by 트레일러, AI 메일 주소, AI 생성 안내 문구 — CONTRIBUTING 4장)
