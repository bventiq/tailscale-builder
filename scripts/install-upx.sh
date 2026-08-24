#!/usr/bin/env bash
# Downloads a pinned upstream UPX release (not the distro-packaged one, which
# can be stale and miss target-format support) for the amd64 CI runner. UPX
# packs by ELF e_machine/endianness, so this single host binary can compress
# binaries for every target architecture we build.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl
require_cmd tar

UPX_VERSION="${UPX_VERSION:-5.2.0}"
DEST_DIR="${1:?usage: install-upx.sh <dest_dir>}"

mkdir -p "$DEST_DIR"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

archive="upx-${UPX_VERSION}-amd64_linux.tar.xz"
url="https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${archive}"
log "downloading ${url}"
curl -sfL "$url" -o "$tmpdir/$archive"
tar -xJf "$tmpdir/$archive" -C "$tmpdir"

install -m 0755 "$tmpdir/upx-${UPX_VERSION}-amd64_linux/upx" "$DEST_DIR/upx"
log "installed upx -> $DEST_DIR/upx"
"$DEST_DIR/upx" --version
