{

	description = "conf flake";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-23.05"; #"github:NixOS/nixpkgs/nixos-23.05";
	};

	outputs = {self, nixpkgs, ... }:
		let
		lib = nixpkgs.lib;
	in {
		nixosConfigurations = {

			nixos = lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ 
					./config 
					./modules
				];
			};

			server = lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ ./configuration.nix ];
			};
		};
	};
}
