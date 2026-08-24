#!/usr/bin/env bash
# Assembles the on-disk fileroot for the tailscale package and invokes
# `apk mkpkg` to produce a single .apk for one architecture.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

: "${APK_BIN:?APK_BIN must point to the host apk binary}"

BIN_DIR="${1:?usage: package-apk.sh <bin_dir> <openwrt_arch> <version> <release> <out_dir>}"
OPENWRT_ARCH="${2:?usage: package-apk.sh <bin_dir> <openwrt_arch> <version> <release> <out_dir>}"
VERSION="${3:?usage: package-apk.sh <bin_dir> <openwrt_arch> <version> <release> <out_dir>}"
RELEASE="${4:-1}"
OUT_DIR="${5:?usage: package-apk.sh <bin_dir> <openwrt_arch> <version> <release> <out_dir>}"

ROOT_DIR="$(mktemp -d)"
trap 'rm -rf "$ROOT_DIR"' EXIT

install -Dm0755 "$BIN_DIR/tailscaled" "$ROOT_DIR/usr/sbin/tailscaled"
ln -s tailscaled "$ROOT_DIR/usr/sbin/tailscale"
install -Dm0755 "$REPO_ROOT/pkg/tailscale/files/tailscale.init" "$ROOT_DIR/etc/init.d/tailscale"
install -Dm0644 "$REPO_ROOT/pkg/tailscale/files/tailscale.conf" "$ROOT_DIR/etc/config/tailscale"
mkdir -p "$ROOT_DIR/etc/tailscale"

mkdir -p "$OUT_DIR"
pkg_file="$OUT_DIR/tailscale-${VERSION}-r${RELEASE}.apk"

log "packaging ${pkg_file} for arch=${OPENWRT_ARCH}"

"$APK_BIN" mkpkg \
  --info "name:tailscale" \
  --info "version:${VERSION}-r${RELEASE}" \
  --info "arch:${OPENWRT_ARCH}" \
  --info "license:BSD-3-Clause" \
  --info "description:Zero config VPN" \
  --info "url:https://tailscale.com" \
  --info "depends:ca-bundle kmod-tun" \
  --script "post-install:${REPO_ROOT}/pkg/tailscale/postinst/post-install.sh" \
  --script "post-deinstall:${REPO_ROOT}/pkg/tailscale/postinst/post-deinstall.sh" \
  --files "$ROOT_DIR" \
  --output "$pkg_file"

log "wrote ${pkg_file}"
