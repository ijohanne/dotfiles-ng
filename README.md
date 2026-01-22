# dotfiles

Nix-based dotfiles for managing macOS and Linux configurations.

## Hosts

- **macbook** — macOS (aarch64-darwin)
- **ij-desktop** — Linux (x86_64-linux)

## Structure

- `hosts/` — Host-specific configurations
- `configs/` — Shared configurations for various programs
- `lib/` — Shared library definitions

## User Settings

User settings are defined in `lib/user.nix`:

```nix
{
  username = "ij";
  email = "ij@opsplaza.com";
  name = "Ian Johannesen";
  developer = true;  # Enable LSP for neovim, lorri daemon, dev packages
}
```

### Developer Setting

When `developer = true`:
- Neovim LSP is enabled (nixd, rust-analyzer, lua_ls)
- Neovim completion (nvim-cmp) with LSP sources
- LSP keybindings (gd, gr, K, leader ca)
- Lorri daemon service (Linux only)
- Dev language servers (nixd, lua-language-server)

When `developer = false`:
- Basic neovim without LSP
- No completion engine
- No LSP keybindings
- No lorri daemon

## Usage

```bash
# Linux (NixOS)
sudo nixos-rebuild switch --flake .#ij-desktop

# macOS
sudo darwin-rebuild switch --flake .#macbook
```

## Terminal Tools

### Zoxide — Smart cd

Intelligent directory jumping that learns your most frequently used directories.

```bash
z project-name        # Jump to directory
zoxide query          # Show frecent directories
cd ~/code             # Also works with regular cd (aliased via --cmd cd)
```

### Lazygit — Git TUI

Feature-rich git terminal UI with Catppuccin Mocha theme.

```bash
lazygit              # Open git TUI
```

**Keybindings:**
- `p` - push
- `P` - pull
- `c` - commit
- `r` - rebase
- `m` - merge

### Delta — Git Diff Viewer

Syntax-highlighting pager for git diffs.

```bash
git diff             # Automatic when configured as git pager
git log -p           # View diffs in log
```

### Tealdeer — Quick Command Help

Community-driven command cheatsheets.

```bash
tldr tar             # Show tar cheatsheet
tldr --list          # List all available commands
tldr --update        # Update cache
```

### Procs — Modern ps Replacement

Colorful process viewer with better formatting.

```bash
procs                # View all processes
procs 8080           # Search by port/PID
procs nginx          # Search by name
ps | procs           # Pipe from ps
```

### Dog — DNS Client

Modern DNS client with JSON output and DoH/DoT support.

```bash
dog example.com              # Simple lookup
dog example.com MX           # Query MX records
dog example.com --json       # JSON output
dog --reverse 8.8.8.8        # Reverse DNS
```

## Fish Shell Abbreviations

```bash
tldr <command>     # Quick help (tealdeer)
ps                 # Modern process viewer (procs)
dig <domain>       # DNS lookup (dog)
```

## Tmux

- **Prefix:** `C-a` (instead of default `C-b`)
- **Keybindings:**
  - `C-a r` — Reload config
  - `hjkl` — Navigate panes
  - `C-a =` — Split horizontal
  - `C-a -` — Split vertical
  - `C-a e/f` — Previous/next window
  - `C-a E/F` — Swap windows
