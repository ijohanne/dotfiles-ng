# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

This is a NixOS/Darwin dotfiles repository. It supports both Darwin and Linux based deployment. This repository uses flakes, so making any nix changes outside this repo are ephemeral. Solutions involving these approaches are to be immediately disregarded.

## Key Commands

### Building Configurations
```bash
# For Darwin
darwin-rebuild switch --flake .#macbook

# For Linux (NixOS)
sudo nixos-rebuild switch --flake .#ij-desktop

# Test build without activating
nix build .#darwinConfigurations.macbook.system
nix build .#nixosConfigurations.ij-desktop.config.system.build.toplevel
```

### Development
```bash
# Validate flake and check all configurations
nix flake check

# Show available outputs
nix flake show

# Update flake inputs
nix flake update
```

## Architecture

### Directory Structure
- `configs/` - contains specific setups for packages and bundles of them
- `hosts/` - contains how to wire up specific hosts
- `lib/` - contains library functions for use in the flake, including user settings

### User Settings
User settings are defined in `lib/user.nix`. Key settings include:
- `developer` - when true, enables LSP for neovim, lorri daemon, and dev language servers

### Special Features
- **Secrets**: Uses sops-nix with age encryption. Secrets are stored in `secrets/secrets.yaml` and configured via `.sops.yaml`. The age key is expected at `~/.config/sops/age/keys.txt`
- **Neovim**: Always use NixNeovim for all plugins and settings to be configured
- **Catppuccin**: Theme consistency across tools (tmux, neovim, lazygit) using Mocha flavor with blue accent (#89b4fa)
- **CLI Tools**: Uses home-manager programs module when available, otherwise adds to home.packages
- **Packages**: Prefer nixpkgs over Homebrew casks for Darwin when the nix package builds successfully on Darwin. Fall back to Homebrew casks only when the nix package doesn't build or isn't available for Darwin

## Development Tips
- Use 'nix store prefetch-file' to check hashes instead of 'nix-prefetch-url'
- Try to use tools like ldd and your expert knowledge of nixpkgs, nix language, nixos and linux to figure out what libs packages might require and what might be missing
- Use the Internet to help guide your solution. The nixpkgs repo at https://github.com/nixos/nixpkgs for source of every single package in nixpkgs and search.nixos.org to find both packages and nixos options are good starts.
- Always ensure that `nix flake check` passes after finishing a task
- When adding CLI tools, prefer home-manager programs modules (e.g., `programs.zoxide`, `programs.lazygit`, `programs.delta`) over raw packages when available
- For packages requiring initial setup (like tealdeer cache updates), add activation scripts via `home.activation`
- Test builds with `nix build` before running `darwin-rebuild switch` to catch errors faster

## Coding Guidelines
- Don't leave code comments, unless the code is not obvious
- For fish shell aliases only implement functions
- When adding conditional features, use `user.developer or false` pattern in config modules
