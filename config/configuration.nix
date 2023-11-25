{ inputs, config, pkgs, ... }:
{
	imports =
		[ 
		./hardware-configuration.nix
		];

	nix.settings.experimental-features = ["nix-command" "flakes"];
# Bootloader.
	boot.loader.grub.enable = true;
	boot.loader.grub.device = "/dev/nvme0n1";
	boot.loader.grub.useOSProber = true;

	networking.hostName = "nixos"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

# Configure network proxy if necessary
# networking.proxy.default = "http://user:password@proxy:port/";
# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	networking.networkmanager.enable = true;
	time.timeZone = "Europe/Warsaw";
	i18n.defaultLocale = "en_US.UTF-8";

	i18n.extraLocaleSettings = {
		LC_ADDRESS = "pl_PL.UTF-8";
		LC_IDENTIFICATION = "pl_PL.UTF-8";
		LC_MEASUREMENT = "pl_PL.UTF-8";
		LC_MONETARY = "pl_PL.UTF-8";
		LC_NAME = "pl_PL.UTF-8";
		LC_NUMERIC = "pl_PL.UTF-8";
		LC_PAPER = "pl_PL.UTF-8";
		LC_TELEPHONE = "pl_PL.UTF-8";
		LC_TIME = "pl_PL.UTF-8";
	};
	
	services.xserver = {
		layout = "pl";
		xkbVariant = "";
		enable = true;
		displayManager = {
			gdm = {
				enable = true;
				wayland = true;
			};
			# sddm.enable =true;
			# defaultSession = "none+awesome";
		};
		# windowManager.awesome = {
		# 	enable = true;
		# 	luaModules = with pkgs.luaPackages; [
		# 		luarocks
		# 		luadbi-mysql
		# 	];
		# };
	};

	programs.hyprland = {
		enable = true;
		package = inputs.hyprland.packages.${pkgs.system}.hyprland;
		enableNvidiaPatches = true;
		xwayland.enable = true;
	};

	sound.enable = true;
	hardware.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
#jack.enable = true;
#media-sessio.enable = true;
	};

# Enable touchpad support (enabled default in most desktopManager).
# services.xserver.libinput.enable = true;

	users.users.freerat = {
		isNormalUser = true;
		description = "Free-Rat";
		extraGroups = [ "networkmanager" "wheel" ];
		packages = with pkgs; [
			firefox
		];
	};

	nix.gc = {
		automatic = true;
		dates = "weekly";
		options = "--delete-older-than 7d";
	};

	system.autoUpgrade = {
		enable = true;
		channel = "https://nixos.org/channels/nixos-23.05";
	};
# Some programs need SUID wrappers, can be configured further or are
# started in user sessions.
# programs.mtr.enable = true;
# programs.gnupg.agent = {
#   enable = true;
#   enableSSHSupport = true;
# };

# List services that you want to enable:

# Enable the OpenSSH daemon.
# services.openssh.enable = true;

# Open ports in the firewall.
# networking.firewall.allowedTCPPorts = [ ... ];
# networking.firewall.allowedUDPPorts = [ ... ];
# Or disable the firewall altogether.
# networking.firewall.enable = false;

# This value determines the NixOS release from which the default
# settings for stateful data, like file locations and database versions
# on your system were taken. It‘s perfectly fine and recommended to leave
# this value at the release version of the first install of this system.
# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.05"; # Did you read the comment?

}
