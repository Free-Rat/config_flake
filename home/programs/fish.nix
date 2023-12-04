{ inputs, config, ... }: {

  programs.fish = {
    enable = true;

    shellAliases = {
      nrf = "sudo nixos-rebuild switch --flake .";

    };

    # plugins = [
    #   {
    #     name = "slavic-cat";
    #     src = pkgs.fetchFromGitHub {
    #       owner = "oh-my-fish";
    #       repo = 
    #     };
    #   }
    # ];

  };

}
