#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. $SCRIPT_DIR/utils.sh

SRC_DIR="$REPO_ROOT/bin"
DEST_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

mkdir -p "$DEST_DIR"

for f in "$SRC_DIR"/*; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"

  # only link executable files
  [ -x "$f" ] || continue

  ln -sf "$f" "$DEST_DIR/$name"
  success "linked $name"
done
