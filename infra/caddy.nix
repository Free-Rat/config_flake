{
  services.caddy = {
    enable = true;
    virtualHosts."tomasz.bijeswoja.zone".extraConfig = ''
      redir https://free-rat.dev{uri}
    '';
    virtualHosts."tomek.bijeswoja.zone".extraConfig = ''
      redir https://free-rat.dev{uri}
    '';
    virtualHosts."freerat.bijeswoja.zone".extraConfig = ''
      redir https://free-rat.dev{uri}
    '';
  };
}
