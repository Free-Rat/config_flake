{
  config,
  pkgs,
  lib,
  ...
}: let
  user = "freerat";
  # password = "JDD";
  # SSID = "HALNy-5G-8644b2";
  # SSIDpassword = "somepass";
  # interface = "wlan0";
  hostname = "melina";
in {
  imports = [./hardware-configuration.nix];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  networking = {
    hostName = hostname;
    # wireless = {
    #   enable = true;
    #   networks."${SSID}".psk = SSIDpassword;
    #   interfaces = [ interface ];
    # };
  };

  environment.systemPackages = with pkgs; [vim git];

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      # password = password;
      extraGroups = ["wheel"];
    };
  };

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
