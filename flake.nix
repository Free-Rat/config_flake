{
  description = "Flake of a Dark Moon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; #"github:NixOS/nixpkgs/nixos-23.05";
	# nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland.url = "github:hyprwm/Hyprland";
    nixvim = {
      url = "github:Free-Rat/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      lib = nixpkgs.lib;
      user = "freerat";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
    in
    {
      nixosConfigurations = {

        #ranni - my laptop
        ranni = lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            ./hosts/ranni
            ./modules
			# ./modules/awesome
			./modules/river.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${user}" = import ./home/home.nix;
              home-manager.extraSpecialArgs = { inherit
				user
				inputs
				# pkgs-stable
				; };
            }
          ];
        };

        #malenia - my desktop
        malenia = lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            ./hosts/malenia
            ./modules
			# ./modules/hyprland.nix
			# ./modules/awesome
			./modules/river.nix
            # hyprland.nixosModules.default
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${user}" = import ./home/home.nix;
              home-manager.extraSpecialArgs = { inherit 
			  	# hyprland
				user
				inputs
				; };
            }
          ];
        };

        #melina - my server
        melina = lib.nixosSystem {
          modules = [
            /etc/nixos/configuration.nix
          ];
        };

        #vyke - my windows pc vm
        vyke = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            /etc/nixos/configuration.nix
          ];
        };
      };
    };
}
