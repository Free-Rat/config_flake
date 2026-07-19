{
  config,
  pkgs,
  lib,
  ...
}:
let
  format-notifs-py = pkgs.writeText "format-notifs.py" (builtins.readFile ./config/format-notifs.py);

  yuckConfig = ''
    (deflisten notifs :initial ""
      `${pkgs.tiramisu}/bin/tiramisu -j | ${pkgs.python3}/bin/python3 ${format-notifs-py}`)

    (defwindow notifications
               :monitor 0
               :geometry (geometry :x "20px"
                                    :y "20px"
                                    :anchor "top right")
               :stacking "overlay"
               (literal :content notifs))
  '';

  scssConfig = builtins.readFile ./config/eww.scss;
in
{
  programs.eww = {
    enable = true;
    yuckConfig = yuckConfig;
    scssConfig = scssConfig;
  };

  home.packages = with pkgs; [
    tiramisu
  ];
}
