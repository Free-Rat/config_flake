{ self, inputs, ... }:
{
  perSystem = { system, pkgs, ... }:
    let
      buildBom = inputs.bombon.lib.${system}.buildBom;

      hostsForSystem = pkgs.lib.filterAttrs (_name: host: host.pkgs.stdenv.hostPlatform.system == system)
        self.nixosConfigurations;
    in
    {
      packages =
        let
          sboms = pkgs.lib.mapAttrs' (name: host:
            pkgs.lib.nameValuePair "sbom-${name}"
              (buildBom host.config.system.build.toplevel { })
          ) hostsForSystem;
          toplevels = pkgs.lib.mapAttrs' (name: host:
            pkgs.lib.nameValuePair "toplevel-${name}"
              host.config.system.build.toplevel
          ) hostsForSystem;
        in
        sboms // toplevels;

      apps.vulnscan = {
        type = "app";
        program = let
          script = pkgs.runCommand "vulnscan" {} ''
            mkdir -p "$out/bin"
            cp ${../scripts/vulnscan.sh} "$out/bin/vulnscan"
            cp ${../.grype.yaml} "$out/bin/.grype.yaml"
            chmod +x "$out/bin/vulnscan"
            substituteInPlace "$out/bin/vulnscan" \
              --replace '@nix@' '${pkgs.nix}/bin/nix' \
              --replace '@grype@' '${pkgs.grype}/bin/grype' \
              --replace '@grypeConfig@' "$out/bin/.grype.yaml" \
              --replace '@nvd@' '${pkgs.nvd}/bin/nvd' \
              --replace '@jq@' '${pkgs.jq}/bin/jq'
          '';
        in "${script}/bin/vulnscan";
      };
    };
}
