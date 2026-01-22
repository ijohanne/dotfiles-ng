# Neovim Configuration Guide

This module uses [nixvim](https://github.com/nix-community/nixvim) to configure Neovim with LSP support, completion, and plugins.

## Common Development Module

All development tools (Neovim, Rust, LSPs) are configured in `configs/dev.nix` and shared between all hosts.

### Importing the Dev Module

Add to your host's `home.nix`:

```nix
{
  imports = [
    ../../configs
    ../../configs/dev.nix
  ];
}
```

## LSP Configuration

LSP servers are configured in `extraConfigLua` using `vim.lsp.config` and `vim.lsp.enable`:

```nix
extraConfigLua = ''
  vim.lsp.config("server_name", { capabilities = capabilities })
  vim.lsp.enable("server_name")
'';
```

### Available LSP Packages

Common LSP packages in nixpkgs:
- `nixd` - Nix language server
- `rust-analyzer` - Rust language server (from rust-overlay)
- `lua-language-server` - Lua language server
- `pyright` - Python language server
- `typescript-language-server` - TypeScript/JavaScript
- `eslint-language-server` - ESLint
- `taplo` - TOML
- `yaml-language-server` - YAML
- `marksman` - Markdown

## Completion (nvim-cmp)

Completion is configured via `extraConfigLua` using nvim-cmp with the following sources:
- `nvim_lsp` - LSP completions
- `nvim_lsp_signature_help` - Function signature help
- `vsnip` - Snippet completions
- `buffer` - Buffer completions
- `path` - Path completions

Key mappings:
- `<C-Space>` - Trigger completion
- `<C-e>` - Abort completion
- `<CR>` - Confirm selection
- `<Tab>`/`<S-Tab>` - Next/previous item
- `<C-b>`/`<C-f>` - Scroll documentation

## Treesitter

To add treesitter support for a language:

```nix
treesitter = {
  enable = true;
  ensureInstalled = [
    "nix"
    "rust"
    "lua"
    # Add new language here...
  ];
};
```

## Keybindings

| Keybinding | Description |
|------------|-------------|
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Show hover |
| `<leader>ca` | Code action |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep (Telescope) |
| `<leader>fb` | Find buffers (Telescope) |
| `<leader>gs` | Git status (Telescope) |
| `<leader>q` | Close buffer |
| `<leader>w` | Save file |

## Plugins Installed

### Completion
- nvim-cmp - Completion engine
- cmp-nvim-lsp - LSP completion source
- cmp-nvim-lsp-signature-help - Function signature help
- cmp-buffer - Buffer completion source
- cmp-path - Path completion source
- cmp-cmdline - Cmdline completion source
- cmp-vsnip - Snippet completion source
- vim-vsnip - Snippet engine

### LSP
- nvim-lspconfig - LSP configuration framework
- fidget-nvim - LSP progress notifications

### Git
- gitsigns-nvim - Git signs and current line blame
- catppuccin-nvim - Colorscheme

### Rust
- crates-nvim - Cargo.toml dependency management

### Search/Finder
- telescope-nvim - Fuzzy finder
- grug-far-nvim - Advanced search/replace
- fzf-vim - FZF integration
- fzfWrapper - FZF wrapper

### Syntax
- nvim-treesitter - Syntax highlighting
- nvim-treesitter-textobjects - Syntax objects

## Colorscheme

Uses catppuccin colorscheme.

## Rust Toolchain

Rust is provided by [oxalica/rust-overlay](https://github.com/oxalica/rust-overlay) for up-to-date versions.

Available packages:
- `pkgs.rust-bin.stable.latest.default` - Rust toolchain (rustc, cargo, rustfmt, clippy, etc.)
- `pkgs.rust-bin.stable.latest.rust-analyzer` - Rust analyzer binary
