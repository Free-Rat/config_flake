{
  description = "Flake of a Dark Moon";
  # Updaing only one input
  # nix flake lock --update-input nixvim 
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; 
	# nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
     home-manager = {
       url = "github:nix-community/home-manager";
       inputs.nixpkgs.follows = "nixpkgs";
     };
    nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland.url = "github:hyprwm/Hyprland";
     nixvim = {
       url = "github:Free-Rat/nixvim";
       inputs.nixpkgs.follows = "nixpkgs";
     };
     nvf = {
       url = "github:Free-Rat/nvf";
       inputs.nixpkgs.follows = "nixpkgs";
     };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      lib = nixpkgs.lib;
      user = "freerat";
      hyettaUser = "tomaszlawicki";
      hyettaHost = "Tomaszs-MacBook-Air";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${system};
    in
    {
     darwinConfigurations.Tomaszs-MacBook-Air = nix-darwin.lib.darwinSystem {
	  system = "aarch64-darwin";
          specialArgs = { inherit inputs hyettaUser hyettaHost; };
	     modules = [
		     ./hosts/hyetta
			 ./modules/darwin.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${hyettaUser}" = import ./home/darwin.nix;
            home-manager.extraSpecialArgs = { inherit
				hyettaUser
				inputs
				; };
            }
	     ];
     };

      nixosConfigurations = {
        #ranni - my laptop
        ranni = lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            ./hosts/ranni
            ./modules
	    ./modules/awesome
			# ./modules/qtile
			# ./modules/river.nix
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
			./modules/awesome
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
