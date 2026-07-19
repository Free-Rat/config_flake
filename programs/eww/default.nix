{
  config,
  pkgs,
  ...
}: {
  programs.eww = {
    enable = true;
    yuckConfig = builtins.readFile ./config/eww.yuck;
    scssConfig = builtins.readFile ./config/eww.scss;
  };
}
