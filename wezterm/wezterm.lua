-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 9

config.enable_tab_bar = false
config.window_decorations = "NONE"

config.color_scheme = "Catppuccin Frappé (Gogh)"

config.window_background_opacity = 1
config.macos_window_background_blur = 1
config.default_prog = {
	"zsh",
	"-lc",
	[[
    if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
      exec tmux
    else
      exec zsh
    fi
  ]],
}

return config
