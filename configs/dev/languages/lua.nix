{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.lua-language-server
  ];

  programs.nixvim = {
    lsp.servers.lua_ls.enable = true;

    treesitter.ensureInstalled = [ "lua" ];
  };
}
