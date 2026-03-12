{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.lua-language-server
  ];

  programs.nixvim = {
    treesitter.ensureInstalled = [ "lua" ];

    extraConfigLua = ''
      vim.lsp.enable("lua_ls")
    '';
  };
}
