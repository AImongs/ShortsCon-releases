#!/bin/sh
# 쇼츠콘 macOS 한 줄 설치(수강생용). 터미널에 아래 한 줄을 붙여 넣고 Return:
#   curl -fsSL https://raw.githubusercontent.com/AImongs/ShortsCon-releases/main/install-mac.sh | sh
# 브라우저로 받은 앱은 Apple 공증이 없어 "손상되었기 때문에 열 수 없습니다"가 뜬다. 터미널(curl)로 받으면 그 표시가 붙지 않는다.
# 이미 설치돼 있으면 최신 버전으로 바꾼다(설정·만든 영상·키는 그대로). 원본: ShortsCon 저장소 packaging/install_mac.sh
set -eu
REPO="AImongs/ShortsCon-releases"
say() { printf '%s\n' "$*"; }
fail() { say ""; say "✖ $*"; exit 1; }

say "쇼츠콘 설치를 시작합니다."
[ "$(uname -s)" = "Darwin" ] || fail "macOS 에서만 실행할 수 있습니다."
[ "$(uname -m)" = "arm64" ] || fail "Apple 실리콘(M1 이상) Mac 전용입니다. 이 Mac 은 인텔 칩이라 설치할 수 없습니다."
DEST="${SHORTSCON_INSTALL_DIR:-/Applications}"
if [ ! -w "$DEST" ]; then DEST="$HOME/Applications"; mkdir -p "$DEST"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

url="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=20" | grep -o 'https://[^"]*-mac-arm64\.zip' | head -n 1)" || true
[ -n "$url" ] || fail "다운로드 주소를 찾지 못했습니다. 인터넷 연결을 확인하고 잠시 뒤 다시 실행하세요."
ver="$(printf '%s' "$url" | sed 's/.*ShortsCon-\([0-9.]*\)-mac-arm64\.zip/\1/')"
have="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DEST/ShortsCon.app/Contents/Info.plist" 2>/dev/null || true)"
if [ "$have" = "$ver" ]; then
  say "이미 최신 버전($ver)입니다."
else
  say "$ver 받는 중…(약 110MB)"
  curl -fL --progress-bar -o "$WORK/sc.zip" "$url" || fail "받지 못했습니다. 인터넷 연결을 확인하세요."
  want="$(curl -fsSL "https://github.com/$REPO/releases/download/v$ver/latest.json" | tr -d ' \n' \
          | sed -n 's/.*"mac":{[^}]*"sha256":"\([0-9a-f]*\)".*/\1/p')" || true
  got="$(shasum -a 256 "$WORK/sc.zip" | cut -d' ' -f1)"
  if [ -n "$want" ] && [ "$want" != "$got" ]; then fail "받은 파일이 배포 파일과 다릅니다(손상). 다시 실행하세요."; fi
  ditto -x -k "$WORK/sc.zip" "$WORK/sc"
  [ -d "$WORK/sc/ShortsCon.app" ] || fail "압축 파일 구성이 예상과 다릅니다."
  if pgrep -f "ShortsCon.app/Contents/MacOS/ShortsCon\$" >/dev/null 2>&1; then
    say "쇼츠콘을 종료합니다…"
    osascript -e 'tell application id "kr.dramak.shortscon" to quit' >/dev/null 2>&1 || true
    sleep 3
  fi
  [ -e "$DEST/ShortsCon.app" ] && mv "$DEST/ShortsCon.app" "$HOME/.Trash/ShortsCon $(date +%Y%m%d-%H%M%S).app"
  ditto "$WORK/sc/ShortsCon.app" "$DEST/ShortsCon.app"
  xattr -cr "$DEST/ShortsCon.app" 2>/dev/null || true
  say "✔ 설치: $DEST/ShortsCon.app ($ver)"
fi
say ""
say "쇼츠콘을 엽니다. 이후 업데이트는 앱이 알아서 안내합니다."
open "$DEST/ShortsCon.app" || true
