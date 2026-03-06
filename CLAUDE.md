# CLAUDE.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

NixOS/Darwin dotfiles repository using **flakes**. All nix changes must be made within this repo — changes outside are ephemeral and must not be suggested.

## Architecture

### Directory Structure

- `configs/` — shared configuration modules (packages, network registry, neovim, dev tools)
- `hosts/` — per-host wiring (configuration.nix, services/, home.nix)
- `lib/` — library functions (`user.nix` for user settings)
- `secrets/` — sops-encrypted secrets (`.sops.yaml` at repo root)
- `scripts/` — utility scripts

### Key References

- **@NETWORK.md** — full network topology, VLANs, switches, cameras, DNS, and how `configs/network.nix` works
- **@configs/nvim_README.md** — neovim/nixvim configuration, LSP setup, keybindings, plugins

### Shared Configuration

- **`configs/network.nix`** — single registry for all hosts (IPs, MACs, DNS), DHCP reservations, and `mailDomains` (used by both khosu and pakhet mail configs)
- **`lib/user.nix`** — user settings; `developer = true` enables LSP, dev tools

### Secrets Management

Uses **sops-nix** (not agenix). Secrets are in `secrets/` encrypted per-host. Tools: `sops`, `age`.

## Host Configurations

| Host | Arch | Nixpkgs | Role |
|------|------|---------|------|
| `macbook` | aarch64-darwin | unstable | Workstation (Darwin + home-manager + nixvim) |
| `ij-desktop` | x86_64-linux | unstable | Desktop workstation |
| `goose` | x86_64-linux | stable | Router/gateway (DNS, DHCP, firewall) |
| `pakhet` | x86_64-linux | stable | Server (mail, gitea, web services) — VM on fatty |
| `khosu` | x86_64-linux | stable | VPS (mail relay, MX for inbound) |
| `rpi4-stable/unstable` | aarch64-linux | stable/unstable | Raspberry Pi images |

## Deployment

### Local hosts (macbook, ij-desktop, goose, pakhet)

```bash
# Darwin
darwin-rebuild switch --flake .#macbook

# NixOS
sudo nixos-rebuild switch --flake .#<hostname>
```

### VPS hosts (khosu)

VPS hosts pull the flake directly from GitHub. Changes **must be pushed first**.

```bash
git push
ssh khosu.unixpimps.net deploy-khosu
```

The `deploy-<hostname>` wrapper runs `nixos-rebuild switch --flake github:ijohanne/dotfiles-ng#<hostname> --refresh`.

### Test builds (without activating)

```bash
nix build .#darwinConfigurations.macbook.system
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### Validation

```bash
nix flake check
nix flake show
```

## Development Tips

- Use `nix store prefetch-file` to check hashes (not `nix-prefetch-url`)
- Use `ldd` and nixpkgs knowledge to find missing libs
- The nixpkgs repo at https://github.com/nixos/nixpkgs and https://search.nixos.org are good references
- Always ensure `nix flake check` passes after finishing a task
- Prefer home-manager `programs.*` modules over raw packages when available
- Test builds with `nix build` before `switch` to catch errors faster

## Coding Guidelines

- Don't leave code comments unless the code is not obvious
- For fish shell aliases, only implement functions
- When adding conditional features, use `user.developer or false` pattern
- **Catppuccin** theme: Mocha flavor, blue accent (#89b4fa) — consistent across tmux, neovim, lazygit
