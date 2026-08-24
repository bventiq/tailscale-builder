#!/usr/bin/env bash
# Takes the per-architecture .apk artifacts produced by the build matrix and
# assembles/signs the published GitHub Pages tree (one directory per
# architecture, each with its .apk + signed Packages.adb, plus the
# VERSION/BUILD_INFO.json/index.html/keys files at the root).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd jq
require_cmd sha256sum
: "${APK_BIN:?APK_BIN must point to the host apk binary}"

GH_PAGES_DIR="${1:?usage: assemble-and-sign.sh <gh_pages_dir> <artifacts_dir> <version> <signing_key_file>}"
ARTIFACTS_DIR="${2:?usage: assemble-and-sign.sh <gh_pages_dir> <artifacts_dir> <version> <signing_key_file>}"
VERSION="${3:?usage: assemble-and-sign.sh <gh_pages_dir> <artifacts_dir> <version> <signing_key_file>}"
SIGNING_KEY_FILE="${4:?usage: assemble-and-sign.sh <gh_pages_dir> <artifacts_dir> <version> <signing_key_file>}"
ARCHES_JSON="${SCRIPT_DIR}/lib/arches.json"

mkdir -p "$GH_PAGES_DIR/keys"
install -m 0644 "$REPO_ROOT/keys/tailscale-builder.pem" "$GH_PAGES_DIR/keys/tailscale-builder.pem"

arch_entries="{}"

while IFS= read -r arch; do
  arch_dir="$GH_PAGES_DIR/$arch"
  mkdir -p "$arch_dir"

  # Drop any previously published package for this arch before installing
  # the new one - we only ever keep the latest version per architecture.
  find "$arch_dir" -maxdepth 1 -name '*.apk' -delete

  src_apk="$(find "${ARTIFACTS_DIR}/apk-${arch}" -maxdepth 1 -name '*.apk' 2>/dev/null | head -n1)"
  [ -n "$src_apk" ] || die "no .apk artifact found for arch=${arch} in ${ARTIFACTS_DIR}/apk-${arch}"

  install -m 0644 "$src_apk" "$arch_dir/"
  bash "$SCRIPT_DIR/publish-index.sh" "$arch_dir" "$SIGNING_KEY_FILE" "tailscale-builder ${VERSION}"

  sha256="$(sha256sum "$arch_dir"/*.apk | awk '{print $1}')"
  fname="$(basename "$arch_dir"/*.apk)"
  arch_entries="$(jq --arg a "$arch" --arg f "$fname" --arg s "$sha256" \
    '. + {($a): {file: $f, sha256: $s}}' <<<"$arch_entries")"

  log "published ${arch}: ${fname} (sha256=${sha256})"
done < <(jq -r '.[].openwrt_arch' "$ARCHES_JSON")

jq -n --arg version "$VERSION" \
  --arg built_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson arches "$arch_entries" \
  '{tailscale_version: $version, built_at: $built_at, arches: $arches}' \
  > "$GH_PAGES_DIR/BUILD_INFO.json"

printf '%s' "$VERSION" > "$GH_PAGES_DIR/VERSION"

repo_url="https://github.com/${GITHUB_REPOSITORY:-}"
cat > "$GH_PAGES_DIR/index.html" <<EOF
<!doctype html>
<html>
<head><meta charset="utf-8"><title>tailscale-builder apk feed</title></head>
<body>
<h1>tailscale-builder</h1>
<p>Current tailscale version: <strong>${VERSION}</strong></p>
<p>See the <a href="${repo_url}">repository README</a> for setup instructions.</p>
</body>
</html>
EOF

log "assembled gh-pages tree for version ${VERSION}"
