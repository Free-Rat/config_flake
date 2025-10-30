{pkgs, ...}: {
  nix = {
    settings = {
      trusted-users = [ "root" "adam" ];
      system-features = [ "gccarch-znver3" ];
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.piaseczny.dev/main"
      ];

      trusted-public-keys = [
        "main:r1LXFoN3gT2PA3SfPbPqXwsC5Z4iXxqPm2l0WCtBKNE"
      ];
    };
  };
}
