{pkgs, ... }: {

  services.nix-daemon.enable = true;
  nix = {
	  package = pkgs.nix;
	  settings = {
		  "extra-experimental-features" = [ "nix-command" "flakes" ];
	  };
  };

# system.configurationRevision = self.rev or self.dirtyRev or null;

# Used for backwards compatibility. please read the changelog
# before changing: `darwin-rebuild changelog`.
	system.stateVersion = 4;
	nixpkgs.hostPlatform = "aarch64-darwin";

# Declare the user that will be running `nix-darwin`.
	users.users.tomaszlawicki = {
		name = "tomaszlawicki";
		home = "/Users/tomaszlawicki";
	};
	programs.zsh.enable = true;

	# environment.systemPackages = with pkgs; [
	# ];
}
