---------------------
--- KEYBINDINGS   ---
---------------------

local programs = require("programs")

local mainMod = "SUPER"


hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(programs.terminal), { description = "Terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout -b 5"), { description = "Power menu" })
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.exec_cmd("hyprlock"), { description = "Lock screen" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager), { description = "File manager" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float(), { description = "Toggle floating" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(programs.menu), { description = "App launcher" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Pseudo tiling" })
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"), { description = "Toggle split" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(), { description = "Fullscreen" })

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })

-- Move windows with mainMod + SHIFT + hjkl
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = tostring(i % 10) -- 10th workspace is on the 0 key
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { description = "Switch to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { description = "Move window to workspace " .. i })
end

-- Screenshot
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Screenshot region" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window"), { description = "Screenshot window" })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Screenshot monitor" })

-- Scratchpad
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move to scratchpad" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll workspace next" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll workspace previous" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window (drag)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (drag)" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { repeating = true, locked = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { repeating = true, locked = true, description = "Toggle mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { repeating = true, locked = true, description = "Toggle mic mute" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
    { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
    { repeating = true, locked = true, description = "Brightness down" })

-- Media controls (requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })

-- Wallpaper picker
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pick-wallpaper"), { description = "Wallpaper picker" })

-- Lock screen wallpaper picker
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("pick-lock-wallpaper"), { description = "Lock wallpaper picker" })

-- QuickPanel
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("quick-panel"), { description = "Quick panel" })

-- Bluetooth manager
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("launch-tui bluetui"), { description = "Bluetooth manager" })

-- Show keybindings
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("show-keybindings"), { description = "Show keybindings" })
