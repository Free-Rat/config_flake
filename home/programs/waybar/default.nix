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
          background-color: rgb(242, 143, 173);
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
        background-color: rgba(43, 48, 59, 0.8);
        /* background: transparent; 
        color: black; */
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
           background-color: rgb(181, 232, 224);
         }
         #workspaces button.urgent {
         }
         #workspaces button:hover {
           background-color: rgb(248, 189, 150);
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
         #mode, #clock, #memory, #temperature,#cpu,#mpd, #custom-wall, #temperature, #backlight, #pulseaudio, #network, #battery, #custom-powermenu, #custom-cava-internal {
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
         /* #idle_inhibitor {
           color: rgb(221, 182, 242);
         }*/
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
         #custom-powermenu {
           color: rgb(242, 143, 173);
           padding-right: 8px;
         }
         #tray {
           padding-right: 8px;
           padding-left: 10px;
         }
         #mpd.paused {
           color: #414868;
           font-style: italic;
         }
         #mpd.stopped {
           background: transparent;
         }
         #mpd {
           color: #c0caf5;
         }
         #custom-cava-internal{
           font-family: "Monaspace Krypton";
           color: #33ccff;
         }
        #custom-cava-internal.Playing {
          background: rgb(137, 180, 250);
          background: radial-gradient(circle, rgba(137, 180, 250, 120) 0%, rgba(142, 179, 250, 120) 6%, rgba(148, 226, 213, 1) 14%, rgba(147, 178, 250, 1) 14%, rgba(155, 176, 249, 1) 18%, rgba(245, 194, 231, 1) 28%, rgba(158, 175, 249, 1) 28%, rgba(181, 170, 248, 1) 58%, rgba(205, 214, 244, 1) 69%, rgba(186, 169, 248, 1) 69%, rgba(195, 167, 247, 1) 72%, rgba(137, 220, 235, 1) 73%, rgba(198, 167, 247, 1) 78%, rgba(203, 166, 247, 1) 100%);
          background-size: 400% 400%;
          animation: gradient_f 9s cubic-bezier(.72, .39, .21, 1) infinite;
          text-shadow: 0px 0px 5px rgba(0, 0, 0, 0.377);
          font-weight: bold;
          color: #fff;
        }
        #custom-cava-internal.Paused,
        #custom-cava-internal.Stopped {
          background: #161925;
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
        "mpd"
        "custom/cava-internal"
        "clock"
      ];
      modules-center = [
        "hyprland/workspaces"
      ];
      modules-right = [
        "cpu"
        # "memory"
        "temperature"
        "battery"
        "pulseaudio"
        "backlight"
        "tray"
        "network"
        # "custom/powermenu"
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
      "clock" = {
        /* 
        "interval" = 1;
        "format" = "{:%I:%M %p  %A %b %d}";
        "tooltip" = true;
        "tooltip-format" = "{=%A; %d %B %Y}\n<tt>{calendar}</tt>"; 
        */
        "format-alt" = "{:%Y-%m-%d}";
        "tooltip-format" = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
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
      "mpd" = {
        "max-length" = 25;
        "format" = "<span foreground='#bb9af7'></span> {title}";
        "format-paused" = " {title}";
        "format-stopped" = "<span foreground='#bb9af7'></span>";
        "format-disconnected" = "";
        "on-click" = "mpc --quiet toggle";
        "on-click-right" = "mpc update; mpc ls | mpc add";
        "on-click-middle" = "kitty --class='ncmpcpp' ncmpcpp ";
        "on-scroll-up" = "mpc --quiet prev";
        "on-scroll-down" = "mpc --quiet next";
        "smooth-scrolling-threshold" = 5;
        "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
      };
      "network" = {
        "format-disconnected" = "󰯡 Disconnected";
        "format-ethernet" = "󰒢 Connected!";
        "format-linked" = "󰖪 {essid} (No IP)";
        "format-wifi" = "󰖩 {essid}";
        "interval" = 1;
        "tooltip" = false;
      };
      # "custom/music" = {
      #   "format" = "{icon}{}";
      #   "format-icons" = {
      #     # // "Playing": " ", // Uncomment if not using caway
      #     "Paused" = " ";
      #     "Stopped" = "&#x202d;ﭥ "; # This stop symbol is RTL. So &#x202d; is left-to-right override.
      #   };
      #   "escape" = true;
      #   "tooltip" = true;
      #   "exec" = "caway";
      #   "return-type" = "json";
      #   "on-click" = "playerctl play-pause";
      #   "on-scroll-up" = "playerctl previous";
      #   "on-scroll-down" = "playerctl next";
      #   "on-click-right" = "g4music";
      #   "max-length" = 35;
      # };
      "custom/powermenu" = {
        "format" = "";
        "on-click" = "pkill rofi || ~/.config/rofi/powermenu/type-3/powermenu.sh";
        "tooltip" = false;
      };
      "tray" = {
        "icon-size" = 18;
        "spacing" = 7;
      };
    }];
  };
}
