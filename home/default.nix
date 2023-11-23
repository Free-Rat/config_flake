{ imputs,  pkgs, user,... }:
{


	# home = {
	# 	username = "${user}";
	# 	homeDirectory = "/home/${user}";
	# 	language.base = "en_US.UTF-8";
	# };
	# programs = {
	# 	home-manager.enable = true;
	# };
	#
	# home.stateVersion = "23.11";

	imports = [
		inputs.home-manager.nixosModules.home-manager
	];

	home-manager = {
		extraSpecialArgs = { inherit inputs; };
		user.user = import ./home.nix
	};

}
