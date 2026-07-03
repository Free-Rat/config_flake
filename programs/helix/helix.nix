{ config, pkgs, inputs, ... }:
# let
#   inherit (config) colorscheme;
# in
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "doom_acario_dark";
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        lsp.display-messages = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixpkgs-fmt";
          };
        }

      ];
    };
    extraPackages = with pkgs; [
      nil
      nixpkgs-fmt
    ];
  };
  # themes = import ./theme.nix { inherit colorscheme; };
}
