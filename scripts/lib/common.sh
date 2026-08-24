#!/usr/bin/env bash
# Shared helpers sourced by the other scripts in this directory.

log() {
  printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$(date -u +%H:%M:%S)" "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}
