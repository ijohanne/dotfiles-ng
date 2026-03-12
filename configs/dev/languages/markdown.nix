{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.marksman
  ];

  programs.nixvim.extraConfigLua = ''
    vim.lsp.enable("marksman")
  '';
}
