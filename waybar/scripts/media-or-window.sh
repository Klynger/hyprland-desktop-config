#!/bin/bash
# Shows current song when playing, active window title otherwise.
# Continuous output for waybar custom module (one JSON line per update).
# Also manages the album art cache file for the image module.

set -euo pipefail

PLAYER_ICONS='{"chromium":"","firefox":"","mpv":"󰐹","spotify":"󰎆"}'
ART_CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-media-art"

refresh_media_art() {
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

update_art_cache() {
    local art_url art_path=""
    art_url=$(playerctl metadata mpris:artUrl 2>/dev/null || true)

    if [[ -n "$art_url" ]]; then
        if [[ "$art_url" == file://* ]]; then
            art_path="${art_url#file://}"
            art_path=$(python3 -c "from urllib.parse import unquote; print(unquote('$art_path'))")
        fi
    fi

    if [[ -n "$art_path" && -f "$art_path" ]]; then
        cp "$art_path" "$ART_CACHE" 2>/dev/null || true
    else
        rm -f "$ART_CACHE"
    fi
}

remove_art_cache() {
    rm -f "$ART_CACHE"
}

emit() {
    local status
    status=$(playerctl status 2>/dev/null || true)

    if [[ "$status" == "Playing" ]]; then
        local title artist album player icon text tooltip
        title=$(playerctl metadata title 2>/dev/null || true)
        artist=$(playerctl metadata artist 2>/dev/null || true)
        album=$(playerctl metadata album 2>/dev/null || true)
        player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null || true)

        icon=$(echo "$PLAYER_ICONS" | jq -r --arg p "$player" '.[$p] // ""')

        text="$title"
        [[ -n "$artist" ]] && text="$title - $artist"
        [[ -n "$icon" ]] && text="$icon $text"

        tooltip="$title"
        [[ -n "$artist" ]] && tooltip="$tooltip\n$artist"
        [[ -n "$album" ]] && tooltip="$tooltip\n$album"

        update_art_cache

        printf '{"text": %s, "tooltip": %s, "class": "playing"}\n' \
            "$(jq -Rn --arg t "$text" '$t')" \
            "$(jq -Rn --arg t "$tooltip" '$t')"
    else
        local title
        title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""' 2>/dev/null || true)
        [[ -z "$title" ]] && title="Desktop"

        remove_art_cache

        printf '{"text": %s, "tooltip": %s, "class": "window"}\n' \
            "$(jq -Rn --arg t "$title" '$t')" \
            "$(jq -Rn --arg t "$title" '$t')"
    fi

    refresh_media_art
}

# Emit initial state
emit

# Listen for player events and active window changes in parallel
# Re-emit on any change from either source
{
    # playerctl emits lines on play/pause/stop/metadata changes
    playerctl --follow status 2>/dev/null &
    PLAYERCTL_PID=$!

    # Listen to Hyprland's IPC socket for activewindow changes
    python3 -uc "
import socket, sys, os
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(os.environ['XDG_RUNTIME_DIR'] + '/hypr/' + os.environ['HYPRLAND_INSTANCE_SIGNATURE'] + '/.socket2.sock')
f = s.makefile()
for line in f:
    sys.stdout.write(line)
    sys.stdout.flush()
" 2>/dev/null &
    SOCAT_PID=$!

    trap 'kill $PLAYERCTL_PID $SOCAT_PID 2>/dev/null; rm -f "$ART_CACHE"' EXIT

    wait
} | while IFS= read -r _; do
    emit
done
