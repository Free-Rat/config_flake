{ inputs, config, pkgs, ... }: {

	programs.swaylock = {
		enable = true;
		settings = {
			color = "#000000";
			font = "monaspace Krypton";
		};
	};
	
}
