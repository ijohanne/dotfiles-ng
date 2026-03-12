{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.nixd
  ];

  programs.nixvim.extraConfigLua = ''
    vim.lsp.enable("nixd")
  '';
}
