#!/usr/bin/env bash
# chagok-docs의 공용 AI 설정(.claude/rules·skills·agents)을 코드 레포의 .claude/로 복사한다.
# 원본은 chagok-docs의 "승인된 커밋"이다. 기본은 형상관리자가 머지한 origin/main(릴리스된 버전).
# develop에만 있는 변경·작업 트리·미커밋·미머지 브랜치는 기본으로 배포하지 않는다.
# 복사본은 코드 레포의 .gitignore로 제외되어 커밋되지 않는다.
#
# 사용 (Git Bash. PowerShell은 & "C:\Program Files\Git\bin\bash.exe" <같은 인자>):
#   작업 폴더(chagok/)에서   bash chagok-docs/scripts/sync-claude.sh chagok-backend chagok-frontend
#   코드 레포 루트에서       bash ../chagok-docs/scripts/sync-claude.sh
#   읽기 전용 확인           --check            (파일·Git 상태를 바꾸지 않음)
#   승인 버전 지정·복구      --ref <커밋|origin/develop>   (origin/develop·origin/main에 머지된 커밋만)
#   손으로 고친 사본이 있어도 진행  --force     (고친 파일은 작업 폴더 .claude-sync-backup/에 보관)
# 원격 최신을 받으려면 먼저 git -C chagok-docs fetch origin (update-workspace.sh가 함께 한다).
set -euo pipefail

MODE=sync; REF=origin/main; FORCE=0; targets=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check ;;
    --ref) shift; REF="${1:?--ref 뒤에 커밋이 필요합니다}" ;;
    --ref=*) REF="${1#--ref=}" ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "모르는 옵션: $1 (--help)" >&2; exit 2 ;;
    *) targets+=("$1") ;;
  esac
  shift
