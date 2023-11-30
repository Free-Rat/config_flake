{
  description = "Flake of a Dark Moon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; #"github:NixOS/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    nvim-flake.url = "github:Free-Rat/nvim-flake";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      lib = nixpkgs.lib;
      user = "freerat";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {

        nixos = lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            ./config
            ./modules
            hyprland.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${user}" = import ./home/home.nix;
              home-manager.extraSpecialArgs = { inherit hyprland user inputs; };
            }
          ];
        };

        server = lib.nixosSystem {
          modules = [ ./configuration.nix ];
        };
      };
    };
}
