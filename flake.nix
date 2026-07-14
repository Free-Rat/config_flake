{
  # pc: sellia
  # thinkpad: lucaria or raya-lucaria
  # macbook: leyndell or midra-manse or manse
  # minipc(public ip): stromveil
  # rasberypi: jarburg
  # old thosiba: morne or castle-morne or nokstella or deeproot

  description = "Flake of a Dark Moon";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuxedo = {
      url = "github:Free-Rat/tuxedo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:Free-Rat/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    eirian-font.url = "github:Free-Rat/eirian-font-nix-pkgs";

    pi = {
      url = "github:Free-Rat/pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    personal-website = {
      url = "git+ssh://git@github.com/Free-Rat/personal-website?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      let
        hm = self.homeModules;
      in
      {
        imports = [
          ./parts/parts-options.nix
        ];

        flake.homeModules = {
          base.common = ./parts/home-common.nix;
          base.cli = ./parts/home-cli.nix;
          base.gitPersonal = ./parts/git-personal.nix;
          base.gitWork = ./parts/git-work.nix;
          base.desktopFiles = ./parts/desktop-files.nix;

          programs.alacritty = ./programs/alacritty;
          programs.bash = ./programs/bash;
          programs.cava = ./programs/cava;
          programs.dunst = ./programs/dunst;
          programs.eww = ./programs/eww;
          programs.ghostty = ./programs/ghostty;
          programs.helix = ./programs/helix;
          programs.kakoune = ./programs/kakoune;
          programs.kitty = ./programs/kitty;
          programs.nushell = ./programs/nushell;
          programs.nvf = ./programs/nvf;
          programs.river = ./programs/river;
          programs.rofi = ./programs/rofi;
          programs.starship = ./programs/starship;
          programs.sway = ./programs/sway;
          programs.tmux = ./programs/tmux;
          programs.wezterm = ./programs/wezterm;
          programs.zsh = ./programs/zsh;

          profiles.linuxDesktop = ./parts/linux-desktop.nix;
          profiles.linuxServer = ./parts/linux-server.nix;
          profiles.darwin = ./parts/darwin.nix;
        };

        flake.nixosModules = {
          common = ./modules;
          hyprland = ./modules/hyprland;
          niri = ./modules/niri;
          awesome = ./modules/awesome;

          infra-services = ./infra/maliketh_services.nix;
          ollama = ./infra/ollama.nix;
          bluetooth = ./modules/bluetooth.nix;
        };

        flake.darwinModules = {
          common = ./modules/darwin.nix;
        };

        flake.nixosConfigurations =
          let
            mkHost =
              {
                name,
                user ? "freerat",
                system ? "x86_64-linux",
                nixosModules ? [ ],
                homeModules,
              }:
              inputs.nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = { inherit inputs user; };
                modules = [
                  ./hosts/${name}
                  self.nixosModules.common
                  inputs.home-manager.nixosModules.home-manager
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      users.${user} = {
                        imports = homeModules;
                      };
                      extraSpecialArgs = {
                        inherit inputs user;
                        username = user;
                        homeDirectory = "/home/${user}";
                      };
                    };
                  }
                ]
                ++ nixosModules;
              };
          in
          {
            ranni = mkHost {
              name = "ranni";
              nixosModules = [ self.nixosModules.hyprland self.nixosModules.bluetooth ];
              homeModules = [
                hm.base.common
                hm.base.cli
                hm.base.gitPersonal
                hm.base.desktopFiles
                hm.programs.nvf
                hm.programs.rofi
                hm.programs.alacritty
                hm.programs.wezterm
                hm.programs.nushell
                hm.programs.cava
                hm.programs.kakoune
                hm.profiles.linuxDesktop
              ];
            };

            malenia = mkHost {
              name = "malenia";
              nixosModules = [ self.nixosModules.hyprland self.nixosModules.ollama self.nixosModules.bluetooth ];
              homeModules = [
                hm.base.common
                hm.base.cli
                hm.base.gitPersonal
                hm.base.desktopFiles
                hm.programs.nvf
                hm.programs.rofi
                hm.programs.alacritty
                hm.programs.wezterm
                hm.programs.nushell
                hm.programs.cava
                hm.programs.kakoune
                hm.profiles.linuxDesktop
              ];
            };

            maliketh = mkHost {
              name = "maliketh";
              nixosModules = [ self.nixosModules.infra-services ];
              homeModules = [
                hm.base.common
                hm.base.cli
                hm.base.gitPersonal
                hm.programs.nvf
                hm.programs.wezterm
                hm.profiles.linuxServer
              ];
            };

            melina = mkHost {
              name = "melina";
              system = "aarch64-linux";
              homeModules = [
                hm.base.common
                hm.base.cli
                hm.base.gitPersonal
                hm.programs.nvf
                hm.programs.ghostty
                hm.profiles.linuxServer
              ];
            };
          };

        flake.darwinConfigurations.MacBook-Air-Tomasz = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs;
            hyettaUser = "tomasz.lawicki";
            hyettaHost = "Tomaszs-MacBook-Air";
          };
          modules = [
            ./hosts/hyetta
            self.darwinModules.common
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users."tomasz.lawicki" = {
                  imports = [
                    hm.base.common
                    hm.base.cli
                    hm.base.gitWork
                    hm.programs.wezterm
                    hm.programs.nvf
                    hm.programs.bash
                    hm.programs.nushell
                    hm.profiles.darwin
                  ];
                };
                extraSpecialArgs = {
                  inherit inputs;
                  hyettaUser = "tomasz.lawicki";
                  username = "tomasz.lawicki";
                  homeDirectory = "/Users/tomasz.lawicki";
                };
              };
            }
          ];
        };

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      }
    );
}
