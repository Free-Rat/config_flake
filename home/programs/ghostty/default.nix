{...}: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    settings = {
      font-family = "Monaspace Krypton Regular";
      font-family-bold = "Monaspace Krypton Bold";
      font-family-italic = "Monaspace Neon Regular Italic";
      font-family-bold-italic = "Monaspace Neon Bold Italic";
      font-size = 11;
      window-decoration = "none";
      background-opacity = 0.7;
      background = "#000000";
      cursor-opacity = 0.9;
      cursor-style = "block";
      shell-integration-features = "no-cursor";
    };
  };
}
