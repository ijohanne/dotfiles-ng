{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.marksman
  ];

  programs.nixvim.lsp.servers.marksman.enable = true;
}
