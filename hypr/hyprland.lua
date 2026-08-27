-- Main Hyprland config (Lua, Hyprland >= 0.55).
-- Each require() runs in its own scope, so an error in one file does not
-- stop the others from loading.

require("envs")
require("monitors") -- machine-specific, copied from hypr_copies/ (gitignored)
require("windows")
require("bindings")
require("looknfeel")
require("inputs")
require("autostart") -- machine-specific, copied from hypr_copies/ (gitignored)
