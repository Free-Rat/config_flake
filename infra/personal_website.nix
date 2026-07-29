{ inputs, pkgs, ... }:
{
  imports = [
    inputs.personal-website.nixosModules.website
  ];

  services.personal-website = {
    enable = true;
    domain = "free-rat.dev";
    package = inputs.personal-website.packages.${pkgs.stdenv.hostPlatform.system}.website;
  };
}
