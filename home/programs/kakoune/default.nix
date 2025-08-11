{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  xdg.configFile."kak-lsp/kak-lsp.toml".source = ./kak-lsp.toml;
  xdg.configFile."kak-tree-sitter/config.toml".source = ./kak-tree-sitter.toml;

  home.packages = with pkgs; [
    fzf
    kakoune

    kakoune-lsp
    kak-tree-sitter
    kakounePlugins.fzf-kak
    kakounePlugins.auto-pairs-kak

    # rust-analizer
    # cland
    clang-tools
    ruff
    marksman
    lua-language-server
    nil
    rust-analyzer
    bash-language-server
    yaml-language-server
  ];

  #   programs.kakoune = {
  #     enable = true;
  #     config = {
  #       indentWidth = 2;
  #       ui.assistant = "none";
  #       ui.enableMouse = true;
  #       showMatching = true;
  #       scrollOff = {
  #         columns = 2;
  #         lines = 3;
  #       };
  #       colorScheme = null; # The colorscheme should be set AFTER kak-tree-sitter has been started.
  #       numberLines = {
  #         enable = true;
  #         relative = true;
  #       };
  #       # keyMappings = import ./kakkeymappings.nix;
  #       hooks = [
  #         {
  #           name = "BufCreate";
  #           option = ".*\.typ";
  #           commands = "set-option buffer filetype typst";
  #         }
  #         {
  #           name = "WinSetOption";
  #           option = "filetype=typst";
  #           commands = ''
  #             hook buffer BufWritePost .* %{
  #               nop %sh{ ${pkgs.typst}/bin/typst compile "$kak_buffile" }
  #             }
  #           '';
  #         }
  #         {
  #           name = "WinSetOption";
  #           option = "filetype=(haskell|c|cpp|rust|python|javascript|typescript|latex|typst|dart|nix|go|cmake)";
  #           commands = ''
  #             lsp-enable-window
  #             lsp-inlay-diagnostics-enable window
  #             lsp-inlay-hints-enable window
  #             lsp-inlay-code-lenses-enable window
  #           '';
  #         }
  #         # {
  #         #   name = "WinSetOption";
  #         #   option = "filetype=(typescript|javascript)";
  #         #   commands = ''
  #         #     hook window BufWritePre .* %{ nop sh{ echo "from $kak_buffile" >out.log; prettier -w $kak_buffile >>out.log 2>err.log} }
  #         #   '';
  #         # }
  #         {
  #           name = "WinSetOption";
  #           option = "filetype=rust";
  #           commands = ''
  #             hook window -group rust-inlay-hints BufReload .* rust-analyzer-inlay-hints
  #             hook window -group rust-inlay-hints NormalIdle .* rust-analyzer-inlay-hints
  #             hook window -group rust-inlay-hints InsertIdle .* rust-analyzer-inlay-hints
  #             hook -once -always window WinSetOption filetype=.* %{
  #               remove-hooks window rust-inlay-hints
  #             }
  #           '';
  #         }
  #         {
  #           name = "ModuleLoaded";
  #           option = "fzf";
  #           commands = "set-option global fzf_highlight_command 'bat'";
  #         }
  #         {
  #           name = "ModuleLoaded";
  #           option = "fzf-file";
  #           commands = "set-option global fzf_file_command 'fd'";
  #         }
  #         {
  #           name = "ModuleLoaded";
  #           option = "fzf-grep";
  #           commands = ''
  #             set-option global fzf_grep_command 'rg'
  #             set-option global fzf_grep_preview_command 'bat'
  #           '';
  #         }
  #       ];
  #     };
  #     extraConfig = ''
  #       eval %sh{kak-lsp}
  #       lsp-enable
  #       eval %sh{ kak-tree-sitter -dks --with-highlighting --with-text-objects -vvvvv --init $kak_session }
  #       colorscheme catppuccin_mocha
  #       eval %sh{kak-lsp --kakoune -s $kak_session}
  #       set global lsp_hover_anchor true
  #       lsp-auto-signature-help-enable
  #       set-option global lsp_hover_anchor true
  #       set-option global lsp_auto_show_code_actions true
  #
  #       set-option global auto_pairs ( ) { } [ ] '"' '"' "'" "'" ` ` “ ” ‘ ’ « » ‹ ›
  #       enable-auto-pairs
  #
  #     '';
  #     #source ${config.home.sessionVariables.PROJECTS_DIR}/impurekaktestrc.kak
  #   };
}
