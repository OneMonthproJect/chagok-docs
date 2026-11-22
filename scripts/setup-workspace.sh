#!/usr/bin/env bash
# 작업 폴더 준비: chagok-docs 옆에 chagok-backend·chagok-frontend를 clone하고,
# 세 레포를 develop으로 바꾸고, 공용 AI 설정을 코드 레포로 복사한다. 처음 한 번만.
#
# 사용 (Git Bash, 작업 폴더 chagok/에서):  bash chagok-docs/scripts/setup-workspace.sh OneMonthproJect
set -euo pipefail

ORG="${1:-OneMonthproJect}"
DOCS="$(cd "$(dirname "$0")/.." && pwd)"
WS="$(dirname "$DOCS")"
cd "$WS"

for r in chagok-docs chagok-backend chagok-frontend; do
  if [ ! -d "$r/.git" ]; then
    git clone "https://github.com/$ORG/$r.git"
  fi
  git -C "$r" switch develop 2>/dev/null || echo "참고: $r에 develop 브랜치가 아직 없습니다 (형상관리자 초기 설정 전)"
done

bash "$DOCS/scripts/sync-claude.sh" chagok-backend chagok-frontend

echo
echo "완료. 작업 폴더: $WS"
echo "Claude Code는 코드 레포 루트에서 실행합니다: cd chagok-backend && claude"
