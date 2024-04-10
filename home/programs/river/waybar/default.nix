{ config, lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
    settings = [{
      layer = "top";
      position = "top";

      modules-left = [
        "custom/launcher"
        # "custom/cava-internal"
		"clock"
      ];

      modules-center = [
        "river/tags"
		"river/mode"
      ];

      modules-right = [
        # "cpu"
        # "memory"
        # "temperature"
        "battery"
        "pulseaudio"
        "backlight"
        "tray"
        "network"
      ];

      "river/tags" = { };

	  "river/mode" = {
			# max-length = 1;
			"format" = "{}";
	  };

      "custom/launcher" = {
        "format" = "";
        "on-click" = "";
        "on-click-middle" = "";
        "on-click-right" = "";
        "tooltip" = false;
      };

      "custom/cava-internal" = {
        "exec" = "sleep 1s && cava-internal";
        "tooltip" = true;
        "on-click" = "playerctl play-pause";
        "on-scroll-up" = "playerctl previous";
        "on-scroll-down" = "playerctl next";
        "on-click-right" = "g4music";
      };

      pulseaudio = {
        "scroll-step" = 1;
        "format" = "{icon} {volume}%";
        "format-muted" = "  󰖁  ";
        "format-icons" = {
          "default" = [ "" "" "" ];
        };
        "on-click" = "pamixer -t";
        "tooltip" = false;
      };

      "custom/media" = {
        "format" = "{icon} {}";
        "return-type" = "json";
        "max-length" = 25;
        "escape" = true;
        "exec" = "$PATH_SCRIPTS/mediaplayer.sh 2> /dev/null";
        "on-click" = "playerctl play-pause";
      };

	  clock = {
		  "interval" = 1;
		  "format" = "{:%a %Y-%m-%d %H:%M:%S %p}";
		  "timezone" = "Poland/Warsaw";
		  "tooltip-format" = ''
			  <big>{:%Y %B}</big>
			  <tt><small>{calendar}</small></tt>'';
	  };

      memory = {
        "interval" = 1;
        "format" = "󰻠 {percentage}%";
        "states" = {
          "warning" = 85;
        };
      };

      cpu = {
        "interval" = 1;
        "format" = "󰍛 {usage}%";
      };

      network = {
        "format-disconnected" = "󰯡";
        "format-ethernet" = "󰒢";
        "format-linked" = "󰖪"; #{essid} (No IP)
        "format-wifi" = "󰖩"; #{essid}
        "interval" = 1;
        "tooltip" = false;
      };

      tray = {
        "icon-size" = 18;
        "spacing" = 7;
      };
    }];

    style = ./style.css;

  };
}
