{ pkgs, inputs, ... }:
{
  home.sessionPath = [ "$HOME/.cargo/bin" ];

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
    inputs.tuxedo.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
    blender
    osu-lazer
    nodejs_22

    opencode
    krita
    tcpdump
    libnotify
    awww
    yazi
    discord-development
    loupe
    viu
    lazydocker
    lazyjournal
    keepassxc
    maim
    shellcheck

    grim
    slurp

    firefox

    signal-cli
    signal-desktop

    entr
    pandoc
    texliveSmall
    wlr-randr
    pavucontrol
    pamixer
    jq

    playerctl
    wl-clipboard
    mpc
    gurk-rs
    acpi
    nautilus
    obsidian
    libheif
    clippy
    sshfs
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      hetzner = {
        hostname = "u555363.your-storagebox.de";
        user = "u555363";
      };
    };
  };
}
