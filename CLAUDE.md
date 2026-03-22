# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> A comprehensive developer reference already exists in `AGENTS.md` — read it for full detail on code style, naming conventions, and important caveats.

---

## What This Repo Is

A personal Hyprland Wayland desktop dotfiles repository. No compiled code, no package manager, no test runner. Languages: Bash, Hyprland config DSL (`.conf`), Lua, CSS, JSONC, TOML.

---

## Installation

```bash
# Symlink all configs (idempotent, safe to re-run)
./scripts/symlinks.sh --create

# Copy machine-specific files once per machine (monitors.conf, autostart.conf)
./scripts/copy-base-files.sh

# Symlink bin/ scripts to $XDG_BIN_HOME (~/.local/bin)
./scripts/install-binaries.sh
```

---

## Linting / Validation

No automated tests. Validate shell scripts manually:

```bash
shellcheck scripts/*.sh
shellcheck bin/*

shfmt -i 4 -w scripts/*.sh
shfmt -i 4 -w bin/*
```

---

## Architecture

### How configs are deployed

`symlinks.conf` declares source→target pairs (shell-expandable paths using `$HOME`/`$(pwd)`) that `symlinks.sh --create` turns into symlinks in `~/.config/`. `basefiles.conf` declares files that must be **copied** (not symlinked) because they are machine-specific.

### Machine-specific files (gitignored)

`hypr/monitors.conf` and `hypr/autostart.conf` are gitignored. Edit templates in `hypr_copies/` instead. Never commit the actual files.

### Hyprland config structure

`hypr/hyprland.conf` sources all sub-configs:
- `programs.conf` — defines `$terminal`, `$browser`, `$fileManager`, `$menu`
- `bindings.conf` — keybindings (Super+hjkl, workspaces 1–10, media/volume/brightness)
- `looknfeel.conf` — gaps, borders, animations, blur, shadows
- `windows.conf` — window rules and workspace assignments per app
- `envs.conf` / `inputs.conf` — environment variables and input settings
- `hypridle.conf` / `hyprlock.conf` — idle/lock screen

### Theming pipeline

`matugen/config.toml` is the theming hub. Running `matugen` generates color outputs for btop, GTK 3/4, swaync, wezterm, rofi, and waybar using Handlebars templates (`{{colors.color_name.variant.hex}}`). Post-hooks apply changes live.

### bin/ scripts

`bin/` contains user-facing helpers (no extension, executable, kebab-case):
- `launch-or-focus` — single-instance launcher using `hyprctl clients -j | jq`
- `launch-webapp` / `launch-or-focus-webapp` — web apps as first-class desktop apps
- `webapp-install` — interactive .desktop file creator (uses `gum`)
- `launch-browser` — detects default browser and maps `--private` to the correct flag
- `change-wallpaper` — random wallpaper from `~/Pictures/Wallpapers/current` via `swww`
- `toggle-theme-mode` — toggles light/dark via `gsettings`

All scripts in `bin/` are auto-discovered by `install-binaries.sh` — no registration needed.

### Script conventions

- Use `scripts/utils.sh` helpers (`info`, `success`, `warning`, `error`) — never raw `echo`
- Source with POSIX dot: `. "$SCRIPT_DIR/utils.sh"`
- `set -euo pipefail` in new scripts
- Always double-quote variables; use `mapfile -t` for arrays
- `symlinks.sh` uses `eval` to expand paths — only use `$HOME` and `$(pwd)` in conf files

---

## Key Caveats

- Do not hardcode usernames or absolute home paths — use `$HOME` or `~`
- `symlinks.conf` must use eval-expandable paths only (`$(pwd)`, `$HOME`)
- New `bin/` scripts must be `chmod +x`
- When adding a new config directory, add its symlink entry to `symlinks.conf`
