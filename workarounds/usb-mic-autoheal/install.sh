#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# USB MIC AUTO-HEAL — INSTALL / UNINSTALL (requires sudo)
# ============================================================
# Installs the udev rule, systemd service, and heal script
# that recover the flaky C-Media USB mic automatically.
# See README.md for the full story.
#
# Usage:
#   sudo ./install.sh --create
#   sudo ./install.sh --delete
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/../../scripts/utils.sh"

if [[ $EUID -ne 0 ]]; then
    error "This script must be run with sudo"
    error "Usage: sudo $0 [--create | --delete]"
    exit 1
fi

BIN_TARGET="/usr/local/bin/usb-mic-autoheal"
SERVICE_TARGET="/etc/systemd/system/usb-mic-autoheal.service"
RULE_TARGET="/etc/udev/rules.d/99-usb-mic-autoheal.rules"

create() {
    info "Installing usb-mic-autoheal..."

    install -m 755 "$SCRIPT_DIR/usb-mic-autoheal" "$BIN_TARGET"
    install -m 644 "$SCRIPT_DIR/usb-mic-autoheal.service" "$SERVICE_TARGET"
    install -m 644 "$SCRIPT_DIR/99-usb-mic-autoheal.rules" "$RULE_TARGET"

    systemctl daemon-reload
    udevadm control --reload-rules

    success "Installed. The mic will now auto-heal on disconnect."
}

delete() {
    info "Removing usb-mic-autoheal..."

    rm -f "$BIN_TARGET" "$SERVICE_TARGET" "$RULE_TARGET"

    systemctl daemon-reload
    udevadm control --reload-rules

    success "Removed."
}

case "${1:-}" in
--create)
    create
    ;;
--delete)
    delete
    ;;
*)
    error "Usage: sudo $0 [--create | --delete]"
    exit 1
    ;;
esac
