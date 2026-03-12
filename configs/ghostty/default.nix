{ ... }:
{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    enableFishIntegration = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;
      theme = "Catppuccin Mocha";
      auto-update = "off";
      term = "xterm-256color";
    } // (if pkgs.stdenv.isDarwin then {
      macos-titlebar-style = "native";
      quit-after-last-window-closed = "true";
    } else {});
  };
}
