{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.nixd
  ];

  programs.nixvim.lsp.servers.nixd.enable = true;
}
