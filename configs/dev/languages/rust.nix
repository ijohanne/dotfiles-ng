{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.rust-bin.stable.latest.default
    pkgs-unstable.rust-bin.stable.latest.rust-analyzer
  ];

  programs.nixvim = {
    extraPlugins = with pkgs-unstable.vimPlugins; [
      crates-nvim
    ];

    treesitter.ensureInstalled = [ "rust" "toml" ];

    extraConfigLua = ''
      vim.lsp.enable("rust_analyzer")
      require("crates").setup()
    '';
  };
}
