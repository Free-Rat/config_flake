local awful = require("awful")
local wibox = require("wibox")

-- Create a volume widget
local volume_widget = wibox.widget {
    {
        id = "volume_text",
        widget = wibox.widget.textbox,
        text = "[N/A]" -- Placeholder text for volume percentage
    },
    layout = wibox.layout.fixed.horizontal,
}

-- Method to set volume
function volume_widget:set_volume(volume, muted)
	if muted then
		self:get_children_by_id("volume_text")[1]:set_text("[ 音量:--% ]")
	else
		self:get_children_by_id("volume_text")[1]:set_text("[ 音量:" .. volume .. "% ]")
	end
end

-- Method to update volume widget
function volume_widget:update()
        awful.spawn.easy_async_with_shell("pamixer --get-volume", function(stdout)
            local volume = tonumber(stdout)
            awful.spawn.easy_async_with_shell("pamixer --get-mute", function(mute_stdout)
                local muted = mute_stdout:match("true")
                if volume then
                    self:set_volume(volume, muted)
                else
                    -- In case of error, set to [N/A]
                    self:set_volume("N/A", false)
                end
            end)
        end)
    end

-- Bind mouse buttons to control volume
volume_widget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function() -- Left click: mute/unmute
            awful.spawn("pamixer --toggle-mute", false)
            volume_widget:update()
        end),
        awful.button({}, 4, function() -- Scroll up: increase volume
            awful.spawn("pamixer --increase 5", false)
            volume_widget:update()
        end),
        awful.button({}, 5, function() -- Scroll down: decrease volume
            awful.spawn("pamixer --decrease 5", false)
            volume_widget:update()
        end)
    )
)

volume_widget:update()

return volume_widget
