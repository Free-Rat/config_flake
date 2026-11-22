# Host prerequisites for the factory (fr-factory#21): what stocznia and the VM
# tests need from the host. Nothing here runs a service yet; the fr-factory
# modules are not imported because they are still slot based (fr-factory#18),
# and stocznia has no package or module yet.
{ pkgs, ... }:
{
  # tap devices and vsock for cloud-hypervisor VMs (vhost_vsock is in configuration.nix).
  boot.kernelModules = [ "tun" "vhost_net" ];

  # Tools stocznia and the bootstrap scripts call: a namespace per run, a tap
  # and veth in it, nft rules inside it, virtiofsd for the dedicated store.
  environment.systemPackages = with pkgs; [
    cloud-hypervisor
    virtiofsd
    socat
    iproute2
    nftables
    util-linux
    jq
  ];

  # Service user of stocznia. It gets CAP_SYS_ADMIN and CAP_NET_ADMIN from its
  # systemd unit later, not from here. `kvm` gives access to /dev/kvm.
  users.groups.stocznia = { };
  users.users.stocznia = {
    isSystemUser = true;
    group = "stocznia";
    extraGroups = [ "kvm" ];
    home = "/var/lib/stocznia";
  };

  # Per-run directories and the dedicated store (stocznia ADR 1 and 2). Both
  # live on the SSD, outside /nix/store.
  systemd.tmpfiles.rules = [
    "d /var/lib/stocznia 0750 stocznia stocznia -"
    "d /var/lib/stocznia/runs 0750 stocznia stocznia -"
    "d /var/lib/stocznia/store 0750 stocznia stocznia -"
  ];

  # Deliberately not set yet (decide with the first stocznia deployment):
  # - net.ipv4.ip_forward and host masquerade: only the build VM needs egress.
  # - zram or swap: it would change the measured capacity (about 4 VMs of 1 GiB).
  # - the fr-factory module and an Attic/OpenBao service.
}
