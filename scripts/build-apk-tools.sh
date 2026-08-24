#!/usr/bin/env bash
# Builds a host `apk` binary (apk-tools) from source, pinned to the commit
# that OpenWrt itself currently vendors, so the .apk/Packages.adb we produce
# stay wire-compatible with the apk client that ships on routers.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd git
require_cmd meson
require_cmd ninja

# Pinned to the commit vendored by openwrt/openwrt (apk-tools v3.0.5).
# Keep this in sync with OpenWrt's package/system/apk when it moves.
APK_TOOLS_REF="${APK_TOOLS_REF:-b5a31c0d865342ad80be10d68f1bb3d3ad9b0866}"

WORKDIR="${1:?usage: build-apk-tools.sh <workdir> <out_dir>}"
OUT_DIR="${2:?usage: build-apk-tools.sh <workdir> <out_dir>}"

mkdir -p "$OUT_DIR"

if [ ! -d "$WORKDIR/.git" ]; then
  git clone https://gitlab.alpinelinux.org/alpine/apk-tools.git "$WORKDIR"
fi
git -C "$WORKDIR" fetch --depth 1 origin "$APK_TOOLS_REF"
git -C "$WORKDIR" checkout --detach "$APK_TOOLS_REF"

meson setup "$WORKDIR/build" "$WORKDIR" \
  -Db_lto=true \
  -Ddocs=disabled \
  -Dhelp=enabled \
  -Dlua_version=5.1 \
  -Ddefault_library=static \
  -Durl_backend=wget \
  -Dzstd=disabled \
  -Dpython=disabled \
  -Dtests=disabled \
  -Dcrypto_backend=openssl

ninja -C "$WORKDIR/build" apk

install -m 0755 "$WORKDIR/build/apk" "$OUT_DIR/apk"
log "built apk-tools -> $OUT_DIR/apk"
"$OUT_DIR/apk" --version
