#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ROOT-LEVEL COPIES — must be run with sudo
# ============================================================
# Copies config directories into system directories
# (e.g. /usr/share/sddm/themes). These require root privileges
# because the targets are owned by root.
#
# Copies are used instead of symlinks because system services
# (like sddm) may not have permission to traverse the user's
# home directory.
#
# Usage:
#   sudo ./scripts/copies-root.sh --create
#   sudo ./scripts/copies-root.sh --delete
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../copies-root.conf"

. "$SCRIPT_DIR/utils.sh"

if [[ $EUID -ne 0 ]]; then
    error "This script must be run with sudo"
    error "Usage: sudo $0 [--create | --delete]"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

create_copies() {
    info "Copying root-level config files..."

    while IFS=: read -r source target || [[ -n "$source" ]]; do
        # Skip empty, invalid, or comment lines
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        source=$(eval echo "$source")
        target=$(eval echo "$target")

        if [[ ! -e "$source" ]]; then
            error "Source not found: $source — skipping"
            continue
        fi

        # Remove old symlink if one exists from the previous approach
        if [[ -L "$target" ]]; then
            rm "$target"
            info "Removed old symlink: $target"
        fi

        target_dir="$(dirname "$target")"
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
            info "Directory created: $target_dir"
        fi

        # Remove existing target to avoid nested copies from cp -r
        if [[ -d "$target" ]]; then
            rm -r "$target"
        fi

        cp -r "$source" "$target"
        success "Copied: $source → $target"
    done < "$CONFIG_FILE"
}

delete_copies() {
    info "Deleting root-level copies..."

    while IFS=: read -r _ target || [[ -n "$target" ]]; do
        if [[ -z "$target" || "$target" == \#* ]]; then
            continue
        fi

        target=$(eval echo "$target")

        if [[ -L "$target" ]]; then
            rm "$target"
            success "Deleted symlink: $target"
        elif [[ -e "$target" ]]; then
            rm -r "$target"
            success "Deleted: $target"
        else
            warning "Not found: $target"
        fi
    done < "$CONFIG_FILE"
}

configure_sddm_theme() {
    local conf_dir="/etc/sddm.conf.d"
    local conf_file="$conf_dir/theme.conf"

    mkdir -p "$conf_dir"

    cat > "$conf_file" <<'CONF'
[Theme]
Current=material-you
CONF

    success "SDDM theme set to material-you in $conf_file"
}

case "${1:-}" in
    "--create")
        create_copies
        configure_sddm_theme
        ;;
    "--delete")
        delete_copies
        ;;
    "--help")
        echo "Usage: sudo $0 [--create | --delete | --help]"
        ;;
    *)
        error "Unknown argument: '${1:-}'"
        echo "Usage: sudo $0 [--create | --delete | --help]"
        exit 1
        ;;
esac
