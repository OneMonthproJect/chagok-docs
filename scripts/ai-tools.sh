#!/usr/bin/env bash
# 차곡 외부 AI 도구(모두 선택) 확인·설치·제거. 기본은 읽기 전용 확인이다.
#
#   bash chagok-docs/scripts/ai-tools.sh                    # check: 설치 상태만 본다(아무것도 바꾸지 않음)
#   bash chagok-docs/scripts/ai-tools.sh install <이름>     # 고른 스킬 하나를 고정 커밋에서 ~/.claude/skills/에 복사
#   bash chagok-docs/scripts/ai-tools.sh remove <이름>      # 이 스크립트로 설치한 스킬만 지운다
#   이름: ponytail · caveman · react-best-practices
#
# 스킬 설치는 파일 복사뿐이다. 훅·settings·권한·플러그인·MCP를 바꾸지 않고, 이미 있으면 건너뛴다.
# RTK·Context7(별도 CLI·MCP)은 실행하지 않고 공식 설치 명령만 보여 준다. 쓰는 조건은 ai-rules.md 「외부 도구」, GUIDE 11장.
set -euo pipefail

SK="${CHAGOK_SKILLS_DIR:-$HOME/.claude/skills}"

# 이름|레포|커밋|레포 안 경로|설치 폴더 이름|라이선스
PINS=(
  "ponytail|DietrichGebert/ponytail|ebd8654c2c627f721eb8f9c0d1bd4090a29f9e10|skills/ponytail|ponytail|MIT"
  "caveman|JuliusBrussee/caveman|e74a11ccdb38b98d15c9f9545787c907dd15f0ab|skills/caveman|caveman|Apache-2.0"
  "react-best-practices|vercel-labs/agent-skills|5a37a6329fbad3666c3207392a6a7c0110e92efb|skills/react-best-practices|vercel-react-best-practices|MIT(SKILL.md 표기)"
)
RTK_VER=1.2.1
CTX7_VER=0.13.1

pin() { local p; for p in "${PINS[@]}"; do [ "${p%%|*}" = "$1" ] && { echo "$p"; return 0; }; done; return 1; }

