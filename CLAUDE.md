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

### Local hosts (macbook, ij-desktop)

```bash
# Darwin
darwin-rebuild switch --flake .#macbook

# NixOS
sudo nixos-rebuild switch --flake .#ij-desktop
```

### Remote hosts (goose, pakhet, khosu)

These hosts pull the flake from GitHub via `deploy-<hostname>` wrappers. Changes **must be pushed first**.

```bash
git push
ssh r0.est.unixpimps.net deploy-goose        # goose (router)
ssh pakhet.est.unixpimps.net deploy-pakhet    # pakhet (server)
ssh khosu.unixpimps.net deploy-khosu          # khosu (VPS)
```

The `deploy-<hostname>` wrapper checks for a local checkout under any user's `~/git/dotfiles-ng`, runs `git add -A` and builds from it if found, otherwise fetches from GitHub. See @NETWORK.md for IPs.

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

# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work (open, no blockers)
bd blocked            # Show blocked issues and what blocks them
bd list               # List all issues (with blocker annotations)
bd show <id>          # View issue details
bd claim <id>         # Claim work (atomic compare-and-swap)
bd close <id>         # Complete work
bd dolt push          # Push to Dolt remote
```

**Dependency status**: `bd ready` and `bd blocked` are the authoritative
sources for whether work is blocked. `bd list` shows active blocker
annotations but use `bd ready`/`bd blocked` for accurate blocking status.

## Agent Warning: Interactive Commands

**DO NOT use `bd edit`** - it opens an interactive editor ($EDITOR) which AI agents cannot use.

Use `bd update` with flags instead:
```bash
bd update <id> --description "new description"
bd update <id> --title "new title"
bd update <id> --design "design notes"
bd update <id> --notes "additional notes"
bd update <id> --acceptance "acceptance criteria"
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
