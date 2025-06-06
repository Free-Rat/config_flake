pcall(require, "luarocks.loader")
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
-- local audio_widget = require("awesome-pulseaudio-widget") -- audio_widget
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
beautiful.init("~/.config/awesome/theme.lua") -- Themes define colours, icons, font and wallpapers.

-- local terminal = "kitty"                      --"alacritty"
local terminal = "ghostty"
local editor = os.getenv("EDITOR") or "nvim"
local editor_cmd = terminal .. " -e " .. editor
local modkey = "Mod4"

require("layouts")
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local myawesomemenu = {
    { "hotkeys",     function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual",      terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart",     awesome.restart },
    { "quit",        function() awesome.quit() end },
}

local mymainmenu = awful.menu({
    items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal }
    }
})
-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

local mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})


-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                { raise = true }
            )
        end
    end),
    awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end))

local function set_wallpaper(s)
    math.randomseed(os.time() + s.index)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper

        local pathWallpapers = os.getenv("PATH_FLAKE_CONFIG") or "/home/freerat/config_flake"
        if pathWallpapers then
            pathWallpapers = pathWallpapers .. "/home/wallpapers"
            local files = {}
            for file in io.popen('ls "' .. pathWallpapers .. '"'):lines() do
                table.insert(files, file)
            end
            if #files > 0 then
                local randomFile = files[math.random(#files)]
                local newPathWallpapers = pathWallpapers .. "/" .. randomFile
                wallpaper = newPathWallpapers
            end
        end

        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    -- "󰈹 ", " ", " ", " ", " ", " ", "󰢱 ", " ", " "
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))

    local vert_sep = wibox.widget {
        widget = wibox.widget.separator,
        orientation = "vertical",
        forced_width = 5,
        visible = false
    }

    local background = wibox.container.background
    background.visible = false
    -- background.bg = beautiful.border_focus .. "99"

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen          = s,
        filter          = awful.widget.taglist.filter.all,
        buttons         = taglist_buttons,
        style           = {
            shape_border_width = 0,
        },
        layout          = {
            spacing        = 5,
            spacing_widget = {
                {
                    forced_width = 10,
                    shape        = gears.shape.rounded_rect,
                    widget       = vert_sep,
                },
                valign = 'center',
                halign = 'center',
                widget = wibox.container.place,
            },
            layout         = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left   = 5,
                right  = 5,
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = background,
        },
    }

    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = 25,
        bg = "#00000080"
    })

    local battery_widget = require("battery")
    volume_widget = require("volume")
    brightness_widget = require("brightness")

    local systray = wibox.widget.systray()
    systray.bg = beautiful.bg_normal .. "00"

    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(s.mytaglist)

    local middle_layout = wibox.layout.fixed.horizontal()
    middle_layout:add(mytextclock)

    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(brightness_widget)
    right_layout:add(volume_widget)
    right_layout:add(battery_widget)
    right_layout:add(systray)
    right_layout:add(mykeyboardlayout)
    right_layout:add(s.mylayoutbox)

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        expand = "none",
        left_layout,
        middle_layout,
        right_layout
    }
end)

