{...}: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    settings = {
      # theme = "deep";
      theme = "Homebrew";
      font-family = "Monaspace Krypton";
      font-family-bold = "Monaspace Krypton Bold";
      font-family-italic = "Monaspace Neon Regular Italic";
      font-family-bold-italic = "Monaspace Neon Bold Italic";
      font-size = 11;
      window-decoration = "none";
      background-opacity = 0.99;
      background = "#000000";
      # cursor-opacity = 0.9;
      cursor-style = "block";
      shell-integration-features = "no-cursor";

      gtk-adwaita = false;
      # optionally disable GTK titlebar and wide tabs if you want a more minimal look
      gtk-titlebar = false;
      gtk-wide-tabs = false;
      gtk-single-instance = true;
    };
  };
}
