{ config, lib, pkgs, ... }:{
  imports = [ 
  	./waybar
  ];

  home.packages = with pkgs; [
    waybar
    swww
  ];

  #test later systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  wayland.windowManager.hyprland = {
    enable = true;
	systemd.enable = true;
	
	settings = {

		# Monitor
		monitor = [
			"DP-3,preferred,1680x0,1"
			"DVI-D-1,preferred,0x0,1"
			",preferred,auto,1"
		];

		# Input config
		input = {
			kb_layout = "pl,us";
			# "follow_mouse" = "1"
			touchpad = {
				"natural_scroll" = "false";
			};
			sensitivity = -0.5; # -1.0 - 1.0, 0 means no modification.
		};

		general = {
			gaps_in = 3;
			gaps_out = 5;
			border_size = 2;
			"col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
			"col.inactive_border" = "rgba(595959aa)";
			layout = "dwindle";
		};

		decoration = {
			rounding = 2;
			blur = {
				enabled = true;
				size = 3;
				passes = 1;
				new_optimizations = true;
			};
			drop_shadow = false;
			shadow_range = 4;
			shadow_render_power = 3;
			"col.shadow" = "rgba(1a1a1aee)";
		};

		animations = {
			enabled = true;
			bezier = "ease,0.4,0.02,0.21,1";
			animation = [
				"windows, 1, 3.5, ease, slide"
					"windowsOut, 1, 3.5, ease, slide"
					"border, 1, 6, default"
					"fade, 1, 3, ease"
					"workspaces, 1, 3.5, ease"
			];
		};

		master = {
			new_is_master = true;
		};

		gestures = {
			workspace_swipe = false;
		};

		"$mod" = "SUPER";

		bind = [

			"$mod, F, fullscreen"
				"$mod, RETURN, exec, alacritty"
				"$mod, B, exec, vieb"
				"$mod, Q, killactive"
				"SUPER_CTRL_SHIFT, Q, exit"
# $mod, G, exec, nautilus
# $mod, V, togglefloating,
				"$mod, SPACE, exec, rofi -show drun"
				"$mod, R, exec, rofiWindow"
# $mod, P, pseudo, # dwindle
				"$mod, T, togglesplit" # dwindle

# Switch Keyboard Layouts
# bind = $mainMod, SPACE, exec, hyprctl switchxkblayout teclado-gamer-husky-blizzard next

				" , Print, exec, grim -g '$(slurp)' - | wl-copy"
				" SHIFT, Print, exec, grim -g '$(slurp)'"

# Functional keybinds
				",XF86AudioMicMute,exec,pamixer --default-source -t"
				",XF86MonBrightnessDown, exec, light -U 20"
				",XF86MonBrightnessUp, exec, light -A 20"
				",XF86AudioMute,exec,pamixer -t"
				",XF86AudioLowerVolume,exec,pamixer -d 10"
				",XF86AudioRaiseVolume,exec,pamixer -i 10"
				",XF86AudioPlay,exec,playerctl play-pause"
				",XF86AudioPause,exec,playerctl play-pause"

# to switch between windows in a floating workspace
				"SUPER,Tab,cyclenext,"
				"SUPER,Tab,bringactivetotop,"

# Move focus with mainMod + vim movement
				"$mod, h, movefocus, l"
				"$mod, l, movefocus, r"
				"$mod, k, movefocus, u"
				"$mod, j, movefocus, d"

# Move windows with mainMod + SHIFT + vim movement
				"$mod SHIFT, h, workspace, e-1"
				"$mod SHIFT, l, workspace, e+1"

# Switch workspaces with mainMod + [0-9]
				"$mod, 1, workspace, 1"
				"$mod, 2, workspace, 2"
				"$mod, 3, workspace, 3"
				"$mod, 4, workspace, 4"
				"$mod, 5, workspace, 5"
				"$mod, 6, workspace, 6"
				"$mod, 7, workspace, 7"
				"$mod, 8, workspace, 8"
				"$mod, 9, workspace, 9"
				"$mod, 0, workspace, 10"

# Move active window to a workspace with mainMod + SHIFT + [0-9]
				"$mod SHIFT, 1, movetoworkspace, 1"
				"$mod SHIFT, 2, movetoworkspace, 2"
				"$mod SHIFT, 3, movetoworkspace, 3"
				"$mod SHIFT, 4, movetoworkspace, 4"
				"$mod SHIFT, 5, movetoworkspace, 5"
				"$mod SHIFT, 6, movetoworkspace, 6"
				"$mod SHIFT, 7, movetoworkspace, 7"
				"$mod SHIFT, 8, movetoworkspace, 8"
				"$mod SHIFT, 9, movetoworkspace, 9"
				"$mod SHIFT, 0, movetoworkspace, 10"

# Scroll through existing workspaces with mainMod + scroll
				"$mod, mouse_down, workspace, e+1"
				"$mod, mouse_up, workspace, e-1"

# Move/resize windows with mainMod + LMB/RMB and dragging
				# "$mod, mouse:272, movewindow"
				# "$mod, mouse:273, resizewindow"
				# "ALT, mouse:272, resizewindow"

				];
	};

	extraConfig = ''

# Fix slow startup
			# exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
			# exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 

# Autostart
			exec-once = hyprctl setcursor Bibata-Modern-Classic 24
			exec-once = dunst
# source = /home/enzo/.config/hypr/colors
			exec = pkill waybar & sleep 0.5 && waybar
			exec-once = swww init & swww kill && swww init
#exec-once = swww init & sleep 0.5 && swww img /home/freerat/config_flake/home/wallpapers/ranni1.jpg
# & sleep 0.5 && swww kill && swww init
#exec-once = swww img /home/freerat/config_flake/home/wallpapers/ranni1.jpg

			dwindle {
				pseudotile = yes
					preserve_split = yes
			}

# Example windowrule v1
# windowrule = float, ^(kitty)$
# Example windowrule v2
# windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

# windowrule=float,^(kitty)$
# windowrule=float,^(pavucontrol)$
# windowrule=center,^(kitty)$
# windowrule=float,^(blueman-manager)$
# windowrule=size 600 500,^(kitty)$
# windowrule=size 934 525,^(mpv)$
# windowrule=float,^(mpv)$
# windowrule=center,^(mpv)$
#windowrule=pin,^(firefox)$
		'';
	};
}
