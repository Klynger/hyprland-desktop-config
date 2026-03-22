#!/bin/bash

# Waybar Power Menu - Hyprland + hyprlock + rofi

# Icons
ICON_SUSPEND="⏾"
ICON_REBOOT=""
ICON_SHUTDOWN=""
ICON_LOGOUT=""

notify() {
    command -v notify-send >/dev/null && notify-send "Power" "$1"
}

rofi_menu() {
    printf "%s\n" "$1" | rofi -dmenu -p "⏻" -theme-str 'listview { lines: 4; }'
}

rofi_confirm() {
    printf "Yes\nNo\n" | rofi -dmenu -p "⏻ Confirm" -theme-str 'listview { lines: 2; }'
}

# ---- Actions ----

do_suspend() {
    if command -v hyprlock >/dev/null; then
        hyprlock &
    fi
    systemctl suspend
}

do_reboot() {
    notify "Rebooting…"
    systemctl reboot
}

do_shutdown() {
    notify "Shutting down…"
    systemctl poweroff
}

do_logout() {
    if command -v hyprctl >/dev/null; then
        hyprctl dispatch exit || true
        return
    fi
    notify "Logout not supported."
}

# ---- Menu ----

CHOICES="$ICON_SUSPEND Suspend
$ICON_REBOOT Reboot
$ICON_SHUTDOWN Shutdown
$ICON_LOGOUT Logout"

CHOICE=$(rofi_menu "$CHOICES" | tr -d '\r')

case "${CHOICE,,}" in
    *suspend*)  [[ $(rofi_confirm) == "Yes" ]] && do_suspend ;;
    *reboot*)   [[ $(rofi_confirm) == "Yes" ]] && do_reboot ;;
    *shutdown*) [[ $(rofi_confirm) == "Yes" ]] && do_shutdown ;;
    *logout*)   [[ $(rofi_confirm) == "Yes" ]] && do_logout ;;
    *) exit 0 ;;
esac
