#!/bin/bash
# Outputs a stable path for waybar image module.
# The actual file is managed by media-or-window.sh.

ART_CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-media-art"

if [[ -f "$ART_CACHE" ]]; then
    echo "$ART_CACHE"
else
    echo ""
fi
