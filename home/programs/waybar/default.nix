{ config, lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
    style = ''
      * {
        font-family: "Monaspace Krypton";
        font-size: 12pt;
        font-weight: bold;
        border-radius: 2px;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      @keyframes blink_red {
        to {
          /* background-color: rgb(242, 143, 173); */
          color: rgb(26, 24, 38);
        }
      }
      .warning, .critical, .urgent {
        animation-name: blink_red;
        animation-duration: 1s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      window#waybar {
        background-color: transparent;
      }

      window > box {
        margin-left: 5px;
        margin-right: 5px;
        margin-top: 5px;
        /* background-color: #1e1e2a; */
        /* background-color: rgba(43, 48, 59, 0.8); */
        background: transparent; 
        /* color: black; */
        padding: 3px;
        padding-left:8px;
        border: 2px none #33ccff;
      }

           #workspaces {
             padding-left: 0px;
             padding-right: 4px;
           }

           #workspaces button {
             padding-top: 5px;
             padding-bottom: 5px;
             padding-left: 6px;
             padding-right: 6px;
             color: rgb(104, 149, 208);
           }

           #workspaces button.active {
             color: rgb(181, 232, 224);
           }

           #workspaces button.urgent {
           }

           #workspaces button:hover {
             color: rgb(248, 189, 150);
           }

           tooltip {
             background: rgb(48, 45, 65);
           }

           tooltip label {
             color: rgb(217, 224, 238);
           }

           #custom-launcher {
             font-size: 20px;
             padding-left: 8px;
             padding-right: 6px;
             color: #7ebae4;
           }

           #mode, #clock, #memory, #temperature,#cpu,#mpd, #custom-wall, #temperature, #backlight, #pulseaudio, #network, #battery, #custom-cava-internal {
             padding-left: 10px;
             padding-right: 10px;
           }

           /* #mode { */
           /* 	margin-left: 10px; */
           /* 	background-color: rgb(248, 189, 150); */
           /*     color: rgb(26, 24, 38); */
           /* } */

           #memory {
             color: rgb(181, 232, 224);
           }

           #cpu {
             color: rgb(245, 194, 231);
           }

           #clock {
             color: rgb(217, 224, 238);
           }

           #custom-wall {
             color: #33ccff;
           }

           #temperature {
             color: rgb(150, 205, 251);
           }

           #backlight {
             color: rgb(248, 189, 150);
           }

           #pulseaudio {
             color: rgb(245, 224, 220);
           }

           #network {
             color: #ABE9B3;
           }

           #network.disconnected {
             color: rgb(255, 255, 255);
           }

           #tray {
             padding-right: 8px;
             padding-left: 10px;
           }

           #custom-cava-internal{
             font-family: "Monaspace Krypton";
             /* color: #33ccff; */
             background: rgb(137, 180, 250);
             background: radial-gradient(circle, rgba(137, 180, 250, 120) 0%, rgba(142, 179, 250, 120) 6%, rgba(148, 226, 213, 1) 14%, rgba(147, 178, 250, 1) 14%, rgba(155, 176, 249, 1) 18%, rgba(245, 194, 231, 1) 28%, rgba(158, 175, 249, 1) 28%, rgba(181, 170, 248, 1) 58%, rgba(205, 214, 244, 1) 69%, rgba(186, 169, 248, 1) 69%, rgba(195, 167, 247, 1) 72%, rgba(137, 220, 235, 1) 73%, rgba(198, 167, 247, 1) 78%, rgba(203, 166, 247, 1) 100%);
             background-size: 400% 400%;
             animation: gradient_f 9s cubic-bezier(.72, .39, .21, 1) infinite;
             text-shadow: 0px 0px 5px rgba(0, 0, 0, 0.377);
             font-weight: bold;
             border-radius: 20px;
             color: #fff;
           }

          #custom-media {
            background-color: #8EC5FC;
            background-image: linear-gradient(62deg, #8EC5FC 0%, #E0C3FC 100%);
            color: black;
            border-radius: 20px;
            margin-right: 5px;
          }

          #battery{
            font-family: "Monaspace Krypton";
            color: #c0caf5;
          }
    '';

    settings = [{

      "layer" = "top";
      "position" = "top";

      modules-left = [
        "custom/launcher"
        "custom/cava-internal"
        "clock#date"
        "clock#time"
      ];

      modules-center = [
        "hyprland/workspaces"
      ];

      modules-right = [
        "cpu"
        "memory"
        "temperature"
        "battery"
        "pulseaudio"
        "backlight"
        "tray"
        "network"
      ];

      "hyprland/workspaces" = { };

      "custom/launcher" = {
        "format" = " ";
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

      "pulseaudio" = {
        "scroll-step" = 1;
        "format" = "{icon} {volume}%";
        "format-muted" = "󰖁 Muted";
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

      "clock#time" = {
        "interval" = 10;
        "format" = "{:%H:%M}";
        "tooltip" = false;
      };

      "clock#date" = {
        "interval" = 20;
        "format" = "{:%e %b %Y}";
        "tooltip" = false;
        "tooltip-format" = "{:%e %B %Y}";
      };

      "memory" = {
        "interval" = 1;
        "format" = "󰻠 {percentage}%";
        "states" = {
          "warning" = 85;
        };
      };

      "cpu" = {
        "interval" = 1;
        "format" = "󰍛 {usage}%";
      };

      "network" = {
        "format-disconnected" = "󰯡 Disconnected";
        "format-ethernet" = "󰒢 Connected!";
        "format-linked" = "󰖪 {essid} (No IP)";
        "format-wifi" = "󰖩 {essid}";
        "interval" = 1;
        "tooltip" = false;
      };

      "tray" = {
        "icon-size" = 18;
        "spacing" = 7;
      };
    }];
  };
}
