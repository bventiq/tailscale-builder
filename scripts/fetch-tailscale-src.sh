#!/usr/bin/env bash
# Fetches the tailscale/tailscale source tarball for a given version, using
# the same codeload URL pattern as the official OpenWrt package Makefile.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl
require_cmd tar

VERSION="${1:?usage: fetch-tailscale-src.sh <version> <dest_dir>}"
DEST_DIR="${2:?usage: fetch-tailscale-src.sh <version> <dest_dir>}"

mkdir -p "$DEST_DIR"
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

url="https://codeload.github.com/tailscale/tailscale/tar.gz/v${VERSION}"
log "fetching tailscale ${VERSION} from ${url}"
curl -sfL "$url" -o "$tmpfile"
tar -xzf "$tmpfile" -C "$DEST_DIR" --strip-components=1

log "extracted tailscale source to ${DEST_DIR}"
