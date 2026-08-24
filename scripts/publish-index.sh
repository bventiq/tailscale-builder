#!/usr/bin/env bash
# Generates and signs the APKv3 repository index (Packages.adb) for a single
# architecture directory containing one or more .apk files.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

: "${APK_BIN:?APK_BIN must point to the host apk binary}"

ARCH_DIR="${1:?usage: publish-index.sh <arch_dir> <signing_key_file> <description>}"
SIGNING_KEY_FILE="${2:?usage: publish-index.sh <arch_dir> <signing_key_file> <description>}"
DESCRIPTION="${3:-tailscale-builder}"

[ -f "$SIGNING_KEY_FILE" ] || die "signing key file not found: ${SIGNING_KEY_FILE}"

log "generating Packages.adb in ${ARCH_DIR}"
(
  cd "$ARCH_DIR"
  shopt -s nullglob
  apks=(./*.apk)
  [ "${#apks[@]}" -gt 0 ] || die "no .apk files found in ${ARCH_DIR}"
  # --allow-untrusted: the individual .apk files are intentionally left
  # unsigned (we only sign the index, matching Alpine's model); without this
  # flag `apk mkndx` refuses to index them with "UNTRUSTED signature".
  "$APK_BIN" mkndx \
    --allow-untrusted \
    --output Packages.adb \
    --sign-key "$SIGNING_KEY_FILE" \
    --description "$DESCRIPTION" \
    "${apks[@]}"
)
log "signed index written to ${ARCH_DIR}/Packages.adb"
