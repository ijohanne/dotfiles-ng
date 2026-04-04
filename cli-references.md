# CLI References

Quick reference for custom keybindings, aliases, and tool replacements configured in this repo.

## Tmux

Prefix: **Ctrl+A**

| Key | Action |
|-----|--------|
| `r` | Reload config |
| `h/j/k/l` | Navigate panes (vi-style) |
| `e` / `f` | Previous / next window |
| `E` / `F` | Swap window backward / forward |
| `=` | Split horizontal |
| `-` | Split vertical |
| `a` | Last window |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Copy to clipboard |

VI key mode, mouse enabled, windows start at 1, status bar at top.

## Neovim

Configured via [nixvim](https://github.com/nix-community/nixvim). Catppuccin Mocha theme.

### Navigation & LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Hover docs |
| `<leader>ca` | Code action |

### Telescope

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>gs` | Git status |

### General

| Key | Action |
|-----|--------|
| `<leader>q` | Close buffer |
| `<leader>w` | Save file |

### Completion (nvim-cmp)

| Key | Action |
|-----|--------|
| `<C-Space>` | Trigger completion |
| `<C-e>` | Abort |
| `<CR>` | Confirm |
| `<Tab>` / `<S-Tab>` | Next / previous |
| `<C-b>` / `<C-f>` | Scroll docs |

### Adding a language

Create `modules/community/home/languages/mylang/default.nix`:

```nix
{ pkgs-unstable, ... }:
{
  home.packages = [ pkgs-unstable.my-language-server ];
  programs.nixvim.extraConfigLua = ''
    vim.lsp.enable("my_server")
  '';
}
```

## Fish Shell

### Aliases

| Alias | Replacement |
|-------|-------------|
| `du` | `dust` |
| `top` | `htop` |
| `la` | `eza -la` |
| `lx` | `eza -la --sort=size` |
| `tree` | `eza --tree` |
| `lt` | `eza --tree -L 2` |
| `vim` / `vi` | `nvim` |
| `dig` | `doggo` |
| `ps` | `procs` |
| `cd` | `zoxide` (fuzzy directory history) |

### Tmux functions

| Function | Action |
|----------|--------|
| `ta` | FZF-pick and attach to tmux session |
| `tat [name]` | Create/attach tmux session |
| `tls` | List sessions |
| `tks` | Kill current session |
| `tka` | Kill all sessions |

## Tool Replacements

| Classic | Replacement | Notes |
|---------|-------------|-------|
| `cat` | `bat` | Syntax highlighting |
| `ls` | `eza` | Icons, tree view |
| `find` | `fd` | Simpler syntax |
| `diff` (git) | `delta` | Side-by-side, syntax highlighting |
| `cd` | `zoxide` | Frecency-based fuzzy matching |
| `grep` | `ripgrep` | Fast regex search |
| `top` | `htop` | Interactive process viewer |
| `ps` | `procs` | Modern ps replacement |

## Ghostty

Font: JetBrainsMono Nerd Font 14pt, Catppuccin Mocha theme.

## Zed

Vim mode enabled. LSP: rust-analyzer, nixd, lua-ls, marksman. Catppuccin Mocha theme.
