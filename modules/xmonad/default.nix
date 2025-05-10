{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = builtins.readFile ./xmonad.hs;
      extraPackages = haskellPackages:
        with haskellPackages; [
          xmonad
          xmonad-contrib
        ];

      # Use the default set of haskellPackages or change to a different set if needed.
      # haskellPackages = pkgs.haskellPackages;

      # (Optional) pass additional GHC arguments, e.g., for optimization.
      # ghcArgs = ["-O2"];

      # (Optional) pass CLI arguments for XMonad at startup.
      # xmonadCliArgs = [];

      # Automatically trigger a recompile when the configuration changes.
      # enableConfiguredRecompile = true;
    };
  };

  services.displayManager.ly = {
    enable = true;
  };

  # Make sure the required packages are installed
  environment.systemPackages = with pkgs; [
    xmonad-with-packages
    xmobar
  ];
}
