#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ROOT-LEVEL SYMLINKS — must be run with sudo
# ============================================================
# Creates/deletes symlinks that target system directories
# (e.g. /usr/share/sddm/themes). These require root privileges
# because the targets are owned by root.
#
# Usage:
#   sudo ./scripts/symlinks-root.sh --create
#   sudo ./scripts/symlinks-root.sh --delete
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../symlinks-root.conf"

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

create_symlinks() {
    info "Creating root-level symbolic links..."

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

        if [[ -L "$target" ]]; then
            warning "Symbolic link already exists: $target"
        elif [[ -e "$target" ]]; then
            warning "Already exists (not a symlink): $target"
        else
            target_dir="$(dirname "$target")"
            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
                info "Directory created: $target_dir"
            fi

            ln -s "$source" "$target"
            success "Created symbolic link: $target → $source"
        fi
    done < "$CONFIG_FILE"
}

delete_symlinks() {
    info "Deleting root-level symbolic links..."

    while IFS=: read -r _ target || [[ -n "$target" ]]; do
        if [[ -z "$target" || "$target" == \#* ]]; then
            continue
        fi

        target=$(eval echo "$target")

        if [[ -L "$target" ]]; then
            rm "$target"
            success "Deleted: $target"
        else
            warning "Not a symlink or not found: $target"
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
        create_symlinks
        configure_sddm_theme
        ;;
    "--delete")
        delete_symlinks
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
