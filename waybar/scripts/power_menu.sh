#!/bin/bash

# Waybar POwer Menu - Hyprland + hyprlock + wofi
# Prompt is a single icon: ⏻
#
# set -euo pipefail

# Icons
ICON_SUSPEND="⏾"
ICON_REBOOT=""
ICON_SHUTDOWN=""
ICON_LOGOUT=""

# Wofi command with GeistMono Nerd Font
WOFI_CMD="wofi -dmenu -p '⏻' -lines 4 \
  -theme-str 'window { font: \"GeistMono Nerd Font 12\"; } \
  listview { columns: 1; } \
  element { font: \"GeistMono Nerd Font 12\"; }'"

notify() {
  command -v notify-send >/dev/null && notify-send "Power" "$1"
}


wofi_menu() {
  printf "%s\n" "$1" | eval $WOFI_CMD
}

wofi_confirm() {
  printf "Yes\nNo\n" | wofi -dmenu -p "⏻ Confirm" -lines 2 \
  -theme-str 'window { font: "JetBrainsMono Nerd Font Propo 12"; } element { font: "JetBrainsMono Nerd Font Propo 12"; }'
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

# ---- Mneu (NO CANCEL) ----

CHOICES="$ICON_SUSPEND Suspend
$ICON_REBOOT Reboot
$ICON_SHUTDOWN Shutdown
$ICON_LOGOUT Logout"

CHOICE=$(wofi_menu "$CHOICES" | tr -d '\r')

case "${CHOICE,,}" in
  *suspend*)  [[ $(wofi_confirm) == "Yes" ]] && do_suspend ;;
  *reboot*)   [[ $(wofi_confirm) == "Yes" ]] && do_reboot ;;
  *shutdown*) [[ $(wofi_confirm) == "Yes" ]] && do_shutdown ;;
  *logout*)   [[ $(wofi_confirm) == "Yes" ]] && do_logout ;;
  *) exit 0 ;;
esac
