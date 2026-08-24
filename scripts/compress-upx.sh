#!/usr/bin/env bash
# Compresses a binary with UPX. This is a HARD requirement, not best-effort:
# many target devices have very little flash, and their storage budget
# assumes a UPX-compressed package. If compression fails, we refuse to ship
# the uncompressed binary and fail the build for this architecture instead
# (the whole publish is gated on every architecture succeeding - see the
# workflow - so a bad arch blocks that cycle's release rather than silently
# shipping an oversized package).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

: "${UPX_BIN:?UPX_BIN must point to the upx binary}"
BINARY="${1:?usage: compress-upx.sh <binary-path>}"

[ -x "$UPX_BIN" ] || command -v "$UPX_BIN" >/dev/null 2>&1 || die "upx binary not found at UPX_BIN=${UPX_BIN}"

before_size="$(stat -c%s "$BINARY")"

if ! "$UPX_BIN" --best --lzma "$BINARY"; then
  die "UPX compression failed for ${BINARY} - refusing to ship an uncompressed binary (flash-constrained devices depend on this)"
fi

after_size="$(stat -c%s "$BINARY")"
log "UPX compressed ${BINARY}: ${before_size} -> ${after_size} bytes"
