#!/usr/bin/env bash
# Host-friendly release-quick wrapper.
#
# Why bare `PREPARE_FOR="" make release-quick` fails on this host:
#   1) system pandoc is 3.x (project expects 2.5 — Dockerfile/README)
#   2) Arch bash-as-/bin/sh: `echo -n "\n\n"` writes literal \n, glues RELEASE tags
#   3) Makefile `find ./ -iname *_sag.tex` walks tmp-* / .worktrees orphan SAGs
#
# Builds via whitepaper-build Docker image (pandoc 2.5). Parks tmp* and
# .worktrees for the run, restores on exit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

IMAGE="${WHITEPAPER_IMAGE:-whitepaper-build:latest}"
PREPARE_FOR="${PREPARE_FOR-}"
MAKE_TARGET="${MAKE_TARGET:-release-quick}"
ASIDE_ROOT="$(mktemp -d /tmp/wp-release-aside.XXXXXX)"
MOVED=()

log() { printf '> %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

restore_aside() {
  local i entry src dest
  for ((i=${#MOVED[@]}-1; i>=0; i--)); do
    entry="${MOVED[$i]}"
    src="${entry%%|*}"
    dest="${entry#*|}"
    if [[ -e "$src" || -L "$src" ]]; then
      if [[ -e "$dest" || -L "$dest" ]]; then
        log "skip restore $src -> $dest (destination exists)"
      else
        mv -- "$src" "$dest"
        log "restored $dest"
      fi
    fi
  done
  rmdir "$ASIDE_ROOT" 2>/dev/null || true
}
trap restore_aside EXIT

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
need_cmd docker
need_cmd make

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  log "docker image $IMAGE missing; building (make docker-build)..."
  make docker-build
fi

# Park scratch/worktree trees so find ./ does not build orphan SAGs.
park_path() {
  local path="$1" base dest abs
  [[ -e "$path" ]] || return 0
  abs="$(cd "$(dirname -- "$path")" && pwd)/$(basename -- "$path")"
  base="$(basename -- "$abs")"
  dest="$ASIDE_ROOT/$base"
  if [[ -e "$dest" ]]; then
    dest="$ASIDE_ROOT/${base}.$$.$RANDOM"
  fi
  mv -- "$abs" "$dest"
  MOVED+=("$dest|$abs")
  log "parked $abs -> $dest"
}

shopt -s nullglob
for d in tmp*; do
  [[ -d "$d" ]] || continue
  park_path "$d"
done
[[ -d .worktrees ]] && park_path .worktrees
shopt -u nullglob

log "running in docker: PREPARE_FOR=$(printf %q "$PREPARE_FOR") make $MAKE_TARGET"
log "image: $IMAGE  (parked ${#MOVED[@]} path(s))"

docker run --rm -t \
  -u "$(id -u):$(id -g)" \
  -e "TERM=${TERM:-xterm-color}" \
  -e "PREPARE_FOR=${PREPARE_FOR}" \
  -v "$ROOT":/work \
  -w /work \
  "$IMAGE" \
  unbuffer make "$MAKE_TARGET"

log "done. outputs:"
ls -la whitepaper-latest.pdf whitepaper-release.pdf output/whitepaper.pdf 2>/dev/null || true
if command -v pdfinfo >/dev/null 2>&1 && [[ -f whitepaper-latest.pdf ]]; then
  pdfinfo whitepaper-latest.pdf | grep -E '^(Title|Pages|File size|Creator):' || true
fi
