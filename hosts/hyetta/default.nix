{pkgs, lib, config, hyettaUser, hyettaHost, ...}: 
let
  myHome = config.users.users.${hyettaUser}.home;
  flake = "${myHome}/config_flake";
  programsDir = "${flake}/home/programs";
in
{
  # services.nix-daemon.enable = true;
  nix = {
    #	enable = true;
    enable = false;
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
  system.primaryUser = "${hyettaUser}";
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Declare the user that will be running `nix-darwin`.
  users.knownUsers = [ hyettaUser ];

  users.users.${hyettaUser} = {
    name = "${hyettaUser}";
    home = "/Users/${hyettaUser}";
    # home = lib.mkForce "/Users/tomasz.lawicki";
    shell = pkgs.bashInteractive;
    uid = 502;
  };
  programs = {
    bash.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    rustc
    cargo
  ];

  environment.shells = with pkgs; [ bashInteractive ];

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
