-----------------------
--- WINDOW RULES    ---
-----------------------

-- Global rules
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },

    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move = { 20, "monitor_h-120" },
    float = true,
})

-- Web apps — workspace 3 (Social)
hl.window_rule({
    name = "force-tile-whatsapp",
    match = { title = ".*[Ww]hats[Aa]pp.*" },

    tile = true,
    workspace = "3",
})

hl.window_rule({
    name = "force-tile-discord",
    match = { class = "^(discord)$" },

    tile = true,
    workspace = "3",
})

hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol)$" },

    workspace = "3",
})

hl.window_rule({
    name = "gnome-calculator",
    match = { class = "^(org\\.gnome\\.Calculator)$" },

    float = true,
})

-- Workspace 4 (Media/Entertainment)
hl.window_rule({
    name = "force-tile-youtube-music",
    match = {
        class = "^(Google-chrome)$",
        title = ".*music\\.youtube\\.com.*",
    },

    tile = true,
    workspace = "4",
})

hl.window_rule({
    name = "steam",
    match = { class = "^(steam)$" },

    tile = false,
    workspace = "4",
})

-- Workspace 5 (Games)
hl.window_rule({
    name = "counter-strike-window",
    match = { class = "cs2" },

    workspace = "5",
})

hl.window_rule({
    name = "age-of-empires-window",
    match = { title = ".*Age of Empires III.*" },

    workspace = "5",
})

hl.window_rule({
    name = "dota-2-window",
    match = { class = "dota2" },

    workspace = "5",
})

hl.window_rule({
    name = "claude",
    match = {
        class = "^(Google-chrome)$",
        title = ".*claude.*",
    },

    tile = true,
    workspace = "3",
})

-----------------------
--- LAYER RULES     ---
-----------------------

hl.layer_rule({
    name = "waybar",
    match = { namespace = "waybar" },
    blur = false,
})

hl.layer_rule({
    name = "rofi",
    match = { namespace = "rofi" },
    blur = true,
})

hl.layer_rule({
    name = "wlogout",
    match = { namespace = "wlogout" },
    blur = true,
})
