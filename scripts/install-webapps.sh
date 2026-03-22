#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="$SCRIPT_DIR/../webapps.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Config file not found: $CONFIG_FILE"
    exit 1
fi

while IFS='|' read -r name url icon exec_cmd mime_types; do
    # Skip empty lines and comments
    [[ -z "$name" || "$name" =~ ^[[:space:]]*# ]] && continue

    # Trim leading/trailing whitespace
    name="${name// /}"
    name="$(echo "$name" | xargs)"
    url="$(echo "$url" | xargs)"
    icon="$(echo "$icon" | xargs)"
    exec_cmd="$(echo "$exec_cmd" | xargs)"
    mime_types="$(echo "$mime_types" | xargs)"

    # Expand $HOME in exec_cmd
    exec_cmd="${exec_cmd/\$HOME/$HOME}"

    info "Installing: $name"
    webapp-install "$name" "$url" "$icon" "$exec_cmd" "$mime_types"
    success "Installed: $name"
done < "$CONFIG_FILE"

success "All web apps installed."
