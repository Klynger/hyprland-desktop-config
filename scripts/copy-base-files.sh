#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $SCRIPT_DIR/utils.sh

CONFIG_FILE="$SCRIPT_DIR/../basefiles.conf"


if [ ! -f "$CONFIG_FILE" ]; then
    error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Get the absolute path of the directory where the script is located
copy-base-files() {
    # Read base files from the config file
    while IFS=: read -r source target || [ -n "$source" ]; do
        # Skip empty or invalid lines in the config file
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            warning "Skipping empty or invalid line: $source:$target"
            continue
        fi

        # Evaluate variables
        source=$(eval echo "$source")
        target=$(eval echo "$target")

        # Check if the source file exists
        if [ ! -e "$source" ]; then
            error "Error: Source file '$source' not found. Skipping copy."
            continue
        elif [ -f "$target" ]; then
            warning "Target file already exists: $target"
            continue
        elif [ -d "$target" ]; then
            warning "Target directory already exists: $target"
            continue
        fi

        # Extract the directory portion of the target path
        target_dir=$(dirname "$target")

        # Check if the target directory exists, and if not, create it
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            info "Directory created: $target_dir"
        fi

        # Create a copy of the base file
        if [ -d "$source" ]; then
            cp -r "$source" "$target"
            success "Copied directory: $source to $target"
        else
            cp "$source" "$target"
            success "Copied file: $source to $target"
        fi
    done <"$CONFIG_FILE"
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    info "Copying base files…"
    copy-base-files
fi
