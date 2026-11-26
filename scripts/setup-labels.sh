#!/usr/bin/env bash
# GitHub 라벨 생성 (레포마다 한 번). GitHub CLI(gh) 로그인 후:
#   bash scripts/setup-labels.sh OneMonthproJect            → 세 레포 모두
#   bash scripts/setup-labels.sh OneMonthproJect chagok-docs  → 한 레포만
set -euo pipefail
ORG="${1:-OneMonthproJect}"
[ $# -gt 0 ] && shift
repos=("$@")
[ ${#repos[@]} -eq 0 ] && repos=(chagok-docs chagok-backend chagok-frontend)

for repo in "${repos[@]}"; do
  echo "== $ORG/$repo"
  L() { gh label create "$1" --repo "$ORG/$repo" --color "$2" --description "$3" --force; }
  # 단계
  L "P0-핵심"   B60205 "시나리오 A·B 재방문 순환 최소 경로"
  L "P0-나머지" D93F0B "M2 통합 검증 통과 후 착수"
  L "P1"        FBCA04 "MVP 범위. P0-나머지 다음에 착수"
  L "P2"        C2E0C6 "이번 프로젝트에서 착수하지 않음(D-70). 이후 별도 프로젝트용 참고"
  L "기반"      5319E7 "프로젝트 생성·공통 코드"
  # 이슈 유형
  L "bug"       D73A4A "명세와 다른 동작"
  L "결정필요"  000000 "팀 결정이 있어야 진행 가능"
  L "docs"      0075CA "문서"
  # PR 영역·유형 (labeler 자동)
  L "backend"   1D76DB "chagok-backend 코드 변경"
  L "frontend"  0E8A16 "chagok-frontend 코드 변경"
  L "db"        7057FF "Flyway 마이그레이션·시드 변경"
  L "ci"        BFDADC "GitHub 설정·CI·AI 설정"
  L "feature"   A2EEEF "기능 PR"
  L "fix"       F9D0C4 "버그 수정 PR"
  # 리뷰
  L "review-me" C5DEF5 "CodeRabbit 리뷰 요청 (cycle·인증·보안·DB 변경 시 자동)"
  L "release"   000000 "develop → main 릴리스 PR"
  # 완료 확인 (D-49)
  L "done-verified" 2DA44E "완료 정의 확인됨 — develop 머지 시 issue-close가 이슈를 닫음"
done
