# AGENTS.md — Hyprland Desktop Config

This is a **personal Hyprland Wayland desktop dotfiles repository** for a single Linux machine.
It is not a software project — there is no compiled code, no package manager, and no test runner.
The primary languages are **Bash** (scripts), **Hyprland config DSL** (`.conf`), **Lua**, **CSS**, **JSONC**, and **TOML**.

---

## Repository Purpose

Manages configuration for a complete Wayland desktop environment:
- **Hyprland** — Wayland compositor / window manager
- **Waybar** — Status bar
- **Wofi** — App launcher
- **WezTerm** — Terminal emulator
- **Swaync** — Notification center
- **Hypridle / Hyprlock** — Idle management and lock screen
- **btop** — System monitor
- **swww** — Animated wallpaper daemon
- **Matugen** — Material You color generation
- **PipeWire / WirePlumber** — Audio
- **GTK 3 / GTK 4** — Theming

---

## Installation Commands

There is no build step. Installation is done by running the scripts in `scripts/`:

```bash
# Create all symlinks from symlinks.conf (idempotent, safe to re-run)
./scripts/symlinks.sh --create

# Remove all managed symlinks
./scripts/symlinks.sh --delete

# Copy machine-specific files (monitors.conf, autostart.conf) — run once per machine
./scripts/copy-base-files.sh

# Symlink all bin/ helper scripts to $XDG_BIN_HOME (~/.local/bin)
./scripts/install-binaries.sh
```

`symlinks.conf` declares all source→target symlink pairs using shell-expandable paths.
`basefiles.conf` declares files that must be **copied** (not symlinked) because they are machine-specific.

---

## Build / Lint / Test

**There is no build system, no linter, and no test framework in this repo.**

For shell scripts, use `shellcheck` manually if available:
```bash
shellcheck scripts/*.sh
shellcheck bin/*
```

For Bash formatting, use `shfmt` if available:
```bash
shfmt -i 4 -w scripts/*.sh
shfmt -i 4 -w bin/*
```

There are no automated tests. Validation is done by running the scripts against the real system.

---

## Directory Structure

```
hyprland-desktop-config/
├── bin/              # Helper scripts symlinked to ~/.local/bin (kebab-case, no extension)
├── scripts/          # Installation/deployment scripts (kebab-case.sh)
├── hypr/             # Hyprland WM config → ~/.config/hypr
├── hypr_copies/      # Machine-specific templates to COPY (not symlink)
├── waybar/           # Waybar status bar → ~/.config/waybar
├── wofi/             # App launcher config → ~/.config/wofi
│   └── themes/       # CSS color scheme presets (kebab-case.css)
├── wezterm/          # WezTerm terminal config
├── btop/             # btop resource monitor → ~/.config/btop
├── swaync/           # Notification center → ~/.config/swaync
├── matugen/          # Color generation tool → ~/.config/matugen
│   └── templates/    # Handlebars-style theme templates
├── gtk-3.0/          # GTK 3 settings → ~/.config/gtk-3.0
├── gtk-4.0/          # GTK 4 settings → ~/.config/gtk-4.0
├── systemd/user/     # Systemd user services and timers → ~/.config/systemd/user
├── uwsm/             # UWSM session manager env config
└── wireplumber/      # WirePlumber audio config → ~/.config/wireplumber
```

---

## Machine-Specific Files

The following files are **gitignored** and must be created per machine:

| File | Source template |
|------|----------------|
| `hypr/monitors.conf` | `hypr_copies/monitors.conf` |
| `hypr/autostart.conf` | `hypr_copies/autostart.conf` |
| `systemd/user/default.target.wants/` | Created by `copy-base-files.sh` |
| `systemd/user/timers.target.wants/` | Created by `copy-base-files.sh` |

Run `./scripts/copy-base-files.sh` once after cloning to set these up.

---

## Code Style Guidelines

### Bash Scripts (`bin/`, `scripts/`)

**Shebang:**
- Use `#!/usr/bin/env bash` for portability (preferred in new scripts)
- Existing scripts use `#!/bin/bash` or `#!/usr/bin/bash` — keep consistency within a file

**Strict mode:**
- Add `set -euo pipefail` to all new scripts (already used in `install-binaries.sh`)
- Existing scripts that lack it should not have it added unless refactoring the full script

**Naming conventions:**
- Script files in `bin/`: `kebab-case`, no file extension (they are executables)
- Script files in `scripts/`: `kebab-case.sh`
- Functions: `snake_case`
- Constants / environment variables: `SCREAMING_SNAKE_CASE`
- Local variables: `lowercase_snake_case`

