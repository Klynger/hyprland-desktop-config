#!/bin/bash
# Outputs the current MPRIS album art file path for waybar image module.
# Falls back to empty string if no art available.

art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [[ -z "$art_url" ]]; then
    echo ""
    exit 0
fi

# Convert file:// URL to path
if [[ "$art_url" == file://* ]]; then
    path="${art_url#file://}"
    # URL decode
    path=$(python3 -c "from urllib.parse import unquote; print(unquote('$path'))")
    if [[ -f "$path" ]]; then
        echo "$path"
    else
        echo ""
    fi
else
    echo ""
fi
