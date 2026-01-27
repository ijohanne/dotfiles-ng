# dotfiles

Nix-based dotfiles for managing macOS and Linux configurations.

## Table of Contents

- [Overview](#overview)
  - [Hosts](#hosts)
  - [Structure](#structure)
  - [User Settings](#user-settings)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [macOS Setup](#macos-setup)
  - [Linux Desktop Setup](#linux-desktop-setup)
  - [Raspberry Pi 4 Image](#raspberry-pi-4-image)
- [Reference](#reference)
  - [Terminal Tools](#terminal-tools)
  - [Neovim](#neovim)
  - [Tmux](#tmux)
  - [Secrets Management](#secrets-management)

## Overview

### Hosts

- **macbook** — macOS (aarch64-darwin)
- **ij-desktop** — Linux (x86_64-linux)
- **rpi4-stable** — Raspberry Pi 4 SD card image (aarch64-linux, nixos-25.05)
- **rpi4-unstable** — Raspberry Pi 4 SD card image (aarch64-linux, nixos-unstable)

### Structure

- `hosts/` — Host-specific configurations
- `configs/` — Shared configurations for various programs
- `lib/` — Shared library definitions

### User Settings

User settings are defined in `lib/user.nix`:

```nix
{
  username = "ij";
  email = "ij@opsplaza.com";
  name = "Ian Johannesen";
  developer = true;  # Enable LSP for neovim, lorri daemon, dev packages
}
```

#### Developer Setting

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

## Quick Start

```bash
# macOS
darwin-rebuild switch --flake .#macbook

# Linux (NixOS)
sudo nixos-rebuild switch --flake .#ij-desktop
```

## Installation

### macOS Setup

#### Prerequisites

1. Install Nix:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Enable flakes (if not using Determinate installer):
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

#### Installation Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Edit `lib/user.nix` with your details:
   ```nix
   {
     username = "your-username";
     email = "your@email.com";
     name = "Your Name";
     developer = true;
   }
   ```

3. Bootstrap nix-darwin (first time only):
   ```bash
   nix run nix-darwin -- switch --flake .#macbook
   ```

4. After bootstrap, use darwin-rebuild:
   ```bash
   darwin-rebuild switch --flake .#macbook
   ```

#### Post-Installation

- Restart your terminal to load fish shell
- Touch ID for sudo is enabled automatically

#### Remote Builder

The macbook is configured to use pakhet (10.255.101.200) as a remote builder for x86_64-linux and aarch64-linux builds.

After deploying the configuration, run the setup script to add the remote builder's SSH host key:

```bash
setup-remote-builder
```

This will:
1. Add pakhet's SSH host key to root's known_hosts
2. Test the connection to verify everything works

### Linux Desktop Setup

The Linux desktop uses disko for declarative disk partitioning with LUKS encryption.

#### Disk Layout

- `/boot` — 512MB EFI System Partition (FAT32)
- LUKS encrypted partition containing LVM:
  - `swap` — 8GB swap with hibernation support
  - `root` — Remaining space as ext4

#### Installation Steps

1. Boot NixOS installer

2. Edit `hosts/ij-desktop/disko.nix` if your disk is not `/dev/nvme0n1`

3. Partition and format the disk:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./hosts/ij-desktop/disko.nix
   ```

4. Mount the partitions (disko does this, but verify):
   ```bash
   mount | grep /mnt
   ```

5. Install NixOS:
   ```bash
   sudo nixos-install --flake .#ij-desktop
   ```

6. Set the LUKS password when prompted during first boot

7. After installation, rebuild with:
   ```bash
   sudo nixos-rebuild switch --flake .#ij-desktop
   ```

### Raspberry Pi 4 Image

The RPi4 images are templates for bootstrapping new NixOS hosts on Raspberry Pi 4. Two variants are available:

- **rpi4-stable** — Uses nixos-25.05 (recommended for production)
- **rpi4-unstable** — Uses nixos-unstable (latest features)

#### Building the Image

```bash
# Stable (recommended)
nix build .#images.rpi4-stable

# Unstable
nix build .#images.rpi4-unstable
```

#### Writing to SD Card

```bash
sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress
```

#### First Boot

The image includes:
- SSH enabled with authorized keys from `lib/user.nix`
- Flakes enabled
- A `rebuild` alias for easy updates

After booting, you can update the system directly from this repository:

```bash
rebuild#rpi4-stable
# or
rebuild#rpi4-unstable
```

#### Creating a New Host from Template

To use this as a starting point for a new dedicated host:

1. Copy the template to a new host directory:
   ```bash
   cp -r hosts/rpi4-image/stable hosts/my-new-rpi
   ```

2. Edit `hosts/my-new-rpi/configuration.nix`:
   ```nix
   networking.hostName = lib.mkForce "my-new-rpi";
   ```

3. Add the new host to `flake.nix`:
   ```nix
   nixosConfigurations = {
     my-new-rpi = nixpkgs-stable.lib.nixosSystem {
       system = "aarch64-linux";
       specialArgs = { inherit inputs self user; };
       modules = [
         ./hosts/my-new-rpi/configuration.nix
       ];
     };
   };
   ```

4. Customize the configuration as needed (add packages, services, etc.)

5. After first boot, switch to the new configuration:
   ```bash
   sudo nixos-rebuild switch --flake github:yourusername/dotfiles#my-new-rpi
   ```

## Reference

### Terminal Tools

#### Zoxide — Smart cd

Intelligent directory jumping that learns your most frequently used directories.

```bash
z project-name        # Jump to directory
zoxide query          # Show frecent directories
cd ~/code             # Also works with regular cd (aliased via --cmd cd)
```

#### Lazygit — Git TUI

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

#### Delta — Git Diff Viewer

Syntax-highlighting pager for git diffs.

```bash
git diff             # Automatic when configured as git pager
git log -p           # View diffs in log
```

#### Tealdeer — Quick Command Help

Community-driven command cheatsheets.

```bash
tldr tar             # Show tar cheatsheet
tldr --list          # List all available commands
tldr --update        # Update cache
```

#### Procs — Modern ps Replacement

Colorful process viewer with better formatting.

```bash
procs                # View all processes
procs 8080           # Search by port/PID
procs nginx          # Search by name
ps | procs           # Pipe from ps
```

#### Dog — DNS Client

Modern DNS client with JSON output and DoH/DoT support.

```bash
dog example.com              # Simple lookup
dog example.com MX           # Query MX records
dog example.com --json       # JSON output
dog --reverse 8.8.8.8        # Reverse DNS
```

#### Fish Shell Abbreviations

```bash
tldr <command>     # Quick help (tealdeer)
ps                 # Modern process viewer (procs)
dig <domain>       # DNS lookup (dog)
```

### Neovim

Configured via NixVim with Catppuccin theme. When `developer = true`, includes LSP support for Nix, Rust, Lua, and Markdown.

#### General

- **Leader:** `Space`
- `<leader>w` — Save file
- `<leader>q` — Close buffer
- `<leader>ff` — Find files (Telescope)
- `<leader>fg` — Live grep (Telescope)
- `<leader>fb` — Find buffers (Telescope)
- `<leader>gs` — Git status (Telescope)

#### LSP (developer mode)

- `gd` — Go to definition
- `gr` — Show references
- `K` — Hover documentation
- `gl` — Show diagnostic
- `[d` / `]d` — Previous/next diagnostic
- `<leader>ca` — Code action

#### Completion (developer mode)

- `<Tab>` / `<S-Tab>` — Next/previous item
- `<CR>` — Confirm selection
- `<C-Space>` — Trigger completion
- `<C-e>` — Abort completion
- `<C-b>` / `<C-f>` — Scroll docs

### Tmux

- **Prefix:** `C-a` (instead of default `C-b`)
- **Keybindings:**
  - `C-a r` — Reload config
  - `hjkl` — Navigate panes
  - `C-a =` — Split horizontal
  - `C-a -` — Split vertical
  - `C-a e/f` — Previous/next window
  - `C-a E/F` — Swap windows

### Secrets Management

Secrets are managed using [sops-nix](https://github.com/Mic92/sops-nix) with age encryption.

#### File Structure

Secrets are organized per-host for isolation:

- `secrets/macbook.yaml` — macbook-only secrets
- `secrets/pakhet.yaml` — pakhet-only secrets
- `secrets/shared.yaml` — secrets accessible by all hosts (if needed)

Each file is encrypted with only the keys that need access, configured in `.sops.yaml`.

#### Key Locations

sops-nix tries these keys in order:
1. `/etc/ssh/ssh_host_ed25519_key` — SSH host key (preferred)
2. `/etc/ssh/ssh_host_rsa_key` — SSH host key (fallback)
3. `~/.config/sops/age/keys.txt` — Personal age key

#### Setup

1. Generate a personal age key (if not using SSH host keys):
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. Get your public key:
   ```bash
   # From age key
   age-keygen -y ~/.config/sops/age/keys.txt

   # From SSH host key
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

3. Add the public key to `.sops.yaml`:
   ```yaml
   keys:
     - &mykey age1...your-public-key...
   
   creation_rules:
     - path_regex: secrets/myhost\.(yaml|json|env|ini)$
       key_groups:
         - age:
             - *mykey
   ```

#### Usage

```bash
# Edit host-specific secrets
sops secrets/macbook.yaml
sops secrets/pakhet.yaml

# View decrypted secrets
sops -d secrets/macbook.yaml
```

#### Adding New Secrets

1. Edit the appropriate secrets file:
   ```bash
   sops secrets/macbook.yaml  # for macbook
   sops secrets/pakhet.yaml   # for pakhet
   ```

2. Add your secret:
   ```yaml
   my_api_key: supersecretvalue
   ```

3. Reference in nix config:
   ```nix
   # In configs/secrets.nix (for macbook/ij-desktop)
   sops.secrets.my_api_key = {};
   
   # Or in host-specific config (for pakhet)
   sops.secrets.my_api_key = {};
   ```

4. Use the secret path in your configuration:
   ```nix
   # The decrypted secret is available at:
   # config.sops.secrets.my_api_key.path
   # Which resolves to: /run/secrets/my_api_key
   ```

#### Adding a New Host

1. Get the new host's public key:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Add to `.sops.yaml`:
   ```yaml
   keys:
     - &newhost age1...public-key...
   
   creation_rules:
     - path_regex: secrets/newhost\.(yaml|json|env|ini)$
       key_groups:
         - age:
             - *ij
             - *newhost
   ```

3. Create the secrets file:
   ```bash
   sops secrets/newhost.yaml
   ```
