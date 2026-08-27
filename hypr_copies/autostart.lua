-----------------
--- AUTOSTART ---
-----------------

-- Machine-specific: this file is copied (not symlinked) to ~/.config/hypr/
-- by scripts/copy-base-files.sh and is gitignored there.

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch. Examples:
--
-- hl.on("hyprland.start", function()
--     hl.exec_cmd("waybar")
--     hl.exec_cmd("wezterm", { workspace = "1" })
-- end)

hl.on("hyprland.start", function()
    hl.exec_cmd("playerctld daemon")
end)
