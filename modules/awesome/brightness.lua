local awful = require("awful")
local wibox = require("wibox")

local brightness_widget = wibox.widget {
    {
        id = "brightness_text",
        widget = wibox.widget.textbox,
        text = "[N/A]" 
    },
    layout = wibox.layout.fixed.horizontal,
}

function brightness_widget:set_brightness(brightness)
	self:get_children_by_id("brightness_text")[1]:set_text("[ 明度:" .. brightness .. "% ]")
end

function brightness_widget:update()
    awful.spawn.easy_async_with_shell("brightnessctl m", function(stdout)
        local brightness_max = tonumber(stdout)
        if brightness_max and brightness_max > 0 then
            awful.spawn.easy_async_with_shell("brightnessctl g", function(mute_stdout)
                local brightness_curr = tonumber(mute_stdout)  -- Use mute_stdout here
                if brightness_curr then
                    local brightness_percentage = (brightness_curr / brightness_max) * 100
                    brightness_percentage = string.format("%.0f", brightness_percentage)
                    self:set_brightness(brightness_percentage)
                else
                    self:set_brightness("N/A")
                end
            end)
        else
            self:set_brightness("N/A")
        end
    end)
end

brightness_widget:buttons(
    awful.util.table.join(
        awful.button({}, 4, function() -- Scroll up: increase
            awful.spawn("brightnessctl set +5%", false)
            brightness_widget:update()
        end),
        awful.button({}, 5, function() -- Scroll down: decrease
            awful.spawn("brightnessctl set 5%-", false)
            brightness_widget:update()
        end)
    )
)

brightness_widget:update()

return brightness_widget
