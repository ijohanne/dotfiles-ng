{ pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.rust-bin.stable.latest.default
    pkgs-unstable.rust-bin.stable.latest.rust-analyzer
  ];

  programs.nixvim = {
    lsp.servers.rust_analyzer.enable = true;

    extraPlugins = with pkgs-unstable.vimPlugins; [
      crates-nvim
    ];

    treesitter.ensureInstalled = [ "rust" "toml" ];

    extraConfigLua = ''
      require("crates").setup()
    '';
  };
}
