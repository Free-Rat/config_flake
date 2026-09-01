{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0:11434";
      OLLAMA_CONTEXT_LENGTH = "98304";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q4_0";
    };
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
