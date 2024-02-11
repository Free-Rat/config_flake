local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")

    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(s.mytaglist)

    local systray = wibox.widget.systray()
    systray.bg = beautiful.bg_normal .. "00"

    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(systray)
    right_layout:add(audio_widget())
    right_layout:add(mytextclock)
    right_layout:add(s.mylayoutbox)

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        left_layout,
        vert_sep,
        right_layout,

    }

local bar = function(s)
    local wb = awful.wibar {
        position = "top",
        height = 18,
        screen = s,
        bg = beautiful.background
    }
    wb:setup {
        {
            {
                layout = wibox.layout.align.horizontal,
                {
                    layout = wibox.layout.align.horizontal,
                    taglist(s),
                    layout(s)
                },
                nil,
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        layout = wibox.layout.align.horizontal,
                        mpd,
                        spacer,
                        battery,
                    },
					{
						layout = wibox.layout.align.horizontal,
						unison,
						spacer,
					},
                    {
                        layout = wibox.layout.align.horizontal,
                        serverload,
                        spacer,
                        vpn,
                    }
                }
            },
            widget = wibox.container.margin,
            right = 5,
            left = 5
        },
        {
            layout = wibox.container.place,
            halign = "center",
            clock
        },
        layout = wibox.layout.stack,
    }
end

return bar
