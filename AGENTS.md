# CLAUDE.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

NixOS/Darwin dotfiles repository using **flakes**. All nix changes must be made within this repo — changes outside are ephemeral and must not be suggested.

## Architecture

### Directory Structure

- `configs/` — shared configuration modules
  - `configs/users/` — per-user home-manager configs (ij.nix, mj.nix, common.nix)
  - `configs/darwin/` — macOS-specific modules
- `modules/community/home/programs/` — public reusable Home Manager program modules
- `modules/community/home/languages/` — public reusable language modules (rust, nix, lua, markdown, flutter) — self-contained: toolchain + LSP + neovim wiring
- `modules/private/inventory/` — private inventory data such as shared user and network registries
- `hosts/` — per-host wiring (configuration.nix, services/, home.nix)
- `lib/` — library functions (`user.nix` for user settings)
- `secrets/` — sops-encrypted secrets (`.sops.yaml` at repo root)
- `scripts/` — utility scripts

### Key References

- **@NETWORK.md** — network topology, VLANs, switches, DNS, and how `modules/private/inventory/network.nix` works
- **@cli-references.md** — keybindings and aliases for tmux, neovim, fish, tool replacements

### Shared Configuration

- **`modules/private/inventory/network.nix`** — single registry for all hosts (IPs, MACs, DNS, DNAT port forwarding), DHCP reservations, `mkDnatRules`, and `mailDomains`
- **`modules/community/home/languages/`** — composable language modules; each provides packages + neovim LSP wiring via `pkgs-unstable`
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

### Remote hosts (goose, pakhet, khosu, anubis)

These hosts pull the flake from GitHub via `deploy-<hostname>` wrappers. Changes **must be pushed first**.

When a matching local checkout is found, the deploy helper intentionally runs `git add -A`
before rebuilding from that checkout. Use `--no-local` to skip the local-checkout path and
build from GitHub instead.

```bash
git push
ssh r0.est.unixpimps.net deploy-goose        # goose (router)
ssh pakhet.est.unixpimps.net deploy-pakhet    # pakhet (server)
ssh khosu.unixpimps.net deploy-khosu          # khosu (VPS)
ssh anubis.unixpimps.net deploy-anubis        # anubis (Kimsufi)
```

The `deploy-<hostname>` wrapper checks for a local checkout under any user's `~/git/dotfiles-ng`, intentionally runs `git add -A`, and builds from it if found. Pass `--no-local` to skip that behavior and rebuild directly from GitHub instead. See @NETWORK.md for IPs.

#### Alternative: `nixos-rebuild` with `--target-host` and `--build-host`

For first-time deploys or when the remote host can't fetch private flake inputs yet, use `nix run nixpkgs#nixos-rebuild` from any machine. Build on a host that has `nix_builder_access_tokens` (e.g. pakhet):

```bash
nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#<hostname> \
  --target-host root@<target> \
  --build-host root@pakhet.est.unixpimps.net
```

All remote hosts have `nix_builder_access_tokens` configured via sops for fetching private GitHub flake inputs. For a brand new host, bootstrap the first deploy using `--build-host` pointed at an existing host that already has the tokens decrypted.

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

## Issue Tracking

This project uses **vardrun** for issue tracking (not GitHub Issues).
When the user says "issue", they mean a vardrun issue.
Run `vardrun prime` for full workflow context — do this at the start of every session.

**Quick reference:**
- `vardrun ready` — find unblocked work
- `vardrun create "Title" --type task --priority 2` — create issue
- `vardrun update <id> --status in_progress` — **take/claim** an issue (auto-assigns you)
- `vardrun update <id> --implementation @plan.md` — set implementation details (markdown)
- `vardrun close <id>` — complete work
- `vardrun show <id> --json` — view issue details (JSON for agents)
- `vardrun list --json` — list all open issues (JSON for agents)
- `vardrun sync` — sync with remote (run after every mutation)

**Taking an issue** = `vardrun update <id> --status in_progress` then `vardrun sync`.
"Take", "claim", "work on", "pick up" all mean this. Always sync after so changes
are visible in the TUI and web interface.

**Tracker hygiene for agents:**
- Put technical plans, rollout steps, acceptance notes, and implementation details in the `implementation` field, not in comments.
- Use vardrun relationships (`dep add ... --type related` or blockers when appropriate) to model epics/child work instead of writing "children" lists in comments.
- Use comments only for human-facing progress updates, decisions, or other historical notes that are useful to read chronologically later.
- If you mutate vardrun state multiple times, prefer serialized `create/update/dep/comment/sync` operations over parallel mutations. The tracker syncs through GitHub, so racing mutations can produce inconsistent state.

**For agents:** Use `--json` on any command to discover field structure at runtime.
For full workflow details and all commands: `vardrun prime`
