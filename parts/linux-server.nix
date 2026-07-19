{ pkgs, inputs, ... }:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "ghostty";

    PATH_FLAKE_CONFIG = "$HOME/config_flake";
    PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
    PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
    PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/programs";
  };

  home.activation.piExtensions = ''
    SETTINGS="$HOME/.pi/agent/settings.json"
    EXTS_PATH="/home/freerat/config_flake/programs/pi/extensions/"

    if [ ! -f "$SETTINGS" ]; then
      mkdir -p "$(dirname "$SETTINGS")"
      echo '{}' > "$SETTINGS"
    fi

    ${pkgs.jq}/bin/jq --arg path "$EXTS_PATH" '
      if .extensions then
        if (.extensions | index($path)) then . else .extensions += [$path] end
      else .extensions = [$path] end
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  '';

  home.packages = with pkgs; [
    clippy
    mpc
    slurp
    tty-clock
    wl-clipboard

    # dev tools
    inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
    opencode

    secretspec # https://secretspec.dev/
  ];
}
