-- Hyprland Lua config (Hyprland >= 0.57).
-- Migrated from hyprland.conf. Reference: https://wiki.hypr.land/configuring/
-- API stubs: <hyprland pkg>/share/hypr/stubs/hl.meta.lua


------------------
---- MONITORS ----
------------------

hl.monitor({ output = "eDP-1", mode = "2560x1600@60", position = "0x0", scale = 1.33 })
-- hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })

-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "preferred", position = "2560x0", scale = 1 })

-- fallback for any other monitor
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "wezterm"
local fileManager = "yazi"
local menu        = "rofi -show drun"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- hand session env to systemd/dbus and activate graphical-session.target;
    -- xdg-desktop-portal has Requisite=graphical-session.target and fails without it
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE; systemctl --user start nixos-fake-graphical-session.target")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("awww-daemon --no-cache")
    hl.exec_cmd("dunst")
    hl.exec_cmd("awww img $(cat ~/.wallpaper_path)")
    hl.exec_cmd("hyprctl setcursor miku-cursor-linux 50")
    hl.exec_cmd("eww open notifications")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- hl.env("XCURSOR_SIZE", "9")
-- hl.env("HYPRCURSOR_SIZE", "9")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 0,

        resize_on_border = false,
        allow_tearing    = false,

        layout = "scrolling",
    },

    decoration = {
        rounding       = 0,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.7,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled           = true,
            size              = 5,
            passes            = 1,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    -- niri-like scrolling tape: https://wiki.hypr.land/configuring/layouts/scrolling-layout/
    scrolling = {
        direction                = "right",  -- new columns open to the right
        column_width             = 0.5,      -- default width of a new column
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0", -- presets cycled by SUPER+R (like niri's preset-column-widths)
        fullscreen_on_one_column = true,     -- lone column fills the screen (~ niri's always-center-single-column)
        focus_fit_method         = 1,        -- 0 center, 1 fit (scroll just enough), 2 clamped_center
        follow_focus             = 1,
        wrap_focus               = false,    -- niri doesn't wrap from last column to first
        wrap_swapcol             = false,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("ease",           { type = "bezier", points = { {0.4, 0.02},  {0.21, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 1,    bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 2,    bezier = "easeOutQuint" })

hl.animation({ leaf = "windows",       enabled = true, speed = 1,    bezier = "ease", style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 0.5,  bezier = "ease", style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1,    bezier = "ease", style = "gnomed" })

hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.7,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.4,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })

hl.animation({ leaf = "layers",        enabled = true, speed = 2.8,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 2,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.2,  bezier = "linear",       style = "fade" })

hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.7,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.4,  bezier = "almostLinear" })

-- vertical slide, since workspaces are now stacked up/down (SUPER+J/K) like niri
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.3,  bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.1,  bezier = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.1,  bezier = "almostLinear", style = "slidevert" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "pl,us",
        kb_variant = "",
        kb_model   = "",
        kb_rules   = "",
        kb_options = "caps:escape",

        follow_mouse = 1,

        sensitivity = -0.2,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Map Wacom to a single monitor
hl.device({
    name      = "wacom-intuos-pt-s-2-pen",
    transform = 0,
    output    = "HDMI-A-2",
})

-- Logitech mouse (rennala)
hl.device({
    name        = "logitech-m215-1",
    sensitivity = 0.0, -- -1.0 - 1.0, 0 means no modification
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local function key(k) return mainMod .. " + " .. k end

hl.bind(key("RETURN"),        hl.dsp.exec_cmd(terminal))
hl.bind(key("F"),             hl.dsp.window.fullscreen())
hl.bind(key("Q"),             hl.dsp.window.close())
hl.bind("SUPER + CTRL + SHIFT + Q", hl.dsp.exit())
hl.bind(key("E"),             hl.dsp.exec_cmd(fileManager))
hl.bind(key("V"),             hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("SPACE"),         hl.dsp.exec_cmd(menu))
hl.bind(key("P"),             hl.dsp.window.pseudo())
-- hl.bind(key("T"),          hl.dsp.layout("togglesplit"))
hl.bind("Print",              hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy'))
hl.bind(key("SHIFT + S"),     hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy'))

hl.bind(key("B"),         hl.dsp.focus({ workspace = "name:browser" }))
hl.bind(key("SHIFT + B"), hl.dsp.window.move({ workspace = "name:browser" }))

-- niri-style navigation (scrolling layout)
-- H/L: move along the tape of columns; J/K: workspace below/above.
-- "r+1" also goes to the next *empty* workspace, like niri's always-one-empty-below.
hl.bind(key("H"), hl.dsp.layout("focus l"))
hl.bind(key("L"), hl.dsp.layout("focus r"))
hl.bind(key("J"), hl.dsp.focus({ workspace = "r+1" }))
hl.bind(key("K"), hl.dsp.focus({ workspace = "r-1" }))

-- SHIFT: carry things along (niri move-column-left/right, move-window-to-workspace)
hl.bind(key("SHIFT + H"), hl.dsp.layout("swapcol l"))
hl.bind(key("SHIFT + L"), hl.dsp.layout("swapcol r"))
hl.bind(key("SHIFT + J"), hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(key("SHIFT + K"), hl.dsp.window.move({ workspace = "r-1" }))

-- CTRL + H/L: column width -/+5% (niri set-column-width), R: cycle width presets
hl.bind(key("CTRL + H"), hl.dsp.layout("colresize -0.05"), { repeating = true })
hl.bind(key("CTRL + L"), hl.dsp.layout("colresize +0.05"), { repeating = true })
hl.bind(key("R"),        hl.dsp.layout("colresize +conf"))
hl.bind(key("C"),        hl.dsp.layout("center"))

-- [ / ]: pull window into neighbouring column, or push it out into its own (niri consume-or-expel)
hl.bind(key("bracketleft"),  hl.dsp.layout("consume_or_expel prev"))
hl.bind(key("bracketright"), hl.dsp.layout("consume_or_expel next"))

-- Switch workspaces / move window with mainMod (+ SHIFT) + [0-9]
for i = 1, 10 do
    local k = i % 10 -- 10 maps to key 0
    hl.bind(key(k),              hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local lr = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lr)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lr)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lr)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   lr)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 5%+"),                            lr)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),                            lr)

-- Requires playerctl
local l = { locked = true }
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       l)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   l)
