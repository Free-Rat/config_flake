{ inputs, pkgs, user }:
{
	home.user = "${user}";
	home.homeDirectory = "/home/${user}";




	home.stateVersion = "23.05";
	programs.home-manager.enable = true;
}	