**Functions:**
```bash
function_name() {
    local var="$1"
    # body
}
```

**Sourcing utilities:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"   # Use POSIX dot, not 'source'
```

**Output / user feedback:**
- Always use the helpers from `scripts/utils.sh` for colored output:
  - `info "message"` — blue, informational
  - `success "message"` — green, completed action
  - `warning "message"` — yellow, non-fatal issue
  - `error "message"` — red, failure (should precede `exit 1`)
- Never use raw `echo` for user-facing messages in scripts

**Argument handling:**
```bash
case "$1" in
    --create) create_symlinks ;;
    --delete) delete_symlinks ;;
    *) error "Unknown option: $1"; exit 1 ;;
esac
```

**Guard against sourcing vs execution** (for utility scripts):
```bash
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    main "$@"
fi
```

**Arrays:**
```bash
mapfile -t ITEMS < <(some_command)
```

**Quoting:** Always double-quote variables: `"$VAR"`, `"${VAR}"`. Use `"$(command)"` for subshells.

**Symlink handling pattern** (from `symlinks.sh`):
- Evaluate paths with `eval` to expand `$HOME`, `$(pwd)` in config files
- Check if target already exists / is already a symlink before acting
- Print status for every symlink processed

### Hyprland Config (`.conf` files in `hypr/`)

- **File organization:** All sub-configs sourced from `hyprland.conf` via `source = ~/.config/hypr/file.conf`
- **Section headers:** Use `###` box-style comment blocks to delineate sections
- **Variables:** `$camelCase` or `$lowercase` (e.g., `$mainMod`, `$terminal`, `$browser`)
- **Machine-specific settings** (monitors, autostart): kept in separate files that are gitignored
- **Window rules:** group related rules together with comments

### CSS (`waybar/style.css`, `wofi/style.css`, `wofi/themes/*.css`)

- Use CSS variables where possible for theming
- Wofi themes live in `wofi/themes/` as standalone files named `theme-name.css` in `kebab-case`
- Keep theme files self-contained; they override variables from the base `style.css`

### JSONC (`waybar/config.jsonc`)

- Use `//` comments to explain non-obvious module configurations
- Maintain the existing module order (left → center → right)

### Lua (`wezterm/wezterm.lua`, `wireplumber/`)

- Follow WezTerm/WirePlumber API conventions
- Use `local` for all variables
- Keep configuration declarative; avoid complex logic

### TOML (`matugen/config.toml`)

- Template paths use `$HOME`-based paths for portability
- `post_script` commands should be idempotent (safe to re-run)

### Matugen Templates (`matugen/templates/`)

- Use `{{colors.color_name.variant.hex}}` syntax for color references
- Variants: `default`, `on`, `container`, `on_container`
- Palette entries follow Material You naming: `primary`, `secondary`, `tertiary`, `error`, `surface`, etc.

---

## Key External Tools (Required on System)

The following must be installed for this config to function. See `tools_to_install.txt` for the full list.

| Tool | Used by |
|------|---------|
| `hyprctl`, `hyprland` | Window manager |
| `waybar` | Status bar |
| `wofi` | App launcher |
| `swww` | Wallpaper daemon |
| `swaync` | Notifications |
| `hypridle`, `hyprlock` | Idle/lock |
| `matugen` | Color theming |
| `jq` | JSON parsing in `launch-or-focus` |
| `gum` | Interactive prompts in `webapp-install` |
| `playerctl` | Media key bindings |
| `brightnessctl` | Backlight control |
| `wpctl` | Volume control |
| `gsettings` | GTK theme toggling |
| `xdg-terminal-exec` | Terminal launching |
| `rfkill` | WiFi toggling |

---

## Important Notes for Agents

- **Do not hardcode usernames or home paths.** Use `$HOME` or `~` in configs. (Note: `hypr/envs.conf` currently has a hardcoded path — this is a known issue to fix.)
- **`hypr/monitors.conf` and `hypr/autostart.conf` are gitignored** — never commit them. Edit `hypr_copies/` templates instead.
- **`symlinks.conf` uses eval-expanded paths** — use `$(pwd)` and `$HOME` only, not absolute paths.
- **All `bin/` scripts must be executable** (`chmod +x`). `install-binaries.sh` symlinks them to `$XDG_BIN_HOME`.
- **When adding a new config directory**, add its symlink to `symlinks.conf` and document the target path.
- **When adding a new `bin/` script**, it will be automatically picked up by `install-binaries.sh` — no registration needed.
- **Wofi themes** in `wofi/themes/` are optional overrides; the active theme must be referenced from `wofi/style.css`.
