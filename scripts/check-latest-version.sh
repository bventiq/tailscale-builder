#!/usr/bin/env bash
# Compares the latest stable tailscale/tailscale release against the version
# currently published on our GitHub Pages apk feed, and emits GitHub Actions
# job outputs `version` and `should_build`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_cmd curl
require_cmd jq

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required to query the GitHub API}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY (owner/repo) is required}"

FORCE_REBUILD="${FORCE_REBUILD:-false}"
PAGES_BASE_URL="${PAGES_BASE_URL:-https://${GITHUB_REPOSITORY%%/*}.github.io/${GITHUB_REPOSITORY##*/}}"

latest_tag="$(curl -sf \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/tailscale/tailscale/releases/latest | jq -r '.tag_name // empty')"

[ -n "$latest_tag" ] || die "failed to resolve the latest tailscale/tailscale release"
latest_version="${latest_tag#v}"

published_version=""
if curl -sf "${PAGES_BASE_URL%/}/VERSION" -o "${RUNNER_TEMP:-/tmp}/published_version" 2>/dev/null; then
  published_version="$(tr -d '[:space:]' < "${RUNNER_TEMP:-/tmp}/published_version")"
fi

should_build=false
if [ "$FORCE_REBUILD" = "true" ]; then
  should_build=true
  log "force_rebuild requested; building version ${latest_version}"
elif [ "$latest_version" != "$published_version" ]; then
  should_build=true
  log "new version detected: published='${published_version:-<none>}' latest='${latest_version}'"
else
  log "no new version to build (published='${published_version}')"
fi

{
  echo "version=${latest_version}"
  echo "should_build=${should_build}"
} >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