done
[ ${#targets[@]} -eq 0 ] && targets=(".")

DOCS="$(cd "$(dirname "$0")/.." && pwd)"
WS="$(dirname "$DOCS")"
SUBS=(rules skills agents)
PATHS=(.claude/rules .claude/skills .claude/agents)
g() { git -C "$DOCS" "$@"; }

# 1) 원본 확인 — 하나라도 실패하면 아무것도 바꾸지 않고 멈춘다.
SHA="$(g rev-parse -q --verify "${REF}^{commit}" || true)"
[ -n "$SHA" ] || { echo "중단: chagok-docs에서 '$REF'를 찾지 못했습니다. git -C chagok-docs fetch origin 후 다시 실행하세요." >&2; exit 1; }
merged=0
for b in origin/develop origin/main; do
  if g rev-parse -q --verify "$b" >/dev/null && g merge-base --is-ancestor "$SHA" "$b"; then merged=1; fi
done
[ $merged -eq 1 ] || { echo "중단: $REF(${SHA:0:7})는 origin/develop·origin/main에 머지되지 않은 커밋입니다. 머지된 커밋만 배포합니다." >&2; exit 1; }
for p in "${PATHS[@]}"; do
  g rev-parse -q --verify "$SHA:$p" >/dev/null || { echo "중단: ${SHA:0:7}에 $p가 없습니다." >&2; exit 1; }
done
# 내용 버전: rules·skills·agents 트리 해시. docs의 다른 문서만 바뀌면 같은 값이다.
VER="$(for p in "${PATHS[@]}"; do g rev-parse "$SHA:$p"; done | git hash-object --stdin)"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT
extract() { mkdir -p "$2" && g archive "$1" "${PATHS[@]}" | (cd "$2" && tar -xf -); }
listf() { (cd "$1" 2>/dev/null && find "${SUBS[@]}" -type f 2>/dev/null | LC_ALL=C sort) || true; }
extract "$SHA" "$TMP/new" || { echo "중단: 원본을 꺼내지 못했습니다." >&2; exit 1; }
NEW="$TMP/new/.claude"
[ -s "$NEW/rules/ai-rules.md" ] || { echo "중단: 원본에 rules/ai-rules.md가 없습니다." >&2; exit 1; }
listf "$NEW" > "$TMP/new.list"

if ls -d "$HOME"/.claude/skills/chagok-* >/dev/null 2>&1; then
  echo "주의: 개인 폴더 ~/.claude/skills/에 chagok-* 스킬이 있습니다. 같은 이름이면 개인 것이 우선해 옛 버전이 쓰입니다. 지우세요."
fi

rc=0
n=0
for t in "${targets[@]}"; do
  n=$((n + 1))
  dir="$(cd "$t" 2>/dev/null && pwd)" || { echo "건너뜀: $t (폴더 없음)"; rc=1; continue; }
  name="$(basename "$dir")"
  case "$name" in
    chagok-backend|chagok-frontend) ;;
    *) echo "건너뜀: $dir (chagok-backend·chagok-frontend에서만 복사합니다)"; continue ;;
  esac
  C="$dir/.claude"; REC="$C/.synced-from"

  # 2) 이전 동기화 기록 — 새 형식은 "sha …"·"tree …" 줄, 옛 형식은 첫 단어가 커밋.
  prev=""; prevver=""
  if [ -f "$REC" ]; then
    prev="$(sed -n 's/^sha //p' "$REC" | head -1)"
    [ -n "$prev" ] || prev="$(head -1 "$REC" | awk '{print $1}')"
    prevver="$(sed -n 's/^tree //p' "$REC" | head -1)"
    prev="$(g rev-parse -q --verify "${prev}^{commit}" 2>/dev/null || true)"
  fi
  known=0; : > "$TMP/prev.list"
  if [ -n "$prev" ]; then
    extract "$prev" "$TMP/prev$n" 2>/dev/null && [ -d "$TMP/prev$n/.claude" ] && known=1
    [ $known -eq 1 ] && listf "$TMP/prev$n/.claude" > "$TMP/prev.list"
  fi

  # 3) 무엇이 바뀌는지 계산
  write=(); remove=(); edited=(); keep=()
  while IFS= read -r f; do
    cmp -s "$NEW/$f" "$C/$f" 2>/dev/null || write+=("$f")
  done < "$TMP/new.list"
  if [ $known -eq 1 ]; then
    while IFS= read -r f; do
      [ -f "$C/$f" ] || continue
      if ! cmp -s "$TMP/prev$n/.claude/$f" "$C/$f"; then edited+=("$f"); fi
    done < "$TMP/prev.list"
    while IFS= read -r f; do
      grep -qxF -- "$f" "$TMP/new.list" && continue
      [ -f "$C/$f" ] || continue
      if cmp -s "$TMP/prev$n/.claude/$f" "$C/$f"; then remove+=("$f"); else keep+=("$f"); fi
    done < "$TMP/prev.list"
  else
    # 이전 상태를 모름: 원본에 있는 파일만 덮어쓰고(다르면 백업), 그 밖의 파일은 지우지 않는다.
    for f in "${write[@]+"${write[@]}"}"; do [ -f "$C/$f" ] && edited+=("$f"); done
  fi
  extra=$(comm -23 <(listf "$C") <(LC_ALL=C sort -u "$TMP/new.list" "$TMP/prev.list") | wc -l)

  same=0; [ ${#write[@]} -eq 0 ] && [ ${#remove[@]} -eq 0 ] && same=1
  recok=0; [ "$prevver" = "$VER" ] && [ "$prev" = "$SHA" ] && recok=1
  label="$name: $(head -1 "$REC" 2>/dev/null || echo '동기화 기록 없음') → ${SHA:0:7} ($REF)"

  if [ "$MODE" = check ]; then
    if [ $same -eq 1 ]; then echo "최신       $label"
    elif [ $known -eq 1 ] && [ ${#edited[@]} -gt 0 ]; then echo "손댄 사본  $label — 손으로 고친 파일 ${#edited[@]}개: ${edited[*]}"; rc=1
    else echo "갱신 필요  $label — 바뀔 파일 ${#write[@]}개, 지울 파일 ${#remove[@]}개"; rc=1; fi
    [ ${#keep[@]} -gt 0 ] && echo "           원본에서 빠졌지만 손댄 파일이라 남김: ${keep[*]}"
    [ "$extra" -gt 0 ] && echo "           관리 대상이 아닌 파일 ${extra}개는 그대로 둡니다"
    continue
  fi

  if [ $same -eq 1 ]; then
    if [ $recok -eq 1 ] || [ "$prevver" = "$VER" ]; then echo "최신(복사 안 함) $label"; continue; fi
  elif [ $known -eq 1 ] && [ ${#edited[@]} -gt 0 ] && [ $FORCE -eq 0 ]; then
    echo "건너뜀: $name — 사본을 손으로 고친 파일이 있습니다: ${edited[*]}"
    echo "        고친 내용이 필요하면 chagok-docs 원본으로 옮기고, 버려도 되면 --force로 다시 실행하세요(백업됨)."
    rc=1; continue
  fi

  # 4) 적용 — 작업 폴더의 임시 사본에서 만든 뒤 폴더 단위로 바꿔 끼운다. 실패하면 원래대로 되돌린다.
  if [ $same -eq 0 ]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    work="$WS/.claude-sync-work/$name-$stamp"; mkdir -p "$work/stage" "$work/old"
    if [ ${#edited[@]} -gt 0 ]; then
      bk="$WS/.claude-sync-backup/$name-$stamp"
      for f in "${edited[@]}"; do mkdir -p "$bk/$(dirname "$f")"; cp -p "$C/$f" "$bk/$f"; done
      echo "백업: 손댄 파일 ${#edited[@]}개 → $bk"
    fi
    for s in "${SUBS[@]}"; do
      if [ -d "$C/$s" ]; then cp -a "$C/$s" "$work/stage/$s"; else mkdir -p "$work/stage/$s"; fi
    done
    for f in "${write[@]+"${write[@]}"}"; do mkdir -p "$work/stage/$(dirname "$f")"; cp -p "$NEW/$f" "$work/stage/$f"; done
    for f in "${remove[@]+"${remove[@]}"}"; do rm -f "$work/stage/$f"; done
    for s in "${SUBS[@]}"; do find "$work/stage/$s" -mindepth 1 -type d -empty -delete 2>/dev/null || true; done
    mkdir -p "$C"
    moved=(); ok=1
    for s in "${SUBS[@]}"; do
      if [ -e "$C/$s" ]; then mv "$C/$s" "$work/old/$s" || { ok=0; break; }; fi
      moved+=("$s")
      mv "$work/stage/$s" "$C/$s" || { ok=0; break; }
    done
    if [ $ok -eq 0 ]; then
      for s in "${moved[@]+"${moved[@]}"}"; do
        [ -e "$work/old/$s" ] || continue
        rm -rf "${C:?}/$s"; mv "$work/old/$s" "$C/$s"
      done
      echo "실패: $name — 폴더를 바꾸지 못해 원래대로 되돌렸습니다(열려 있는 Claude 세션·편집기를 닫고 다시 실행). 남은 임시 폴더: $work" >&2
      rc=1; continue
    fi
    rm -rf "$work"; rmdir "$WS/.claude-sync-work" 2>/dev/null || true
  fi

  # 5) 정상 반영된 때에만 기록을 바꾼다.
  { echo "${SHA:0:7} ($REF)"; echo "sha $SHA"; echo "tree $VER"; } > "$REC.tmp" && mv "$REC.tmp" "$REC"
  if [ $same -eq 1 ]; then echo "기록 갱신  $label (파일은 이미 같음)"
  else echo "복사함     $label — 바뀜 ${#write[@]}개, 지움 ${#remove[@]}개"; fi
  [ ${#keep[@]} -gt 0 ] && echo "           원본에서 빠졌지만 손댄 파일이라 남김: ${keep[*]}"
  [ "$extra" -gt 0 ] && echo "           관리 대상이 아닌 파일 ${extra}개는 그대로 둠"
done
[ "$MODE" = sync ] && [ $rc -eq 0 ] && echo "Claude Code를 새 세션으로 시작하면 바뀐 설정이 적용됩니다."
exit $rc
