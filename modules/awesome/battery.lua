local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local watch = require("awful.widget.watch")

local battery_widget = wibox.widget.textbox()

local battery_widget = wibox.widget {
    widget = wibox.widget.textbox,
    -- align  = 'center',
    -- valign = 'center'
    -- font = "sans 12"  -- You can adjust the font and size
}

local function update_battery_widget(widget, stdout)
	local battery_0 = stdout:match("Battery 0:.-(%d?%d?%d)%%")
    local battery_1 = stdout:match("Battery 1:.-(%d?%d?%d)%%")
    widget.text = "[ 電池:" .. battery_0 .. "%" .. "|" .. battery_1 .. "% ]"
    -- widget.text = "[ " .. battery_0 .. "%" .. "|" .. battery_1 .. "% ]"
end

awful.widget.watch("acpi -i", 30, update_battery_widget, battery_widget)

return battery_widget
