# Neovim Configuration

Uses [nixvim](https://github.com/nix-community/nixvim). Two layers:

- **`configs/programs/neovim/`** — base config (opts, colorscheme, treesitter, cmp, LSP infra). Sets `vim.lsp.config('*', { capabilities })` so all servers get cmp capabilities.
- **`configs/dev/languages/`** — self-contained language modules. Each provides toolchain + LSP server + `vim.lsp.enable("server")`.

Language modules use `pkgs-unstable` for LSP/toolchain packages.

## Adding a Language

Create `configs/dev/languages/mylang.nix`:

```nix
{ pkgs-unstable, ... }:
{
  home.packages = [ pkgs-unstable.my-language-server ];
  programs.nixvim.extraConfigLua = ''
    vim.lsp.enable("my_server")
  '';
}
```

## Importing

```nix
# Desktop — all languages
imports = [
  ../../configs/programs/neovim
  ../../configs/dev/languages
];

# Server — selective
imports = [
  ../../configs/programs/neovim
  ../../configs/dev/languages/nix.nix
];
```

For keybindings and plugin list, see [cli-references.md](/cli-references.md).
