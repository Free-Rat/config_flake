local wezterm = require 'wezterm'

local colors = {
  background = "#000000",
  foreground = "#C0C0C0",

  tab_bar = {
    background = "#000000",
    active_tab = {
      bg_color = "#000000",
      fg_color = "#FFFFFF",
      intensity = "Bold",
      underline = 'None',
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = "#000000",
      fg_color = "#888888",
    },
    inactive_tab_hover = {
      bg_color = "#554466",
      fg_color = "#FFFFFF",
    },
  },
}

return colors

