# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

This is a NixOS/Darwin dotfiles repository. It supports both Darwin and Linux based deployment. This repository uses flakes, so making any nix changes outside this repo are ephemeral. Solutions involving these approaches are to be immediately disregarded. 

## Key Commands

### Building Configurations
```bash
darwin-rebuild build --flake .#macbook # For Darwin
```

### Development
```bash
# Validate flake and check all configurations
nix flake check

# Show available outputs
nix flake show
```

## Architecture

### Directory Structure
- `configs/` - contains specific setups for packages and bundles of them
- `hosts/` - contains how to wire up specific hosts
- `lib/` - contains library functions for use in the flake

### Special Features
- **Secrets**: Uses agenix for encrypted secrets in `systems/*/secrets/`
- **Neovim**: Always use NixNeovim for all plugins and settings to be configured

## Development Tips
- Use 'nix store prefetch-file' to check hashes instead of 'nix-prefetch-url'
- Try to use tools like ldd and your expert knowledge of nixpkgs, nix language, nixos and linux to figure out what libs packages might require and what might be missing
- Use the Internet to help guide your solution. The nixpkgs repo at https://github.com/nixos/nixpkgs for source of every single package in nixpkgs and search.nixos.org to find both packages and nixos options are good starts.
- Always ensure that `nix flake check` passes after finishing a task

## Coding Guidelines
- Don't leave code comments, unless the code is not obvious
- For fish shell aliases only implement functions
