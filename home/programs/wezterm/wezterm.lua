local wezterm = require 'wezterm'
local act = wezterm.action

local config_dir = wezterm.config_dir

-- update package.path
package.path = package.path
    .. ";" .. config_dir .. "/?.lua"
    .. ";" .. config_dir .. "/?/init.lua"

local config = wezterm.config_builder()

local my_colors = require 'colors'
config.colors = my_colors
config.tab_bar_at_bottom = false

-- config.color_scheme = 'MonaLisa'
config.window_background_opacity = 0.7
config.text_background_opacity = 0.5
config.automatically_reload_config = true
config.macos_window_background_blur = 20
config.font_size = 15.0
config.native_macos_fullscreen_mode = true
-- config.macos_fullscreen_extend_behind_notch = false

-- config.enable_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false

config.use_fancy_tab_bar = false
-- config.show_tabs_in_tab_bar = false
--
-- config.keys = {
--   { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
-- }
config.keys = {
    {
        key = '9',
        mods = 'ALT',
        action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|COMMANDS' },
    },
    {
        key = 'g',
        mods = 'CTRL',
        action = act.PaneSelect {},
    },
    { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
}

config.ssh_domains = {
    {
        name = "aiserver",
        remote_address = "10.0.2.49",
        username = "tomasz_lawicki",
    },
    {
        name = "maliketh",
        remote_address = "ssh.free-rat.dev:2222",
        username = "freerat",
    },
}

config.font = wezterm.font('Monaspace Krypton', { weight = 'Regular' })
-- config.font = wezterm.font('DepartureMono Nerd Font')
-- config.font = wezterm.font('ProggyClean CE Nerd Font')
-- config.font = wezterm.font('Hack Nerd Font')
return config