-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key(
        { modkey, "Control" }, "b",
        function()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
            end
        end,
        { description = "toogle wibar", group = "client" }
    ),
    awful.key(
        { modkey, }, "s",
        hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }
    ),
    awful.key(
        { modkey, }, "Left",
        awful.tag.viewprev,
        { description = "view previous", group = "tag" }
    ),
    awful.key(
        { modkey, }, "Right",
        awful.tag.viewnext,
        { description = "view next", group = "tag" }
    ),
    awful.key(
        { modkey, }, "Escape",
        awful.tag.history.restore,
        { description = "go back", group = "tag" }
    ),
    awful.key(
        { modkey, }, "j",
        function()
            awful.client.focus.byidx(1)
        end,
        { description = "focus next by index", group = "client" }
    ),
    awful.key(
        { modkey, }, "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }
    ),
    awful.key(
        { modkey, }, "w",
        function()
            mymainmenu:show()
        end,
        { description = "show main menu", group = "awesome" }
    ),

    -- Layout manipulation
    awful.key(
        { modkey, "Shift" }, "j",
        function()
            awful.client.swap.byidx(1)
        end,
        { description = "swap with next client by index", group = "client" }
    ),
    awful.key(
        { modkey, "Shift" }, "k",
        function()
            awful.client.swap.byidx(-1)
        end,
        { description = "swap with previous client by index", group = "client" }
    ),
    awful.key(
        { modkey, "Control" }, "j",
        function()
            awful.screen.focus_relative(1)
        end,
        { description = "focus the next screen", group = "screen" }
    ),
    awful.key(
        { modkey, "Control" }, "k",
        function()
            awful.screen.focus_relative(-1)
        end,
        { description = "focus the previous screen", group = "screen" }
    ),
    awful.key(
        { modkey, }, "u",
        awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }
    ),
    awful.key({ modkey, }, "b",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }
    ),

    -- Standard program
    awful.key(
        { modkey, }, "Return",
        function()
            awful.spawn(terminal)
        end,
        { description = "open a terminal", group = "launcher" }
    ),
    awful.key(
        { modkey, "Control" }, "r",
        awesome.restart,
        { description = "reload awesome", group = "awesome" }
    ),
    awful.key(
        { modkey, "Shift", "Control" }, "q",
        awesome.quit,
        { description = "quit awesome", group = "awesome" }
    ),
    awful.key(
        { modkey, }, "l",
        function()
            awful.tag.incmwfact(0.05)
        end,
        { description = "increase master width factor", group = "layout" }
    ),
    awful.key(
        { modkey, }, "h",
        function()
            awful.tag.incmwfact(-0.05)
        end,
        { description = "decrease master width factor", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "h",
        function()
            awful.tag.incnmaster(1, nil, true)
        end,
        { description = "increase the number of master clients", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "l",
        function()
            awful.tag.incnmaster(-1, nil, true)
        end,
        { description = "decrease the number of master clients", group = "layout" }
    ),
    awful.key(
        { modkey, "Control" }, "h",
        function()
            awful.tag.incncol(1, nil, true)
        end,
        { description = "increase the number of columns", group = "layout" }
    ),
    awful.key(
        { modkey, "Control" }, "l",
        function()
            awful.tag.incncol(-1, nil, true)
        end,
        { description = "decrease the number of columns", group = "layout" }
    ),
    awful.key(
        { modkey, }, "Tab",
        function()
            awful.layout.inc(1)
        end,
        { description = "select next", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "Tab",
        function()
            awful.layout.inc(-1)
        end,
        { description = "select previous", group = "layout" }
    ),

    awful.key({ modkey, "Control" }, "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                    "request::activate", "key.unminimize", { raise = true }
                )
            end
        end,
        { description = "restore minimized", group = "client" }
    ),

    -- Prompt
    awful.key({ modkey }, "space",
        function()
            awful.util.spawn('rofi -show drun')
        end, -- awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }
    ),
    awful.key({ modkey, "Shift" }, "space",
        function()
            awful.util.spawn('rofi -show')
        end, -- awful.screen.focused().mypromptbox:run() end,
        { description = "list of running proc", group = "launcher" }
    ),
    awful.key({ modkey }, "x",
        function()
            awful.prompt.run {
                prompt       = "Run Lua code: ",
                textbox      = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        { description = "lua execute prompt", group = "awesome" }
    ),
    -- Menubar
    awful.key(
        { modkey }, "p",
        function()
            menubar.show()
        end,
        { description = "show the menubar", group = "launcher" }
    ),

    -- AudioVolume
    awful.key({}, "XF86AudioRaiseVolume",
        function()
            awful.util.spawn("pamixer -i 10")
            volume_widget:update()
        end,
        { description = "volume up", group = "audio" }
    ),
    awful.key({}, "XF86AudioLowerVolume",
        function()
            awful.util.spawn("pamixer -d 10")
            volume_widget:update()
        end,
        { description = "volume low", group = "audio" }
    ),
    awful.key({}, "XF86AudioMute",
        function()
            awful.util.spawn("pamixer --toggle-mute")
            volume_widget:update()
        end,
        { description = "mute", group = "audio" }
    ),

    -- Brightness
    awful.key({}, "XF86MonBrightnessUp",
        function()
            awful.util.spawn("brightnessctl set +5%")
            brightness_widget:update()
        end,
        { description = "brightness up", group = "brightness" }
    ),
    awful.key({}, "XF86MonBrightnessDown",
        function()
            awful.util.spawn("brightnessctl set 5%-")
            brightness_widget:update()
        end,
        { description = "brightness up", group = "brightness" }
    ),

    -- screenshot
    awful.key(
        { modkey, "Shift" }, "s",
        function()
            awful.spawn.with_shell("maim -s | xclip -selection clipboard -t image/png")
        end,
        { description = "take a screenshot to clipboard", group = "screenshot" }
    )

-- NOTE to self: if adding new bindings REMEMBER ABOUT COLON

--  "XF86AudioMedia",
-- ("playerctl play-pause"),
--  "XF86AudioPlay",
--  ("playerctl play-pause"),
--  "XF86AudioPrev",
--  ("playerctl previous"),
--   "XF86AudioNext",
--  ("playerctl next"),
)

clientkeys = gears.table.join(
    awful.key({ modkey, }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey }, "q", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    awful.key({ modkey, }, "o", function(c) c:move_to_screen() end,
        { description = "move to screen", group = "client" }),
    awful.key({ modkey, }, "t", function(c) c.ontop = not c.ontop end,
        { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey, }, "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        { description = "minimize", group = "client" }),
    awful.key({ modkey, }, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" }),
    awful.key({ modkey, "Control" }, "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        { description = "(un)maximize vertically", group = "client" }),
    awful.key({ modkey, "Shift" }, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #" .. i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            { description = "move focused client to tag #" .. i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },

    --[[
    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }
	},
	--]]

    -- Add titlebars to normal clients and dialogs
    -- { rule_any = {type = { "normal", "dialog" }
    --   }, properties = { titlebars_enabled = true }
    -- },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- rounded_rect
-- client.connect_signal("manage", function(c)
--     c.shape = function(cr, w, h)
--         gears.shape.rounded_rect(cr, w, h, 17)
--     end
-- end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        {
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus",
    function(c)
        c.border_color = beautiful.border_focus
        -- c.border_width = beautiful.border_width
    end
)
client.connect_signal("unfocus",
    function(c)
        c.border_color = beautiful.border_normal
        -- c.border_width = beautiful.border_width_unfocus
    end
)
-- }}}

-- Autostart
-- "xrandr --output DP-3 --primary --mode 1920x1080 --pos 1680x0 --rotate normal \
--			--output DVI-D-1 --mode 1680x1050 --pos 0x0 --rotate normal"
do
    local cmds =
    {
        "picom --config /home/freerat/config_flake/modules/awesome/picom-config.conf --backend glx --vsync",
        "nm-applet",
        -- "feh --bg-fill $(cat /home/freerat/.wallpaper_path)",
        -- "feh",
        "/home/freerat/.fehbg",
        "xrandr \
    --output HDMI-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
    --output HDMI-2 --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
	--output DP-1 --mode 1680x1050 --pos 1920x0 --rotate normal "
    }

    for _, i in pairs(cmds) do
        awful.util.spawn(i)
    end
end
