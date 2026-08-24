#!/usr/bin/env bash
# Cross-compiles tailscaled (with the tailscale CLI dispatch built in via
# ts_include_cli) for one target, mirroring the flags used by the official
# OpenWrt net/tailscale package Makefile so behavior matches upstream.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd go

SRC_DIR="${1:?usage: build-tailscaled.sh <src_dir> <out_dir> <version> <release>}"
OUT_DIR="${2:?usage: build-tailscaled.sh <src_dir> <out_dir> <version> <release>}"
VERSION="${3:?usage: build-tailscaled.sh <src_dir> <out_dir> <version> <release>}"
RELEASE="${4:-1}"

: "${GOARCH:?GOARCH must be set by the caller}"

export GOOS=linux
export CGO_ENABLED=0
export GOARCH
export GOARM="${GOARM:-}"
export GOMIPS="${GOMIPS:-}"
export GO386="${GO386:-}"
export GOAMD64="${GOAMD64:-}"

mkdir -p "$OUT_DIR"

TAGS="ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm"
LDFLAGS="-s -w -X 'tailscale.com/version.longStamp=${VERSION}-${RELEASE} (OpenWrt)' -X tailscale.com/version.shortStamp=${VERSION}"

log "building tailscaled: GOARCH=${GOARCH} GOARM=${GOARM} GOMIPS=${GOMIPS} GO386=${GO386} GOAMD64=${GOAMD64}"

(
  cd "$SRC_DIR"
  go build -trimpath -tags "$TAGS" -ldflags "$LDFLAGS" -o "$OUT_DIR/tailscaled" ./cmd/tailscaled
)

ln -sf tailscaled "$OUT_DIR/tailscale"
log "built ${OUT_DIR}/tailscaled ($(du -h "$OUT_DIR/tailscaled" | cut -f1))"
