# dotfiles

Nix-based dotfiles for managing macOS and Linux configurations.

## Hosts

- **macbook** — macOS (aarch64-darwin)
- **ij-desktop** — Linux (x86_64-linux)

## Structure

- `hosts/` — Host-specific configurations
- `configs/` — Shared configurations for various programs
- `lib/` — Shared library definitions

## Usage

```bash
# Linux (NixOS)
sudo nixos-rebuild switch --flake .#ij-desktop

# macOS
sudo darwin-rebuild switch --flake .#macbook
```
