{...}: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    settings = {
      font-family = "Monaspace Krypton Light";
      font-family-bold = "Monaspace Krypton Bold";
      font-family-italic = "Monaspace Neon Light Italic";
      font-family-bold-italic = "Monaspace Neon Bold Italic";
      font-size = 10;
      window-decoration = "none";
      background-opacity = 0.5;
      background = "#000000";
      cursor-opacity = 0.8;
      cursor-style = "block";
      shell-integration-features = "no-cursor";
    };
  };
}
