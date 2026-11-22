#!/usr/bin/env bash
# chagok-docs의 공용 AI 설정(.claude/rules·skills·agents)을 코드 레포의 .claude/로 복사한다.
# 원본은 chagok-docs에만 있다. 복사본은 코드 레포의 .gitignore로 제외되어 커밋되지 않는다.
#
# 사용 (Git Bash):
#   코드 레포 루트에서      bash ../chagok-docs/scripts/sync-claude.sh
#   작업 폴더(chagok/)에서  bash chagok-docs/scripts/sync-claude.sh chagok-backend chagok-frontend
#
# chagok-docs를 pull한 뒤, 또는 스킬·규칙이 바뀌었다는 공지를 받으면 다시 실행한다.
set -euo pipefail

DOCS="$(cd "$(dirname "$0")/.." && pwd)"
SRC_REV="$(git -C "$DOCS" rev-parse --short HEAD 2>/dev/null || echo unknown)"
SRC_BRANCH="$(git -C "$DOCS" branch --show-current 2>/dev/null || echo unknown)"

if [ "$SRC_BRANCH" != "develop" ]; then
  echo "주의: chagok-docs가 develop이 아니라 '$SRC_BRANCH' 브랜치입니다. 이 브랜치의 설정이 복사됩니다."
fi

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(".")

for t in "${targets[@]}"; do
  dir="$(cd "$t" && pwd)"
  name="$(basename "$dir")"
  case "$name" in
    chagok-backend|chagok-frontend) ;;
    *) echo "건너뜀: $dir (chagok-backend·chagok-frontend에서만 복사합니다)"; continue ;;
  esac
  mkdir -p "$dir/.claude"
  for sub in rules skills agents; do
    rm -rf "${dir:?}/.claude/$sub"
    cp -r "$DOCS/.claude/$sub" "$dir/.claude/$sub"
  done
  echo "$SRC_REV ($SRC_BRANCH)" > "$dir/.claude/.synced-from"
  echo "복사함: $name/.claude/{rules,skills,agents} ← chagok-docs $SRC_REV ($SRC_BRANCH)"
done
