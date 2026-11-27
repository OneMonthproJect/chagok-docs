#!/usr/bin/env bash
# 팀원용 한 번에 적용: 세 레포 안전 최신화 → 공용 AI 설정 동기화 → 외부 도구 확인. 작업 폴더(chagok/)에서 실행한다.
#
#   bash chagok-docs/scripts/update-workspace.sh                 # 적용 (AI 설정은 승인·릴리스된 docs origin/main 기준)
#   bash chagok-docs/scripts/update-workspace.sh --check         # 읽기 전용(fetch도 하지 않음, 아무것도 바꾸지 않음)
#   bash chagok-docs/scripts/update-workspace.sh --ref <커밋>    # 형상관리자가 공지한 승인 버전(또는 origin/develop)으로 동기화·복구
#   PowerShell: & "C:\Program Files\Git\bin\bash.exe" chagok-docs/scripts/update-workspace.sh
#
# 하는 일: ① 레포별 브랜치·미커밋·미푸시 확인 ② git fetch origin ③ develop에 있고, 커밋 안 한 변경이 없고,
#          원격과 갈라지지 않은 레포만 fast-forward ④ sync-claude.sh ⑤ ai-tools.sh(확인만)
# 하지 않는 일: 브랜치 전환, stash·reset·clean, push, 브랜치 삭제, 외부 도구 설치, 권한 설정 변경.
# 안전하지 않은 레포는 그 레포만 건너뛰고 이유를 알려 준다(종료 코드 1).
set -euo pipefail

# 최신화 중에 이 파일이 바뀌어도 안전하도록 임시 사본으로 다시 실행한다.
if [ -z "${CHAGOK_UW_COPY:-}" ]; then
  self="$(mktemp)"; cp "$0" "$self"
  CHAGOK_UW_COPY="$self" CHAGOK_DOCS="$(cd "$(dirname "$0")/.." && pwd)" exec bash "$self" "$@"
fi
trap 'rm -f "$CHAGOK_UW_COPY"' EXIT

MODE=apply; SYNC_ARGS=(); REF=origin/main
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check; SYNC_ARGS+=(--check) ;;
    --ref) shift; REF="${1:?--ref 뒤에 커밋이 필요합니다}" ;;
    --ref=*) REF="${1#--ref=}" ;;
    -h|--help) sed -n '2,15p' "$CHAGOK_DOCS/scripts/update-workspace.sh" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "모르는 옵션: $1 (--help)" >&2; exit 2 ;;
  esac
  shift
done

DOCS="$CHAGOK_DOCS"; WS="$(dirname "$DOCS")"
rc=0

echo "== 1. 레포 상태·최신화 ($MODE)"
[ "$MODE" = check ] && echo "   (--check: fetch하지 않으므로 원격 상태는 마지막 fetch 기준)"
for r in chagok-docs chagok-backend chagok-frontend; do
  d="$WS/$r"
  if ! git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then echo "   $r: 없음 — setup-workspace.sh로 clone"; rc=1; continue; fi
  if [ "$MODE" = apply ] && ! git -C "$d" fetch -q origin; then echo "   $r: fetch 실패 — 건너뜀(네트워크·인증 확인)"; rc=1; continue; fi
  br="$(git -C "$d" branch --show-current)"
  dirty="$(git -C "$d" status --porcelain --untracked-files=no | wc -l | tr -d ' ')"
  ahead="$(git -C "$d" rev-list --count origin/develop..develop 2>/dev/null || echo '?')"
  behind="$(git -C "$d" rev-list --count develop..origin/develop 2>/dev/null || echo '?')"
  unpushed=""
  if up="$(git -C "$d" rev-parse -q --verify '@{u}' 2>/dev/null)" && [ -n "$up" ]; then
    k="$(git -C "$d" rev-list --count '@{u}..HEAD')"; [ "$k" != 0 ] && unpushed=", push 안 한 커밋 ${k}개"
  fi
  head="   $r [${br:-HEAD 분리}]"
  if [ "$br" != develop ]; then
    echo "$head 작업 브랜치라 전환하지 않음 (develop은 원격보다 ${behind}개 뒤${unpushed}). 작업을 마치고 develop으로 돌아온 뒤 다시 실행"
  elif [ "$dirty" != 0 ]; then
    echo "$head 건너뜀: 커밋하지 않은 변경 ${dirty}개. 내 작업 브랜치에 커밋한 뒤 다시 실행(stash·reset 하지 않음)"; rc=1
  elif [ "$ahead" != 0 ]; then
    echo "$head 건너뜀: 로컬 develop에 원격에 없는 커밋 ${ahead}개(갈라짐). 강제로 맞추지 말고 형상관리자에게 문의"; rc=1
  elif [ "$behind" = 0 ]; then
    echo "$head 최신"
  elif [ "$MODE" = check ]; then
    echo "$head 최신화 가능: 원격 커밋 ${behind}개"
  elif git -C "$d" merge -q --ff-only origin/develop; then
    echo "$head 최신화: 커밋 ${behind}개 반영"
  else
    echo "$head 건너뜀: fast-forward 실패(작업 트리 파일 충돌). 상태를 확인하세요"; rc=1
  fi
done

echo "== 2. 공용 AI 설정 (chagok-docs → 코드 레포 .claude/)"
targets=()
for r in chagok-backend chagok-frontend; do [ -d "$WS/$r" ] && targets+=("$WS/$r"); done
if [ ${#targets[@]} -gt 0 ]; then
  bash "$DOCS/scripts/sync-claude.sh" "${SYNC_ARGS[@]+"${SYNC_ARGS[@]}"}" --ref "$REF" "${targets[@]}" || rc=1
fi

echo "== 3. 외부 도구 (선택, 확인만)"
if [ -f "$DOCS/scripts/ai-tools.sh" ]; then bash "$DOCS/scripts/ai-tools.sh" check || true; fi

echo "== 결과"
echo "   AI 설정 기준 $REF: $(git -C "$DOCS" log -1 --format='%h %cs %<(50,trunc)%s' "$REF" 2>/dev/null || echo '찾지 못함')"
if [ "$MODE" = check ]; then
  echo "   읽기 전용 확인만 했습니다. 적용하려면 --check 없이 다시 실행하세요."
elif [ $rc -eq 0 ]; then
  echo "   문제 없음. 열려 있던 Claude Code 세션은 끝내고 새 세션(코드 레포 루트에서 claude)으로 시작하세요."
else
  echo "   건너뛴 레포가 있습니다. 위 안내대로 정리한 뒤 다시 실행하면 그 레포만 처리됩니다."
fi
exit $rc
