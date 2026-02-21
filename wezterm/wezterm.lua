-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 9

config.enable_tab_bar = false
config.window_decorations = "NONE"

config.color_scheme = 'Tokyo Night Storm'

config.window_background_opacity = 0.9
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

-- Enable compose key support for cedilla
config.use_ime = true
config.use_dead_keys = true

return config
