{

	description = "conf flake";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-23.05"; #"github:NixOS/nixpkgs/nixos-23.05";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = {self, nixpkgs, ... }@inputs:
		let
		lib = nixpkgs.lib;
		user = "freerat";
	in {
		nixosConfigurations = {

			nixos = lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { inherit inputs user; };
				modules = [ 
					./config 
					./modules
					# ./home
				];
			};

			server = lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ ./configuration.nix ];
			};
		};
	};
}
