from libqtile import bar, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.widget import backlight
from colors import get_colors

mod = "mod4"
terminal = "kitty" 
spawn_menu = "rofi -show drun"

colors = get_colors()

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h",
        lazy.layout.left(),
        desc="Move focus to left"),
    Key([mod], "l",
        lazy.layout.right(),
        desc="Move focus to right"),
    Key([mod], "j",
        lazy.layout.down(),
        desc="Move focus down"),
    Key([mod], "k",
        lazy.layout.up(),
        desc="Move focus up"),
    Key([mod], "n",
        lazy.layout.next(),
        desc="Move window focus to other window"),
    Key([mod], "space",
        lazy.spawn(spawn_menu),
        desc="spawn rofi"),
    Key([mod], "b",
        lazy.hide_show_bar(position="top"),
        desc="Hide/Show bar"),
    # Sound
    Key([], "XF86AudioMute",
        # lazy.spawn("amixer -q set Master toggle")),
        lazy.spawn("pamixer --toggle-mute")),
    Key([], "XF86AudioLowerVolume",
        # lazy.spawn("amixer -c 0 sset Master 1- unmute")),
        lazy.spawn("pamixer -d 5")),
    Key([], "XF86AudioRaiseVolume",
        lazy.spawn("pamixer -i 5")),

    Key([], "XF86MonBrightnessUp",
        lazy.spawn("brightnessctl set +5%")),
    Key([], "XF86MonBrightnessDown",
        lazy.spawn("brightnessctl set 5%-")),

    Key([], "XF86AudioMedia",
        lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioPlay",
        lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioPrev",
        lazy.spawn("playerctl previous")),
    Key([], "XF86AudioNext",
        lazy.spawn("playerctl next")),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h",
        lazy.layout.shuffle_left(),
        desc="Move window to the left"),
    Key([mod, "shift"], "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right"),
    Key([mod, "shift"], "j",
        lazy.layout.shuffle_down(),
        desc="Move window down"),
    Key([mod, "shift"], "k",
        lazy.layout.shuffle_up(),
        desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h",
        lazy.layout.grow_left(),
        desc="Grow window to the left"),
    Key([mod, "control"], "l",
        lazy.layout.grow_right(),
        desc="Grow window to the right"),
    Key([mod, "control"], "j",
        lazy.layout.grow_down(),
        desc="Grow window down"),
    Key([mod, "control"], "k",
        lazy.layout.grow_up(),
        desc="Grow window up"),
    Key([mod], "n",
        lazy.layout.normalize(),
        desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",),
    Key([mod], "Return",
        lazy.spawn(terminal),
        desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab",
        lazy.next_layout(),
        desc="Toggle between layouts"),
    Key([mod], "q",
        lazy.window.kill(),
        desc="Kill focused window"),
    Key([mod],"f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",),
    Key([mod], "t",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r",
        lazy.reload_config(),
        desc="Reload the config"),
    Key([mod, "control"], "q",
        lazy.shutdown(),
        desc="Shutdown Qtile"),
    Key([mod], "r",
        lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod + shift + group number = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

layouts = [
    # layout.Columns(
    #     border_focus_stack=[colors['color1'], colors['color2']],
    #     border_focus=colors['color1'],
    #     # margin=2,
    #     border_width=1),
    # layout.Stack(num_stacks=2),
    layout.Bsp(
        border_focus_stack=[colors['color1'], colors['color2']],
        border_focus=colors['color1'],
        border_width=1),
    layout.Max(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="Monaspace Krypton",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    highlight_method='text',
                    active=colors['color3'], # used but not focused
                    # foreground="ffffff",
                    # highlight_color="ffffff",
                    this_current_screen_border=colors['foreground'], # focused
                    this_screen_border=colors['foreground'],
                    # background=theme['green']
                ),
                widget.CurrentLayout(),
                widget.Prompt(),
                widget.Spacer(),
                # widget.WindowName(),
                # widget.Chord(
                #     chords_colors={
                #         "launch": ("#ff0000", "#ffffff"),
                #     },
                #     name_transform=lambda name: name.upper(),
                # ),
                # widget.TextBox("default config", name="default"),
                # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
                # widget.StatusNotifier(),
                # widget.Backlight(),
                widget.Volume(
                    emoji=True,
                    emoji_list=["󰝟 ", "󰕿 ", "󰖀 ", "󰕾 "],
                    fmt="[ {}"),
                widget.Volume(
                    fmt="{} ]"),
                widget.Systray(),
                widget.Clock(format="%Y-%m-%d %a %H:%M %p"),
                widget.GenPollText(
                    name="battery0",
                    update_interval=5,
                    func = lambda: open("/sys/class/power_supply/BAT0/capacity").read().strip() + "%",
                    fmt = "[ 󰄌 {} ]"),
                widget.GenPollText(
                    name="battery1",
                    update_interval=5,
                    func = lambda: open("/sys/class/power_supply/BAT1/capacity").read().strip() + "%",
                    fmt = "[ 󰄌 {} ]"),
                # widget.QuickExit(),
            ],
            24,
            opacity=0.9,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
        # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
        # By default we handle these events delayed to already improve performance, however your system might still be struggling
        # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
        # x11_drag_polling_rate = 60,
    ),
]

# Drag floating layouts.
# mouse = [
#     Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
#     Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
#     Click([mod], "Button2", lazy.window.bring_to_front()),
# ]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = False 
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

wmname = "LG3D"