check() {
  echo "   스킬 (개인 폴더 $SK, Claude Code가 description만 읽고 필요할 때 부름)"
  local p name repo sha sub dir lic st
  for p in "${PINS[@]}"; do
    IFS='|' read -r name repo sha sub dir lic <<< "$p"
    if [ -f "$SK/$dir/.chagok-pin" ]; then
      if grep -q "$sha" "$SK/$dir/.chagok-pin"; then st="있음(고정 버전 ${sha:0:7})"; else st="있음(다른 고정 버전 — remove 후 install로 교체)"; fi
    elif [ -d "$SK/$dir" ]; then st="있음(직접 설치한 것, 버전 모름 — 그대로 써도 됨)"
    else st="없음 → 필요하면: bash chagok-docs/scripts/ai-tools.sh install $name"; fi
    printf '     %-22s %s\n' "$name" "$st"
  done
  echo "     web-design-guidelines  보류(출처 레포·스킬에 라이선스 표기 없음)"
  echo "     webapp-testing         쓰지 않음(Playwright MCP와 중복)"
  if ls -d "$SK"/chagok-* >/dev/null 2>&1; then echo "   주의: $SK에 chagok-* 스킬이 있습니다. 레포 스킬보다 우선하니 지우세요."; fi

  echo "   CLI·MCP (설치는 직접, 아래 명령)"
  if command -v rtk >/dev/null 2>&1; then
    st="$(rtk --version 2>/dev/null | head -1)"
    if grep -qs 'rtk' "$HOME/.claude/settings.json"; then st="$st, 주의: ~/.claude/settings.json에 rtk 훅이 있음(차곡은 수동 사용, rtk init 하지 않음)"; fi
    printf '     %-22s %s\n' rtk "$st"
  else
    printf '     %-22s %s\n' rtk "없음 → 필요하면: winget install --id rtk-ai.rtk -e --version $RTK_VER (훅을 거는 rtk init은 하지 않음)"
  fi
  if grep -qs 'context7' "$HOME/.claude.json" || ls -d "$SK"/*context7* >/dev/null 2>&1; then st="있음"
  else st="없음 → 필요하면: npx ctx7@$CTX7_VER setup --claude (OAuth·외부 통신, 제거 npx ctx7@$CTX7_VER remove)"; fi
  printf '     %-22s %s\n' context7 "$st"
  if grep -qs '"playwright@claude-plugins-official": *true' "$HOME/.claude/settings.json"; then st="켜짐"; else st="없음(UI 확인이 필요할 때 /plugin에서 playwright 설치)"; fi
  printf '     %-22s %s\n' playwright "$st"
  echo "     /security-review·skill-creator: Claude Code·claude.ai 기본 제공(설치 없음)"
}

install_one() (
  local p name repo sha sub dir lic tmp top
  p="$(pin "$1")" || { echo "모르는 이름: $1 (ponytail·caveman·react-best-practices)" >&2; return 2; }
  IFS='|' read -r name repo sha sub dir lic <<< "$p"
  if [ -e "$SK/$dir" ]; then echo "이미 있음: $SK/$dir — 건너뜀(교체하려면 remove 후 install)"; return 0; fi
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "받는 중: $repo @ ${sha:0:12} ($sub, $lic)"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/$sha" -o "$tmp/src.tgz" || { echo "실패: 내려받지 못했습니다(아무것도 바뀌지 않음)" >&2; return 1; }
  top="${repo#*/}-$sha"
  (cd "$tmp" && tar -xzf src.tgz "$top/$sub" && { tar -xzf src.tgz "$top/LICENSE" 2>/dev/null || true; }) \
    || { echo "실패: 압축에서 $sub를 찾지 못했습니다(아무것도 바뀌지 않음)" >&2; return 1; }
  [ -f "$tmp/$top/$sub/SKILL.md" ] || { echo "실패: SKILL.md 없음(아무것도 바뀌지 않음)" >&2; return 1; }
  [ -f "$tmp/$top/LICENSE" ] && [ ! -e "$tmp/$top/$sub/LICENSE" ] && cp "$tmp/$top/LICENSE" "$tmp/$top/$sub/LICENSE"
  printf 'repo %s\nsha %s\npath %s\nlicense %s\ninstalled-by chagok-docs/scripts/ai-tools.sh\n' "$repo" "$sha" "$sub" "$lic" > "$tmp/$top/$sub/.chagok-pin"
  mkdir -p "$SK"
  mv "$tmp/$top/$sub" "$SK/$dir"
  echo "설치함: $SK/$dir — Claude Code 새 세션부터 보입니다. 쓰는 조건은 ai-rules.md 「외부 도구」"
)

remove_one() (
  local p name repo sha sub dir lic
  p="$(pin "$1")" || { echo "모르는 이름: $1" >&2; return 2; }
  IFS='|' read -r name repo sha sub dir lic <<< "$p"
  if [ ! -e "$SK/$dir" ]; then echo "없음: $SK/$dir"; return 0; fi
  if [ ! -f "$SK/$dir/.chagok-pin" ]; then echo "지우지 않음: $SK/$dir 는 이 스크립트가 설치한 것이 아닙니다(직접 지우세요)" >&2; return 1; fi
  rm -rf "${SK:?}/$dir"; echo "지움: $SK/$dir"
)

case "${1:-check}" in
  check) check ;;
  install) shift; [ $# -ge 1 ] || { echo "install 뒤에 이름" >&2; exit 2; }; for n in "$@"; do install_one "$n"; done ;;
  remove) shift; [ $# -ge 1 ] || { echo "remove 뒤에 이름" >&2; exit 2; }; for n in "$@"; do remove_one "$n"; done ;;
  -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "모르는 명령: $1 (check·install·remove)" >&2; exit 2 ;;
esac
