{pkgs, config, ...}: 
let
  myHome = config.users.users.tomaszlawicki.home;
  flake = "${myHome}/config_flake";
  programsDir = "${flake}/home/programs";
in
{
  # services.nix-daemon.enable = true;
  nix = {
    enable = true;
    package = pkgs.nix;
    settings = {
      "extra-experimental-features" = ["nix-command" "flakes"];
    };
  };

  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility. please read the changelog
  # before changing: `darwin-rebuild changelog`.
  # ids.gids.nixbld = 350;
  system.stateVersion = 6;
  system.primaryUser = "tomaszlawicki";
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Declare the user that will be running `nix-darwin`.
  users.users.tomaszlawicki = {
    name = "tomaszlawicki";
    home = "/Users/tomaszlawicki";
    shell = pkgs.bash;
  };
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    rustc
    cargo
  ];

  environment.shells = with pkgs; [ bash ];

  launchd.user.envVariables = {
    PATH_FLAKE_CONFIG   = flake;
    PATH_SCRIPTS        = "${flake}/scripts";
    PATH_WALLPAPERS     = "${flake}/wallpapers";
    PATH_PROGRAMS       = programsDir;
    KAKOUNE_CONFIG_DIR  = "${programsDir}/kakoune";
    WEZTERM_CONFIG_DIR  = "${programsDir}/wezterm";
    WEZTERM_CONFIG_FILE = "${programsDir}/wezterm/wezterm.lua";
  };
}
